//! App-owned bounded pixels. Painting only looks up Main-owned images;
//! filesystem/ICO work belongs to one copied BSP job, joined before reuse.
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const Sys = r.r4sys.Context;
pub const capacity = 64; // One complete Explorer page; old pages use LRU.
pub const bytes_max = 4096;
pub const pixels_max = 32 * 32;
pub const Size = struct { width: u32, height: u32 };
pub const Image = struct {
    loaded: bool = false,
    width: u32 = 0,
    height: u32 = 0,
    pixels: [pixels_max]u32 = @splat(0),
};
pub const Stamp = struct {
    watch: a.DirectoryChangeCursor = .{},
    pub fn valid(self: Stamp, sys: *const Sys) bool {
        if (self.watch.mount_generation == 0) return false;
        var cursor = self.watch;
        return sys.directoryChangePoll(&cursor) >= 0 and cursor.sequence == self.watch.sequence;
    }
    pub fn sameEpoch(self: Stamp, other: Stamp) bool {
        // Different drive roots can witness the same global namespace epoch.
        return self.watch.sequence == other.watch.sequence;
    }
};
pub const Record = struct {
    path: [128]u8 = @splat(0),
    identity: a.FileMetadata2 = .{},
    stamp: Stamp = .{},
    image: Image = .{}, // Stable failure is deliberately a negative entry.
};

pub fn normalized(path: []const u8) ?[128]u8 {
    const parsed = r.path.FilePath.parse(path) catch return null;
    if (parsed.len == 0 or parsed.len >= 128) return null;
    var result: [128]u8 = @splat(0);
    @memcpy(result[0..parsed.len], parsed.bytes());
    return result;
}
fn text(path: *const [128]u8) []const u8 {
    return std.mem.sliceTo(path, 0);
}
fn parentDirectory(path: []const u8) [128:0]u8 {
    var parent: [128:0]u8 = @splat(0);
    const separator = std.mem.lastIndexOfScalar(u8, path, '\\') orelse {
        parent[0] = '.';
        return parent;
    };
    const length = if (separator == 2 and path[1] == ':') 3 else separator;
    @memcpy(parent[0..length], path[0..length]);
    return parent;
}
fn equal(left: []const u8, right: []const u8) bool {
    return std.ascii.eqlIgnoreCase(left, right);
}

pub fn Store(comptime count: usize) type {
    return struct {
        const Self = @This();
        pub const Slot = struct { occupied: bool = false, used: u64 = 0, record: Record = .{} };
        slots: [count]Slot = @splat(.{}),
        clock: u64 = 0,
        pub fn clear(self: *Self) void {
            for (&self.slots) |*slot| slot.occupied = false;
        }
        pub fn find(self: *const Self, path: []const u8) ?usize {
            for (&self.slots, 0..) |*slot, index| if (slot.occupied and equal(text(&slot.record.path), path)) return index;
            return null;
        }
        fn touch(self: *Self, index: usize) void {
            self.clock +%= 1;
            if (self.clock == 0) {
                for (&self.slots) |*slot| slot.used = 0;
                self.clock = 1;
            }
            self.slots[index].used = self.clock;
        }
        pub fn image(self: *Self, path: []const u8) ?*const Image {
            const index = self.find(path) orelse return null;
            self.touch(index);
            return if (self.slots[index].record.image.loaded) &self.slots[index].record.image else null;
        }
        pub fn insert(self: *Self, record: *const Record) void {
            var chosen = self.find(text(&record.path));
            if (chosen == null) for (&self.slots, 0..) |*slot, index| {
                if (!slot.occupied) {
                    chosen = index;
                    break;
                }
            };
            if (chosen == null) {
                var oldest: usize = 0;
                for (&self.slots, 0..) |*slot, index| if (slot.used < self.slots[oldest].used) {
                    oldest = index;
                };
                chosen = oldest;
            }
            const index = chosen.?;
            self.slots[index].record = record.*;
            self.slots[index].occupied = true;
            self.touch(index);
        }
    };
}

pub fn Owner(comptime decode: fn ([]const u8, []u32) ?Size) type {
    return struct {
        const Self = @This();
        pub const State = enum { pending, complete, stale, cancelled, unavailable };
        pub const Job = struct {
            sys: Sys,
            generation: u64,
            record: Record,
            state: State = .pending,
            handle: a.ProgramJoinHandle = .{},
            active: bool = false,
            stopped: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
            done: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
        };
        const Want = struct { path: [128]u8 = @splat(0), retries: u8 = 0, blocked: bool = false };
        store: Store(capacity) = .{},
        epoch: ?Stamp = null,
        wanted: [capacity]Want = @splat(.{}),
        wanted_count: usize = 0,
        view_generation: u64 = 0,
        generation: u64 = 0,
        job: ?*Job = null,

        pub fn setWanted(self: *Self, paths: []const [128]u8, view: u64) void {
            var next: [capacity]Want = @splat(.{});
            var length: usize = 0;
            for (paths) |*path| {
                const normal = normalized(text(path)) orelse continue;
                var duplicate = false;
                for (next[0..length]) |*existing| if (equal(text(&existing.path), text(&normal))) {
                    duplicate = true;
                    break;
                };
                if (duplicate) continue;
                if (length == capacity) break;
                next[length].path = normal;
                if (view == self.view_generation) if (self.wantedIndex(text(&normal))) |old| {
                    next[length].retries = self.wanted[old].retries;
                    next[length].blocked = self.wanted[old].blocked;
                };
                length += 1;
            }
            self.wanted = next;
            self.wanted_count = length;
            self.view_generation = view;
            if (self.job) |job| if (self.wantedIndex(text(&job.record.path)) == null) job.stopped.store(true, .release);
        }
        fn wantedIndex(self: *const Self, path: []const u8) ?usize {
            for (self.wanted[0..self.wanted_count], 0..) |*want, index| if (equal(text(&want.path), path)) return index;
            return null;
        }
        fn missing(self: *const Self) ?usize {
            for (self.wanted[0..self.wanted_count], 0..) |*want, index| {
                if (!want.blocked and self.store.find(text(&want.path)) == null) return index;
            }
            return null;
        }
        pub fn busy(self: *const Self) bool {
            return self.job != null or self.missing() != null;
        }
        pub fn image(self: *Self, path: []const u8) ?*const Image {
            return self.store.image(path);
        }
        fn resetBlocked(self: *Self) void {
            for (self.wanted[0..self.wanted_count]) |*want| {
                want.blocked = false;
                want.retries = 0;
            }
        }
        /// RAM-only, before paint. One global epoch check, not one per icon.
        pub fn refresh(self: *Self, sys: *const Sys) bool {
            if (self.wanted_count == 0) return false;
            const epoch = self.epoch orelse return false;
            var changed = !epoch.valid(sys);
            // A mount can retire without a directory publication. Validate
            // each distinct retained mount too; usual one-drive paint polls
            // once. No storage inventory: that API can scan new devices.
            var checked: [capacity + 1]a.DirectoryChangeCursor = undefined;
            checked[0] = epoch.watch;
            var count: usize = 1;
            if (!changed) for (&self.store.slots) |*slot| {
                if (!slot.occupied) continue;
                const watch = slot.record.stamp.watch;
                var seen = false;
                for (checked[0..count]) |previous| {
                    if (watch.mount_slot == previous.mount_slot and watch.mount_generation == previous.mount_generation) {
                        seen = true;
                        break;
                    }
                }
                if (seen) continue;
                if (!slot.record.stamp.valid(sys)) {
                    changed = true;
                    break;
                }
                checked[count] = watch;
                count += 1;
            };
            if (changed) {
                self.store.clear();
                self.epoch = null;
                self.resetBlocked();
            }
            return changed;
        }
        /// Caller has published its standard/cached icons before this admission.
        pub fn afterPublish(self: *Self, sys: *const Sys) void {
            if (self.job != null) return;
            const index = self.missing() orelse return;
            const job = sys.allocator().create(Job) catch {
                self.wanted[index].blocked = true;
                return;
            };
            self.generation +%= 1;
            if (self.generation == 0) self.generation = 1;
            job.* = .{ .sys = sys.*, .generation = self.generation, .record = .{ .path = self.wanted[index].path } };
            if (sys.threadCreateHandle(run, @intFromPtr(job), 128 * 1024, 0, &job.handle) != a.thread_ok) {
                sys.allocator().destroy(job);
                self.wanted[index].blocked = true;
                return;
            }
            job.active = true;
            self.job = job;
        }
        pub fn collectJoined(self: *Self, sys: *const Sys) ?*Job {
            const job = self.job orelse return null;
            var code: i32 = 0;
            if (sys.threadHandleJoin(&job.handle, 0, &code) != a.thread_ok) return null;
            job.active = false;
            self.job = null;
            if (code != 0 or !job.done.load(.acquire)) job.state = .unavailable;
            return job;
        }
        pub fn applyJoined(self: *Self, sys: *const Sys, job: *const Job) bool {
            std.debug.assert(!job.active);
            const want = self.wantedIndex(text(&job.record.path)) orelse return false;
            if (job.generation != self.generation) return false;
            if (job.state == .complete and job.record.stamp.valid(sys)) {
                if (self.epoch != null and !self.epoch.?.sameEpoch(job.record.stamp)) self.store.clear();
                self.epoch = job.record.stamp;
                self.store.insert(&job.record);
                self.wanted[want].retries = 0;
                return true;
            }
            if (job.state == .cancelled) return false;
            if (job.state == .stale or job.state == .complete) {
                self.wanted[want].retries +|= 1;
                self.wanted[want].blocked = self.wanted[want].retries >= 3;
            } else self.wanted[want].blocked = true;
            return false;
        }
        pub fn destroy(sys: *const Sys, job: *Job) void {
            std.debug.assert(!job.active);
            sys.allocator().destroy(job);
        }
        pub fn poll(self: *Self, sys: *const Sys) bool {
            var changed = self.refresh(sys);
            if (self.collectJoined(sys)) |job| {
                changed = self.applyJoined(sys, job) or changed;
                destroy(sys, job);
            }
            return changed;
        }
        pub fn drain(self: *Self, sys: *const Sys) void {
            self.wanted_count = 0;
            const job = self.job orelse return;
            job.stopped.store(true, .release);
            var code: i32 = 0;
            while (sys.threadHandleJoin(&job.handle, a.thread_wait_forever, &code) != a.thread_ok) sys.sleepTicks(1);
            job.active = false;
            self.job = null;
            destroy(sys, job);
        }
        fn run(raw: u64) callconv(.c) i32 {
            const job: *Job = @ptrFromInt(raw);
            job.state = if (job.stopped.load(.acquire) or job.sys.programShouldClose()) .cancelled else load(job);
            if (job.stopped.load(.acquire)) job.state = .cancelled;
            job.done.store(true, .release);
            return 0;
        }
        fn load(job: *Job) State {
            const sys = &job.sys;
            const path = text(&job.record.path);
            const parent = parentDirectory(path);
            if (sys.directoryChangeBegin(&parent, &job.record.stamp.watch) != 0) return .unavailable;
            const files = r.app_storage.Files{ .sys = sys.* };
            const file_path = r.app_storage.PathZ{ .ptr = @ptrCast(&job.record.path), .len = @intCast(path.len) };
            job.record.identity = switch (files.metadata(file_path)) {
                .found => |value| value,
                .missing => return if (job.record.stamp.valid(sys)) .complete else .stale,
                .failure => return .unavailable,
            };
            // Parent and metadata must identify the actual backing mount,
            // including relative paths and the hidden BOOT namespace.
            if (job.record.identity.flags & a.file_metadata2_flag_identity_valid == 0) return .unavailable;
            if (job.record.identity.identity.mount_slot != job.record.stamp.watch.mount_slot or
                job.record.identity.identity.mount_generation != job.record.stamp.watch.mount_generation) return .stale;
            if (job.record.identity.flags & a.file_metadata2_flag_directory != 0 or
                job.record.identity.flags & a.file_metadata2_flag_byte_size_valid == 0 or
                job.record.identity.byte_size == 0 or job.record.identity.byte_size > bytes_max)
                return if (job.record.stamp.valid(sys)) .complete else .stale;
            if (job.stopped.load(.acquire)) return .cancelled;
            var bytes: [bytes_max]u8 = undefined;
            const got = sys.fileRead(@ptrCast(&job.record.path), &bytes);
            const after = switch (files.metadata(file_path)) {
                .found => |value| value,
                else => return .stale,
            };
            if (!sameFile(job.record.identity, after)) return .stale;
            // Existing whole-file contract and4KB decode budget. Oversize
            // files were handled above as stable standard-icon results.
            if (got > 0 and got == job.record.identity.byte_size) {
                if (decode(bytes[0..@intCast(got)], &job.record.image.pixels)) |size| {
                    if (size.width != 0 and size.height != 0 and size.width <= 32 and size.height <= 32) {
                        job.record.image.loaded = true;
                        job.record.image.width = size.width;
                        job.record.image.height = size.height;
                    }
                }
            }
            return if (job.record.stamp.valid(sys)) .complete else .stale;
        }
    };
}
fn sameFile(left: a.FileMetadata2, right: a.FileMetadata2) bool {
    return left.flags & a.file_metadata2_flag_identity_valid != 0 and std.meta.eql(left, right);
}

test "icon store LRU owns pixels and negative entries without scratch references" {
    try std.testing.expectEqualStrings("C:\\BOOT\\Icons", std.mem.sliceTo(&parentDirectory("C:\\BOOT\\Icons\\A.ICO"), 0));
    try std.testing.expectEqualStrings("C:\\", std.mem.sliceTo(&parentDirectory("C:\\A.ICO"), 0));
    try std.testing.expectEqualStrings("TEMP", std.mem.sliceTo(&parentDirectory("TEMP\\A.ICO"), 0));
    try std.testing.expectEqualStrings(".", std.mem.sliceTo(&parentDirectory("A.ICO"), 0));
    var store: Store(2) = .{};
    var record: Record = .{ .path = normalized("C:/ICONS/../A.ICO").?, .image = .{ .loaded = true, .width = 1, .height = 1 } };
    record.image.pixels[0] = 0x123456;
    store.insert(&record);
    record.image.pixels[0] = 0x654321;
    try std.testing.expectEqual(@as(u32, 0x123456), store.image("c:\\a.ico").?.pixels[0]);
    record.path = normalized("C:\\B.ICO").?;
    record.image.loaded = false;
    store.insert(&record);
    try std.testing.expect(store.image("C:\\B.ICO") == null and store.find("C:\\B.ICO") != null);
    _ = store.image("C:\\A.ICO");
    record.path = normalized("C:\\C.ICO").?;
    store.insert(&record);
    try std.testing.expect(store.find("C:\\B.ICO") == null and store.find("C:\\A.ICO") != null);
    store.clear();
    try std.testing.expect(store.find("C:\\A.ICO") == null);
    try std.testing.expect(normalized("C:\\" ++ "x" ** 128) == null);
}

test "GUI raster copies cached pixels before eviction or stack destruction" {
    var image: Image = .{ .loaded = true, .width = 2, .height = 2 };
    @memset(image.pixels[0..4], 0x123456);
    var commands: [2]a.GuiFrameCommand = undefined;
    var resources: [16]u8 = undefined;
    var frame = r.gui.FrameCanvas.init(undefined, &commands, &resources, true);
    try std.testing.expect(frame.raster(0, 0, 2, 2, 1, image.pixels[0..4]) >= 0);
    @memset(&image.pixels, 0x654321);
    for (0..4) |index| try std.testing.expectEqual(@as(u32, 0x123456), std.mem.readInt(u32, resources[index * 4 ..][0..4], .little));
    try std.testing.expectEqual(@as(usize, 1), frame.command_len);
}

test "ordinary folders with no shortcut demand never call system metadata" {
    const Decode = struct {
        fn run(_: []const u8, _: []u32) ?Size {
            return null;
        }
    };
    const owner = try std.testing.allocator.create(Owner(Decode.run));
    defer std.testing.allocator.destroy(owner);
    owner.* = .{};
    try std.testing.expect(@sizeOf(Owner(Decode.run)) < 512 * 1024);
    try std.testing.expect(!owner.refresh(undefined) and !owner.busy());
    owner.afterPublish(undefined);
    try std.testing.expect(owner.job == null and owner.generation == 0);
}
