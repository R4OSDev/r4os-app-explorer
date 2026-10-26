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
    return if (freeOwnerNativeSelfTest(&sys, geometry, identity)) 0 else 1;
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
