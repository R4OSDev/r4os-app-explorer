//! One copied BSP query, admitted only after a published content frame.
//! Native join, rather than a done flag or a caller deadline, retires its data.
const r4os = @import("r4os");
const std = @import("std");
const Sys = r4os.r4sys.Context;
const Info = r4os.abi.DriveInfo;
const Stamp = r4os.abi.DirectoryChangeCursor;

pub const State = enum { unknown, pending, ready, unavailable };
pub const Completion = struct { info: ?Info };
const Key = struct { generation: u64, letter: u8, kind: u8, bytes: u64, stamp: Stamp };
pub const Joined = struct { key: Key, info: ?Info, sample: Stamp };
const Job = struct {
    sys: Sys,
    key: Key,
    sample: Stamp,
    handle: r4os.abi.ProgramJoinHandle = .{},
    stopped: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    done: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    info: ?Info = null,
};

pub const Owner = struct {
    state: State = .unknown,
    generation: u64 = 0,
    current: ?Key = null,
    wanted: ?Key = null,
    job: ?*Job = null,
    retries: u8 = 0,

    fn advance(self: *Owner) void {
        self.generation +%= 1;
        while (self.generation == 0 or (self.job != null and self.generation == self.job.?.key.generation)) self.generation +%= 1;
    }

    pub fn clear(self: *Owner) void {
        self.advance();
        self.current = null;
        self.wanted = null;
        self.state = .unknown;
    }

    pub fn request(self: *Owner, geometry: Info, stamp: Stamp) void {
        self.advance();
        self.retries = 0;
        if (stamp.version != 1 or stamp.size != 40 or stamp.mount_generation == 0) {
            self.current = null;
            self.wanted = null;
            self.state = .unavailable;
            return;
        }
        const key: Key = .{ .generation = self.generation, .letter = geometry.letter, .kind = geometry.kind, .bytes = geometry.bytes, .stamp = stamp };
        self.current = key;
        self.wanted = key;
        self.state = .pending;
    }

    pub fn busy(self: *const Owner) bool {
        return self.job != null;
    }

    /// The caller has published the content which must precede cold FREE work.
    pub fn afterPublish(self: *Owner, sys: *const Sys) void {
        if (self.job != null) return;
        const key = self.wanted orelse return;
        self.wanted = null;
        const job = sys.allocator().create(Job) catch {
            self.state = .unavailable;
            return;
        };
        job.* = .{ .sys = sys.*, .key = key, .sample = key.stamp };
        if (sys.threadCreateHandle(run, @intFromPtr(job), 128 * 1024, 0, &job.handle) != r4os.abi.thread_ok) {
            sys.allocator().destroy(job);
            self.state = .unavailable;
            return;
        }
        self.job = job;
    }

    fn finish(self: *Owner, key: Key, info: ?Info, sample: Stamp, observed: Stamp, raw: i32) bool {
        const current = self.current orelse return false;
        if (current.generation != key.generation or current.letter != key.letter) return false;
        self.state = .unavailable;
        self.wanted = null;
        if (raw < 0 or sample.mount_slot != current.stamp.mount_slot or sample.mount_generation != current.stamp.mount_generation or
            observed.mount_slot != sample.mount_slot or observed.mount_generation != sample.mount_generation) return true;
        // Poll's return value is directory-specific. Its sequence advances for
        // ALL committed mutations, including allocation in another directory.
        if (raw != 0 or observed.sequence != sample.sequence) {
            if (self.retries < 3) {
                self.retries += 1;
                var retry = current;
                retry.stamp = observed;
                self.current = retry;
                self.wanted = retry;
                self.state = .pending;
            }
            return true;
        }
        var accepted = current;
        accepted.stamp = observed;
        self.current = accepted;
        if (info) |value| {
            if (value.mounted != 0 and value.letter == current.letter and value.kind == current.kind and value.bytes == current.bytes and
                value.reserved & r4os.abi.drive_info_flag_free_valid != 0)
                self.state = .ready;
        }
        return true;
    }

    /// Own the value only after the native thread has actually retired.
    pub fn collectJoined(self: *Owner, sys: *const Sys) ?Joined {
        const job = self.job orelse return null;
        if (!job.done.load(.acquire)) return null;
        var code: i32 = 0;
        if (sys.threadHandleJoin(&job.handle, 0, &code) != r4os.abi.thread_ok) return null;
        const key = job.key;
        const info = if (code == 0) job.info else null;
        const sample = job.sample;
        sys.allocator().destroy(job);
        self.job = null;
        return .{ .key = key, .info = info, .sample = sample };
    }

    pub fn applyJoined(self: *Owner, sys: *const Sys, joined: Joined) ?Completion {
        const key = joined.key;
        const current = self.current orelse return null;
        if (current.generation != key.generation or current.letter != key.letter) return null;
        var observed = joined.sample;
        const raw = sys.directoryChangePoll(&observed);
        if (!self.finish(key, joined.info, joined.sample, observed, raw)) return null;
        // Unavailable still needs a UI update; retain the current geometry.
        return .{ .info = if (self.state == .ready) joined.info else null };
    }

    /// Returns only a result for the still-current navigation/mount/mutation.
    pub fn poll(self: *Owner, sys: *const Sys) ?Completion {
        const joined = self.collectJoined(sys) orelse return null;
        return self.applyJoined(sys, joined);
    }

    pub fn drain(self: *Owner, sys: *const Sys) void {
        self.wanted = null;
        self.current = null;
        if (self.job) |job| job.stopped.store(true, .release);
        while (self.job != null) {
            _ = self.poll(sys);
            if (self.job != null) sys.sleepTicks(1);
        }
    }
};

fn run(value: u64) callconv(.c) i32 {
    const job: *Job = @ptrFromInt(value);
    // The UI snapshot supplies the exact mount identity. The RAM-only poll
    // accepts a fresh mutation sequence before taking the FREE snapshot.
    if (!job.stopped.load(.acquire) and job.sys.directoryChangePoll(&job.sample) >= 0)
        job.info = job.sys.driveInfo(job.key.letter - 'A');
    job.done.store(true, .release);
    return 0;
}

fn sampleStamp() Stamp {
    return .{ .node = 5, .mount_slot = 2, .mount_generation = 10, .sequence = 7 };
}

fn sampleGeometry(letter: u8) Info {
    return .{ .mounted = 1, .letter = letter, .kind = 3, .bytes = 4096 };
}

test "navigation generation rejects a late old-volume result" {
    var owner: Owner = .{};
    var first = sampleGeometry('C');
    owner.request(first, sampleStamp());
    const old = owner.current.?;
    owner.request(sampleGeometry('D'), sampleStamp());
    first.reserved = r4os.abi.drive_info_flag_free_valid;
    try std.testing.expect(!owner.finish(old, first, old.stamp, old.stamp, 0));
    try std.testing.expectEqual(State.pending, owner.state);
    try std.testing.expectEqual(@as(u8, 'D'), owner.wanted.?.letter);
    const current = owner.current.?;
    owner.clear();
    try std.testing.expect(!owner.finish(current, sampleGeometry('D'), current.stamp, current.stamp, 0));
    try std.testing.expect(owner.wanted == null);
}

test "unknown free zero differs from an exact full-volume zero" {
    var owner: Owner = .{};
    var info = sampleGeometry('C');
    owner.request(info, sampleStamp());
    try std.testing.expect(owner.finish(owner.current.?, info, owner.current.?.stamp, owner.current.?.stamp, 0));
    try std.testing.expectEqual(State.unavailable, owner.state);
    owner.request(info, sampleStamp());
    info.reserved = r4os.abi.drive_info_flag_free_valid;
    try std.testing.expect(owner.finish(owner.current.?, info, owner.current.?.stamp, owner.current.?.stamp, 0));
    try std.testing.expectEqual(State.ready, owner.state);
    try std.testing.expectEqual(@as(u64, 0), info.free_bytes);
}

test "changed mounted geometry and failed query never become exact free space" {
    var owner: Owner = .{};
    var info = sampleGeometry('C');
    owner.request(info, sampleStamp());
    info.bytes += 4096;
    info.reserved = r4os.abi.drive_info_flag_free_valid;
    try std.testing.expect(owner.finish(owner.current.?, info, owner.current.?.stamp, owner.current.?.stamp, 0));
    try std.testing.expectEqual(State.unavailable, owner.state);
    owner.request(sampleGeometry('C'), sampleStamp());
    try std.testing.expect(owner.finish(owner.current.?, null, owner.current.?.stamp, owner.current.?.stamp, 0));
    try std.testing.expectEqual(State.unavailable, owner.state);
}

test "mutation in another directory invalidates an otherwise successful result" {
    var owner: Owner = .{};
    var info = sampleGeometry('C');
    info.reserved = r4os.abi.drive_info_flag_free_valid;
    owner.request(info, sampleStamp());
    const old = owner.current.?;
    var changed = old.stamp;
    changed.sequence += 1;
    // Raw0 says this directory did not change; the global sequence still did.
    try std.testing.expect(owner.finish(old, info, old.stamp, changed, 0));
    try std.testing.expectEqual(State.pending, owner.state);
    try std.testing.expectEqual(changed.sequence, owner.wanted.?.stamp.sequence);
    const retry = owner.current.?;
    try std.testing.expect(owner.finish(retry, info, retry.stamp, retry.stamp, 0));
    try std.testing.expectEqual(State.ready, owner.state);
}

test "same geometry on a different mount generation never admits old free data" {
    var owner: Owner = .{};
    var info = sampleGeometry('C');
    info.reserved = r4os.abi.drive_info_flag_free_valid;
    owner.request(info, sampleStamp());
    const old = owner.current.?;
    var replaced = old.stamp;
    replaced.mount_generation += 1;
    try std.testing.expect(owner.finish(old, info, old.stamp, replaced, -3));
    try std.testing.expectEqual(State.unavailable, owner.state);
    try std.testing.expect(owner.wanted == null);
}

test "continuous mutations allow only three new samples per navigation" {
    var owner: Owner = .{};
    var info = sampleGeometry('C');
    info.reserved = r4os.abi.drive_info_flag_free_valid;
    owner.request(info, sampleStamp());
    for (0..4) |attempt| {
        const key = owner.current.?;
        var changed = key.stamp;
        changed.sequence += 1;
        try std.testing.expect(owner.finish(key, info, key.stamp, changed, 1));
        try std.testing.expectEqual(if (attempt < 3) State.pending else State.unavailable, owner.state);
    }
    try std.testing.expect(owner.wanted == null);
}
