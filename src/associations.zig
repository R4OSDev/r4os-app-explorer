const std = @import("std");
const r4os = @import("r4os");
const r4std = @import("r4std");
const sdk_assoc = r4std.app_assoc;
const handler = r4std.file_handler;

pub const Config = sdk_assoc.Config;
pub const Choice = handler.Choice;
pub const ChoiceList = handler.ChoiceList;
pub const max_open_with_items = handler.max_choices;

pub fn initDefault() Config {
    return Config.initDefault();
}

pub fn loadFromBytes(bytes: []const u8) Config {
    var config = Config.initDefault();
    _ = Config.loadFromBytes(&config, bytes);
    return config;
}

pub fn appCount(config: anytype) usize {
    var count: usize = 0;
    var index: usize = 0;
    while (index < config.app_count) : (index += 1) {
        if (usableApp(&config.apps[index])) count += 1;
    }
    return count;
}

pub fn appForMenuIndex(config: anytype, menu_index: usize) ?*const @TypeOf(config.*.apps[0]) {
    var visible: usize = 0;
    var index: usize = 0;
    while (index < config.app_count) : (index += 1) {
        const app = &config.apps[index];
        if (!usableApp(app)) continue;
        if (visible == menu_index) return app;
        visible += 1;
    }
    return null;
}

pub fn menuIndexForAppId(config: anytype, app_id: []const u8) ?usize {
    var visible: usize = 0;
    var index: usize = 0;
    while (index < config.app_count) : (index += 1) {
        const app = &config.apps[index];
        if (!usableApp(app)) continue;
        if (equalsIgnoreCase(app.idText(), app_id)) return visible;
        visible += 1;
    }
    return null;
}

pub fn defaultIndex(config: anytype, path: []const u8) usize {
    var args: [128]u8 = .{0} ** 128;
    if (config.resolvePath(path, args[0..])) |target| {
        if (menuIndexForAppId(config, target.app_id)) |index| return index;
    }
    return 0;
}

pub fn defaultChoiceIndex(config: *const Config, choices: *const ChoiceList, path: []const u8) usize {
    if (sdk_assoc.extensionOfPath(path)) |extension| {
        if (config.extensionByName(extension)) |entry| {
            for (choices.slice(), 0..) |choice, index| switch (entry.handler_kind) {
                .none => break,
                .app => if (choice.kind == .application and equalsIgnoreCase(choice.handler_id, entry.appIdText())) return index,
                .subsystem => if (choice.kind == .subsystem and equalsIgnoreCase(choice.handler_id, entry.subsystemIdText()) and
                    equalsIgnoreCase(choice.format_id, entry.formatIdText())) return index,
            };
        }
    }
    for (choices.slice(), 0..) |choice, index| if (choice.kind == .subsystem) return index;
    return 0;
}

pub fn extensionForPath(config: anytype, path: []const u8) ?*const @TypeOf(config.*.extensions[0]) {
    const ext_name = sdk_assoc.extensionOfPath(path) orelse return null;
    return config.extensionByName(ext_name);
}

pub fn prefix(config: anytype, path: []const u8) []const u8 {
    if (extensionForPath(config, path)) |ext| return ext.prefixText();
    return "";
}

pub fn typeName(config: anytype, path: []const u8) []const u8 {
    if (extensionForPath(config, path)) |ext| return ext.typeNameText();
    return "File";
}

pub fn typeShort(config: anytype, path: []const u8) []const u8 {
    if (extensionForPath(config, path)) |ext| return ext.shortNameText();
    return "File";
}

pub fn rank(config: anytype, path: []const u8) u8 {
    if (extensionForPath(config, path)) |ext| return ext.rank;
    return 6;
}

fn usableApp(app: anytype) bool {
    return app.valid and
        app.idText().len != 0 and
        sdk_assoc.isR4XPath(app.pathText()) and
        std.mem.indexOf(u8, app.argsText(), "%1") != null;
}

fn equalsIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var index: usize = 0;
    while (index < a.len) : (index += 1) {
        if (asciiLower(a[index]) != asciiLower(b[index])) return false;
    }
    return true;
}

fn asciiLower(ch: u8) u8 {
    return if (ch >= 'A' and ch <= 'Z') ch + 32 else ch;
}

test "default config maps known extensions through SDK backend" {
    var config = initDefault();
    try std.testing.expectEqual(@as(usize, 4), appCount(&config));
    try std.testing.expectEqual(@as(usize, 0), defaultIndex(&config, "C:\\AUTOEXEC.BAT"));
    try std.testing.expectEqual(@as(usize, 1), defaultIndex(&config, "D:\\IMAGE.bmp"));
    try std.testing.expectEqual(@as(usize, 3), defaultIndex(&config, "C:\\TEMP\\TADA.WAV"));
    try std.testing.expectEqual(@as(usize, 0), defaultIndex(&config, "C:\\TEMP\\DATA.BIN"));
    try std.testing.expectEqualStrings("Notepad", appForMenuIndex(&config, 0).?.titleText());
    try std.testing.expectEqualStrings("Paint", appForMenuIndex(&config, 1).?.titleText());
    try std.testing.expectEqualStrings("Fonts", appForMenuIndex(&config, 2).?.titleText());
    try std.testing.expectEqualStrings("R4Synth", appForMenuIndex(&config, 3).?.titleText());
    try std.testing.expect(appForMenuIndex(&config, 4) == null);
    try std.testing.expectEqualStrings("[TXT]", prefix(&config, "C:\\CONFIG.R4S"));
    try std.testing.expectEqualStrings("[BMP]", prefix(&config, "D:\\IMAGE.bmp"));
    try std.testing.expectEqualStrings("[AUD]", prefix(&config, "D:\\SONG.mid"));
    try std.testing.expectEqualStrings("Bitmap", typeName(&config, "D:\\IMAGE.bmp"));
    try std.testing.expectEqualStrings("BMP", typeShort(&config, "D:\\IMAGE.bmp"));
    try std.testing.expect(rank(&config, "README.TXT") < rank(&config, "IMAGE.BMP"));
    try std.testing.expect(rank(&config, "IMAGE.BMP") < rank(&config, "TADA.WAV"));
}

test "config overrides drive Explorer menu and launch defaults" {
    if (!r4std.initialized()) return error.SkipZigTest;
    var config = loadFromBytes(
        \\R4S_FORMAT=1
        \\SCHEMA=APPASSOC
        \\APP.NOTEPAD.TITLE=Editor
        \\APP.NOTEPAD.PATH=C:\R4OS\SOFTWARE\DESKTOP\EDITOR.R4X
        \\APP.NOTEPAD.POLICY=console
        \\APP.NOTEPAD.ARGS=/OPEN %1
        \\EXT.TXT.APP=NOTEPAD
        \\EXT.TXT.TYPE=Plain Text
        \\EXT.TXT.SHORT=TXT
        \\EXT.TXT.PREFIX=[TXT]
        \\EXT.TXT.RANK=3
    );
    try std.testing.expectEqualStrings("Editor", appForMenuIndex(&config, 0).?.titleText());
    try std.testing.expectEqualStrings("Plain Text", typeName(&config, "D:\\README.TXT"));
    var args: [128]u8 = .{0} ** 128;
    const target = config.resolvePath("D:\\README.TXT", args[0..]).?;
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\EDITOR.R4X", target.app_path);
    try std.testing.expectEqualStrings("/OPEN D:\\README.TXT", target.args);
    try std.testing.expectEqual(@as(usize, 0), defaultIndex(&config, "D:\\README.TXT"));
}

test "broken config keeps defaults and r4x files stay direct" {
    if (!r4std.initialized()) return error.SkipZigTest;
    var config = loadFromBytes(
        \\R4S_FORMAT=1
        \\SCHEMA=APPASSOC
        \\APP.NOTEPAD.PATH=C:\R4OS\SOFTWARE\DESKTOP\BROKEN.TXT
        \\APP.PAINT.ARGS=/OPEN
        \\EXT.TXT.APP=MISSING
    );
    var args: [128]u8 = .{0} ** 128;
    const text = config.resolvePath("C:\\TEMP\\NOTE.TXT", args[0..]).?;
    try std.testing.expectEqualStrings("NOTEPAD", text.app_id);
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\NOTEPAD.R4X", text.app_path);
    const direct = config.resolvePath("C:\\R4OS\\SOFTWARE\\DESKTOP\\APP.R4X", args[0..]).?;
    try std.testing.expectEqualStrings("", direct.app_id);
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\APP.R4X", direct.app_path);
    try std.testing.expectEqualStrings("", direct.args);
}
