const r4os = @import("r4os");
const dialog_app = @import("dialog_app");
const drive_free = dialog_app.drive_free;
const std = @import("std");
pub fn r4_app_main(app: *r4os.App) i32 {
    const code = dialog_app.r4_app_main(app);
    if (code != 0) return code;
    const sys = app.system();
    var selftest = false;
    var files = false;
    var tokens = std.mem.tokenizeAny(u8, std.mem.span(sys.argsRaw()), " \t");
    while (tokens.next()) |token| {
        selftest = selftest or std.ascii.eqlIgnoreCase(token, "/SELFTEST");
        files = files or std.ascii.eqlIgnoreCase(token, "/FILES");
    }
    if (!selftest or !files) return 0;
    var identity: r4os.abi.ProgramJoinHandle = .{};
    if (sys.threadCurrentHandle(&identity) != r4os.abi.thread_ok) return 1;
    const geometry = sys.driveInfoGeometry('C' - 'A') orelse return 1;
    if (!freeOwnerNativeSelfTest(&sys, geometry, identity)) return 1;
    return if (navigationNativeSelfTest(&sys, identity)) 0 else 1;
}

fn waitFreeJoined(ctx: *const r4os.r4sys.Context, owner: *drive_free.Owner) ?drive_free.Joined {
    const start = ctx.ticks();
    while (ctx.ticks() -% start < 4000) {
        if (owner.collectJoined(ctx)) |joined| return joined;
        if (!owner.busy()) return null;
        ctx.sleepTicks(1);
    }
    return null;
}

// Explicit /SELFTEST /FILES only. The GUI case separately proves real frame
// publication; here a real joined value is deliberately delayed across mutation.
fn freeOwnerNativeSelfTest(ctx: *const r4os.r4sys.Context, geometry: r4os.abi.DriveInfo, identity: r4os.abi.ProgramJoinHandle) bool {
    var path: [128:0]u8 = undefined;
    _ = std.fmt.bufPrintZ(&path, "C:\\TEMP\\EXP-FREE-{d}-{x}.TXT", .{ identity.instance_id, identity.instance_generation }) catch return false;
    const files: r4os.app_storage.Files = .{ .sys = ctx.* };
    const file_path: r4os.app_storage.PathZ = .{ .ptr = &path, .len = @intCast(std.mem.sliceTo(&path, 0).len) };
    if (files.info(file_path) != .missing) return false;
    var owned = false;
    defer if (owned) {
        _ = files.delete(file_path);
    };
    var owner: drive_free.Owner = .{};
    defer owner.drain(ctx);
    var stamp: r4os.abi.DirectoryChangeCursor = .{};
    if (ctx.directoryChangeBegin("C:\\", &stamp) != 0) return false;
    owner.request(geometry, stamp);
    owner.afterPublish(ctx);
    const old = waitFreeJoined(ctx, &owner) orelse return false;
    if (old.info == null or old.info.?.reserved & r4os.abi.drive_info_flag_free_valid == 0) return false;
    var data: [64 * 1024]u8 = undefined;
    @memset(&data, 0x5a);
    if (!dialog_app.createProbeFile(files, &path, &data)) return false;
    owned = true;
    const invalidated = owner.applyJoined(ctx, old) orelse return false;
    if (invalidated.info != null or owner.state != .pending or owner.wanted == null) return false;
    var latest: ?r4os.abi.DriveInfo = null;
    for (0..4) |_| {
        owner.afterPublish(ctx);
        const joined = waitFreeJoined(ctx, &owner) orelse return false;
        const accepted = owner.applyJoined(ctx, joined) orelse return false;
        if (accepted.info) |info| {
            latest = info;
            break;
        }
        if (owner.state != .pending) return false;
    }
    const value = latest orelse return false;
    const exact = ctx.driveInfo('C' - 'A') orelse return false;
    if (owner.state != .ready or value.free_bytes != exact.free_bytes or value.free_clusters != exact.free_clusters) return false;
    // Exercise the actual kernel rejection of a retired/nonmatching mount ID,
    // keeping letter/kind/capacity equal. No real volume is unmounted here.
    var stale = stamp;
    stale.mount_generation +%= 1;
    owner.request(geometry, stale);
    owner.afterPublish(ctx);
    const retired = waitFreeJoined(ctx, &owner) orelse return false;
    const rejected = owner.applyJoined(ctx, retired) orelse return false;
    if (retired.info != null or rejected.info != null or owner.state != .unavailable) return false;
    if (ctx.directoryChangeBegin("C:\\", &stamp) != 0) return false;
    owner.request(geometry, stamp);
    owner.afterPublish(ctx);
    const cancelled = waitFreeJoined(ctx, &owner) orelse return false;
    owner.clear();
    if (owner.applyJoined(ctx, cancelled) != null or owner.busy()) return false;
    ctx.println("EXPLORER FREE OWNER OK mutation=rejected retry=exact stale-mount=rejected abort=discarded native-join=yes");
    return true;
}

fn navJoined(sys: *const r4os.r4sys.Context, owner: *dialog_app.Navigation) ?*dialog_app.Navigation.Job {
    const deadline = sys.ticks() +| sys.ticksFromMilliseconds(10000);
    while (sys.ticks() < deadline) {
        if (owner.collectJoined(sys)) |job| return job;
        sys.sleepTicks(1);
    }
    return null;
}

// Fixture-only: actual BSP workers and kernel joins, not a producer done flag.
fn navigationNativeSelfTest(sys: *const r4os.r4sys.Context, identity: r4os.abi.ProgramJoinHandle) bool {
    const N = dialog_app.Navigation;
    var root: [128:0]u8 = undefined;
    _ = std.fmt.bufPrintZ(&root, "C:\\TEMP\\EXPN-{d}-{x}", .{ identity.instance_id, identity.instance_generation }) catch return false;
    if (sys.exists(&root) or sys.dirCreate(&root) <= 0) return false;
    var first: [128:0]u8 = undefined;
    var second: [128:0]u8 = undefined;
    var left: [128:0]u8 = undefined;
    var right: [128:0]u8 = undefined;
    var only: [128:0]u8 = undefined;
    var mutation: [128:0]u8 = undefined;
    _ = std.fmt.bufPrintZ(&first, "{s}\\OLD", .{std.mem.sliceTo(&root, 0)}) catch return false;
    _ = std.fmt.bufPrintZ(&second, "{s}\\NEW", .{std.mem.sliceTo(&root, 0)}) catch return false;
    _ = std.fmt.bufPrintZ(&left, "{s}\\A.LNK", .{std.mem.sliceTo(&first, 0)}) catch return false;
    _ = std.fmt.bufPrintZ(&right, "{s}\\Z.LNK", .{std.mem.sliceTo(&first, 0)}) catch return false;
    _ = std.fmt.bufPrintZ(&only, "{s}\\ONLY.TXT", .{std.mem.sliceTo(&second, 0)}) catch return false;
    _ = std.fmt.bufPrintZ(&mutation, "{s}\\MUTATE.TXT", .{std.mem.sliceTo(&first, 0)}) catch return false;
    defer {
        _ = sys.fileDelete(&left);
        _ = sys.fileDelete(&right);
        _ = sys.fileDelete(&only);
        _ = sys.fileDelete(&mutation);
        _ = sys.dirDelete(&first);
        _ = sys.dirDelete(&second);
        _ = sys.dirDelete(&root);
    }
    if (sys.dirCreate(&first) <= 0 or sys.dirCreate(&second) <= 0) return false;
    const beta = "R4S_FORMAT=1\nSCHEMA=R4LNK\nTARGET=C:\\AUTOEXEC.BAT\nTITLE=Beta\n";
    const alpha = "R4S_FORMAT=1\nSCHEMA=R4LNK\nTARGET=C:\\AUTOEXEC.BAT\nTITLE=Alpha\n";
    if (sys.fileWrite(&left, beta) != beta.len or sys.fileWrite(&right, alpha) != alpha.len or sys.fileWrite(&only, "only") != 4) return false;
    const Config = @FieldType(N.Job, "config");
    const config = Config.initDefault();
    var owner: N = .{};
    var published: N.Snapshot = .{};
    defer published.deinit(sys.allocator());
    defer owner.drain(sys);
    var old = N.Request{ .location = .{ .mode = .directory }, .mode = .name, .ascending = true };
    @memcpy(old.location.path[0..std.mem.sliceTo(&first, 0).len], std.mem.sliceTo(&first, 0));
    var next = old;
    @memset(&next.location.path, 0);
    @memcpy(next.location.path[0..std.mem.sliceTo(&second, 0).len], std.mem.sliceTo(&second, 0));
    owner.request(sys, old);
    if (owner.job != null or !owner.loading()) return false;
    if (owner.afterPublish(sys, &config)) return false;
    const deadline = sys.ticks() +| sys.ticksFromMilliseconds(10000);
    while (owner.job != null and !owner.job.?.done.load(.acquire) and sys.ticks() < deadline) sys.sleepTicks(1);
    if (owner.job == null or !owner.job.?.done.load(.acquire)) return false;
    const late_generation = owner.job.?.key.generation;
    // Let a real completed worker arrive after its request has been superseded.
    owner.request(sys, next);
    const late = navJoined(sys, &owner) orelse return false;
    const discarded = late.key.generation == late_generation and !owner.current(late.key);
    N.destroy(sys, late);
    if (!discarded or owner.afterPublish(sys, &config)) return false;
    const latest = navJoined(sys, &owner) orelse return false;
    const latest_ok = owner.current(latest.key) and latest.result == .ok and N.valid(sys, latest) and latest.snapshot.values.items.len == 1 and
        std.mem.eql(u8, std.mem.sliceTo(&latest.snapshot.values.items[0].path, 0), std.mem.sliceTo(&only, 0));
    N.destroy(sys, latest);
    if (!latest_ok) return false;
    owner.request(sys, old);
    if (owner.afterPublish(sys, &config)) return false;
    const base = navJoined(sys, &owner) orelse return false;
    if (base.result != .ok or !N.valid(sys, base) or base.snapshot.values.items.len != 2) {
        N.destroy(sys, base);
        return false;
    }
    published = base.snapshot;
    base.snapshot = .{};
    const original = published.values.items[0].label;
    owner.armDetails(base, published.values.items);
    if (owner.afterPublish(sys, &config)) return false;
    const details = navJoined(sys, &owner) orelse return false;
    const sorted = details.result == .ok and N.valid(sys, details) and details.snapshot.values.items.len == 2 and
        std.mem.eql(u8, std.mem.sliceTo(&details.snapshot.values.items[0].label, 0), "Alpha") and
        std.mem.eql(u8, std.mem.sliceTo(&details.snapshot.values.items[1].label, 0), "Beta") and std.mem.eql(u8, &published.values.items[0].label, &original);
    if (!sorted) {
        N.destroy(sys, details);
        return false;
    }
    const changed = sys.fileWrite(&mutation, "mutation") == 8 and !N.valid(sys, details);
    N.destroy(sys, details);
    if (!changed) return false;
    owner.request(sys, old);
    if (owner.afterPublish(sys, &config)) return false;
    owner.drain(sys);
    if (owner.busy()) return false;
    sys.println("EXPLORER NAV OWNER OK late=discarded base=sorted details=sorted source=immutable mutation=rejected native-join=yes cancel-drained=yes");
    return true;
}
