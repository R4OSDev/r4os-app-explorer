//! One generation-owned BSP job at a time. Main owns every published snapshot;
//! a detail job borrows ONLY its immutable item span, pinned until native join.
//! A later base job cannot start/adopt/free that span before this join.
const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;
const Sys = r4os.r4sys.Context;

pub fn Owner(comptime Model: type) type {
    return struct {
        const Self = @This();
        pub const Snapshot = r4os.directory_page.Snapshot(Model.Item, 16 * 1024 * 1024);
        pub const Phase = enum { base, details };
        pub const Result = enum { pending, ok, failed, stale, cancelled };
        pub const Request = struct {
            generation: u64 = 0,
            location: Model.Location,
            mode: Model.SortMode,
            ascending: bool,
            history: Model.HistoryAction = .none,
            origin: Model.Location = .{},
            page: Model.PageDirection = .first,
            cycle_drive: bool = false,
        };
        pub const Job = struct {
            sys: Sys,
            key: Request,
            config: Model.Config,
            phase: Phase = .base,
            result: Result = .pending,
            snapshot: Snapshot = .{},
            // Read-only Main storage, pinned by serial job/adoption/drain.
            source: []const Model.Item = &.{},
            geometry: abi.DriveInfo = .{},
            watch: abi.DirectoryChangeCursor = .{},
            inventory_generation: u64 = 0,
            shortcuts: usize = 0,
            handle: abi.ProgramJoinHandle = .{},
            active: bool = false,
            stopped: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
            done: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
        };

        generation: u64 = 0,
        desired: ?Request = null,
        queued: bool = false,
        job: ?*Job = null,

        pub fn current(self: *const Self, key: Request) bool {
            const desired = self.desired orelse return false;
            return desired.generation == key.generation;
        }
        pub fn loading(self: *const Self) bool {
            return self.queued or (self.job != null and self.current(self.job.?.key) and self.job.?.phase == .base);
        }
        pub fn busy(self: *const Self) bool {
            return self.queued or self.job != null;
        }
        pub fn request(self: *Self, sys: *const Sys, next: Request) void {
            self.generation +%= 1;
            while (self.generation == 0 or (self.job != null and self.generation == self.job.?.key.generation)) self.generation +%= 1;
            var wanted = next;
            wanted.generation = self.generation;
            self.desired = wanted;
            self.queued = true;
            if (self.job) |job| {
                job.stopped.store(true, .release);
                if (!job.active) {
                    self.job = null;
                    destroy(sys, job);
                }
            }
        }
        pub fn cancel(self: *Self, sys: *const Sys) void {
            self.desired = null;
            self.queued = false;
            if (self.job) |job| {
                job.stopped.store(true, .release);
                if (!job.active) {
                    self.job = null;
                    destroy(sys, job);
                }
            }
        }
        /// Caller has successfully published the latest loading/base frame.
        /// Config is copied, no mutable App/window/facade borrow reaches a job.
        pub fn afterPublish(self: *Self, sys: *const Sys, config: *const Model.Config) bool {
            if (self.job) |job| {
                if (job.active) return false;
                if (!self.current(job.key) or job.stopped.load(.acquire)) {
                    self.job = null;
                    destroy(sys, job);
                    return false;
                }
                if (start(job)) return false;
                self.job = null;
                destroy(sys, job);
                return true;
            }
            if (!self.queued) return false;
            const key = self.desired orelse return false;
            self.queued = false;
            const job = sys.allocator().create(Job) catch return true;
            job.* = .{ .sys = sys.*, .key = key, .config = config.* };
            if (!start(job)) {
                destroy(sys, job);
                return true;
            }
            self.job = job;
            return false;
        }
        fn start(job: *Job) bool {
            job.result = .pending;
            job.done.store(false, .release);
            if (job.sys.threadCreateHandle(run, @intFromPtr(job), 128 * 1024, 0, &job.handle) != abi.thread_ok) return false;
            job.active = true;
            return true;
        }
        pub fn collectJoined(self: *Self, sys: *const Sys) ?*Job {
            const job = self.job orelse return null;
            if (!job.active) return null;
            var code: i32 = 0;
            if (sys.threadHandleJoin(&job.handle, 0, &code) != abi.thread_ok) return null;
            job.active = false;
            self.job = null;
            if (code != 0 or !job.done.load(.acquire)) job.result = .failed;
            return job;
        }
        /// Base snapshot has moved to Main. Its immutable span is pinned:
        /// Main can page/read it, but can only free/replace it after this job
        /// joins. New navigation is queued behind that same join boundary.
        pub fn armDetails(self: *Self, job: *Job, source: []const Model.Item) void {
            std.debug.assert(self.job == null and !job.active and job.snapshot.values.items.len == 0);
            job.phase = .details;
            // Navigation/history has already committed with the base view.
            // Retrying metadata must never push/pop that history a second time.
            job.key.history = .none;
            job.key.page = .refresh;
            job.source = source;
            job.result = .pending;
            self.job = job;
        }
        pub fn destroy(sys: *const Sys, job: *Job) void {
            std.debug.assert(!job.active);
            job.snapshot.deinit(sys.allocator());
            sys.allocator().destroy(job);
        }
        pub fn drain(self: *Self, sys: *const Sys) void {
            self.queued = false;
            self.desired = null;
            const job = self.job orelse return;
            job.stopped.store(true, .release);
            if (job.active) {
                var code: i32 = 0;
                // A done marker or timeout never releases borrowed source data.
                while (sys.threadHandleJoin(&job.handle, abi.thread_wait_forever, &code) != abi.thread_ok) sys.sleepTicks(1);
                job.active = false;
            }
            self.job = null;
            destroy(sys, job);
        }
        pub fn valid(sys: *const Sys, job: *const Job) bool {
            if (job.key.location.mode == .computer) {
                const storage: r4os.storage.Context = .{ .sys = sys };
                var inventory: abi.StorageInventory = .{};
                return storage.inventory(&inventory) == 0 and inventory.generation == job.inventory_generation;
            }
            if (job.watch.mount_generation == 0) return false;
            var observed = job.watch;
            // Conservatively reject any intervening global publication, also
            // an ancestor rename or mount change outside the watched node.
            return sys.directoryChangePoll(&observed) == 0 and observed.sequence == job.watch.sequence;
        }
        fn checkpoint(job: *const Job) bool {
            if (job.stopped.load(.acquire)) return false;
            job.sys.sleepTicks(0);
            return !job.stopped.load(.acquire) and !job.sys.programShouldClose();
        }
        fn run(raw: u64) callconv(.c) i32 {
            const job: *Job = @ptrFromInt(raw);
            const result = if (job.phase == .base) readBase(job) else readDetails(job);
            job.result = result;
            if (result != .ok) job.snapshot.deinit(job.sys.allocator());
            job.done.store(true, .release);
            return 0;
        }
        fn readBase(job: *Job) Result {
            if (!checkpoint(job)) return .cancelled;
            if (job.key.location.mode == .computer) {
                const storage: r4os.storage.Context = .{ .sys = &job.sys };
                var inventory: abi.StorageInventory = .{};
                if (storage.inventory(&inventory) != 0) return .failed;
                job.inventory_generation = inventory.generation;
                for (0..26) |index| {
                    if (!checkpoint(job)) return .cancelled;
                    const geometry = job.sys.driveInfoGeometry(@intCast(index)) orelse continue;
                    if (geometry.mounted == 0) continue;
                    job.snapshot.append(job.sys.allocator(), Model.drive(geometry)) catch return .failed;
                }
            } else {
                const letter = Model.letter(&job.key.location.path);
                if (letter < 'A' or letter > 'Z') return .failed;
                if (job.key.cycle_drive) {
                    var found = false;
                    for (1..26) |offset| {
                        if (!checkpoint(job)) return .cancelled;
                        const index = (@as(usize, letter - 'A') + offset) % 26;
                        const geometry = job.sys.driveInfoGeometry(@intCast(index)) orelse continue;
                        if (geometry.mounted == 0 or !Model.browsable(geometry.kind)) continue;
                        job.geometry = geometry;
                        job.key.location.path = Model.drive(geometry).path;
                        found = true;
                        break;
                    }
                    if (!found) return .failed;
                } else job.geometry = job.sys.driveInfoGeometry(letter - 'A') orelse return .failed;
                if (job.geometry.mounted == 0 or !Model.browsable(job.geometry.kind)) return .failed;
                var cursor: abi.DirectoryBatchCursor = .{};
                var records: [4]abi.DirectoryBatchEntry = undefined;
                while (true) {
                    if (!checkpoint(job)) return .cancelled;
                    const raw = job.sys.directoryBatch(@ptrCast(&job.key.location.path), &cursor, &records);
                    if (raw == -5) break;
                    if (raw == -10) return .stale;
                    if (raw < 0 or raw > records.len) return .failed;
                    for (records[0..@intCast(raw)]) |*record| {
                        const item = Model.item(record) orelse return .failed;
                        if (item.is_shortcut) job.shortcuts += 1;
                        job.snapshot.append(job.sys.allocator(), item) catch return .failed;
                    }
                }
                job.watch = cursor.change;
            }
            if (!sort(job)) return .cancelled;
            return if (valid(&job.sys, job)) .ok else .stale;
        }
        fn readDetails(job: *Job) Result {
            if (!valid(&job.sys, job)) return .stale;
            if (job.source.len > Snapshot.limit) return .failed;
            job.snapshot.values.ensureTotalCapacityPrecise(job.sys.allocator(), job.source.len) catch return .failed;
            for (job.source, 0..) |item, index| {
                if (index % 32 == 0 and !checkpoint(job)) return .cancelled;
                job.snapshot.values.appendAssumeCapacity(item);
            }
            // One explicit shortcut read/parse per cooperative step. None of
            // these files gates the first complete base snapshot publication.
            for (job.snapshot.values.items) |*item| {
                if (!item.is_shortcut) continue;
                if (!checkpoint(job)) return .cancelled;
                Model.details(&job.sys, item);
            }
            if (!sort(job)) return .cancelled;
            return if (valid(&job.sys, job)) .ok else .stale;
        }
        fn less(job: *const Job, a: Model.Item, b: Model.Item) bool {
            return Model.compare(job.key.mode, job.key.ascending, &job.config, a, b) < 0;
        }
        fn sort(job: *Job) bool {
            var state = HeapSort(Model.Item, *const Job, less).init(job.snapshot.values.items.len);
            while (true) {
                if (!checkpoint(job)) return false;
                if (state.step(job.snapshot.values.items, job, 32)) return true;
            }
        }
    };
}

/// Each step visits at most budget heap roots; each sift has logarithmic depth.
/// The state itself owns no storage, so no unfinished sort can escape as a view.
pub fn HeapSort(comptime Item: type, comptime Context: type, comptime less: fn (Context, Item, Item) bool) type {
    return struct {
        parent: usize,
        end: usize,
        pub fn init(count: usize) @This() {
            return .{ .parent = count / 2, .end = count };
        }
        pub fn step(self: *@This(), items: []Item, context: Context, budget: usize) bool {
            var work: usize = 0;
            while (work < budget) : (work += 1) {
                if (self.parent != 0) {
                    self.parent -= 1;
                    sift(items, context, self.parent, self.end);
                } else if (self.end > 1) {
                    self.end -= 1;
                    std.mem.swap(Item, &items[0], &items[self.end]);
                    sift(items, context, 0, self.end);
                } else return true;
            }
            return self.parent == 0 and self.end <= 1;
        }
        fn sift(items: []Item, context: Context, start: usize, end: usize) void {
            var parent = start;
            while (parent < end / 2) {
                var child = parent * 2 + 1;
                if (child + 1 < end and less(context, items[child], items[child + 1])) child += 1;
                if (!less(context, items[parent], items[child])) break;
                std.mem.swap(Item, &items[parent], &items[child]);
                parent = child;
            }
        }
    };
}

test "bounded heap steps match established ordering with duplicates and tiny budgets" {
    const Order = struct {
        fn less(reverse: bool, a: u32, b: u32) bool {
            return if (reverse) a > b else a < b;
        }
    };
    for ([_]usize{ 0, 1, 2, 3, 17, 257, 2048 }) |count| {
        for ([_]usize{ 1, 7, 32 }) |budget| for ([_]bool{ false, true }) |reverse| {
            var actual: [2050]u32 = @splat(0xdeadbeef);
            var reference: [2048]u32 = undefined;
            for (actual[1..][0..count], 0..) |*item, index| item.* = @intCast((index * 31 + index / 7) % 131);
            @memcpy(reference[0..count], actual[1..][0..count]);
            std.sort.heap(u32, reference[0..count], reverse, Order.less);
            var state = HeapSort(u32, bool, Order.less).init(count);
            var calls: usize = 0;
            while (!state.step(actual[1..][0..count], reverse, budget)) {
                calls += 1;
                try std.testing.expect(calls < count * 2 + 2);
            }
            try std.testing.expectEqualSlices(u32, reference[0..count], actual[1..][0..count]);
            try std.testing.expectEqual(@as(u32, 0xdeadbeef), actual[0]);
            try std.testing.expectEqual(@as(u32, 0xdeadbeef), actual[count + 1]);
        };
    }
}

test "replacing or cancelling navigation retains an active worker and removes its loading authority" {
    const Model = struct {
        pub const Item = struct { is_shortcut: bool = false };
        pub const Config = u8;
        pub const Location = struct { mode: enum { computer, directory } = .directory, path: [128]u8 = @splat(0) };
        pub const SortMode = enum { name };
        pub const HistoryAction = enum { none };
        pub const PageDirection = enum { first };
    };
    const N = Owner(Model);
    const sys: Sys = undefined; // No allocator/native call is admitted by these transitions.
    const key = N.Request{ .generation = 7, .location = .{}, .mode = .name, .ascending = true };
    var job = N.Job{ .sys = undefined, .key = key, .config = 0, .active = true };
    var owner = N{ .generation = 7, .desired = key, .job = &job };
    try std.testing.expect(owner.loading());
    owner.request(&sys, key);
    try std.testing.expect(job.stopped.load(.acquire));
    try std.testing.expect(owner.job.? == &job and owner.queued and !owner.current(key));
    const replacement = owner.desired.?;
    try std.testing.expect(replacement.generation != key.generation);
    owner.cancel(&sys);
    try std.testing.expect(!owner.loading() and owner.busy() and owner.job.? == &job);
}
