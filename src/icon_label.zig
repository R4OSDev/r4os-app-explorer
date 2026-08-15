pub const name_chars: usize = 12;
pub const text_max: usize = name_chars + 1;
pub const buffer_len: usize = text_max + 1;

pub const Label = struct {
    line_count: usize = 0,
    lines: [2][buffer_len]u8 = .{
        .{0} ** buffer_len,
        .{0} ** buffer_len,
    },
};

pub fn format(name: []const u8, preserve_extension: bool) Label {
    var result = Label{};
    if (name.len <= name_chars) {
        result.line_count = if (name.len == 0) 0 else 1;
        setLine(result.lines[0][0..], name);
        return result;
    }

    result.line_count = 2;
    setContinuedLine(result.lines[0][0..], name[0..@min(name.len, name_chars)]);

    if (name.len <= name_chars * 2) {
        setLine(result.lines[1][0..], name[name_chars..]);
        return result;
    }

    if (preserve_extension) {
        if (extensionStart(name)) |dot| {
            if (dot > name_chars and dot < name.len) {
                setTruncatedWithExtension(result.lines[1][0..], name[name_chars..dot], name[dot..]);
                return result;
            }
        }
    }

    setTruncated(result.lines[1][0..], name[name_chars..]);
    return result;
}

pub fn selfTest() bool {
    if (!expect("AUTOEXEC.BAT", false, 1, "AUTOEXEC.BAT", "")) return false;
    if (!expect("ABCDEFGHIJKLM", false, 2, "ABCDEFGHIJKL-", "M")) return false;
    if (!expect("ABCDEFGHIJKLMNOPQRSTUVWX", false, 2, "ABCDEFGHIJKL-", "MNOPQRSTUVWX")) return false;
    if (!expect("ABCDEFGHIJKLMNOPQRSTUVWXY", false, 2, "ABCDEFGHIJKL-", "MNOPQRSTU...")) return false;
    if (!expect("LONGCONFIGURATIONFILE.R4S", true, 2, "LONGCONFIGUR-", "ATIONF...R4S")) return false;
    if (!expect("LONGCONFIGURATIONFOLDERNAME", false, 2, "LONGCONFIGUR-", "ATIONFOLD...")) return false;
    return true;
}

fn setLine(out: []u8, value: []const u8) void {
    @memset(out, 0);
    if (out.len == 0) return;
    const count = @min(value.len, @min(name_chars, out.len - 1));
    if (count > 0) @memcpy(out[0..count], value[0..count]);
    out[count] = 0;
}

fn setContinuedLine(out: []u8, value: []const u8) void {
    @memset(out, 0);
    if (out.len == 0) return;
    const count = @min(value.len, @min(name_chars, out.len - 1));
    if (count > 0) @memcpy(out[0..count], value[0..count]);
    if (count + 1 < out.len) {
        out[count] = '-';
        out[count + 1] = 0;
    } else {
        out[count] = 0;
    }
}

fn setTruncated(out: []u8, value: []const u8) void {
    @memset(out, 0);
    if (out.len == 0) return;
    const prefix_count = @min(value.len, @min(name_chars - 3, out.len - 1));
    if (prefix_count > 0) @memcpy(out[0..prefix_count], value[0..prefix_count]);
    appendBytes(out, "...");
}

fn setTruncatedWithExtension(out: []u8, middle: []const u8, extension: []const u8) void {
    @memset(out, 0);
    if (out.len == 0) return;
    const ext = if (extension.len > 0 and extension[0] == '.') extension[1..] else extension;
    if (ext.len + 3 >= name_chars) {
        appendBytes(out, "...");
        const keep_ext = @min(ext.len, name_chars - 3);
        appendBytes(out, ext[ext.len - keep_ext ..]);
        return;
    }
    const prefix_capacity = name_chars - 3 - ext.len;
    const prefix_count = @min(middle.len, prefix_capacity);
    if (prefix_count > 0) @memcpy(out[0..prefix_count], middle[0..prefix_count]);
    out[prefix_count] = 0;
    appendBytes(out, "...");
    appendBytes(out, ext);
}

fn appendBytes(out: []u8, value: []const u8) void {
    var len = spanZ(out).len;
    if (len >= out.len) return;
    const max_chars = @min(name_chars, out.len - 1);
    if (len >= max_chars) return;
    const count = @min(value.len, max_chars - len);
    if (count > 0) @memcpy(out[len .. len + count], value[0..count]);
    len += count;
    out[len] = 0;
}

fn extensionStart(name: []const u8) ?usize {
    var dot: ?usize = null;
    var i: usize = 0;
    while (i < name.len) : (i += 1) {
        if (name[i] == '.') dot = i;
    }
    const start = dot orelse return null;
    if (start == 0 or start + 1 >= name.len) return null;
    return start;
}

fn expect(name: []const u8, preserve_extension: bool, line_count: usize, first: []const u8, second: []const u8) bool {
    const label = format(name, preserve_extension);
    if (label.line_count != line_count) return false;
    if (!equals(spanZ(label.lines[0][0..]), first)) return false;
    if (!equals(spanZ(label.lines[1][0..]), second)) return false;
    if (label.line_count == 1 and spanZ(label.lines[0][0..]).len > name_chars) return false;
    if (label.line_count == 2) {
        const first_len = spanZ(label.lines[0][0..]).len;
        const second_len = spanZ(label.lines[1][0..]).len;
        if (first_len > text_max or first_len == 0 or label.lines[0][first_len - 1] != '-') return false;
        if (second_len > name_chars) return false;
    }
    return true;
}

fn spanZ(buf: []const u8) []const u8 {
    var len: usize = 0;
    while (len < buf.len and buf[len] != 0) : (len += 1) {}
    return buf[0..len];
}

fn equals(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (a[i] != b[i]) return false;
    }
    return true;
}

test "Explorer icon labels wrap and truncate consistently" {
    const std = @import("std");
    try std.testing.expect(expect("AUTOEXEC.BAT", false, 1, "AUTOEXEC.BAT", ""));
    try std.testing.expect(expect("ABCDEFGHIJKLM", false, 2, "ABCDEFGHIJKL-", "M"));
    try std.testing.expect(expect("ABCDEFGHIJKLMNOPQRSTUVWX", false, 2, "ABCDEFGHIJKL-", "MNOPQRSTUVWX"));
    try std.testing.expect(expect("ABCDEFGHIJKLMNOPQRSTUVWXY", false, 2, "ABCDEFGHIJKL-", "MNOPQRSTU..."));
    try std.testing.expect(expect("LONGCONFIGURATIONFILE.R4S", true, 2, "LONGCONFIGUR-", "ATIONF...R4S"));
    try std.testing.expect(expect("LONGCONFIGURATIONFOLDERNAME", false, 2, "LONGCONFIGUR-", "ATIONFOLD..."));
}
