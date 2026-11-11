//! Explorer's bounded representations over the existing CLIPSVC owner.
//! A failed commit retains its exact token until Status or Abort resolves it.
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const offers = r.clipboard_offer;
const stream = r.stream_transfer;
const time = r.time_contract.checked;

const Pending = struct { lease: offers.Lease, ready: bool = false };

pub const Owner = struct {
    client: ?offers.Client = null,
    pending: ?Pending = null,
    snapshot: ?offers.Lease = null,

    pub fn connect(self: *Owner, app: *const r.App2) i32 {
        if (self.client != null) return 0;
        var client: offers.Client = undefined;
        const rc = app.clipboardOffers(&client);
        if (rc == 0) self.client = client;
        return rc;
    }

    fn resolve(self: *Owner) i32 {
        const pending = self.pending orelse return 0;
        const client = &(self.client orelse return a.clipboard_offer_error_closed);
        var current: offers.Lease = undefined;
        const rc = if (pending.ready) client.status(pending.lease, &current) else client.abort(pending.lease);
        if (rc == a.clipboard_offer_error_closed or rc == a.clipboard_offer_error_provider_changed or rc == a.clipboard_offer_error_not_found) {
            self.pending = null;
            return 0;
        }
        if (rc != 0) return rc;
        if (pending.ready and current.state == a.clipboard_offer_state_writing) {
            const aborted = client.abort(pending.lease);
            if (aborted != 0 and aborted != a.clipboard_offer_error_closed and aborted != a.clipboard_offer_error_provider_changed and aborted != a.clipboard_offer_error_not_found) return aborted;
        }
        self.pending = null;
        return 0;
    }

    pub fn publish(self: *Owner, format: u32, payload: []const u8, result: *offers.Lease) i32 {
        const resolved = self.resolve();
        if (resolved != 0) return resolved;
        const client = &(self.client orelse return a.clipboard_offer_error_closed);
        var budget = r.rpc_budget.Budget.fromTimeout(client.clock, r.time_contract.timeoutFinite(.{ .nanoseconds = 5_000_000_000 })) catch |err| return r.rpc_budget.code(err);
        var view = client.withBudget(&budget) catch |err| return r.rpc_budget.code(err);
        var info: offers.Info = undefined;
        var rc = view.info(&info);
        if (rc != 0) return rc;
        view = client.withBudget(&budget) catch |err| return r.rpc_budget.code(err);
        var stage: offers.Lease = undefined;
        rc = view.begin(info, payload.len, &stage);
        if (rc != 0) return rc;
        self.pending = .{ .lease = stage };
        view = client.withBudget(&budget) catch |err| return r.rpc_budget.code(err);
        rc = view.declare(stage, 0, format, payload.len);
        if (rc != 0) return rc;
        var offset: usize = 0;
        while (offset < payload.len) {
            const end = offset + @min(payload.len - offset, a.clipboard_offer_put_chunk);
            view = client.withBudget(&budget) catch |err| return r.rpc_budget.code(err);
            rc = view.put(stage, 0, format, offset, payload.len, payload[offset..end]);
            if (rc != 0) return rc;
            offset = end;
        }
        self.pending.?.ready = true;
        view = client.withBudget(&budget) catch |err| return r.rpc_budget.code(err);
        rc = view.commit(stage, result);
        if (rc == 0) self.pending = null;
        return rc;
    }

    fn release(self: *Owner) i32 {
        const snapshot = self.snapshot orelse return 0;
        const client = &(self.client orelse return a.clipboard_offer_error_closed);
        const rc = client.release(snapshot);
        if (rc == 0 or rc == a.clipboard_offer_error_closed or rc == a.clipboard_offer_error_provider_changed) self.snapshot = null;
        return rc;
    }

    /// Output remains private until the original snapshot release is known.
    pub fn read(self: *Owner, format: u32, storage: []u8, identity: *offers.Lease) i32 {
        if (self.snapshot != null and self.release() != 0) return a.clipboard_offer_error_closed;
        const client = &(self.client orelse return a.clipboard_offer_error_closed);
        var budget = r.rpc_budget.Budget.fromTimeout(client.clock, r.time_contract.timeoutFinite(.{ .nanoseconds = 5_000_000_000 })) catch |err| return r.rpc_budget.code(err);
        var view = client.withBudget(&budget) catch |err| return r.rpc_budget.code(err);
        var snapshot: offers.Lease = undefined;
        const rc = view.snapshot(&snapshot);
        if (rc != 0) return rc;
        self.snapshot = snapshot;
        const count = self.readSnapshot(format, storage, snapshot, &budget);
        const released = self.release();
        if (released != 0) return released;
        if (count >= 0) identity.* = snapshot;
        return count;
    }

    fn readSnapshot(self: *Owner, format: u32, storage: []u8, snapshot: offers.Lease, budget: *r.rpc_budget.Budget) i32 {
        const client = &(self.client orelse return a.clipboard_offer_error_closed);
        var cursor: u32 = 0;
        var selected: ?offers.Format = null;
        while (true) {
            var formats: [8]offers.Format = undefined;
            var page: offers.Page = undefined;
            const view = client.withBudget(budget) catch |err| return r.rpc_budget.code(err);
            const rc = view.enumerate(snapshot, cursor, &formats, &page);
            if (rc != 0) return rc;
            for (formats[0..page.count]) |candidate| {
                if (candidate.format == format and (selected == null or candidate.item < selected.?.item)) selected = candidate;
            }
            if (page.next == page.total) break;
            if (page.next <= cursor) return a.clipboard_offer_error_invalid;
            cursor = page.next;
        }
        const chosen = selected orelse return a.clipboard_offer_error_not_found;
        if (chosen.total_bytes > storage.len) return a.clipboard_offer_error_too_large;
        var reader = OfferReader{ .client = client.*, .snapshot = snapshot, .format = chosen };
        if (chosen.total_bytes == 0) {
            var chunk: offers.Chunk = undefined;
            const view = client.withBudget(budget) catch |err| return r.rpc_budget.code(err);
            const rc = view.read(snapshot, chosen.item, format, 0, storage[0..0], &chunk);
            return if (rc == 0 and chunk.total_bytes == 0) 0 else if (rc != 0) rc else a.clipboard_offer_error_invalid;
        }
        var clock = stream.adapters.PlatformClock{ .read = client.clock };
        var transfer = stream.Transfer.initAbsolute(.read_exact, chosen.total_bytes, budget.deadline) catch return a.clipboard_offer_error_invalid;
        while (true) {
            const offset: usize = @intCast(transfer.bytes);
            const progress = transfer.readStep(storage[offset..], a.clipboard_offer_read_chunk, false, stream.adapters.PlatformClock.sample, &clock, OfferReader.read, &reader) catch return a.clipboard_offer_error_invalid;
            if (progress.outcome == @intFromEnum(stream.Outcome.complete)) return @intCast(progress.bytes);
            if (progress.flags & stream.core.terminal != 0 or progress.last_bytes == 0) return if (progress.error_code < 0) progress.error_code else a.clipboard_offer_error_incomplete;
        }
    }

    pub fn close(self: *Owner) i32 {
        if (self.client) |*client| {
            if (self.pending) |pending| _ = client.abort(pending.lease);
            _ = self.release();
            const rc = client.close();
            if (rc >= 0) self.client = null;
            return rc;
        }
        return 0;
    }
};

const OfferReader = struct {
    client: offers.Client,
    snapshot: offers.Lease,
    format: offers.Format,

    fn read(raw: ?*anyopaque, offset: u64, output: [*]u8, length: u32, deadline: *const time.DeadlineBudget) callconv(.c) stream.Ack {
        const self: *OfferReader = @ptrCast(@alignCast(raw.?));
        var budget = r.rpc_budget.Budget{ .clock = self.client.clock, .deadline = deadline.* };
        const view = self.client.withBudget(&budget) catch |err| return .{ .kind = @intFromEnum(stream.IoKind.failed), .error_code = r.rpc_budget.code(err) };
        var chunk: offers.Chunk = undefined;
        const rc = view.read(self.snapshot, self.format.item, self.format.format, offset, output[0..length], &chunk);
        if (rc != 0) return .{ .kind = @intFromEnum(stream.IoKind.failed), .error_code = rc };
        if (chunk.total_bytes != self.format.total_bytes) return .{ .kind = @intFromEnum(stream.IoKind.failed), .error_code = a.clipboard_offer_error_invalid };
        return .{ .bytes = chunk.bytes, .kind = @intFromEnum(if (chunk.flags & a.clipboard_offer_flag_eof != 0) stream.IoKind.eof else stream.IoKind.progress) };
    }
};

pub fn encodeFile(path: []const u8, storage: []u8) r.binary_cursor.Error![]const u8 {
    _ = r.path.AbsoluteFilePath.parse(path) catch return error.InvalidBuffer;
    var writer = try r.binary_cursor.Writer.init(storage);
    try writer.writeInt(u32, 1, .little);
    try writer.writeInt(u32, @intCast(path.len), .little);
    try writer.put(path);
    return storage[0..writer.position];
}

pub fn decodeFile(payload: []const u8, storage: []u8) r.binary_cursor.Error![]const u8 {
    var reader = try r.binary_cursor.Reader.init(payload);
    if (try reader.readInt(u32, .little) != 1) return error.InvalidBuffer;
    const length = try reader.readInt(u32, .little);
    const span = try reader.take(length);
    const path = try span.bytes();
    if (reader.position != reader.length or path.len >= storage.len) return error.Capacity;
    _ = r.path.AbsoluteFilePath.parse(path) catch return error.InvalidBuffer;
    @memset(storage, 0);
    @memcpy(storage[0..path.len], path);
    return storage[0..path.len];
}

test "file offer uses canonical complete single-path wire records" {
    var bytes: [136]u8 = undefined;
    const path = "C:\\TEMP\\Ä中.TXT";
    const encoded = try encodeFile(path, &bytes);
    var restored: [128]u8 = undefined;
    try std.testing.expectEqualStrings(path, try decodeFile(encoded, &restored));
    try std.testing.expectError(error.Truncated, decodeFile(encoded[0 .. encoded.len - 1], &restored));
    bytes[0] = 2;
    try std.testing.expectError(error.InvalidBuffer, decodeFile(encoded, &restored));
    try std.testing.expectError(error.InvalidBuffer, encodeFile("relative.txt", &bytes));
    try std.testing.expectError(error.Capacity, decodeFile(try encodeFile(path, &bytes), restored[0..5]));
}

test "unconfirmed clipboard commit retains its token and blocks replacement" {
    const Peer = struct {
        var allow_status = false;
        var status_state: u32 = a.clipboard_offer_state_committed;
        var status_calls: usize = 0;
        var abort_calls: usize = 0;
        var other_calls: usize = 0;
        fn clock(output: *a.MonotonicClockInfo) callconv(.c) i32 {
            output.* = .{ .flags = a.monotonic_clock_flag_valid, .source = 1, .generation = 1, .resolution_ns = 1, .event_requested_hz = 1000 };
            return 1;
        }
        fn close(_: u32) callconv(.c) i32 {
            return 0;
        }
        fn call(_: u32, op: u16, input: [*]const u8, size: u32, header: *a.ServiceMessageHeader, output: [*]u8, capacity: u32, _: u64) callconv(.c) i32 {
            header.* = .{};
            if (op == a.clipboard_offer_op_status) {
                status_calls += 1;
                if (size != @sizeOf(offers.Lease)) return a.clipboard_offer_error_invalid;
                const token = std.mem.bytesToValue(offers.Lease, input[0..@sizeOf(offers.Lease)]);
                if (token.provider != 42 or token.id != 99) return a.clipboard_offer_error_invalid;
                if (!allow_status) return a.service_api_result_timeout;
                const lease = offers.Lease{ .provider = 42, .id = 99, .revision = 7, .expires_ns = 9_000_000_000, .state = status_state };
                if (capacity < @sizeOf(offers.Lease)) return a.clipboard_offer_error_invalid;
                @memcpy(output[0..@sizeOf(offers.Lease)], std.mem.asBytes(&lease));
                return @sizeOf(offers.Lease);
            }
            if (op == a.clipboard_offer_op_abort) {
                abort_calls += 1;
                return 0;
            }
            other_calls += 1;
            header.status = a.service_api_result_bad_op;
            return 0;
        }
    };
    Peer.allow_status = false;
    Peer.status_calls = 0;
    Peer.other_calls = 0;
    const stage = offers.Lease{ .provider = 42, .id = 99, .expires_ns = 9_000_000_000, .state = a.clipboard_offer_state_writing };
    var owner = Owner{
        .client = .{ .call = Peer.call, .close_call = Peer.close, .handle = 1, .clock = Peer.clock },
        .pending = .{ .lease = stage, .ready = true },
    };
    var result: offers.Lease = undefined;
    try std.testing.expectEqual(a.service_api_result_timeout, owner.publish(a.clipboard_offer_format_text_utf8, "replacement", &result));
    try std.testing.expectEqualDeep(stage, owner.pending.?.lease);
    try std.testing.expectEqual(@as(usize, 1), Peer.status_calls);
    try std.testing.expectEqual(@as(usize, 0), Peer.other_calls);
    Peer.allow_status = true;
    try std.testing.expectEqual(a.clipboard_offer_error_unsupported, owner.publish(a.clipboard_offer_format_text_utf8, "replacement", &result));
    try std.testing.expect(owner.pending == null);
    try std.testing.expectEqual(@as(usize, 2), Peer.status_calls);
    try std.testing.expectEqual(@as(usize, 1), Peer.other_calls);
    Peer.status_state = a.clipboard_offer_state_writing;
    owner.pending = .{ .lease = stage, .ready = true };
    try std.testing.expectEqual(a.clipboard_offer_error_unsupported, owner.publish(a.clipboard_offer_format_text_utf8, "replacement", &result));
    try std.testing.expect(owner.pending == null);
    try std.testing.expectEqual(@as(usize, 1), Peer.abort_calls);
    try std.testing.expectEqual(@as(usize, 2), Peer.other_calls);
}
