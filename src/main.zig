const r4os = @import("r4os");
const r4std = @import("r4std");
const AppApi = struct {
    sys: r4os.r4sys.Context,
    desk: r4os.r4desk.Context,
    draw: r4os.r4draw.Context,
    net: r4os.r4net.Context,
    dev: r4os.r4dev.Context,

    fn init(r4_app: *r4os.App) ?AppApi {
        return .{
            .sys = r4_app.system(),
            .desk = r4_app.desktop() orelse return null,
            .draw = r4_app.drawing() orelse return null,
            .net = r4_app.networkLowLevel() orelse return null,
            .dev = r4_app.devicesLowLevel() orelse return null,
        };
    }
};
const file_assoc = @import("associations.zig");
const icon_label = @import("icon_label.zig");

const black: u32 = 0x000000;
const white: u32 = 0xFFFFFF;
const app_bg: u32 = 0xE8E8E8;
const panel_bg: u32 = 0xD8D8D8;
const status_bg: u32 = 0xD0D0D0;
const title_bg: u32 = 0x008080;
const select_bg: u32 = 0x000080;
const chrome_line_shadow: u32 = 0x808080;
const chrome_line_light: u32 = 0xFFFFFF;

const max_entries: usize = 64;
const no_selection: usize = max_entries;
const row_h: i32 = 16;
const drive_kind_fat32: u8 = 2;
const drive_kind_ntfs: u8 = 3;

fn driveBrowsable(kind: u8) bool {
    return kind == drive_kind_fat32 or kind == drive_kind_ntfs;
}
const entry_kind_file: i32 = 0;
const entry_kind_dir: i32 = 1;
const entry_kind_drive: i32 = 2;
const key_f3: u8 = 0x82;
const double_click_ms: u64 = 500;
const page_stride: u32 = @intCast(max_entries);
const assoc_config_max_bytes: usize = 4096;
const history_max: usize = 16;
const explorer_min_frame_w: i32 = 570;
const explorer_min_frame_h: i32 = 320;
const explorer_fallback_frame_chrome_w: i32 = 16;
const explorer_fallback_frame_chrome_h: i32 = 38;
const explorer_min_client_fallback_w: i32 = explorer_min_frame_w - explorer_fallback_frame_chrome_w;
const explorer_min_client_fallback_h: i32 = explorer_min_frame_h - explorer_fallback_frame_chrome_h;
const icon_cell_w: i32 = 112;
const icon_cell_h: i32 = 84;
const icon_pad_x: i32 = 4;
const icon_pad_y: i32 = 10;
const icon_label_name_chars: usize = icon_label.name_chars;
const icon_label_text_max: usize = icon_label.text_max;
const icon_label_w: i32 = 104;
const icon_label_y: i32 = 46;
const icon_label_line_gap: i32 = 2;
const explorer_menu_y: i32 = 0;
const explorer_menu_h: i32 = 20;
const explorer_toolbar_y: i32 = explorer_menu_y + explorer_menu_h;
const explorer_toolbar_h: i32 = 48;
const explorer_address_y: i32 = explorer_toolbar_y + explorer_toolbar_h;
const explorer_address_h: i32 = 24;
const explorer_icon_view_bottom_pad: i32 = 18;
const chrome_separator_h: i32 = 2;
const chrome_top_line_y: i32 = explorer_menu_y;
const chrome_menu_toolbar_line_y: i32 = explorer_toolbar_y;
const chrome_toolbar_address_line_y: i32 = explorer_address_y;
const toolbar_back_icon_resource = "BACK.ICO";
const toolbar_forward_icon_resource = "FORWARD.ICO";
const toolbar_up_icon_resource = "UP.ICO";
const toolbar_cut_icon_resource = "CUT.ICO";
const toolbar_copy_icon_resource = "COPY.ICO";
const toolbar_paste_icon_resource = "PASTE.ICO";
const toolbar_delete_icon_resource = "DELETE.ICO";
const folder_icon_path = "C:\\R4OS\\Media\\Icons\\Folder.ico";
const toolbar_icon_bytes_max: usize = 4096;
const loaded_icon_max_w: usize = 32;
const loaded_icon_max_h: usize = 32;
const loaded_icon_pixels_max: usize = loaded_icon_max_w * loaded_icon_max_h;
const toolbar_icon_max_w: usize = 32;
const toolbar_icon_max_h: usize = 21;
const toolbar_icon_preferred: u16 = 32;
const folder_icon_max_w: usize = 32;
const folder_icon_max_h: usize = 32;
const folder_icon_preferred: u16 = 32;
const toolbar_icon_alpha_visible: u8 = 128;
const shortcut_file_max_bytes: usize = 1024;
const toolbar_button_gap: i32 = 3;
const toolbar_button_start_x: i32 = 4;
const toolbar_icon_button_w: i32 = 74;
const toolbar_icon_button_h: i32 = 42;
const toolbar_icon_button_y: i32 = 23;
const toolbar_text_button_y: i32 = 28;
const toolbar_text_button_h: i32 = 28;
const toolbar_separator_w: i32 = 2;
const toolbar_back_x: i32 = toolbar_button_start_x;
const toolbar_forward_x: i32 = toolbar_back_x + toolbar_icon_button_w + toolbar_button_gap;
const toolbar_up_x: i32 = toolbar_forward_x + toolbar_icon_button_w + toolbar_button_gap;
const toolbar_separator_x: i32 = toolbar_up_x + toolbar_icon_button_w + toolbar_button_gap;
const toolbar_cut_w: i32 = toolbar_icon_button_w;
const toolbar_copy_w: i32 = toolbar_icon_button_w;
const toolbar_paste_w: i32 = toolbar_icon_button_w;
const toolbar_delete_w: i32 = toolbar_icon_button_w;
const toolbar_cut_x: i32 = toolbar_separator_x + toolbar_separator_w + toolbar_button_gap;
const toolbar_copy_x: i32 = toolbar_cut_x + toolbar_cut_w + toolbar_button_gap;
const toolbar_paste_x: i32 = toolbar_copy_x + toolbar_copy_w + toolbar_button_gap;
const toolbar_delete_x: i32 = toolbar_paste_x + toolbar_paste_w + toolbar_button_gap;

const association_count_max: usize = file_assoc.max_open_with_items;
const open_with_row_h: i32 = 20;
const table_type_w: i32 = 68;
const table_size_w: i32 = 64;
const table_date_w: i32 = 152;

const ShortcutOpenError = r4std.shortcut.Error || error{
    ShortcutNotFound,
    ShortcutPathTooLong,
};

const SortMode = enum {
    name,
    kind,
    size,
    modified,
};

const NameMode = enum {
    none,
    new_folder,
    new_file,
    rename,
};

const Command = enum(u32) {
    file_new_menu = 101,
    file_delete = 102,
    file_rename = 103,
    file_close = 104,
    new_folder = 105,
    new_text_document = 106,
    edit_cut = 201,
    edit_copy = 202,
    edit_paste = 203,
    edit_select_all = 204,
    view_refresh = 301,
    view_toggle_address = 302,
};

const ExplorerMenus = struct {
    file_items: [4]r4os.gui.MenuItem = undefined,
    edit_items: [4]r4os.gui.MenuItem = undefined,
    view_items: [2]r4os.gui.MenuItem = undefined,
    menus: [3]r4os.gui.MenubarMenu = undefined,
};

const new_menu_items = [_]r4os.gui.MenuItem{
    .{ .text = "Folder", .id = @intFromEnum(Command.new_folder) },
    .{ .text = "Text Document", .id = @intFromEnum(Command.new_text_document) },
};

const ViewMode = enum {
    computer,
    directory,
};

const FsAction = enum {
    delete_file,
    delete_dir,
    create_dir,
    create_file,
    rename,
    copy,
    move,
};

const Entry = struct {
    kind: i32 = -1,
    path: [128]u8 = .{0} ** 128,
    label: [56]u8 = .{0} ** 56,
    is_shortcut: bool = false,
    shortcut_valid: bool = false,
    shortcut_icon: [128]u8 = .{0} ** 128,
    info_valid: bool = false,
    attr: u8 = 0,
    size: u64 = 0,
    first_cluster: u32 = 0,
    modified_time: u16 = 0,
    modified_date: u16 = 0,
};

const TimestampView = struct {
    timezone_index: usize = r4std.time.utc_index,
    clock_format: u32 = r4os.abi.clock_format_24h,
    local: bool = false,
};

const IconLabel = icon_label.Label;

const HistoryEntry = struct {
    mode: ViewMode = .computer,
    path: [128]u8 = .{0} ** 128,
};

const DecodedIcon = struct {
    width: u32,
    height: u32,
};

const LoadedIconImage = struct {
    loaded: bool = false,
    width: u32 = 0,
    height: u32 = 0,
    pixels: [loaded_icon_pixels_max]u32 = .{0} ** loaded_icon_pixels_max,
};

pub fn r4_app_main(r4_app: *r4os.App) i32 {
    if (!r4std.init(r4_app.startContext())) return r4os.abi.err_no_group;
    var ctx = AppApi.init(r4_app) orelse return r4os.abi.err_no_group;
    if (hasArg(ctx.sys.argsRaw(), "/SELFTEST")) return runSelfTest(&ctx.sys);
    var app = App{ .ctx = &ctx };
    return app.run();
}

const App = struct {
    ctx: *AppApi,
    hosted_w: i32 = 420,
    hosted_h: i32 = 260,
    initialized: bool = false,
    selected_index: usize = no_selection,
    scroll_offset: usize = 0,
    page_start_index: u32 = 2,
    has_prev_page: bool = false,
    has_more_entries: bool = false,
    pending_delete: bool = false,
    pending_delete_all: bool = false,
    pending_delete_path: [128]u8 = .{0} ** 128,
    copy_source_path: [128]u8 = .{0} ** 128,
    copy_is_move: bool = false,
    pending_paste: bool = false,
    pending_paste_target: [128]u8 = .{0} ** 128,
    open_with_active: bool = false,
    open_with_index: usize = 0,
    open_with_path: [128]u8 = .{0} ** 128,
    open_with_choices: r4std.file_handler.ChoiceList = .{},
    name_mode: NameMode = .none,
    name_input: r4os.gui.TextField(48) = .{},
    rename_source_path: [128]u8 = .{0} ** 128,
    menubar_state: r4os.gui.MenubarState = .{},
    menu_storage: ExplorerMenus = .{},
    new_menu_open: bool = false,
    address_visible: bool = true,
    select_all_active: bool = false,
    quit_requested: bool = false,
    last_click_index: usize = no_selection,
    last_click_tick: u64 = 0,
    sort_mode: SortMode = .name,
    sort_ascending: bool = true,
    assoc: r4std.app_assoc.Config = .{},
    assoc_loaded_from_file: bool = false,
    view_mode: ViewMode = .computer,
    back_history: [history_max]HistoryEntry = .{HistoryEntry{}} ** history_max,
    back_count: usize = 0,
    forward_history: [history_max]HistoryEntry = .{HistoryEntry{}} ** history_max,
    forward_count: usize = 0,
    current_drive: r4os.abi.DriveInfo = .{},
    current_path: [128]u8 = .{0} ** 128,
    status: [80]u8 = .{0} ** 80,
    entries: [max_entries]Entry = .{Entry{}} ** max_entries,
    entry_count: usize = 0,
    toolbar_back_icon: LoadedIconImage = .{},
    toolbar_forward_icon: LoadedIconImage = .{},
    toolbar_up_icon: LoadedIconImage = .{},
    toolbar_cut_icon: LoadedIconImage = .{},
    toolbar_copy_icon: LoadedIconImage = .{},
    toolbar_paste_icon: LoadedIconImage = .{},
    toolbar_delete_icon: LoadedIconImage = .{},
    folder_icon: LoadedIconImage = .{},
    textfile_icon: LoadedIconImage = .{},

    fn run(self: *App) i32 {
        if (self.ctx.desk.programWindowId() >= 0) return self.runHosted();
        self.ctx.sys.println("Explorer");
        self.ctx.sys.println("Please start from Desktop or the Computer desktop shortcut.");
        return 0;
    }

    fn runHosted(self: *App) i32 {
        _ = self.ctx.desk.guiSetTitle("Explorer");
        self.setExplorerMinFrameSize();
        self.init();
        var info: r4os.abi.GuiWindowInfo = .{};
        _ = self.ctx.desk.guiWindowInfo(&info);
        self.updateHostedMetrics(info);
        self.render();

        while (!self.quit_requested and !self.ctx.sys.programShouldClose()) {
            var event: r4os.abi.GuiEvent = .{};
            while (self.ctx.desk.guiPollEvent(&event) > 0) {
                const kind: r4os.abi.GuiEventKind = @enumFromInt(event.kind);
                switch (kind) {
                    .close => return 0,
                    .resize => {
                        _ = self.ctx.desk.guiWindowInfo(&info);
                        self.updateHostedMetrics(info);
                        self.render();
                    },
                    .mouse_down => self.handleMouseDown(event.x, event.y, event.tick),
                    .mouse_up => self.handleMouseUp(event.x, event.y),
                    .mouse_move => self.handleMouseMove(event.x, event.y),
                    .key_down => self.handleKey(@intCast(event.key & 0xFF)),
                    else => {},
                }
            }
            self.ctx.sys.sleepTicks(3);
        }
        return 0;
    }

    fn setExplorerMinFrameSize(self: *App) void {
        var info: r4os.abi.GuiWindowInfo = .{};
        var chrome_w = explorer_fallback_frame_chrome_w;
        var chrome_h = explorer_fallback_frame_chrome_h;
        if (self.ctx.desk.guiWindowInfo(&info) >= 0 and info.frame_w > 0 and info.frame_h > 0 and info.client_w > 0 and info.client_h > 0) {
            chrome_w = @max(0, info.frame_w - info.client_w);
            chrome_h = @max(0, info.frame_h - info.client_h);
        }
        _ = self.ctx.desk.guiSetMinSize(
            @max(1, explorer_min_frame_w - chrome_w),
            @max(1, explorer_min_frame_h - chrome_h),
        );
    }

    fn init(self: *App) void {
        if (self.initialized) return;
        self.loadAssociations();
        self.loadToolbarIcons();
        self.loadEntryIcons();
        self.view_mode = .computer;
        setZ(self.current_path[0..], "Computer");
        self.loadComputerView();
        if (explorerStartPathArg(self.ctx.sys.argsRaw())) |path| self.navigateToPath(path, false);
        self.initialized = true;
    }

    fn loadToolbarIcons(self: *App) void {
        var bytes: [toolbar_icon_bytes_max]u8 = undefined;
        self.loadToolbarIcon(toolbar_back_icon_resource, &self.toolbar_back_icon, bytes[0..]);
        self.loadToolbarIcon(toolbar_forward_icon_resource, &self.toolbar_forward_icon, bytes[0..]);
        self.loadToolbarIcon(toolbar_up_icon_resource, &self.toolbar_up_icon, bytes[0..]);
        self.loadToolbarIcon(toolbar_cut_icon_resource, &self.toolbar_cut_icon, bytes[0..]);
        self.loadToolbarIcon(toolbar_copy_icon_resource, &self.toolbar_copy_icon, bytes[0..]);
        self.loadToolbarIcon(toolbar_paste_icon_resource, &self.toolbar_paste_icon, bytes[0..]);
        self.loadToolbarIcon(toolbar_delete_icon_resource, &self.toolbar_delete_icon, bytes[0..]);
    }

    fn loadToolbarIcon(self: *App, resource_name: []const u8, target: *LoadedIconImage, bytes: []u8) void {
        if (decodeToolbarIconResource(&self.ctx.sys, resource_name, bytes, target.pixels[0..])) |icon| {
            target.loaded = true;
            target.width = icon.width;
            target.height = icon.height;
        }
    }

    fn loadEntryIcons(self: *App) void {
        var bytes: [toolbar_icon_bytes_max]u8 = undefined;
        self.loadFolderIcon(folder_icon_path, &self.folder_icon, bytes[0..]);
        self.loadFolderIcon(r4os.ico.textfile_icon_path, &self.textfile_icon, bytes[0..]);
    }

    fn loadFolderIcon(self: *App, path: []const u8, target: *LoadedIconImage, bytes: []u8) void {
        if (decodeFolderIcon(&self.ctx.sys, path, bytes, target.pixels[0..])) |icon| {
            target.loaded = true;
            target.width = icon.width;
            target.height = icon.height;
        }
    }

    fn loadAssociations(self: *App) void {
        self.assoc = r4std.app_assoc.Config.initDefault();
        self.assoc_loaded_from_file = false;
        var buffer: [assoc_config_max_bytes]u8 = undefined;
        const len = self.ctx.sys.fileRead(r4std.settings.paths.assoc, buffer[0..]);
        if (len > 0) {
            self.assoc_loaded_from_file = self.assoc.loadFromBytes(buffer[0..@intCast(len)]);
        }
        _ = r4std.subsystem_runtime.load(&self.ctx.sys);
    }

    fn updateHostedMetrics(self: *App, info: r4os.abi.GuiWindowInfo) void {
        const canvas = r4os.gui.Canvas.init(&self.ctx.draw, info);
        self.hosted_w = clampI32(canvas.w, 260, 1600);
        self.hosted_h = clampI32(canvas.h, 180, 1000);
    }

    fn handleKey(self: *App, key: u8) void {
        if (self.open_with_active) {
            self.handleOpenWithKey(key);
            return;
        }
        if (self.name_mode != .none) {
            self.handleNameDialogKey(key);
            return;
        }
        if (self.new_menu_open) {
            if (key == 0x1B) {
                self.new_menu_open = false;
                self.render();
            }
            return;
        }
        if (self.menubar_state.isOpen() or key == r4os.gui.Key.menu_focus or key == r4os.gui.Key.f10) {
            var menu_storage: ExplorerMenus = undefined;
            const menus = buildExplorerMenus(&menu_storage, self.address_visible);
            const result = self.menubar_state.keyAction(menus, key);
            if (result.hasCommand()) self.executeCommand(result.command_id);
            self.render();
            return;
        }
        if (key == 0x1B) return;
        if (key == r4os.gui.Key.ctrl_a) {
            self.selectAll();
            return;
        }
        if (key == r4os.gui.Key.ctrl_c) {
            self.copySelected();
            return;
        }
        if (key == r4os.gui.Key.ctrl_x) {
            self.cutSelected();
            return;
        }
        if (key == r4os.gui.Key.ctrl_v) {
            self.pasteCopied();
            return;
        }
        if (key == 0x08) {
            self.goUp();
            return;
        }
        if (key == r4os.gui.Key.left or key == r4os.gui.Key.right or key == r4os.gui.Key.up or key == r4os.gui.Key.down or key == r4os.gui.Key.page_up or key == r4os.gui.Key.page_down or key == r4os.gui.Key.home or key == r4os.gui.Key.end) {
            self.moveSelectionByKey(key);
            return;
        }
        if (key == key_f3 or key == 'r' or key == 'R') {
            self.refreshDirectory();
            return;
        }
        if (key == 0x7F) {
            self.deleteSelected();
            return;
        }
        if (key == 'n' or key == 'N') {
            self.beginNewFolder();
            return;
        }
        if (key == 'f' or key == 'F') {
            self.beginNewFile();
            return;
        }
        if (key == 'y' or key == 'Y') {
            self.copySelected();
            return;
        }
        if (key == 'u' or key == 'U') {
            self.cutSelected();
            return;
        }
        if (key == 'p' or key == 'P') {
            self.pasteCopied();
            return;
        }
        if (key == 0x83 or key == 'm' or key == 'M') {
            self.beginRename();
            return;
        }
        if (key == '[' or key == '<') {
            self.goBack();
            return;
        }
        if (key == ']' or key == '>') {
            self.goForward();
            return;
        }
        if (key == 'c' or key == 'C') {
            self.switchToDrive('C');
            return;
        }
        if (key == 'd' or key == 'D') {
            self.switchToDrive('D');
            return;
        }
        if (key == 'v' or key == 'V') {
            self.switchToNextBrowseDrive();
            return;
        }
        if (key == 'w' or key == 'W') {
            self.beginOpenWith();
            return;
        }
        if (key == '\r' or key == '\n') self.openSelected();
    }

    fn handleMouseDown(self: *App, x: i32, y: i32, tick: u64) void {
        if (self.open_with_active) {
            self.handleOpenWithMouse(x, y);
            return;
        }
        if (self.name_mode != .none) {
            self.handleNameDialogMouse(x, y);
            return;
        }
        if (self.new_menu_open) {
            if (self.newMenuIndexAt(x, y)) |index| {
                self.new_menu_open = false;
                self.executeCommand(new_menu_items[index].id);
                return;
            }
            self.new_menu_open = false;
        }
        var menu_storage: ExplorerMenus = undefined;
        const menus = buildExplorerMenus(&menu_storage, self.address_visible);
        const menu_rect = self.menuBarRect();
        const menu_was_open = self.menubar_state.isOpen();
        const menu_result = self.menubar_state.mouseDown(menu_rect, menus, x, y);
        if (menu_rect.contains(x, y) or (menu_was_open and menu_result.action != .none)) {
            self.render();
            return;
        }
        if (self.backButtonRect().contains(x, y)) {
            self.goBack();
            return;
        }
        if (self.forwardButtonRect().contains(x, y)) {
            self.goForward();
            return;
        }
        if (self.upButtonRect().contains(x, y)) {
            self.goUp();
            return;
        }
        if (self.cutButtonRect().contains(x, y)) {
            self.cutSelected();
            return;
        }
        if (self.copyButtonRect().contains(x, y)) {
            self.copySelected();
            return;
        }
        if (self.pasteButtonRect().contains(x, y)) {
            self.pasteCopied();
            return;
        }
        if (self.deleteButtonRect().contains(x, y)) {
            self.deleteSelected();
            return;
        }
        if (self.iconIndexAt(x, y)) |index| {
            const is_double = self.last_click_index == index and self.last_click_tick != 0 and tick >= self.last_click_tick and tick - self.last_click_tick <= self.ctx.sys.ticksFromMilliseconds(double_click_ms);
            if (index != self.selected_index) self.clearPendingDelete();
            self.select_all_active = false;
            self.selected_index = index;
            self.last_click_index = index;
            self.last_click_tick = tick;
            if (is_double) {
                self.openSelected();
            } else {
                self.updateSelectedStatus();
                self.render();
            }
            return;
        }
        const scrollbar = self.iconScrollbar();
        const part = scrollbar.partAt(x, y);
        if (part != .none) {
            const step = scrollbar.step(part);
            if (step.action == .changed) {
                self.scroll_offset = step.first_index;
                self.render();
            }
        }
    }

    fn handleMouseUp(self: *App, x: i32, y: i32) void {
        if (!self.menubar_state.isOpen()) return;
        var menu_storage: ExplorerMenus = undefined;
        const menus = buildExplorerMenus(&menu_storage, self.address_visible);
        const result = self.menubar_state.mouseUp(self.menuBarRect(), menus, x, y);
        if (result.hasCommand()) self.executeCommand(result.command_id);
        self.render();
    }

    fn handleMouseMove(self: *App, x: i32, y: i32) void {
        if (!self.menubar_state.isOpen()) return;
        var menu_storage: ExplorerMenus = undefined;
        const menus = buildExplorerMenus(&menu_storage, self.address_visible);
        _ = self.menubar_state.mouseMove(self.menuBarRect(), menus, x, y);
        self.render();
    }

    fn render(self: *App) void {
        var paint = switch (r4os.app_gui.beginPaintForSize(&self.ctx.draw, self.hosted_w, self.hosted_h)) {
            .paint => |value| value,
            .failure => return,
        };
        defer paint.discard();
        const canvas = paint.canvas;
        var scratch: [80]u8 = .{0} ** 80;

        _ = canvas.clear(app_bg);
        _ = canvas.rect(self.toolbarRect(), panel_bg);
        self.drawToolbarButton(canvas, self.backButtonRect(), .back);
        self.drawToolbarButton(canvas, self.forwardButtonRect(), .forward);
        self.drawToolbarButton(canvas, self.upButtonRect(), .up);
        self.drawToolbarSeparator(canvas, toolbar_separator_x);
        self.drawToolbarButton(canvas, self.cutButtonRect(), .cut);
        self.drawToolbarButton(canvas, self.copyButtonRect(), .copy);
        self.drawToolbarButton(canvas, self.pasteButtonRect(), .paste);
        self.drawToolbarButton(canvas, self.deleteButtonRect(), .delete);
        self.drawAddressBar(canvas, scratch[0..]);
        self.drawChromeSeparators(canvas);
        self.drawIconView(canvas, scratch[0..]);
        _ = canvas.scrollbar(self.iconScrollbar(), scratch[0..]);
        _ = canvas.rect(r4os.gui.statusBarRect(canvas.bounds()), status_bg);
        _ = canvas.label(.{
            .rect = .{ .x = 8, .y = canvas.h - 15, .w = canvas.w - 16, .h = 14 },
            .text = spanZ(self.status[0..]),
            .fg = black,
            .bg = status_bg,
        }, scratch[0..]);
        self.drawMenuBar(canvas, scratch[0..]);
        if (self.name_mode != .none) self.drawNameDialog(canvas, scratch[0..]);
        if (self.open_with_active) self.drawOpenWithDialog(canvas, scratch[0..]);
        _ = paint.present();
    }

    const ToolbarLabel = enum {
        back,
        forward,
        up,
        cut,
        copy,
        paste,
        delete,
    };

    fn drawToolbarButton(self: *App, canvas: r4os.gui.Canvas, rect: r4os.gui.Rect, label: ToolbarLabel) void {
        if (self.toolbarIcon(label)) |icon| {
            self.drawToolbarIconButton(canvas, rect, toolbarLabelText(label), icon);
            return;
        }
        var text: [16]u8 = .{0} ** 16;
        var draw_scratch: [24]u8 = .{0} ** 24;
        toolbarText(label, &text);
        _ = canvas.toolbarButton(.{
            .rect = rect,
            .text = spanZ(text[0..]),
        }, draw_scratch[0..]);
    }

    fn toolbarIcon(self: *const App, label: ToolbarLabel) ?*const LoadedIconImage {
        return switch (label) {
            .back => &self.toolbar_back_icon,
            .forward => &self.toolbar_forward_icon,
            .up => &self.toolbar_up_icon,
            .cut => &self.toolbar_cut_icon,
            .copy => &self.toolbar_copy_icon,
            .paste => &self.toolbar_paste_icon,
            .delete => &self.toolbar_delete_icon,
        };
    }

    fn drawToolbarIconButton(self: *App, canvas: r4os.gui.Canvas, rect: r4os.gui.Rect, text: []const u8, icon: *const LoadedIconImage) void {
        _ = self;
        var draw_scratch: [24]u8 = .{0} ** 24;
        if (!icon.loaded) {
            _ = canvas.toolbarButton(.{ .rect = rect, .text = text }, draw_scratch[0..]);
            return;
        }

        _ = canvas.toolbarButton(.{ .rect = rect, .text = "" }, draw_scratch[0..]);
        const icon_w: i32 = @intCast(icon.width);
        const icon_h: i32 = @intCast(icon.height);
        const icon_x = rect.x + @divTrunc(rect.w - icon_w, 2);
        const icon_y = rect.y + 4;
        const pixel_count = @as(usize, @intCast(icon.width)) * @as(usize, @intCast(icon.height));
        _ = canvas.raster(icon_x, icon_y, icon.width, icon.height, 1, icon.pixels[0..pixel_count]);

        const label_rect = r4os.gui.Rect{
            .x = rect.x + 2,
            .y = icon_y + icon_h + 1,
            .w = rect.w - 4,
            .h = @max(8, rect.bottom() - (icon_y + icon_h + 2)),
        };
        _ = canvas.label(.{
            .rect = label_rect,
            .text = text,
            .alignment = .center,
            .fg = black,
            .bg = r4os.gui.default_palette.face,
        }, draw_scratch[0..]);
    }

    fn toolbarLabelText(label: ToolbarLabel) []const u8 {
        return switch (label) {
            .back => "Back",
            .forward => "Forward",
            .up => "Up",
            .cut => "Cut",
            .copy => "Copy",
            .paste => "Paste",
            .delete => "Delete",
        };
    }

    fn toolbarText(label: ToolbarLabel, out: *[16]u8) void {
        @memset(out[0..], 0);
        setZ(out[0..], toolbarLabelText(label));
    }

    fn drawMenuBar(self: *App, canvas: r4os.gui.Canvas, scratch: []u8) void {
        _ = canvas.menubar(self.menubar(), scratch);
        if (self.new_menu_open) self.drawNewMenu(canvas, scratch);
    }

    fn drawAddressBar(self: *App, canvas: r4os.gui.Canvas, scratch: []u8) void {
        if (!self.address_visible) return;
        const rect = self.addressRect();
        _ = canvas.rect(rect, panel_bg);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 6, .w = 58, .h = 12 },
            .text = "Address",
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        const field = r4os.gui.Rect{ .x = rect.x + 66, .y = rect.y + 3, .w = @max(80, rect.w - 74), .h = 18 };
        _ = canvas.rect(field, white);
        self.drawInsetFrame(canvas, field);
        _ = canvas.label(.{
            .rect = .{ .x = field.x + 5, .y = field.y + 5, .w = field.w - 10, .h = 10 },
            .text = spanZ(self.current_path[0..]),
            .fg = black,
            .bg = white,
        }, scratch);
    }

    fn drawChromeSeparators(self: *const App, canvas: r4os.gui.Canvas) void {
        self.drawHorizontalChromeSeparator(canvas, chrome_top_line_y);
        self.drawHorizontalChromeSeparator(canvas, chrome_menu_toolbar_line_y);
        self.drawHorizontalChromeSeparator(canvas, chrome_toolbar_address_line_y);
        if (self.address_visible) self.drawHorizontalChromeSeparator(canvas, self.iconViewY() - chrome_separator_h);
    }

    fn drawHorizontalChromeSeparator(self: *const App, canvas: r4os.gui.Canvas, y: i32) void {
        if (self.hosted_w <= 0) return;
        _ = canvas.rect(.{ .x = 0, .y = y, .w = self.hosted_w, .h = 1 }, chrome_line_shadow);
        _ = canvas.rect(.{ .x = 0, .y = y + 1, .w = self.hosted_w, .h = 1 }, chrome_line_light);
    }

    fn drawIconView(self: *App, canvas: r4os.gui.Canvas, scratch: []u8) void {
        const outer = self.iconViewRect();
        _ = canvas.rect(outer, white);
        self.drawInsetFrame(canvas, outer);
        const body = self.iconBodyRect();
        if (self.entry_count == 0) {
            _ = canvas.label(.{
                .rect = .{ .x = body.x + 12, .y = body.y + 12, .w = body.w - 24, .h = 14 },
                .text = if (self.view_mode == .computer) "No drives visible" else "This folder is empty",
                .fg = black,
                .bg = white,
            }, scratch);
            return;
        }
        const visible = self.visibleIconCount();
        var drawn: usize = 0;
        while (drawn < visible and self.scroll_offset + drawn < self.entry_count) : (drawn += 1) {
            const index = self.scroll_offset + drawn;
            self.drawIconEntry(canvas, scratch, index, self.iconCellRect(index));
        }
    }

    fn drawIconEntry(self: *App, canvas: r4os.gui.Canvas, scratch: []u8, index: usize, cell: r4os.gui.Rect) void {
        _ = scratch;
        if (index >= self.entry_count) return;
        const entry = &self.entries[index];
        const selected = self.select_all_active or index == self.selected_index;
        const icon = r4os.gui.Rect{ .x = cell.x + @divTrunc(cell.w - 32, 2), .y = cell.y + icon_pad_y, .w = 32, .h = 32 };
        if (entry.is_shortcut) {
            self.drawShortcutIcon(canvas, icon, entry);
        } else {
            switch (entry.kind) {
                entry_kind_drive => self.drawDriveIcon(canvas, icon),
                entry_kind_dir => self.drawFolderIcon(canvas, icon),
                else => self.drawFileIcon(canvas, icon, spanZ(entry.label[0..])),
            }
        }
        const label = self.iconLabelRect(cell);
        const formatted = icon_label.format(spanZ(entry.label[0..]), entry.kind == entry_kind_file);
        const fg = if (selected) white else black;
        const bg = if (selected) select_bg else white;
        if (selected) {
            _ = canvas.rect(label, select_bg);
        }
        self.drawIconLabel(canvas, label, formatted, fg, bg);
    }

    fn drawIconLabel(self: *App, canvas: r4os.gui.Canvas, rect: r4os.gui.Rect, label: IconLabel, fg: u32, bg: u32) void {
        _ = self;
        const line_h = @max(@as(i32, 1), canvas.font.line_height);
        const total_h = if (label.line_count > 1) line_h * 2 + icon_label_line_gap else line_h;
        var y = rect.y + @max(@as(i32, 0), @divTrunc(rect.h - total_h, 2));
        var i: usize = 0;
        while (i < label.line_count and i < label.lines.len) : (i += 1) {
            const line = spanZ(label.lines[i][0..]);
            if (line.len != 0) {
                const text_w = canvas.textWidthZ(@ptrCast(label.lines[i][0..].ptr));
                const x = r4os.gui.alignedTextXWidth(rect, text_w, .center);
                _ = canvas.text(x, y, @ptrCast(label.lines[i][0..].ptr), fg, bg);
            }
            y += line_h + icon_label_line_gap;
        }
    }

    fn drawFolderIcon(self: *App, canvas: r4os.gui.Canvas, rect: r4os.gui.Rect) void {
        if (self.drawLoadedIconCentered(canvas, rect, &self.folder_icon)) return;
        _ = canvas.rect(.{ .x = rect.x + 2, .y = rect.y + 8, .w = rect.w - 4, .h = rect.h - 8 }, 0xFFE680);
        _ = canvas.rect(.{ .x = rect.x + 5, .y = rect.y + 4, .w = 12, .h = 7 }, 0xFFF0A0);
        _ = canvas.rect(.{ .x = rect.x + 2, .y = rect.y + rect.h - 2, .w = rect.w - 4, .h = 1 }, 0x806000);
        _ = canvas.rect(.{ .x = rect.x + rect.w - 3, .y = rect.y + 9, .w = 1, .h = rect.h - 10 }, 0x806000);
    }

    fn drawLoadedIconCentered(self: *App, canvas: r4os.gui.Canvas, rect: r4os.gui.Rect, icon: *const LoadedIconImage) bool {
        _ = self;
        if (!icon.loaded or icon.width == 0 or icon.height == 0) return false;
        const icon_w: i32 = @intCast(icon.width);
        const icon_h: i32 = @intCast(icon.height);
        const icon_x = rect.x + @divTrunc(rect.w - icon_w, 2);
        const icon_y = rect.y + @divTrunc(rect.h - icon_h, 2);
        const pixel_count = @as(usize, @intCast(icon.width)) * @as(usize, @intCast(icon.height));
        if (pixel_count > icon.pixels.len) return false;
        _ = canvas.raster(icon_x, icon_y, icon.width, icon.height, 1, icon.pixels[0..pixel_count]);
        return true;
    }

    fn drawDriveIcon(self: *App, canvas: r4os.gui.Canvas, rect: r4os.gui.Rect) void {
        _ = self;
        _ = canvas.rect(.{ .x = rect.x + 2, .y = rect.y + 11, .w = rect.w - 4, .h = 13 }, 0xD8D8D8);
        _ = canvas.rect(.{ .x = rect.x + 4, .y = rect.y + 14, .w = rect.w - 8, .h = 3 }, 0x808080);
        _ = canvas.rect(.{ .x = rect.x + rect.w - 9, .y = rect.y + 19, .w = 4, .h = 3 }, 0x00A060);
        _ = canvas.rect(.{ .x = rect.x + 2, .y = rect.y + 23, .w = rect.w - 4, .h = 2 }, 0x606060);
    }

    fn drawFileIcon(self: *App, canvas: r4os.gui.Canvas, rect: r4os.gui.Rect, name: []const u8) void {
        // Dateityp-Icons (0.61.15): Endungsliste im SDK, hier nur Konsum.
        if (r4os.ico.isTextFileName(name) and self.drawLoadedIconCentered(canvas, rect, &self.textfile_icon)) return;
        _ = canvas.rect(.{ .x = rect.x + 7, .y = rect.y + 3, .w = 18, .h = 24 }, white);
        _ = canvas.rect(.{ .x = rect.x + 22, .y = rect.y + 6, .w = 5, .h = 5 }, 0xD0D0D0);
        _ = canvas.rect(.{ .x = rect.x + 7, .y = rect.y + 3, .w = 1, .h = 24 }, 0x606060);
        _ = canvas.rect(.{ .x = rect.x + 7, .y = rect.y + 26, .w = 18, .h = 1 }, 0x606060);
        _ = canvas.rect(.{ .x = rect.x + 11, .y = rect.y + 13, .w = 10, .h = 1 }, 0x808080);
        _ = canvas.rect(.{ .x = rect.x + 11, .y = rect.y + 17, .w = 10, .h = 1 }, 0x808080);
    }

    fn drawShortcutIcon(self: *App, canvas: r4os.gui.Canvas, rect: r4os.gui.Rect, entry: *const Entry) void {
        if (entry.shortcut_valid and spanZ(entry.shortcut_icon[0..]).len != 0 and self.drawShortcutIconPath(canvas, rect, spanZ(entry.shortcut_icon[0..]))) {
            self.drawShortcutOverlay(canvas, rect);
            return;
        }
        self.drawFileIcon(canvas, rect, "");
        self.drawShortcutOverlay(canvas, rect);
    }

    fn drawShortcutIconPath(self: *App, canvas: r4os.gui.Canvas, rect: r4os.gui.Rect, path: []const u8) bool {
        var bytes: [toolbar_icon_bytes_max]u8 = undefined;
        var pixels: [loaded_icon_pixels_max]u32 = undefined;
        const icon = decodeFolderIcon(&self.ctx.sys, path, bytes[0..], pixels[0..]) orelse return false;
        const icon_w: i32 = @intCast(icon.width);
        const icon_h: i32 = @intCast(icon.height);
        const icon_x = rect.x + @divTrunc(rect.w - icon_w, 2);
        const icon_y = rect.y + @divTrunc(rect.h - icon_h, 2);
        const pixel_count = @as(usize, @intCast(icon.width)) * @as(usize, @intCast(icon.height));
        if (pixel_count > pixels.len) return false;
        _ = canvas.raster(icon_x, icon_y, icon.width, icon.height, 1, pixels[0..pixel_count]);
        return true;
    }

    fn drawShortcutOverlay(self: *App, canvas: r4os.gui.Canvas, rect: r4os.gui.Rect) void {
        _ = self;
        const x = rect.x + 2;
        const y = rect.y + rect.h - 11;
        _ = canvas.rect(.{ .x = x, .y = y + 5, .w = 12, .h = 6 }, white);
        _ = canvas.rect(.{ .x = x + 1, .y = y + 6, .w = 8, .h = 2 }, 0x000080);
        _ = canvas.rect(.{ .x = x + 1, .y = y + 8, .w = 8, .h = 2 }, 0x000080);
        _ = canvas.rect(.{ .x = x + 8, .y = y + 4, .w = 2, .h = 6 }, 0x000080);
        _ = canvas.rect(.{ .x = x + 10, .y = y + 5, .w = 2, .h = 4 }, 0x000080);
    }

    fn drawInsetFrame(self: *App, canvas: r4os.gui.Canvas, rect: r4os.gui.Rect) void {
        _ = self;
        _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = rect.w, .h = 1 }, 0x808080);
        _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = 1, .h = rect.h }, 0x808080);
        _ = canvas.rect(.{ .x = rect.x, .y = rect.y + rect.h - 1, .w = rect.w, .h = 1 }, 0xFFFFFF);
        _ = canvas.rect(.{ .x = rect.x + rect.w - 1, .y = rect.y, .w = 1, .h = rect.h }, 0xFFFFFF);
    }

    fn drawEntryTable(self: *App, canvas: r4os.gui.Canvas, scratch: []u8) void {
        const timestamp_view = self.timestampView();
        var title_name: [20]u8 = .{0} ** 20;
        var title_type: [20]u8 = .{0} ** 20;
        var title_size: [20]u8 = .{0} ** 20;
        var title_date: [20]u8 = .{0} ** 20;
        self.columnTitle(title_name[0..], "Name", .name);
        self.columnTitle(title_type[0..], "Type", .kind);
        self.columnTitle(title_size[0..], "Size", .size);
        self.columnTitle(title_date[0..], if (timestamp_view.local) "Modified" else "Modified UTC", .modified);

        var columns: [4]r4os.gui.TableColumn = undefined;
        self.fillEntryColumns(&columns, spanZ(title_name[0..]), spanZ(title_type[0..]), spanZ(title_size[0..]), spanZ(title_date[0..]));

        var cells: [max_entries * 4][]const u8 = undefined;
        var names: [max_entries][64]u8 = .{.{0} ** 64} ** max_entries;
        var types: [max_entries][16]u8 = .{.{0} ** 16} ** max_entries;
        var sizes: [max_entries][24]u8 = .{.{0} ** 24} ** max_entries;
        var dates: [max_entries][32]u8 = .{.{0} ** 32} ** max_entries;

        var index: usize = 0;
        while (index < self.entry_count) : (index += 1) {
            const entry = &self.entries[index];
            self.writeEntryName(names[index][0..], entry);
            copyZ(types[index][0..], self.entryTypeShort(entry));
            _ = sizeText(sizes[index][0..], entry);
            _ = modifiedText(dates[index][0..], entry, timestamp_view);
            const base = index * 4;
            cells[base] = spanZ(names[index][0..]);
            cells[base + 1] = spanZ(types[index][0..]);
            cells[base + 2] = spanZ(sizes[index][0..]);
            cells[base + 3] = spanZ(dates[index][0..]);
        }

        _ = canvas.tableView(.{
            .rect = self.listRect(),
            .columns = columns[0..],
            .cells = cells[0 .. self.entry_count * 4],
            .row_count = self.entry_count,
            .selected_index = self.selected_index,
            .first_index = self.scroll_offset,
            .row_h = row_h,
            .header_h = row_h,
        }, scratch);
    }

    fn columnTitle(self: *const App, out: []u8, title: []const u8, mode: SortMode) void {
        setZ(out, title);
        if (self.sort_mode == mode) appendZ(out, if (self.sort_ascending) " ^" else " v");
    }

    fn fillEntryColumns(self: *const App, columns: *[4]r4os.gui.TableColumn, name: []const u8, kind: []const u8, size: []const u8, modified: []const u8) void {
        const body_w = self.entryTableBodyWidth();
        const fixed_w = table_type_w + table_size_w + table_date_w;
        columns.* = .{
            .{ .title = name, .width = @max(64, body_w - fixed_w), .alignment = .left },
            .{ .title = kind, .width = table_type_w, .alignment = .left },
            .{ .title = size, .width = table_size_w, .alignment = .right },
            .{ .title = modified, .width = table_date_w, .alignment = .left },
        };
    }

    fn drawDetails(self: *App, canvas: r4os.gui.Canvas, scratch: []u8) void {
        const rect = self.detailsRect();
        _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = rect.w, .h = 18 }, title_bg);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 6, .y = rect.y + 4, .w = rect.w - 12, .h = 12 },
            .text = "Details",
            .fg = white,
            .bg = title_bg,
        }, scratch);
        if (self.selected_index >= self.entry_count) {
            self.drawDriveDetails(canvas, scratch, rect);
            return;
        }
        const entry = &self.entries[self.selected_index];
        self.drawEntryDetails(canvas, scratch, rect, entry);
    }

    fn writeEntryName(self: *const App, out: []u8, entry: *const Entry) void {
        copyZ(out, "");
        const prefix_text = self.entryPrefix(entry);
        if (prefix_text.len != 0) {
            appendZ(out, prefix_text);
            appendZ(out, " ");
        }
        appendZ(out, spanZ(entry.label[0..]));
    }

    fn drawDriveDetails(self: *App, canvas: r4os.gui.Canvas, scratch: []u8, rect: r4os.gui.Rect) void {
        var line: [96]u8 = .{0} ** 96;
        copyZ(line[0..], "Drive: ");
        if (self.current_drive.mounted != 0) {
            appendZ(line[0..], driveLetterText(self.current_drive.letter));
            appendZ(line[0..], " ");
            appendZ(line[0..], spanZ(self.current_drive.name[0..]));
        } else {
            appendZ(line[0..], driveLetterText(driveRootLetter(spanZ(self.current_path[0..]))));
            appendZ(line[0..], ": not mounted");
        }
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 30, .w = rect.w - 16, .h = 14 },
            .text = spanZ(line[0..]),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 50, .w = rect.w - 16, .h = 14 },
            .text = driveRoleLine(line[0..], self.current_drive),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 70, .w = rect.w - 16, .h = 14 },
            .text = driveSizeLine(line[0..], "Size: ", self.current_drive.bytes),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 90, .w = rect.w - 16, .h = 14 },
            .text = driveSizeLine(line[0..], "Free: ", self.current_drive.free_bytes),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 110, .w = rect.w - 16, .h = 14 },
            .text = driveClusterLine(line[0..], self.current_drive),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 134, .w = rect.w - 16, .h = 14 },
            .text = "Path:",
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 154, .w = rect.w - 16, .h = 48 },
            .text = spanZ(self.current_path[0..]),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
    }

    fn drawEntryDetails(self: *App, canvas: r4os.gui.Canvas, scratch: []u8, rect: r4os.gui.Rect, entry: *const Entry) void {
        const timestamp_view = self.timestampView();
        var line: [96]u8 = .{0} ** 96;
        copyZ(line[0..], "Type: ");
        appendZ(line[0..], self.entryTypeName(entry));
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 30, .w = rect.w - 16, .h = 14 },
            .text = spanZ(line[0..]),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        copyZ(line[0..], "Name: ");
        appendZ(line[0..], spanZ(entry.label[0..]));
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 50, .w = rect.w - 16, .h = 14 },
            .text = spanZ(line[0..]),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        if (entry.is_shortcut) {
            self.drawShortcutDetails(canvas, scratch, rect, entry, line[0..]);
            return;
        }
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 70, .w = rect.w - 16, .h = 14 },
            .text = sizeLine(line[0..], entry),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 90, .w = rect.w - 16, .h = 14 },
            .text = attrLine(line[0..], entry),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 110, .w = rect.w - 16, .h = 14 },
            .text = modifiedLine(line[0..], entry, timestamp_view),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 134, .w = rect.w - 16, .h = 14 },
            .text = "Path:",
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 154, .w = rect.w - 16, .h = 48 },
            .text = spanZ(entry.path[0..]),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
    }

    fn drawShortcutDetails(self: *App, canvas: r4os.gui.Canvas, scratch: []u8, rect: r4os.gui.Rect, entry: *const Entry, line: []u8) void {
        var target_line: [128]u8 = .{0} ** 128;
        var args_line: [128]u8 = .{0} ** 128;
        var policy_line: [40]u8 = .{0} ** 40;
        const link = self.readShortcutFile(spanZ(entry.path[0..])) catch |err| {
            copyZ(target_line[0..], "Target: ");
            appendZ(target_line[0..], shortcutErrorText(err));
            copyZ(args_line[0..], "Args: -");
            copyZ(policy_line[0..], "Policy: -");
            self.drawShortcutDetailLines(canvas, scratch, rect, spanZ(target_line[0..]), spanZ(args_line[0..]), spanZ(policy_line[0..]), entry, line);
            return;
        };
        const resolved = link.resolve() catch |err| {
            copyZ(target_line[0..], "Target: ");
            appendZ(target_line[0..], shortcutErrorText(err));
            copyZ(args_line[0..], "Args: -");
            copyZ(policy_line[0..], "Policy: -");
            self.drawShortcutDetailLines(canvas, scratch, rect, spanZ(target_line[0..]), spanZ(args_line[0..]), spanZ(policy_line[0..]), entry, line);
            return;
        };
        copyZ(target_line[0..], "Target: ");
        appendZ(target_line[0..], resolved.target);
        copyZ(args_line[0..], "Args: ");
        appendZ(args_line[0..], if (resolved.args.len == 0) "-" else resolved.args);
        copyZ(policy_line[0..], "Policy: ");
        appendZ(policy_line[0..], r4std.shortcut.policyText(resolved.policy));
        self.drawShortcutDetailLines(canvas, scratch, rect, spanZ(target_line[0..]), spanZ(args_line[0..]), spanZ(policy_line[0..]), entry, line);
    }

    fn drawShortcutDetailLines(self: *App, canvas: r4os.gui.Canvas, scratch: []u8, rect: r4os.gui.Rect, target: []const u8, args: []const u8, policy: []const u8, entry: *const Entry, line: []u8) void {
        _ = self;
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 70, .w = rect.w - 16, .h = 32 },
            .text = target,
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 106, .w = rect.w - 16, .h = 14 },
            .text = args,
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 126, .w = rect.w - 16, .h = 14 },
            .text = policy,
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 150, .w = rect.w - 16, .h = 14 },
            .text = "Path:",
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 8, .y = rect.y + 170, .w = rect.w - 16, .h = 32 },
            .text = spanZ(entry.path[0..]),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        _ = line;
    }

    fn loadDirectory(self: *App) void {
        if (self.view_mode == .computer) {
            self.loadComputerView();
            return;
        }
        self.entry_count = 0;
        self.selected_index = no_selection;
        self.select_all_active = false;
        self.scroll_offset = 0;
        self.clearPendingDelete();
        self.clearPendingPaste();
        self.has_prev_page = self.page_start_index > 2;
        self.has_more_entries = false;
        self.last_click_index = no_selection;
        self.last_click_tick = 0;
        self.current_drive = self.loadCurrentDriveInfo();
        var index: u32 = self.page_start_index;
        while (self.entry_count < self.entries.len) : (index += 1) {
            var path: [128]u8 = .{0} ** 128;
            const kind = self.ctx.sys.dirEntry(zptr(self.current_path[0..]), index, path[0 .. path.len - 1]);
            if (kind < 0) break;
            var entry = Entry{ .kind = kind };
            copyZ(entry.path[0..], spanZ(path[0..]));
            copyZ(entry.label[0..], tailName(spanZ(path[0..])));
            self.loadEntryInfo(&entry);
            self.loadShortcutEntryMetadata(&entry);
            self.entries[self.entry_count] = entry;
            self.entry_count += 1;
        }
        if (self.entry_count == self.entries.len) {
            var probe: [128]u8 = .{0} ** 128;
            self.has_more_entries = self.ctx.sys.dirEntry(zptr(self.current_path[0..]), index, probe[0 .. probe.len - 1]) >= 0;
        }
        self.sortEntries();
        if (self.entry_count > 0) self.selected_index = 0;
        self.updateDirectoryStatus();
    }

    fn loadComputerView(self: *App) void {
        self.entry_count = 0;
        self.selected_index = no_selection;
        self.select_all_active = false;
        self.scroll_offset = 0;
        self.clearPendingDelete();
        self.clearPendingPaste();
        self.has_prev_page = false;
        self.has_more_entries = false;
        self.last_click_index = no_selection;
        self.last_click_tick = 0;
        self.current_drive = .{};
        self.view_mode = .computer;
        setZ(self.current_path[0..], "Computer");

        var index: u8 = 0;
        while (index < 26 and self.entry_count < self.entries.len) : (index += 1) {
            const info = self.ctx.sys.driveInfo(index) orelse continue;
            if (info.mounted == 0) continue;
            var entry = Entry{ .kind = entry_kind_drive, .info_valid = true, .attr = 0, .size = info.bytes };
            entry.modified_time = 0;
            entry.modified_date = 0;
            setDriveRoot(entry.path[0..], info.letter);
            setDriveLabel(entry.label[0..], info.letter);
            self.entries[self.entry_count] = entry;
            self.entry_count += 1;
        }
        if (self.entry_count > 0) self.selected_index = 0;
        self.updateComputerStatus();
    }

    fn loadEntryInfo(self: *App, entry: *Entry) void {
        if (self.ctx.sys.fileInfo(zptr(entry.path[0..]))) |info| {
            entry.info_valid = true;
            entry.attr = info.attr;
            entry.size = info.size;
            entry.first_cluster = info.first_cluster;
            entry.modified_time = info.modified_time;
            entry.modified_date = info.modified_date;
            if (info.is_dir != 0) entry.kind = entry_kind_dir;
        }
    }

    fn loadShortcutEntryMetadata(self: *const App, entry: *Entry) void {
        if (entry.kind != entry_kind_file or !isShortcutPath(spanZ(entry.path[0..]))) return;
        entry.is_shortcut = true;
        shortcutLabelFromPath(entry.label[0..], spanZ(entry.path[0..]));
        const link = self.readShortcutFile(spanZ(entry.path[0..])) catch return;
        const resolved = link.resolve() catch return;
        entry.shortcut_valid = true;
        if (resolved.title.len != 0) copyZ(entry.label[0..], resolved.title);
        if (resolved.icon.len != 0) copyZ(entry.shortcut_icon[0..], resolved.icon);
    }

    fn timestampView(self: *const App) TimestampView {
        var status: r4os.abi.TimeServiceStatus = .{};
        if (self.ctx.sys.timeServiceStatus(&status) == r4os.abi.service_api_result_ok) {
            return .{
                .timezone_index = @intCast(status.timezone_index),
                .clock_format = status.clock_format,
                .local = true,
            };
        }
        return .{};
    }

    fn loadCurrentDriveInfo(self: *App) r4os.abi.DriveInfo {
        const letter = driveRootLetter(spanZ(self.current_path[0..]));
        if (letter < 'A' or letter > 'Z') return .{};
        return self.ctx.sys.driveInfo(letter - 'A') orelse .{ .letter = letter };
    }

    fn openSelected(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        if (self.select_all_active) {
            setZ(self.status[0..], "Open requires a single selection");
            self.render();
            return;
        }
        if (self.selected_index >= self.entry_count) return;
        const entry = &self.entries[self.selected_index];
        if (entry.kind == entry_kind_drive or entry.kind == entry_kind_dir) {
            self.navigateToPath(spanZ(entry.path[0..]), true);
            self.render();
            return;
        }
        if (entry.is_shortcut) {
            self.openShortcut(entry);
            return;
        }
        self.openFilePath(spanZ(entry.path[0..]), entry);
    }

    fn beginOpenWith(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        if (self.select_all_active) {
            setZ(self.status[0..], "Open With requires a single selection");
            self.render();
            return;
        }
        if (self.selected_index >= self.entry_count) {
            setZ(self.status[0..], "No selection to open with");
            self.render();
            return;
        }
        const entry = &self.entries[self.selected_index];
        if (entry.is_shortcut) {
            setZ(self.status[0..], "Open With opens files, not shortcuts");
            self.render();
            return;
        }
        if (entry.kind > 0) {
            setZ(self.status[0..], "Open With supports files only");
            self.render();
            return;
        }
        self.beginOpenWithFor(entry);
    }

    fn openShortcut(self: *App, entry: *const Entry) void {
        const link = self.readShortcutFile(spanZ(entry.path[0..])) catch |err| {
            self.shortcutOpenFailed(err);
            return;
        };
        const resolved = link.resolve() catch |err| {
            self.shortcutOpenFailed(err);
            return;
        };
        switch (resolved.kind) {
            .program => {
                var status_buf: [80]u8 = .{0} ** 80;
                const title = if (resolved.title.len == 0) "Shortcut" else resolved.title;
                self.launchPath(resolved.target, resolved.args, resolved.policy, openStatus(status_buf[0..], title));
                self.render();
            },
            .directory => {
                self.navigateToPath(resolved.target, true);
                self.render();
            },
            .file => {
                self.openFilePath(resolved.target, null);
            },
        }
    }

    fn openFilePath(self: *App, path: []const u8, entry: ?*const Entry) void {
        const input = self.handlerInput(path) catch |err| {
            setZ(self.status[0..], probeErrorStatus(err));
            self.render();
            return;
        };
        var args_buf: [r4os.subsystem_launch.max_args_bytes]u8 = undefined;
        var resolution: r4std.file_handler.Resolution = .{};
        r4std.file_handler.resolve(&self.assoc, r4std.subsystem_runtime.catalog(), input, args_buf[0..], &resolution) catch |err| {
            setZ(self.status[0..], handlerErrorStatus(err));
            self.render();
            return;
        };
        switch (resolution.state) {
            .selected => self.launchTarget(resolution.target.?),
            .ambiguous, .unknown => {
                if (entry) |selected_entry| {
                    self.beginOpenWithFor(selected_entry);
                } else {
                    self.beginOpenWithPath(path);
                }
            },
        }
    }

    fn handlerInput(self: *App, path: []const u8) r4std.subsystem_runtime.ProbeError!r4std.file_handler.Input {
        if (r4std.app_assoc.isR4XPath(path)) return .{
            .path = path,
            .probe_prefix = &.{},
            .file_size = 0,
            .probe_window_complete = true,
        };
        return r4std.subsystem_runtime.probe(&self.ctx.sys, path);
    }

    fn shortcutOpenFailed(self: *App, err: ShortcutOpenError) void {
        copyZ(self.status[0..], "Shortcut failed: ");
        appendZ(self.status[0..], shortcutErrorText(err));
        self.render();
    }

    fn beginOpenWithFor(self: *App, entry: *const Entry) void {
        self.beginOpenWithPath(spanZ(entry.path[0..]));
    }

    fn beginOpenWithPath(self: *App, path: []const u8) void {
        const input = self.handlerInput(path) catch |err| {
            setZ(self.status[0..], probeErrorStatus(err));
            self.render();
            return;
        };
        r4std.file_handler.collectChoices(&self.assoc, r4std.subsystem_runtime.catalog(), input, &self.open_with_choices) catch |err| {
            setZ(self.status[0..], handlerErrorStatus(err));
            self.render();
            return;
        };
        if (self.open_with_choices.count == 0) {
            setZ(self.status[0..], "No Open With handlers");
            self.render();
            return;
        }
        if (path.len + 1 > self.open_with_path.len) {
            setZ(self.status[0..], "Open failed: path too long");
            self.render();
            return;
        }
        copyZ(self.open_with_path[0..], path);
        self.open_with_index = self.defaultOpenWithIndex(path);
        self.open_with_active = true;
        setZ(self.status[0..], "Choose Open With target");
        self.render();
    }

    fn handleOpenWithKey(self: *App, key: u8) void {
        if (key == 0x1B) {
            self.closeOpenWith("Open With cancelled");
            return;
        }
        if (key == r4os.gui.Key.up) {
            if (self.open_with_index > 0) self.open_with_index -= 1;
            self.render();
            return;
        }
        if (key == r4os.gui.Key.down) {
            if (self.open_with_index + 1 < self.openWithCount()) self.open_with_index += 1;
            self.render();
            return;
        }
        if (key >= '1' and key <= '9') {
            const index: usize = @intCast(key - '1');
            if (index < self.openWithCount()) {
                self.open_with_index = index;
                self.commitOpenWith();
                return;
            }
        }
        if (key == '\r' or key == '\n') {
            self.commitOpenWith();
            return;
        }
    }

    fn handleOpenWithMouse(self: *App, x: i32, y: i32) void {
        if (self.openWithIndexAt(x, y)) |index| {
            self.open_with_index = index;
            self.commitOpenWith();
            return;
        }
        if (self.openWithOkButtonRect().contains(x, y)) {
            self.commitOpenWith();
            return;
        }
        if (self.openWithCancelButtonRect().contains(x, y)) {
            self.closeOpenWith("Open With cancelled");
            return;
        }
    }

    fn commitOpenWith(self: *App) void {
        const choice = self.openWithChoice(self.open_with_index) orelse {
            self.closeOpenWith("Open With selection invalid");
            return;
        };
        var path: [128]u8 = .{0} ** 128;
        copyZ(path[0..], spanZ(self.open_with_path[0..]));
        self.open_with_active = false;
        @memset(self.open_with_path[0..], 0);
        var args_buf: [r4os.subsystem_launch.max_args_bytes]u8 = undefined;
        const target = r4std.file_handler.targetForChoice(choice, spanZ(path[0..]), args_buf[0..]) catch |err| {
            setZ(self.status[0..], handlerErrorStatus(err));
            self.render();
            return;
        };
        self.launchTarget(target);
    }

    fn closeOpenWith(self: *App, message: []const u8) void {
        self.open_with_active = false;
        @memset(self.open_with_path[0..], 0);
        self.open_with_choices = .{};
        setZ(self.status[0..], message);
        self.render();
    }

    fn launchTarget(self: *App, target: r4std.file_handler.Target) void {
        if (target.kind == .subsystem and !r4std.subsystem_runtime.hostPresent(&self.ctx.sys, target.app_path)) {
            setZ(self.status[0..], "Open failed: subsystem host missing");
            self.render();
            return;
        }
        var status_buf: [80]u8 = .{0} ** 80;
        const ok_status = if (target.kind == .direct_program)
            "Program launch requested"
        else
            openStatus(status_buf[0..], target.title);
        self.launchPath(target.app_path, target.args, target.policy, ok_status);
        self.render();
    }

    fn launchPath(self: *App, app_path: []const u8, args: []const u8, policy: r4os.abi.LaunchPolicy, ok_status: []const u8) void {
        var app_buf: [128]u8 = .{0} ** 128;
        if (app_path.len + 1 > app_buf.len) {
            setZ(self.status[0..], "Open failed: app path too long");
            return;
        }
        copyZ(app_buf[0..], app_path);
        var arg_buf: [128]u8 = .{0} ** 128;
        if (args.len + 1 > arg_buf.len) {
            setZ(self.status[0..], "Open failed: path too long");
            return;
        }
        copyZ(arg_buf[0..], args);
        const hosted = self.ctx.desk.programWindowId() >= 0;
        const result = if (hosted)
            self.ctx.desk.programRequestHostLaunch(zptr(app_buf[0..]), zptr(arg_buf[0..]), policy)
        else
            self.ctx.sys.programLaunch(zptr(app_buf[0..]), zptr(arg_buf[0..]), policy);
        if (result < 0) {
            setZ(self.status[0..], launchErrorStatus(result, hosted));
        } else {
            setZ(self.status[0..], ok_status);
        }
    }

    fn readShortcutFile(self: *const App, path: []const u8) ShortcutOpenError!r4std.shortcut.Shortcut {
        var path_buf: [128]u8 = .{0} ** 128;
        if (path.len == 0 or path.len + 1 > path_buf.len) return error.ShortcutPathTooLong;
        copyZ(path_buf[0..], path);
        var bytes: [shortcut_file_max_bytes]u8 = undefined;
        const read = self.ctx.sys.fileRead(zptr(path_buf[0..]), bytes[0..]);
        if (read <= 0) return error.ShortcutNotFound;
        return r4std.shortcut.parse(bytes[0..@intCast(read)]);
    }

    fn goUp(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        if (self.view_mode == .computer) {
            setZ(self.status[0..], "Already at Computer");
            self.render();
            return;
        }
        if (isRoot(spanZ(self.current_path[0..]))) {
            self.navigateToComputer(true);
            self.render();
            return;
        }
        const old = self.currentLocation();
        parentPath(self.current_path[0..]);
        self.pushBackHistory(old);
        self.clearForwardHistory();
        self.loadFirstDirectoryPage();
        self.render();
    }

    fn refreshDirectory(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        if (self.view_mode == .computer) {
            self.loadComputerView();
        } else {
            self.loadDirectory();
        }
        self.render();
    }

    fn executeCommand(self: *App, command_id: u32) void {
        self.menubar_state.close();
        switch (command_id) {
            @intFromEnum(Command.file_new_menu) => self.new_menu_open = true,
            @intFromEnum(Command.file_delete) => self.deleteSelected(),
            @intFromEnum(Command.file_rename) => self.beginRename(),
            @intFromEnum(Command.file_close) => self.quit_requested = true,
            @intFromEnum(Command.new_folder) => self.beginNewFolder(),
            @intFromEnum(Command.new_text_document) => self.beginNewFile(),
            @intFromEnum(Command.edit_cut) => self.cutSelected(),
            @intFromEnum(Command.edit_copy) => self.copySelected(),
            @intFromEnum(Command.edit_paste) => self.pasteCopied(),
            @intFromEnum(Command.edit_select_all) => self.selectAll(),
            @intFromEnum(Command.view_refresh) => self.refreshDirectory(),
            @intFromEnum(Command.view_toggle_address) => self.toggleAddressBar(),
            else => {},
        }
    }

    fn toggleAddressBar(self: *App) void {
        self.address_visible = !self.address_visible;
        setZ(self.status[0..], if (self.address_visible) "Address bar shown" else "Address bar hidden");
        self.render();
    }

    fn loadFirstDirectoryPage(self: *App) void {
        self.page_start_index = 2;
        self.loadDirectory();
    }

    fn nextPage(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        if (!self.has_more_entries) {
            setZ(self.status[0..], "Already at last page");
            self.render();
            return;
        }
        self.page_start_index += page_stride;
        self.loadDirectory();
        self.render();
    }

    fn prevPage(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        if (self.page_start_index <= 2) {
            setZ(self.status[0..], "Already at first page");
            self.render();
            return;
        }
        if (self.page_start_index > 2 + page_stride) {
            self.page_start_index -= page_stride;
        } else {
            self.page_start_index = 2;
        }
        self.loadDirectory();
        self.render();
    }

    fn sortBy(self: *App, mode: SortMode) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        var selected_path: [128]u8 = .{0} ** 128;
        if (self.selected_index < self.entry_count) copyZ(selected_path[0..], spanZ(self.entries[self.selected_index].path[0..]));
        if (self.sort_mode == mode) {
            self.sort_ascending = !self.sort_ascending;
        } else {
            self.sort_mode = mode;
            self.sort_ascending = true;
        }
        self.sortEntries();
        self.restoreSelection(spanZ(selected_path[0..]));
        self.ensureSelectionVisible();
        self.updateDirectoryStatus();
        self.render();
    }

    fn sortEntries(self: *App) void {
        var i: usize = 0;
        while (i < self.entry_count) : (i += 1) {
            var best = i;
            var j = i + 1;
            while (j < self.entry_count) : (j += 1) {
                if (self.compareEntries(self.entries[j], self.entries[best]) < 0) best = j;
            }
            if (best != i) {
                const tmp = self.entries[i];
                self.entries[i] = self.entries[best];
                self.entries[best] = tmp;
            }
        }
    }

    fn compareEntries(self: *const App, a: Entry, b: Entry) i8 {
        const dir_cmp = compareBoolDesc(a.kind > 0, b.kind > 0);
        if (dir_cmp != 0) return dir_cmp;
        var cmp = self.compareByMode(self.sort_mode, a, b);
        if (cmp == 0) cmp = compareNames(a, b);
        if (!self.sort_ascending) cmp = -cmp;
        return cmp;
    }

    fn compareByMode(self: *const App, mode: SortMode, a: Entry, b: Entry) i8 {
        return switch (mode) {
            .name => compareNames(a, b),
            .kind => compareU8(self.entryTypeRank(a), self.entryTypeRank(b)),
            .size => compareU64(if (a.kind > 0) 0 else a.size, if (b.kind > 0) 0 else b.size),
            .modified => compareU32(dateSortValue(a), dateSortValue(b)),
        };
    }

    fn restoreSelection(self: *App, selected_path: []const u8) void {
        self.select_all_active = false;
        if (selected_path.len == 0) {
            self.selected_index = if (self.entry_count > 0) 0 else no_selection;
            return;
        }
        var i: usize = 0;
        while (i < self.entry_count) : (i += 1) {
            if (equalsIgnoreCase(spanZ(self.entries[i].path[0..]), selected_path)) {
                self.selected_index = i;
                return;
            }
        }
        self.selected_index = if (self.entry_count > 0) 0 else no_selection;
    }

    fn currentLocation(self: *const App) HistoryEntry {
        var entry = HistoryEntry{ .mode = self.view_mode };
        copyZ(entry.path[0..], spanZ(self.current_path[0..]));
        return entry;
    }

    fn pushBackHistory(self: *App, entry: HistoryEntry) void {
        pushHistory(&self.back_history, &self.back_count, entry);
    }

    fn pushForwardHistory(self: *App, entry: HistoryEntry) void {
        pushHistory(&self.forward_history, &self.forward_count, entry);
    }

    fn clearForwardHistory(self: *App) void {
        self.forward_count = 0;
    }

    fn navigateToComputer(self: *App, record_history: bool) void {
        const old = self.currentLocation();
        if (record_history) {
            self.pushBackHistory(old);
            self.clearForwardHistory();
        }
        self.view_mode = .computer;
        self.loadComputerView();
    }

    fn navigateToPath(self: *App, path: []const u8, record_history: bool) void {
        if (path.len == 0) return;
        var target: [128]u8 = .{0} ** 128;
        copyZ(target[0..], path);
        const letter = driveRootLetter(spanZ(target[0..]));
        if (letter < 'A' or letter > 'Z') {
            setZ(self.status[0..], "Path is not a drive path");
            return;
        }
        const info = self.ctx.sys.driveInfo(letter - 'A') orelse {
            setZ(self.status[0..], "Drive not mounted");
            return;
        };
        if (!driveBrowsable(info.kind)) {
            setZ(self.status[0..], "Drive is not a browsable volume");
            return;
        }
        const old = self.currentLocation();
        if (record_history) {
            self.pushBackHistory(old);
            self.clearForwardHistory();
        }
        self.view_mode = .directory;
        copyZ(self.current_path[0..], spanZ(target[0..]));
        self.loadFirstDirectoryPage();
    }

    fn restoreLocation(self: *App, entry: HistoryEntry) void {
        self.view_mode = entry.mode;
        copyZ(self.current_path[0..], spanZ(entry.path[0..]));
        if (entry.mode == .computer) {
            self.loadComputerView();
        } else {
            self.loadFirstDirectoryPage();
        }
    }

    fn goBack(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        if (self.back_count == 0) {
            setZ(self.status[0..], "No previous location");
            self.render();
            return;
        }
        const current = self.currentLocation();
        self.pushForwardHistory(current);
        self.back_count -= 1;
        const previous = self.back_history[self.back_count];
        self.restoreLocation(previous);
        self.render();
    }

    fn goForward(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        if (self.forward_count == 0) {
            setZ(self.status[0..], "No next location");
            self.render();
            return;
        }
        const current = self.currentLocation();
        self.pushBackHistory(current);
        self.forward_count -= 1;
        const next = self.forward_history[self.forward_count];
        self.restoreLocation(next);
        self.render();
    }

    fn switchToDrive(self: *App, letter: u8) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        const upper = asciiUpper(letter);
        const index: u32 = if (upper >= 'A' and upper <= 'Z') upper - 'A' else 0;
        const info = self.ctx.sys.driveInfo(index) orelse {
            setZ(self.status[0..], "Drive not mounted");
            self.render();
            return;
        };
        if (!driveBrowsable(info.kind)) {
            setZ(self.status[0..], "Drive is not a browsable volume");
            self.render();
            return;
        }
        var path: [4]u8 = .{0} ** 4;
        setDriveRoot(path[0..], upper);
        self.navigateToPath(spanZ(path[0..]), true);
        self.render();
    }

    fn switchToNextBrowseDrive(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        const current = driveRootLetter(spanZ(self.current_path[0..]));
        const current_index: u8 = if (current >= 'A' and current <= 'Z') current - 'A' else 0;
        var step: u8 = 1;
        while (step < 26) : (step += 1) {
            const index: u8 = @intCast((@as(u16, current_index) + step) % 26);
            if (self.ctx.sys.driveInfo(index)) |info| {
                if (driveBrowsable(info.kind)) {
                    var path: [4]u8 = .{0} ** 4;
                    setDriveRoot(path[0..], info.letter);
                    self.navigateToPath(spanZ(path[0..]), true);
                    self.render();
                    return;
                }
            }
        }
        setZ(self.status[0..], "No FAT32 drive available");
        self.render();
    }

    fn moveSelectionByKey(self: *App, key: u8) void {
        if (self.entry_count == 0) return;
        self.clearPendingDelete();
        self.clearPendingPaste();
        self.select_all_active = false;
        if (self.selected_index >= self.entry_count) self.selected_index = 0;
        const old = self.selected_index;
        const columns = self.iconColumns();
        const visible = self.visibleIconCount();
        switch (key) {
            r4os.gui.Key.left => {
                if (self.selected_index > 0) self.selected_index -= 1;
            },
            r4os.gui.Key.right => {
                if (self.selected_index + 1 < self.entry_count) self.selected_index += 1;
            },
            r4os.gui.Key.up => {
                if (self.selected_index >= columns) self.selected_index -= columns;
            },
            r4os.gui.Key.down => {
                if (self.selected_index + columns < self.entry_count) self.selected_index += columns;
            },
            r4os.gui.Key.page_up => {
                if (self.selected_index > visible) {
                    self.selected_index -= visible;
                } else {
                    self.selected_index = 0;
                }
            },
            r4os.gui.Key.page_down => self.selected_index = @min(self.entry_count - 1, self.selected_index + visible),
            r4os.gui.Key.home => self.selected_index = 0,
            r4os.gui.Key.end => self.selected_index = self.entry_count - 1,
            else => {},
        }
        self.ensureSelectionVisible();
        self.updateSelectedStatus();
        if (old != self.selected_index or key == r4os.gui.Key.home or key == r4os.gui.Key.end) self.render();
    }

    fn updateDirectoryStatus(self: *App) void {
        var buf: [16]u8 = .{0} ** 16;
        const page = ((self.page_start_index - 2) / page_stride) + 1;
        setZ(self.status[0..], "Entries: ");
        appendZ(self.status[0..], u32Text(buf[0..], @intCast(self.entry_count)));
        if (self.has_more_entries) appendZ(self.status[0..], "+");
        appendZ(self.status[0..], " page ");
        appendZ(self.status[0..], u32Text(buf[0..], page));
        if (self.has_prev_page or self.has_more_entries) appendZ(self.status[0..], " of many");
        appendZ(self.status[0..], " sorted ");
        appendZ(self.status[0..], sortModeName(self.sort_mode));
        appendZ(self.status[0..], if (self.sort_ascending) " asc" else " desc");
        if (self.current_drive.free_bytes > 0) {
            var size_buf: [24]u8 = .{0} ** 24;
            appendZ(self.status[0..], " free ");
            appendByteSize(self.status[0..], size_buf[0..], self.current_drive.free_bytes);
        }
    }

    fn updateComputerStatus(self: *App) void {
        var buf: [16]u8 = .{0} ** 16;
        setZ(self.status[0..], "Computer: ");
        appendZ(self.status[0..], u32Text(buf[0..], @intCast(self.entry_count)));
        appendZ(self.status[0..], if (self.entry_count == 1) " drive" else " drives");
    }

    fn updateSelectedStatus(self: *App) void {
        if (self.select_all_active) {
            var buf: [16]u8 = .{0} ** 16;
            setZ(self.status[0..], "Selected: ");
            appendZ(self.status[0..], u32Text(buf[0..], @intCast(self.entry_count)));
            appendZ(self.status[0..], " entries");
            return;
        }
        if (self.selected_index >= self.entry_count) return;
        setZ(self.status[0..], "Selected: ");
        appendZ(self.status[0..], spanZ(self.entries[self.selected_index].label[0..]));
    }

    fn selectAll(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        if (self.entry_count == 0) {
            setZ(self.status[0..], "No entries to select");
            self.render();
            return;
        }
        self.selected_index = 0;
        self.scroll_offset = 0;
        self.select_all_active = true;
        self.updateSelectedStatus();
        self.render();
    }

    fn deleteSelected(self: *App) void {
        if (self.view_mode == .computer) {
            setZ(self.status[0..], "Drives cannot be deleted here");
            self.render();
            return;
        }
        if (self.select_all_active) {
            self.deleteAllSelected();
            return;
        }
        if (self.selected_index >= self.entry_count) {
            setZ(self.status[0..], "No selection to delete");
            self.render();
            return;
        }
        const entry = &self.entries[self.selected_index];
        const path = spanZ(entry.path[0..]);
        if (!self.pending_delete or !equalsIgnoreCase(spanZ(self.pending_delete_path[0..]), path)) {
            self.pending_delete = true;
            copyZ(self.pending_delete_path[0..], path);
            setZ(self.status[0..], "Confirm delete: click Delete again");
            self.render();
            return;
        }

        const result = deleteEntry(&self.ctx.sys, entry);
        self.clearPendingDelete();
        if (result > 0) {
            self.loadDirectory();
            setZ(self.status[0..], "Deleted");
        } else {
            self.setFsErrorStatus(if (entry.kind > 0) .delete_dir else .delete_file, result);
        }
        self.render();
    }

    fn deleteAllSelected(self: *App) void {
        if (!self.pending_delete or !self.pending_delete_all) {
            self.clearPendingDelete();
            self.pending_delete = true;
            self.pending_delete_all = true;
            var count_buf: [16]u8 = .{0} ** 16;
            setZ(self.status[0..], "Confirm delete ");
            appendZ(self.status[0..], u32Text(count_buf[0..], @intCast(self.entry_count)));
            appendZ(self.status[0..], " entries: click Delete again");
            self.render();
            return;
        }

        const summary = deleteEntries(&self.ctx.sys, self.entries[0..self.entry_count]);
        self.clearPendingDelete();
        self.loadDirectory();
        self.setDeleteSummaryStatus(summary);
        self.render();
    }

    fn setDeleteSummaryStatus(self: *App, summary: DeleteSummary) void {
        var count_buf: [16]u8 = .{0} ** 16;
        setZ(self.status[0..], "Deleted ");
        appendZ(self.status[0..], u32Text(count_buf[0..], summary.deleted));
        appendZ(self.status[0..], " entries");
        if (summary.failed > 0) {
            appendZ(self.status[0..], ", ");
            appendZ(self.status[0..], u32Text(count_buf[0..], summary.failed));
            appendZ(self.status[0..], " failed");
        }
    }

    fn beginNewFolder(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        if (self.view_mode == .computer) {
            setZ(self.status[0..], "Open a drive before creating folders");
            self.render();
            return;
        }
        self.name_mode = .new_folder;
        self.name_input.clear();
        self.name_input.set("NEWFOLDER");
        self.name_input.focused = true;
        setZ(self.status[0..], "New folder name");
        self.render();
    }

    fn beginNewFile(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        if (self.view_mode == .computer) {
            setZ(self.status[0..], "Open a drive before creating files");
            self.render();
            return;
        }
        self.name_mode = .new_file;
        self.name_input.clear();
        self.name_input.set("NEWFILE.TXT");
        self.name_input.focused = true;
        setZ(self.status[0..], "New file name");
        self.render();
    }

    fn beginRename(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        if (self.select_all_active) {
            setZ(self.status[0..], "Rename requires a single selection");
            self.render();
            return;
        }
        if (self.view_mode == .computer) {
            setZ(self.status[0..], "Drives cannot be renamed here");
            self.render();
            return;
        }
        if (self.selected_index >= self.entry_count) {
            setZ(self.status[0..], "No selection to rename");
            self.render();
            return;
        }
        self.name_mode = .rename;
        self.name_input.clear();
        self.name_input.set(spanZ(self.entries[self.selected_index].label[0..]));
        self.name_input.focused = true;
        copyZ(self.rename_source_path[0..], spanZ(self.entries[self.selected_index].path[0..]));
        setZ(self.status[0..], "Rename entry");
        self.render();
    }

    fn handleNameDialogKey(self: *App, key: u8) void {
        const dialog = self.nameDialog();
        const action = dialog.keyAction(key);
        if (action == .cancel) {
            self.closeNameDialog("Cancelled");
            return;
        }
        if (action == .ok) {
            self.commitNameDialog();
            return;
        }
        if (self.name_input.handleClipboardKey(&self.ctx.desk, key)) self.render();
    }

    fn handleNameDialogMouse(self: *App, x: i32, y: i32) void {
        switch (self.nameDialog().actionAt(x, y)) {
            .ok => {
                self.commitNameDialog();
                return;
            },
            .cancel => {
                self.closeNameDialog("Cancelled");
                return;
            },
            .select => {
                self.name_input.focused = true;
                self.render();
                return;
            },
            else => {},
        }
    }

    fn commitNameDialog(self: *App) void {
        const name = self.name_input.value();
        if (!validFileName(name)) {
            setZ(self.status[0..], "Invalid name");
            self.render();
            return;
        }
        var target_path: [128]u8 = .{0} ** 128;
        if (!childPath(spanZ(self.current_path[0..]), name, target_path[0..])) {
            setZ(self.status[0..], "Path too long");
            self.render();
            return;
        }

        const mode = self.name_mode;
        const result = switch (mode) {
            .new_folder => self.ctx.sys.dirCreate(zptr(target_path[0..])),
            .new_file => self.ctx.sys.fileWrite(zptr(target_path[0..]), ""),
            .rename => self.ctx.sys.fileRename(zptr(self.rename_source_path[0..]), zptr(target_path[0..])),
            .none => return,
        };
        const ok = if (mode == .new_file) result >= 0 else result > 0;
        if (!ok) {
            self.setFsErrorStatus(fsActionForNameMode(mode), result);
            self.render();
            return;
        }

        self.name_mode = .none;
        self.name_input.focused = false;
        self.loadDirectory();
        self.restoreSelection(spanZ(target_path[0..]));
        self.ensureSelectionVisible();
        setZ(self.status[0..], switch (mode) {
            .new_folder => "Folder created",
            .new_file => "File created",
            .rename => "Renamed",
            .none => "Ready",
        });
        self.render();
    }

    fn closeNameDialog(self: *App, message: []const u8) void {
        self.name_mode = .none;
        self.name_input.focused = false;
        @memset(self.rename_source_path[0..], 0);
        setZ(self.status[0..], message);
        self.render();
    }

    fn clearPendingDelete(self: *App) void {
        self.pending_delete = false;
        self.pending_delete_all = false;
        @memset(self.pending_delete_path[0..], 0);
    }

    fn copySelected(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        self.selectTransferSource(false);
    }

    fn cutSelected(self: *App) void {
        self.clearPendingDelete();
        self.clearPendingPaste();
        self.selectTransferSource(true);
    }

    fn selectTransferSource(self: *App, move_source: bool) void {
        if (self.select_all_active) {
            setZ(self.status[0..], if (move_source) "Cut requires a single selection" else "Copy requires a single selection");
            self.render();
            return;
        }
        if (self.selected_index >= self.entry_count) {
            setZ(self.status[0..], if (move_source) "No selection to cut" else "No selection to copy");
            self.render();
            return;
        }
        const entry = &self.entries[self.selected_index];
        if (entry.kind > 0) {
            setZ(self.status[0..], if (move_source) "Cut supports files only" else "Copy supports files only");
            self.render();
            return;
        }
        copyZ(self.copy_source_path[0..], spanZ(entry.path[0..]));
        self.copy_is_move = move_source;
        setZ(self.status[0..], if (move_source) "Move source: " else "Copy source: ");
        appendZ(self.status[0..], spanZ(entry.label[0..]));
        self.render();
    }

    fn pasteCopied(self: *App) void {
        self.clearPendingDelete();
        if (self.view_mode == .computer) {
            setZ(self.status[0..], "Open a drive before pasting");
            self.render();
            return;
        }
        const source = spanZ(self.copy_source_path[0..]);
        if (source.len == 0) {
            setZ(self.status[0..], "No copy source");
            self.render();
            return;
        }
        var target_path: [128]u8 = .{0} ** 128;
        if (!childPath(spanZ(self.current_path[0..]), tailName(source), target_path[0..])) {
            setZ(self.status[0..], "Target path too long");
            self.render();
            return;
        }
        const target = spanZ(target_path[0..]);
        if (equalsIgnoreCase(source, target)) {
            setZ(self.status[0..], "Cannot paste onto itself");
            self.render();
            return;
        }
        if (self.ctx.sys.fileInfo(zptr(target_path[0..])) != null and (!self.pending_paste or !equalsIgnoreCase(spanZ(self.pending_paste_target[0..]), target))) {
            self.pending_paste = true;
            copyZ(self.pending_paste_target[0..], target);
            setZ(self.status[0..], "Confirm overwrite: click Paste again");
            self.render();
            return;
        }
        const move_source = self.copy_is_move;
        const result = if (move_source)
            self.ctx.sys.fileMove(zptr(self.copy_source_path[0..]), zptr(target_path[0..]))
        else
            self.ctx.sys.fileCopy(zptr(self.copy_source_path[0..]), zptr(target_path[0..]));
        self.clearPendingPaste();
        if (result > 0) {
            if (move_source) self.clearTransferSource();
            self.loadDirectory();
            self.restoreSelection(target);
            self.ensureSelectionVisible();
            setZ(self.status[0..], if (move_source) "Moved" else "Copied");
        } else {
            self.setFsErrorStatus(if (move_source) .move else .copy, result);
        }
        self.render();
    }

    fn setFsErrorStatus(self: *App, action: FsAction, code: i32) void {
        setZ(self.status[0..], fsActionLabel(action));
        appendZ(self.status[0..], " failed");
        const detail = fsErrorDetail(action, code);
        if (detail.len > 0) {
            appendZ(self.status[0..], ": ");
            appendZ(self.status[0..], detail);
        }
    }

    fn clearPendingPaste(self: *App) void {
        self.pending_paste = false;
        @memset(self.pending_paste_target[0..], 0);
    }

    fn clearTransferSource(self: *App) void {
        self.copy_is_move = false;
        @memset(self.copy_source_path[0..], 0);
    }

    fn drawNameDialog(self: *App, canvas: r4os.gui.Canvas, scratch: []u8) void {
        const dialog = self.nameDialog();
        _ = canvas.inputDialog(dialog, scratch);
        _ = self.name_input.draw(canvas, dialog.valueRect(), scratch);
    }

    fn drawOpenWithDialog(self: *App, canvas: r4os.gui.Canvas, scratch: []u8) void {
        const rect = self.openWithDialogRect();
        _ = canvas.rect(rect, panel_bg);
        _ = canvas.rect(.{ .x = rect.x, .y = rect.y, .w = rect.w, .h = 18 }, title_bg);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 6, .y = rect.y + 4, .w = rect.w - 12, .h = 12 },
            .text = "Open With",
            .fg = white,
            .bg = title_bg,
        }, scratch);
        _ = canvas.label(.{
            .rect = .{ .x = rect.x + 12, .y = rect.y + 30, .w = rect.w - 24, .h = 14 },
            .text = tailName(spanZ(self.open_with_path[0..])),
            .fg = black,
            .bg = panel_bg,
        }, scratch);
        self.drawOpenWithRows(canvas, scratch);
        _ = canvas.button(.{ .rect = self.openWithOkButtonRect(), .text = "Open" }, scratch);
        _ = canvas.button(.{ .rect = self.openWithCancelButtonRect(), .text = "Cancel" }, scratch);
    }

    fn drawOpenWithRows(self: *App, canvas: r4os.gui.Canvas, scratch: []u8) void {
        var items: [association_count_max]r4os.gui.MenuItem = undefined;
        const count = self.fillOpenWithMenuItems(&items);
        _ = canvas.menu(.{
            .rect = self.openWithMenuRect(),
            .items = items[0..count],
            .selected_index = self.open_with_index,
            .row_h = open_with_row_h,
        }, scratch);
    }

    fn fillOpenWithMenuItems(self: *const App, items: *[association_count_max]r4os.gui.MenuItem) usize {
        const count = self.openWithCount();
        var index: usize = 0;
        while (index < count) : (index += 1) {
            const choice = self.openWithChoice(index).?;
            items[index] = .{ .text = choice.title };
        }
        return count;
    }

    fn openWithCount(self: *const App) usize {
        return self.open_with_choices.count;
    }

    fn openWithChoice(self: *const App, index: usize) ?r4std.file_handler.Choice {
        if (index >= self.open_with_choices.count) return null;
        return self.open_with_choices.items[index];
    }

    fn defaultOpenWithIndex(self: *const App, path: []const u8) usize {
        return file_assoc.defaultChoiceIndex(&self.assoc, &self.open_with_choices, path);
    }

    fn menuBarRect(self: *const App) r4os.gui.Rect {
        return .{ .x = 0, .y = explorer_menu_y, .w = self.hosted_w, .h = explorer_menu_h };
    }

    fn menubar(self: *App) r4os.gui.Menubar {
        const menus = buildExplorerMenus(&self.menu_storage, self.address_visible);
        return .{
            .rect = self.menuBarRect(),
            .menus = menus,
            .state = self.menubar_state,
        };
    }

    fn newMenuRect(self: *const App) r4os.gui.Rect {
        var menu_storage: ExplorerMenus = undefined;
        const menus = buildExplorerMenus(&menu_storage, self.address_visible);
        const parent = r4os.gui.menubarPopupRect(self.menuBarRect(), menus, 0);
        return .{
            .x = parent.right() - r4os.gui.default_metrics.frame_inset,
            .y = parent.y,
            .w = r4os.gui.menuPopupWidth(new_menu_items[0..]),
            .h = r4os.gui.menuPopupHeight(new_menu_items[0..], r4os.gui.default_metrics.menu_row_h),
        };
    }

    fn drawNewMenu(self: *const App, canvas: r4os.gui.Canvas, scratch: []u8) void {
        _ = canvas.menu(.{ .rect = self.newMenuRect(), .items = new_menu_items[0..] }, scratch);
    }

    fn newMenuIndexAt(self: *const App, x: i32, y: i32) ?usize {
        return r4os.gui.menuIndexAt(self.newMenuRect(), new_menu_items[0..], r4os.gui.default_metrics.menu_row_h, x, y);
    }

    fn toolbarRect(self: *const App) r4os.gui.Rect {
        return .{ .x = 0, .y = explorer_toolbar_y, .w = self.hosted_w, .h = explorer_toolbar_h };
    }

    fn addressRect(self: *const App) r4os.gui.Rect {
        return .{ .x = 0, .y = explorer_address_y, .w = self.hosted_w, .h = explorer_address_h };
    }

    fn iconViewY(self: *const App) i32 {
        return explorer_address_y + if (self.address_visible) explorer_address_h else chrome_separator_h;
    }

    fn iconViewRect(self: *const App) r4os.gui.Rect {
        const y = self.iconViewY();
        return .{ .x = 0, .y = y, .w = self.hosted_w, .h = @max(50, self.hosted_h - y - explorer_icon_view_bottom_pad) };
    }

    fn backButtonRect(self: *const App) r4os.gui.Rect {
        _ = self;
        return .{ .x = toolbar_back_x, .y = toolbar_icon_button_y, .w = toolbar_icon_button_w, .h = toolbar_icon_button_h };
    }

    fn forwardButtonRect(self: *const App) r4os.gui.Rect {
        _ = self;
        return .{ .x = toolbar_forward_x, .y = toolbar_icon_button_y, .w = toolbar_icon_button_w, .h = toolbar_icon_button_h };
    }

    fn upButtonRect(self: *const App) r4os.gui.Rect {
        _ = self;
        return .{ .x = toolbar_up_x, .y = toolbar_icon_button_y, .w = toolbar_icon_button_w, .h = toolbar_icon_button_h };
    }

    fn cutButtonRect(self: *const App) r4os.gui.Rect {
        _ = self;
        return .{ .x = toolbar_cut_x, .y = toolbar_icon_button_y, .w = toolbar_cut_w, .h = toolbar_icon_button_h };
    }

    fn copyButtonRect(self: *const App) r4os.gui.Rect {
        _ = self;
        return .{ .x = toolbar_copy_x, .y = toolbar_icon_button_y, .w = toolbar_copy_w, .h = toolbar_icon_button_h };
    }

    fn pasteButtonRect(self: *const App) r4os.gui.Rect {
        _ = self;
        return .{ .x = toolbar_paste_x, .y = toolbar_icon_button_y, .w = toolbar_paste_w, .h = toolbar_icon_button_h };
    }

    fn deleteButtonRect(self: *const App) r4os.gui.Rect {
        _ = self;
        return .{ .x = toolbar_delete_x, .y = toolbar_icon_button_y, .w = toolbar_delete_w, .h = toolbar_icon_button_h };
    }

    fn drawToolbarSeparator(self: *const App, canvas: r4os.gui.Canvas, x: i32) void {
        _ = self;
        _ = canvas.rect(.{ .x = x, .y = 24, .w = 1, .h = 40 }, 0xFFFFFF);
        _ = canvas.rect(.{ .x = x + 1, .y = 24, .w = 1, .h = 40 }, 0x808080);
    }

    fn nameDialogRect(self: *const App) r4os.gui.Rect {
        const w: i32 = 260;
        const h: i32 = 116;
        return r4os.gui.centeredRect(r4os.gui.screenRect(self.hosted_w, self.hosted_h), w, h);
    }

    fn nameDialog(self: *const App) r4os.gui.InputDialog {
        return .{
            .rect = self.nameDialogRect(),
            .title = switch (self.name_mode) {
                .new_folder => "New Folder",
                .new_file => "New File",
                .rename => "Rename",
                .none => "",
            },
            .label = "Name:",
            .value = self.name_input.value(),
            .focus_action = .select,
        };
    }

    fn nameFieldRect(self: *const App) r4os.gui.Rect {
        return self.nameDialog().valueRect();
    }

    fn nameOkButtonRect(self: *const App) r4os.gui.Rect {
        return self.nameDialog().okRect();
    }

    fn nameCancelButtonRect(self: *const App) r4os.gui.Rect {
        return self.nameDialog().cancelRect();
    }

    fn openWithDialogRect(self: *const App) r4os.gui.Rect {
        const w: i32 = 280;
        const h: i32 = 162;
        return .{
            .x = @divTrunc(self.hosted_w - w, 2),
            .y = @divTrunc(self.hosted_h - h, 2),
            .w = w,
            .h = h,
        };
    }

    fn openWithMenuRect(self: *const App) r4os.gui.Rect {
        const rect = self.openWithDialogRect();
        const count = @max(@as(usize, 1), self.openWithCount());
        return .{ .x = rect.x + 12, .y = rect.y + 50, .w = rect.w - 24, .h = @as(i32, @intCast(count)) * open_with_row_h + 6 };
    }

    fn openWithIndexAt(self: *const App, x: i32, y: i32) ?usize {
        var items: [association_count_max]r4os.gui.MenuItem = undefined;
        const count = self.fillOpenWithMenuItems(&items);
        return (r4os.gui.Menu{ .rect = self.openWithMenuRect(), .items = items[0..count], .row_h = open_with_row_h }).indexAt(x, y);
    }

    fn openWithOkButtonRect(self: *const App) r4os.gui.Rect {
        const rect = self.openWithDialogRect();
        return .{ .x = rect.x + rect.w - 132, .y = rect.y + rect.h - 30, .w = 54, .h = 20 };
    }

    fn openWithCancelButtonRect(self: *const App) r4os.gui.Rect {
        const rect = self.openWithDialogRect();
        return .{ .x = rect.x + rect.w - 72, .y = rect.y + rect.h - 30, .w = 62, .h = 20 };
    }

    fn iconBodyRect(self: *const App) r4os.gui.Rect {
        const rect = self.iconViewRect().inset(2, 2);
        return .{ .x = rect.x, .y = rect.y, .w = @max(1, rect.w - r4os.gui.default_metrics.scrollbar_w), .h = rect.h };
    }

    fn iconColumns(self: *const App) usize {
        const body = self.iconBodyRect();
        return @max(@as(usize, 1), @as(usize, @intCast(@max(1, @divTrunc(body.w, icon_cell_w)))));
    }

    fn iconRowsVisible(self: *const App) usize {
        const body = self.iconBodyRect();
        return @max(@as(usize, 1), @as(usize, @intCast(@max(1, @divTrunc(body.h, icon_cell_h)))));
    }

    fn visibleIconCount(self: *const App) usize {
        return @max(@as(usize, 1), self.iconColumns() * self.iconRowsVisible());
    }

    fn iconCellRect(self: *const App, index: usize) r4os.gui.Rect {
        const body = self.iconBodyRect();
        const columns = self.iconColumns();
        const relative = if (index >= self.scroll_offset) index - self.scroll_offset else 0;
        const col: i32 = @intCast(relative % columns);
        const row: i32 = @intCast(relative / columns);
        return .{
            .x = body.x + col * icon_cell_w + icon_pad_x,
            .y = body.y + row * icon_cell_h + icon_pad_y,
            .w = icon_cell_w - icon_pad_x * 2,
            .h = icon_cell_h - icon_pad_y,
        };
    }

    fn iconLabelRect(self: *const App, cell: r4os.gui.Rect) r4os.gui.Rect {
        _ = self;
        return .{
            .x = cell.x + @divTrunc(cell.w - icon_label_w, 2),
            .y = cell.y + icon_label_y,
            .w = icon_label_w,
            .h = r4os.gui.font_h * 2 + icon_label_line_gap,
        };
    }

    fn iconIndexAt(self: *const App, x: i32, y: i32) ?usize {
        const body = self.iconBodyRect();
        if (!body.contains(x, y)) return null;
        const rel_x = x - body.x;
        const rel_y = y - body.y;
        if (rel_x < 0 or rel_y < 0) return null;
        const columns = self.iconColumns();
        const col: usize = @intCast(@divTrunc(rel_x, icon_cell_w));
        const row: usize = @intCast(@divTrunc(rel_y, icon_cell_h));
        if (col >= columns) return null;
        const index = self.scroll_offset + row * columns + col;
        if (index >= self.entry_count) return null;
        return index;
    }

    fn iconScrollbar(self: *const App) r4os.gui.Scrollbar {
        const outer = self.iconViewRect().inset(2, 2);
        return .{
            .rect = .{ .x = outer.x + outer.w - r4os.gui.default_metrics.scrollbar_w, .y = outer.y, .w = r4os.gui.default_metrics.scrollbar_w, .h = outer.h },
            .total_items = self.entry_count,
            .visible_items = self.visibleIconCount(),
            .first_index = self.scroll_offset,
        };
    }

    fn listRect(self: *const App) r4os.gui.Rect {
        return .{ .x = 8, .y = 34, .w = @max(120, self.hosted_w - 218), .h = @max(90, self.hosted_h - 60) };
    }

    fn headerRect(self: *const App) r4os.gui.Rect {
        return r4os.gui.tableHeaderRect(self.listRect(), row_h);
    }

    fn rowsRect(self: *const App) r4os.gui.Rect {
        return r4os.gui.tableBodyRect(self.listRect(), row_h, self.entry_count > self.visibleRows());
    }

    fn nameColumnRect(self: *const App, rect: r4os.gui.Rect) r4os.gui.Rect {
        _ = self;
        return .{ .x = rect.x, .y = rect.y, .w = @max(64, rect.w - table_date_w - table_size_w - table_type_w - r4os.gui.default_metrics.scrollbar_w), .h = rect.h };
    }

    fn typeColumnRect(self: *const App, rect: r4os.gui.Rect) r4os.gui.Rect {
        const name = self.nameColumnRect(rect);
        return .{ .x = name.x + name.w, .y = rect.y, .w = table_type_w, .h = rect.h };
    }

    fn sizeColumnRect(self: *const App, rect: r4os.gui.Rect) r4os.gui.Rect {
        const typ = self.typeColumnRect(rect);
        return .{ .x = typ.x + typ.w, .y = rect.y, .w = table_size_w, .h = rect.h };
    }

    fn dateColumnRect(self: *const App, rect: r4os.gui.Rect) r4os.gui.Rect {
        const size = self.sizeColumnRect(rect);
        const w = @max(40, rect.x + rect.w - size.x - size.w - r4os.gui.default_metrics.scrollbar_w);
        return .{ .x = size.x + size.w, .y = rect.y, .w = w, .h = rect.h };
    }

    fn sortModeAt(self: *const App, x: i32) SortMode {
        const header = self.headerRect();
        if (self.typeColumnRect(header).contains(x, header.y)) return .kind;
        if (self.sizeColumnRect(header).contains(x, header.y)) return .size;
        if (self.dateColumnRect(header).contains(x, header.y)) return .modified;
        return .name;
    }

    fn detailsRect(self: *const App) r4os.gui.Rect {
        return .{ .x = self.hosted_w - 198, .y = 34, .w = 190, .h = @max(90, self.hosted_h - 60) };
    }

    fn visibleRows(self: *const App) usize {
        return @max(@as(usize, 1), r4os.gui.visibleTableRows(r4os.gui.tableBodyRect(self.listRect(), row_h, false), row_h));
    }

    fn entryTableBodyWidth(self: *const App) i32 {
        return r4os.gui.tableBodyRect(self.listRect(), row_h, self.entry_count > self.visibleRows()).w;
    }

    fn entryHitTable(self: *const App) r4os.gui.TableView {
        return .{
            .rect = self.listRect(),
            .columns = &.{},
            .cells = &.{},
            .row_count = self.entry_count,
            .selected_index = self.selected_index,
            .first_index = self.scroll_offset,
            .row_h = row_h,
            .header_h = row_h,
        };
    }

    fn entryScrollbar(self: *const App) r4os.gui.Scrollbar {
        return .{
            .rect = r4os.gui.tableScrollbarRect(self.listRect(), row_h),
            .total_items = self.entry_count,
            .visible_items = self.visibleRows(),
            .first_index = self.scroll_offset,
        };
    }

    fn ensureSelectionVisible(self: *App) void {
        if (self.entry_count == 0) {
            self.scroll_offset = 0;
            return;
        }
        if (self.selected_index >= self.entry_count) return;
        const visible = self.visibleIconCount();
        if (self.selected_index < self.scroll_offset) {
            self.scroll_offset = self.selected_index;
        } else if (self.selected_index >= self.scroll_offset + visible) {
            self.scroll_offset = self.selected_index + 1 - visible;
        }
    }

    fn entryPrefix(self: *const App, entry: *const Entry) []const u8 {
        if (entry.kind == entry_kind_drive) return "[DRV]";
        if (entry.kind > 0) return "[DIR]";
        if (entry.is_shortcut) return "[LNK]";
        const path = spanZ(entry.path[0..]);
        if (endsWithIgnoreCase(path, ".R4X")) return "[APP]";
        if (endsWithIgnoreCase(path, ".R4D")) return "[DRV]";
        return file_assoc.prefix(&self.assoc, path);
    }

    fn entryTypeName(self: *const App, entry: *const Entry) []const u8 {
        if (entry.kind == entry_kind_drive) return "Drive";
        if (entry.kind > 0) return "Folder";
        if (entry.is_shortcut) return if (entry.shortcut_valid) "Shortcut" else "Invalid shortcut";
        const path = spanZ(entry.path[0..]);
        if (endsWithIgnoreCase(path, ".R4X")) return "R4X program";
        if (endsWithIgnoreCase(path, ".R4D")) return "R4D driver";
        return file_assoc.typeName(&self.assoc, path);
    }

    fn entryTypeShort(self: *const App, entry: *const Entry) []const u8 {
        if (entry.kind == entry_kind_drive) return "Drive";
        if (entry.kind > 0) return "Folder";
        if (entry.is_shortcut) return if (entry.shortcut_valid) "Shortcut" else "Bad link";
        const path = spanZ(entry.path[0..]);
        if (endsWithIgnoreCase(path, ".R4X")) return "R4X";
        if (endsWithIgnoreCase(path, ".R4D")) return "Driver";
        return file_assoc.typeShort(&self.assoc, path);
    }

    fn entryTypeRank(self: *const App, entry: Entry) u8 {
        if (entry.kind == entry_kind_drive) return 0;
        if (entry.kind > 0) return 1;
        if (entry.is_shortcut) return 2;
        const path = spanZ(entry.path[0..]);
        if (endsWithIgnoreCase(path, ".R4X")) return 3;
        if (endsWithIgnoreCase(path, ".R4D")) return 4;
        return file_assoc.rank(&self.assoc, path);
    }
};

const DeleteSummary = struct {
    deleted: u32 = 0,
    failed: u32 = 0,
};

fn deleteEntry(ctx: *const r4os.r4sys.Context, entry: *const Entry) i32 {
    return if (entry.kind > 0)
        ctx.dirDelete(zptr(entry.path[0..]))
    else
        ctx.fileDelete(zptr(entry.path[0..]));
}

fn deleteEntries(ctx: *const r4os.r4sys.Context, entries: []const Entry) DeleteSummary {
    var summary = DeleteSummary{};
    for (entries) |*entry| {
        if (deleteEntry(ctx, entry) > 0) {
            summary.deleted += 1;
        } else {
            summary.failed += 1;
        }
    }
    return summary;
}

fn buildExplorerMenus(out: *ExplorerMenus, address_visible: bool) []const r4os.gui.MenubarMenu {
    out.file_items = .{
        .{ .text = "New >", .id = @intFromEnum(Command.file_new_menu) },
        .{ .text = "Delete", .id = @intFromEnum(Command.file_delete), .shortcut = "Del", .separator_before = true },
        .{ .text = "Rename", .id = @intFromEnum(Command.file_rename), .shortcut = "F2" },
        .{ .text = "Close", .id = @intFromEnum(Command.file_close), .separator_before = true },
    };
    out.edit_items = .{
        .{ .text = "Cut", .id = @intFromEnum(Command.edit_cut), .shortcut = "Ctrl+X" },
        .{ .text = "Copy", .id = @intFromEnum(Command.edit_copy), .shortcut = "Ctrl+C" },
        .{ .text = "Paste", .id = @intFromEnum(Command.edit_paste), .shortcut = "Ctrl+V" },
        .{ .text = "Select All", .id = @intFromEnum(Command.edit_select_all), .shortcut = "Ctrl+A", .separator_before = true },
    };
    out.view_items = .{
        .{ .text = "Refresh", .id = @intFromEnum(Command.view_refresh), .shortcut = "F3" },
        .{ .text = if (address_visible) "Address Bar: On" else "Address Bar: Off", .id = @intFromEnum(Command.view_toggle_address), .separator_before = true },
    };
    out.menus = .{
        .{ .text = "File", .items = out.file_items[0..] },
        .{ .text = "Edit", .items = out.edit_items[0..] },
        .{ .text = "View", .items = out.view_items[0..] },
    };
    return out.menus[0..];
}

fn runSelfTest(ctx: *const r4os.r4sys.Context) i32 {
    ctx.println("EXPLORER selftest");
    var config = r4std.app_assoc.Config.initDefault();
    var file_buf: [assoc_config_max_bytes]u8 = undefined;
    const len = ctx.fileRead(r4std.settings.paths.assoc, file_buf[0..]);
    if (len > 0) _ = config.loadFromBytes(file_buf[0..@intCast(len)]);

    if (file_assoc.appCount(&config) < 3) return explorerFail(ctx, "open-with-count");
    if (file_assoc.appForMenuIndex(&config, 0) == null) return explorerFail(ctx, "open-with-app");
    if (file_assoc.defaultIndex(&config, "D:\\IMAGE.BMP") >= file_assoc.appCount(&config)) return explorerFail(ctx, "default-index");
    if (icon_cell_w < 72 or icon_cell_h < 64 or icon_pad_x * 2 >= icon_cell_w or icon_pad_y * 2 >= icon_cell_h) return explorerFail(ctx, "icon-layout");
    if (!explorerChromeLayoutOk()) return explorerFail(ctx, "chrome-layout");
    if (!explorerMenusOk()) return explorerFail(ctx, "menu-layout");
    if (!explorerIconLabelLayoutOk()) return explorerFail(ctx, "icon-label-layout");
    var toolbar_icon_bytes: [toolbar_icon_bytes_max]u8 = undefined;
    var icon_pixels: [loaded_icon_pixels_max]u32 = undefined;
    if (!expectToolbarIcon(ctx, toolbar_back_icon_resource, toolbar_icon_bytes[0..], icon_pixels[0..])) return explorerFail(ctx, "toolbar-back-icon");
    if (!expectToolbarIcon(ctx, toolbar_forward_icon_resource, toolbar_icon_bytes[0..], icon_pixels[0..])) return explorerFail(ctx, "toolbar-forward-icon");
    if (!expectToolbarIcon(ctx, toolbar_up_icon_resource, toolbar_icon_bytes[0..], icon_pixels[0..])) return explorerFail(ctx, "toolbar-up-icon");
    if (!expectToolbarIcon(ctx, toolbar_cut_icon_resource, toolbar_icon_bytes[0..], icon_pixels[0..])) return explorerFail(ctx, "toolbar-cut-icon");
    if (!expectToolbarIcon(ctx, toolbar_copy_icon_resource, toolbar_icon_bytes[0..], icon_pixels[0..])) return explorerFail(ctx, "toolbar-copy-icon");
    if (!expectToolbarIcon(ctx, toolbar_paste_icon_resource, toolbar_icon_bytes[0..], icon_pixels[0..])) return explorerFail(ctx, "toolbar-paste-icon");
    if (!expectToolbarIcon(ctx, toolbar_delete_icon_resource, toolbar_icon_bytes[0..], icon_pixels[0..])) return explorerFail(ctx, "toolbar-delete-icon");
    if (!expectToolbarResourceStat(ctx, toolbar_back_icon_resource, toolbar_icon_bytes[0..])) return explorerFail(ctx, "toolbar-resource-stat");
    if (!expectFolderIcon(ctx, folder_icon_path, toolbar_icon_bytes[0..], icon_pixels[0..])) return explorerFail(ctx, "folder-icon");

    const c_info = ctx.driveInfo('C' - 'A') orelse return explorerFail(ctx, "drive-c");
    if (!driveBrowsable(c_info.kind) or c_info.mounted == 0) return explorerFail(ctx, "drive-c-kind");
    const d_info = ctx.driveInfo('D' - 'A') orelse return explorerFail(ctx, "drive-d");
    if (!driveBrowsable(d_info.kind) or d_info.mounted == 0) return explorerFail(ctx, "drive-d-kind");

    var root_path: [8]u8 = .{0} ** 8;
    setDriveRoot(root_path[0..], 'C');
    if (!equalsIgnoreCase(spanZ(root_path[0..]), "C:\\")) return explorerFail(ctx, "drive-root");
    var drive_label: [8]u8 = .{0} ** 8;
    setDriveLabel(drive_label[0..], 'D');
    if (!equalsIgnoreCase(spanZ(drive_label[0..]), "D:")) return explorerFail(ctx, "drive-label");
    if (driveRootLetter("Computer") != 0) return explorerFail(ctx, "drive-letter-strict");
    const start_arg = explorerStartPathArg("  C:\\R4OS\\DESKTOP\\TOOLS  ") orelse return explorerFail(ctx, "start-arg");
    if (!equalsIgnoreCase(start_arg, "C:\\R4OS\\DESKTOP\\TOOLS")) return explorerFail(ctx, "start-arg-path");
    if (explorerStartPathArg(" /SELFTEST ") != null) return explorerFail(ctx, "start-arg-switch");

    var temp_entry: [128]u8 = .{0} ** 128;
    if (!findDirectoryEntryPath(ctx, "C:\\", "TEMP", temp_entry[0..])) return explorerFail(ctx, "dir-entry-temp");
    if (!equalsIgnoreCase(spanZ(temp_entry[0..]), "C:\\TEMP")) return explorerFail(ctx, "dir-entry-drive-prefix");
    if (driveRootLetter(spanZ(temp_entry[0..])) != 'C') return explorerFail(ctx, "dir-entry-drive-letter");

    var args: [128]u8 = .{0} ** 128;
    const text = config.resolvePath("C:\\TEMP\\NOTE.TXT", args[0..]) orelse return explorerFail(ctx, "txt-target");
    if (text.kind != .associated) return explorerFail(ctx, "txt-kind");
    if (!endsWithIgnoreCase(text.app_path, ".R4X")) return explorerFail(ctx, "txt-app");
    if (!equalsIgnoreCase(text.args, "C:\\TEMP\\NOTE.TXT")) return explorerFail(ctx, "txt-args");
    if (file_assoc.typeName(&config, "C:\\TEMP\\NOTE.TXT").len == 0) return explorerFail(ctx, "txt-type");
    if (file_assoc.prefix(&config, "C:\\TEMP\\NOTE.TXT").len == 0) return explorerFail(ctx, "txt-prefix");

    const bmp = config.resolvePath("C:\\TEMP\\PIC.BMP", args[0..]) orelse return explorerFail(ctx, "bmp-target");
    if (bmp.kind != .associated or !endsWithIgnoreCase(bmp.app_path, ".R4X")) return explorerFail(ctx, "bmp-app");
    const audio = config.resolvePath("C:\\TEMP\\TADA.WAV", args[0..]) orelse return explorerFail(ctx, "audio-target");
    if (audio.kind != .associated or !endsWithIgnoreCase(audio.app_path, ".R4X")) return explorerFail(ctx, "audio-app");
    const direct = config.resolvePath("C:\\R4OS\\SOFTWARE\\DESKTOP\\APP.R4X", args[0..]) orelse return explorerFail(ctx, "r4x-target");
    if (direct.kind != .direct_program or direct.args.len != 0 or direct.policy != .auto) return explorerFail(ctx, "r4x-direct");
    if (config.resolvePath("C:\\TEMP\\DATA.BIN", args[0..]) != null) return explorerFail(ctx, "unknown-target");
    if (!isShortcutPath("C:\\R4OS\\DESKTOP\\COMPUTER.LNK")) return explorerFail(ctx, "lnk-path");
    if (!explorerShortcutSelfTest(ctx, &config)) return 1;
    if (!explorerSubsystemSelfTest(ctx, &config)) return 1;

    var src_path: [128]u8 = .{0} ** 128;
    var copy_path: [128]u8 = .{0} ** 128;
    var move_path: [128]u8 = .{0} ** 128;
    setZ(src_path[0..], "C:\\EXPSRC.TXT");
    setZ(copy_path[0..], "C:\\TEMP\\EXPCT.TXT");
    setZ(move_path[0..], "C:\\EXPMV.TXT");
    _ = ctx.fileDelete(zptr(src_path[0..]));
    _ = ctx.fileDelete(zptr(copy_path[0..]));
    _ = ctx.fileDelete(zptr(move_path[0..]));
    if (ctx.fileWrite(zptr(src_path[0..]), "Explorer selftest source\n") <= 0) return explorerFail(ctx, "write");
    if (ctx.fileCopy(zptr(src_path[0..]), zptr(copy_path[0..])) <= 0) return explorerFail(ctx, "copy");
    var copied_entry: [128]u8 = .{0} ** 128;
    if (!findDirectoryEntryPath(ctx, "C:\\TEMP", "EXPCT.TXT", copied_entry[0..])) return explorerFail(ctx, "dir-entry-child");
    if (!startsWithIgnoreCase(spanZ(copied_entry[0..]), "C:\\TEMP\\")) return explorerFail(ctx, "dir-entry-child-prefix");
    if (ctx.fileDelete(zptr(src_path[0..])) <= 0) return explorerFail(ctx, "delete-source");
    if (ctx.fileMove(zptr(copy_path[0..]), zptr(move_path[0..])) <= 0) return explorerFail(ctx, "move");
    if (ctx.fileDelete(zptr(move_path[0..])) <= 0) return explorerFail(ctx, "delete");

    var multi_path_a: [128]u8 = .{0} ** 128;
    var multi_path_b: [128]u8 = .{0} ** 128;
    setZ(multi_path_a[0..], "C:\\TEMP\\EXPMD1.TXT");
    setZ(multi_path_b[0..], "C:\\TEMP\\EXPMD2.TXT");
    _ = ctx.fileDelete(zptr(multi_path_a[0..]));
    _ = ctx.fileDelete(zptr(multi_path_b[0..]));
    if (ctx.fileWrite(zptr(multi_path_a[0..]), "Explorer multi-delete A\n") <= 0) return explorerFail(ctx, "multi-delete-write-a");
    if (ctx.fileWrite(zptr(multi_path_b[0..]), "Explorer multi-delete B\n") <= 0) {
        _ = ctx.fileDelete(zptr(multi_path_a[0..]));
        return explorerFail(ctx, "multi-delete-write-b");
    }
    var multi_entries = [_]Entry{ .{}, .{} };
    multi_entries[0].kind = entry_kind_file;
    multi_entries[1].kind = entry_kind_file;
    copyZ(multi_entries[0].path[0..], spanZ(multi_path_a[0..]));
    copyZ(multi_entries[1].path[0..], spanZ(multi_path_b[0..]));
    const multi_delete = deleteEntries(ctx, multi_entries[0..]);
    const residue_a = ctx.fileDelete(zptr(multi_path_a[0..]));
    const residue_b = ctx.fileDelete(zptr(multi_path_b[0..]));
    if (multi_delete.deleted != 2 or multi_delete.failed != 0 or residue_a > 0 or residue_b > 0) return explorerFail(ctx, "multi-delete");

    ctx.println("EXPLORER selftest: OK");
    return 0;
}

fn explorerShortcutSelfTest(ctx: *const r4os.r4sys.Context, config: *const r4std.app_assoc.Config) bool {
    var bytes: [shortcut_file_max_bytes]u8 = undefined;

    var program_link = r4std.shortcut.Shortcut.init("C:\\R4OS\\SOFTWARE\\DESKTOP\\NOTEPAD.R4X") catch return explorerFailBool(ctx, "shortcut-program-init");
    program_link.setTitle("Notepad") catch return explorerFailBool(ctx, "shortcut-program-title");
    program_link.setPolicy(.gui);
    program_link.setIcon("C:\\R4OS\\Media\\Icons\\Notepad.ico") catch return explorerFailBool(ctx, "shortcut-program-icon");
    const program_bytes = program_link.writeTo(bytes[0..]) catch return explorerFailBool(ctx, "shortcut-program-write");
    const parsed_program = r4std.shortcut.parse(program_bytes) catch return explorerFailBool(ctx, "shortcut-program-parse");
    const program = parsed_program.resolve() catch return explorerFailBool(ctx, "shortcut-program-resolve");
    if (program.kind != .program or program.policy != .gui or !endsWithIgnoreCase(program.target, "NOTEPAD.R4X")) return explorerFailBool(ctx, "shortcut-program-target");

    var dir_link = r4std.shortcut.Shortcut.init("C:\\TEMP\\") catch return explorerFailBool(ctx, "shortcut-dir-init");
    dir_link.setTitle("Temp") catch return explorerFailBool(ctx, "shortcut-dir-title");
    const dir_bytes = dir_link.writeTo(bytes[0..]) catch return explorerFailBool(ctx, "shortcut-dir-write");
    const parsed_dir = r4std.shortcut.parse(dir_bytes) catch return explorerFailBool(ctx, "shortcut-dir-parse");
    const dir = parsed_dir.resolve() catch return explorerFailBool(ctx, "shortcut-dir-resolve");
    if (dir.kind != .directory or !equalsIgnoreCase(dir.target, "C:\\TEMP\\")) return explorerFailBool(ctx, "shortcut-dir-target");

    var file_link = r4std.shortcut.Shortcut.init("C:\\TEMP\\NOTE.TXT") catch return explorerFailBool(ctx, "shortcut-file-init");
    const file_bytes = file_link.writeTo(bytes[0..]) catch return explorerFailBool(ctx, "shortcut-file-write");
    const parsed_file = r4std.shortcut.parse(file_bytes) catch return explorerFailBool(ctx, "shortcut-file-parse");
    const file = parsed_file.resolve() catch return explorerFailBool(ctx, "shortcut-file-resolve");
    var args: [128]u8 = .{0} ** 128;
    const file_target = config.resolvePath(file.target, args[0..]) orelse return explorerFailBool(ctx, "shortcut-file-assoc");
    if (file.kind != .file or file_target.kind != .associated or !endsWithIgnoreCase(file_target.app_path, ".R4X")) return explorerFailBool(ctx, "shortcut-file-target");

    if (!expectShortcutError("R4S_FORMAT=1\nSCHEMA=APPASSOC\nTARGET=C:\\TEMP\\NOTE.TXT\n", error.WrongSchema)) return explorerFailBool(ctx, "shortcut-wrong-schema");
    if (!expectShortcutError("R4S_FORMAT=1\nSCHEMA=R4LNK\nTITLE=Broken\n", error.MissingTarget)) return explorerFailBool(ctx, "shortcut-missing-target");
    if (!expectShortcutError("R4S_FORMAT=1\nSCHEMA=R4LNK\nTARGET=C:\\TEMP\\NOTE.TXT\nPOLICY=magic\n", error.InvalidPolicy)) return explorerFailBool(ctx, "shortcut-invalid-policy");
    if (!expectShortcutError("R4S_FORMAT=1\nSCHEMA=R4LNK\nTARGET=C:\\TEMP\\NOTE.TXT\nARGS=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n", error.ArgsTooLong)) return explorerFailBool(ctx, "shortcut-args-too-long");
    return true;
}

fn explorerSubsystemSelfTest(ctx: *const r4os.r4sys.Context, config: *const r4std.app_assoc.Config) bool {
    if (r4std.subsystem_runtime.load(ctx) != .loaded) return explorerFailBool(ctx, "subsystem-catalog");
    const catalog = r4std.subsystem_runtime.catalog();
    const paths = [_][]const u8{ "C:\\TEMP\\SUBSYSTEM-A.BAS", "C:\\TEMP\\SUBSYSTEM-B.BAS" };
    var encoded_a: [r4os.subsystem_launch.max_args_bytes]u8 = undefined;
    var encoded_b: [r4os.subsystem_launch.max_args_bytes]u8 = undefined;
    const encoded = [_][]u8{ encoded_a[0..], encoded_b[0..] };
    var encoded_len: [2]usize = .{ 0, 0 };
    for (paths, encoded, 0..) |path, storage, index| {
        const input = r4std.subsystem_runtime.probe(ctx, path) catch return explorerFailBool(ctx, "subsystem-probe");
        var resolution: r4std.file_handler.Resolution = .{};
        r4std.file_handler.resolve(config, catalog, input, storage, &resolution) catch return explorerFailBool(ctx, "subsystem-resolve");
        const target = resolution.target orelse return explorerFailBool(ctx, "subsystem-target");
        if (target.kind != .subsystem or !equalsIgnoreCase(target.handler_id, "test.basic")) return explorerFailBool(ctx, "subsystem-id");
        if (!r4std.subsystem_runtime.hostPresent(ctx, target.app_path)) return explorerFailBool(ctx, "subsystem-host");
        const request = r4os.subsystem_launch.parse(target.args) catch return explorerFailBool(ctx, "subsystem-request");
        if (!equalsIgnoreCase(request.guest_path, path)) return explorerFailBool(ctx, "subsystem-guest-path");
        encoded_len[index] = target.args.len;
    }
    const request_a = r4os.subsystem_launch.parse(encoded_a[0..encoded_len[0]]) catch return explorerFailBool(ctx, "subsystem-instance-a");
    const request_b = r4os.subsystem_launch.parse(encoded_b[0..encoded_len[1]]) catch return explorerFailBool(ctx, "subsystem-instance-b");
    if (equalsIgnoreCase(request_a.guest_path, request_b.guest_path)) return explorerFailBool(ctx, "subsystem-instance-paths");

    const input = r4std.subsystem_runtime.probe(ctx, paths[0]) catch return explorerFailBool(ctx, "subsystem-choice-probe");
    var choices: r4std.file_handler.ChoiceList = .{};
    r4std.file_handler.collectChoices(config, catalog, input, &choices) catch return explorerFailBool(ctx, "subsystem-choices");
    var app_found = false;
    var subsystem_found = false;
    for (choices.slice()) |choice| switch (choice.kind) {
        .application => app_found = true,
        .subsystem => {
            if (equalsIgnoreCase(choice.handler_id, "test.basic")) subsystem_found = true;
        },
    };
    if (!app_found or !subsystem_found) return explorerFailBool(ctx, "subsystem-open-with");

    var shortcut_bytes: [shortcut_file_max_bytes]u8 = undefined;
    const link = r4std.shortcut.Shortcut.init(paths[0]) catch return explorerFailBool(ctx, "subsystem-shortcut-init");
    const written = link.writeTo(shortcut_bytes[0..]) catch return explorerFailBool(ctx, "subsystem-shortcut-write");
    const shortcut = r4std.shortcut.parse(written) catch return explorerFailBool(ctx, "subsystem-shortcut-parse");
    const file = shortcut.resolve() catch return explorerFailBool(ctx, "subsystem-shortcut-resolve");
    if (file.kind != .file or !equalsIgnoreCase(file.target, paths[0])) return explorerFailBool(ctx, "subsystem-shortcut-target");
    return true;
}

fn expectShortcutError(bytes: []const u8, expected: r4std.shortcut.Error) bool {
    _ = r4std.shortcut.parse(bytes) catch |err| return err == expected;
    return false;
}

fn explorerFailBool(ctx: *const r4os.r4sys.Context, label: []const u8) bool {
    _ = explorerFail(ctx, label);
    return false;
}

fn explorerChromeLayoutOk() bool {
    return chrome_separator_h == 2 and
        chrome_top_line_y == explorer_menu_y and
        chrome_menu_toolbar_line_y == explorer_toolbar_y and
        chrome_toolbar_address_line_y == explorer_address_y and
        chrome_menu_toolbar_line_y + chrome_separator_h < toolbar_icon_button_y and
        chrome_toolbar_address_line_y + chrome_separator_h <= explorer_address_y + 2 and
        toolbar_button_gap == 3 and
        toolbar_button_start_x == 4 and
        toolbar_delete_x + toolbar_delete_w <= explorer_min_client_fallback_w and
        explorer_min_frame_w == 570 and
        explorer_min_frame_h == 320 and
        explorer_min_client_fallback_h == 282;
}

fn explorerMenusOk() bool {
    var menu_storage: ExplorerMenus = undefined;
    const menus = buildExplorerMenus(&menu_storage, true);
    return menus.len == 3 and
        menus[0].items.len == 4 and
        menus[1].items.len == 4 and
        menus[2].items.len == 2 and
        menus[0].items[0].id == @intFromEnum(Command.file_new_menu) and
        menus[2].items[1].id == @intFromEnum(Command.view_toggle_address) and
        new_menu_items.len == 2;
}

fn explorerIconLabelLayoutOk() bool {
    if (icon_label_w < @as(i32, @intCast(icon_label_text_max)) * r4os.gui.font_w) return false;
    if (icon_cell_w - icon_pad_x * 2 < icon_label_w) return false;
    if (icon_label_y + r4os.gui.font_h * 2 + icon_label_line_gap > icon_cell_h - icon_pad_y) return false;
    return icon_label.selfTest();
}

fn expectToolbarIcon(ctx: *const r4os.r4sys.Context, resource_name: []const u8, bytes_buffer: []u8, pixels: []u32) bool {
    const icon = decodeToolbarIconResource(ctx, resource_name, bytes_buffer, pixels) orelse return false;
    return icon.width == 32 and icon.height == 21;
}

fn expectToolbarResourceStat(ctx: *const r4os.r4sys.Context, resource_name: []const u8, bytes_buffer: []u8) bool {
    var module_path: [132]u8 = .{0} ** 132;
    if (ctx.programModulePath(module_path[0..128]) <= 0) return false;
    var name_buf: [64]u8 = .{0} ** 64;
    setZ(name_buf[0..], resource_name);
    const stat = ctx.moduleResourceStat(zptr(module_path[0..]), r4os.r4sys.module_resource_type_file, 0, zptr(name_buf[0..]));
    if (stat <= 0) return false;
    const read = readOwnFileResource(ctx, resource_name, bytes_buffer) orelse return false;
    return read.len == @as(usize, @intCast(stat));
}

fn expectFolderIcon(ctx: *const r4os.r4sys.Context, path: []const u8, bytes_buffer: []u8, pixels: []u32) bool {
    const icon = decodeFolderIcon(ctx, path, bytes_buffer, pixels) orelse return false;
    return icon.width == 32 and icon.height == 32;
}

fn decodeToolbarIconResource(ctx: *const r4os.r4sys.Context, resource_name: []const u8, bytes_buffer: []u8, pixels: []u32) ?DecodedIcon {
    const bytes = readOwnFileResource(ctx, resource_name, bytes_buffer) orelse return null;
    return decodeIconBytes(bytes, pixels, toolbar_icon_max_w, toolbar_icon_max_h, toolbar_icon_preferred, r4os.gui.default_palette.face);
}

fn readOwnFileResource(ctx: *const r4os.r4sys.Context, resource_name: []const u8, bytes_buffer: []u8) ?[]const u8 {
    var module_path: [132]u8 = .{0} ** 132;
    if (ctx.programModulePath(module_path[0..128]) <= 0) return null;
    var name_buf: [64]u8 = .{0} ** 64;
    if (resource_name.len >= name_buf.len) return null;
    setZ(name_buf[0..], resource_name);
    const read = ctx.moduleResourceRead(zptr(module_path[0..]), r4os.r4sys.module_resource_type_file, 0, zptr(name_buf[0..]), bytes_buffer);
    if (read <= 0) return null;
    return bytes_buffer[0..@as(usize, @intCast(read))];
}

fn decodeFolderIcon(ctx: *const r4os.r4sys.Context, path_text: []const u8, bytes_buffer: []u8, pixels: []u32) ?DecodedIcon {
    return decodeIcon(ctx, path_text, bytes_buffer, pixels, folder_icon_max_w, folder_icon_max_h, folder_icon_preferred, white);
}

fn decodeIcon(
    ctx: *const r4os.r4sys.Context,
    path_text: []const u8,
    bytes_buffer: []u8,
    pixels: []u32,
    max_w: usize,
    max_h: usize,
    preferred_size: u16,
    transparent_bg: u32,
) ?DecodedIcon {
    var path: [64]u8 = .{0} ** 64;
    setZ(path[0..], path_text);
    const read = ctx.fileRead(zptr(path[0..]), bytes_buffer);
    if (read <= 0) return null;
    return decodeIconBytes(bytes_buffer[0..@as(usize, @intCast(read))], pixels, max_w, max_h, preferred_size, transparent_bg);
}

fn decodeIconBytes(
    bytes: []const u8,
    pixels: []u32,
    max_w: usize,
    max_h: usize,
    preferred_size: u16,
    transparent_bg: u32,
) ?DecodedIcon {
    const entry = r4os.ico.chooseBest(bytes, preferred_size) catch return null;
    const image = r4os.ico.parseBmpImage(bytes, entry) catch return null;
    if (image.width == 0 or image.height == 0) return null;
    if (@as(usize, @intCast(image.width)) > max_w or @as(usize, @intCast(image.height)) > max_h) return null;

    const needed = @as(usize, @intCast(image.width)) * @as(usize, @intCast(image.height));
    if (pixels.len < needed) return null;
    var y: u32 = 0;
    while (y < image.height) : (y += 1) {
        var x: u32 = 0;
        while (x < image.width) : (x += 1) {
            const index = @as(usize, @intCast(y)) * @as(usize, @intCast(image.width)) + @as(usize, @intCast(x));
            const pixel = r4os.ico.pixelAt(bytes, image, x, y) orelse return null;
            pixels[index] = if (pixel.alpha < toolbar_icon_alpha_visible) transparent_bg else pixel.rgb;
        }
    }
    return .{ .width = image.width, .height = image.height };
}

fn findDirectoryEntryPath(ctx: *const r4os.r4sys.Context, directory: [*:0]const u8, name: []const u8, out: []u8) bool {
    if (out.len == 0) return false;
    var index: u32 = 2;
    while (true) : (index += 1) {
        @memset(out, 0);
        const kind = ctx.dirEntry(directory, index, out[0 .. out.len - 1]);
        if (kind < 0) return false;
        if (equalsIgnoreCase(tailName(spanZ(out)), name)) return true;
    }
}

fn explorerFail(ctx: *const r4os.r4sys.Context, label: []const u8) i32 {
    ctx.write("EXPLORER selftest FAILED: ");
    ctx.println(label);
    return 1;
}

fn launchErrorStatus(result: i32, hosted: bool) []const u8 {
    if (hosted) {
        return switch (result) {
            -1 => "Launch failed: app instance missing",
            -2 => "Launch failed: bad path or args",
            -3 => "Launch failed: host window missing",
            -4 => "Launch failed: invalid policy",
            else => "Launch failed",
        };
    }
    return switch (result) {
        -1 => "Launch failed: app not found",
        -2 => "Launch failed: invalid app or policy",
        else => "Launch failed",
    };
}

fn probeErrorStatus(err: r4std.subsystem_runtime.ProbeError) []const u8 {
    return switch (err) {
        error.InvalidPath => "Open failed: invalid or too long path",
        error.MissingFile => "Open failed: file missing",
        error.Directory => "Open failed: target is a directory",
        error.ReadFailed => "Open failed: file read error",
    };
}

fn handlerErrorStatus(err: r4std.file_handler.Error) []const u8 {
    return switch (err) {
        error.StaleAssociation => "Open failed: subsystem not installed",
        error.InvalidAssociation => "Open failed: invalid association",
        error.InvalidInput => "Open failed: invalid file input",
        error.TooManyCandidates => "Open failed: too many subsystem matches",
        error.TooManyChoices => "Open With has too many handlers",
        error.BufferTooSmall => "Open failed: path too long",
        error.InvalidGuestPath => "Open failed: invalid or too long path",
        error.InvalidMagic, error.MalformedRecord, error.InvalidKey, error.InvalidValue, error.MissingGuest, error.DuplicateGuest, error.TooManyOptions => "Open failed: invalid subsystem launch request",
    };
}

fn openStatus(out: []u8, title: []const u8) []const u8 {
    setZ(out, "Opened with ");
    appendZ(out, title);
    return spanZ(out);
}

fn sortModeName(mode: SortMode) []const u8 {
    return switch (mode) {
        .name => "name",
        .kind => "type",
        .size => "size",
        .modified => "date",
    };
}

fn compareNames(a: Entry, b: Entry) i8 {
    return compareTextIgnoreCase(spanZ(a.label[0..]), spanZ(b.label[0..]));
}

fn compareBoolDesc(a: bool, b: bool) i8 {
    if (a == b) return 0;
    return if (a) -1 else 1;
}

fn compareU8(a: u8, b: u8) i8 {
    if (a < b) return -1;
    if (a > b) return 1;
    return 0;
}

fn compareU32(a: u32, b: u32) i8 {
    if (a < b) return -1;
    if (a > b) return 1;
    return 0;
}

fn compareU64(a: u64, b: u64) i8 {
    if (a < b) return -1;
    if (a > b) return 1;
    return 0;
}

fn compareTextIgnoreCase(a: []const u8, b: []const u8) i8 {
    const count = @min(a.len, b.len);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        const ca = asciiLower(a[i]);
        const cb = asciiLower(b[i]);
        if (ca < cb) return -1;
        if (ca > cb) return 1;
    }
    if (a.len < b.len) return -1;
    if (a.len > b.len) return 1;
    return 0;
}

fn hasArg(args: [*:0]const u8, wanted: []const u8) bool {
    var offset: usize = 0;
    while (offset < 256 and args[offset] != 0) {
        while (offset < 256 and (args[offset] == ' ' or args[offset] == '\t')) : (offset += 1) {}
        const start = offset;
        while (offset < 256 and args[offset] != 0 and args[offset] != ' ' and args[offset] != '\t') : (offset += 1) {}
        if (equalsIgnoreCase(args[start..offset], wanted)) return true;
    }
    return false;
}

fn explorerStartPathArg(args: [*:0]const u8) ?[]const u8 {
    var offset: usize = 0;
    while (offset < 256 and args[offset] != 0) {
        while (offset < 256 and isSpace(args[offset])) : (offset += 1) {}
        if (offset >= 256 or args[offset] == 0) return null;
        const quoted = args[offset] == '"';
        if (quoted) offset += 1;
        const start = offset;
        if (quoted) {
            while (offset < 256 and args[offset] != 0 and args[offset] != '"') : (offset += 1) {}
        } else {
            while (offset < 256 and args[offset] != 0 and !isSpace(args[offset])) : (offset += 1) {}
        }
        const token = args[start..offset];
        if (quoted and offset < 256 and args[offset] == '"') offset += 1;
        if (token.len != 0 and token[0] != '/' and token[0] != '-') return token;
    }
    return null;
}

fn isShortcutPath(path: []const u8) bool {
    return endsWithIgnoreCase(path, ".LNK");
}

fn shortcutLabelFromPath(out: []u8, path: []const u8) void {
    const tail = tailName(path);
    if (tail.len > 4 and endsWithIgnoreCase(tail, ".LNK")) {
        setZ(out, tail[0 .. tail.len - 4]);
    } else {
        setZ(out, tail);
    }
}

fn shortcutErrorText(err: ShortcutOpenError) []const u8 {
    return switch (err) {
        error.ShortcutNotFound => "shortcut file not found",
        error.ShortcutPathTooLong => "shortcut path too long",
        error.MissingFormat, error.UnsupportedFormat, error.MissingSchema, error.WrongSchema => "invalid shortcut schema",
        error.MissingTarget => "missing target",
        error.InvalidTarget => "invalid target",
        error.TargetTooLong => "target path too long",
        error.ArgsTooLong => "arguments too long",
        error.IconTooLong => "icon path too long",
        error.WorkdirTooLong => "working directory too long",
        error.InvalidPolicy => "unsupported policy",
        error.InvalidText => "invalid text",
        error.UnknownField, error.DuplicateField => "invalid shortcut fields",
        error.TitleTooLong => "title too long",
        error.BufferTooSmall => "shortcut buffer too small",
    };
}

fn isSpace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

fn equalsIgnoreCase(a: []const u8, b: []const u8) bool {
    return compareTextIgnoreCase(a, b) == 0;
}

fn dateSortValue(entry: Entry) u32 {
    return (@as(u32, entry.modified_date) << 16) | entry.modified_time;
}

fn sizeText(out: []u8, entry: *const Entry) []const u8 {
    if (!entry.info_valid) return setAndSpan(out, "");
    if (entry.kind > 0) return setAndSpan(out, "<DIR>");
    return u64Text(out, entry.size);
}

fn modifiedText(out: []u8, entry: *const Entry, timestamp_view: TimestampView) []const u8 {
    @memset(out, 0);
    if (!entry.info_valid or entry.modified_date == 0) return out[0..0];
    if (!appendFatDateTime(out, entry.modified_date, entry.modified_time, timestamp_view)) return out[0..0];
    return spanZ(out);
}

fn setAndSpan(out: []u8, value: []const u8) []const u8 {
    setZ(out, value);
    return spanZ(out);
}

fn fsActionLabel(action: FsAction) []const u8 {
    return switch (action) {
        .delete_file, .delete_dir => "Delete",
        .create_dir => "Create folder",
        .create_file => "Create file",
        .rename => "Rename",
        .copy => "Copy",
        .move => "Move",
    };
}

fn fsActionForNameMode(mode: NameMode) FsAction {
    return switch (mode) {
        .new_folder => .create_dir,
        .new_file => .create_file,
        .rename, .none => .rename,
    };
}

fn fsErrorDetail(action: FsAction, code: i32) []const u8 {
    if (code == 0) {
        return switch (action) {
            .delete_dir => "folder not empty or not found",
            .delete_file => "file not found",
            .create_dir => "name exists or disk full",
            .create_file => "name exists or disk full",
            .rename => "name exists or source missing",
            .copy, .move => "source not found",
        };
    }
    return switch (code) {
        -1 => "bad path",
        -2 => "drive is not FAT32",
        -3 => switch (action) {
            .rename => "different drive or root path",
            else => "root path not allowed",
        },
        -4 => switch (action) {
            .copy, .move => "folders are not supported",
            .rename => "root path not allowed",
            .create_file => "write failed or disk full",
            else => "parent folder missing",
        },
        -5 => switch (action) {
            .rename => "move between folders not supported",
            .copy, .move => "target folder missing",
            else => "path error",
        },
        -6 => switch (action) {
            .rename => "source folder missing",
            .move => "source folder missing after copy",
            else => "path error",
        },
        -8 => "source and target are the same",
        -9 => "write failed or disk full",
        -10 => "target copied, source delete failed",
        -11 => "read-only source",
        else => "unknown error",
    };
}

fn sizeLine(out: []u8, entry: *const Entry) []const u8 {
    var number: [24]u8 = .{0} ** 24;
    setZ(out, "Size: ");
    if (!entry.info_valid) {
        appendZ(out, "unknown");
    } else if (entry.kind > 0) {
        appendZ(out, "<DIR>");
    } else {
        appendZ(out, u64Text(number[0..], entry.size));
        appendZ(out, " bytes");
    }
    return spanZ(out);
}

fn attrLine(out: []u8, entry: *const Entry) []const u8 {
    setZ(out, "Attr: ");
    if (!entry.info_valid) {
        appendZ(out, "unknown");
        return spanZ(out);
    }
    var any = false;
    if ((entry.attr & 0x01) != 0) {
        appendZ(out, "R");
        any = true;
    }
    if ((entry.attr & 0x02) != 0) {
        appendZ(out, "H");
        any = true;
    }
    if ((entry.attr & 0x04) != 0) {
        appendZ(out, "S");
        any = true;
    }
    if ((entry.attr & 0x10) != 0) {
        appendZ(out, "D");
        any = true;
    }
    if ((entry.attr & 0x20) != 0) {
        appendZ(out, "A");
        any = true;
    }
    if (!any) appendZ(out, "none");
    return spanZ(out);
}

fn modifiedLine(out: []u8, entry: *const Entry, timestamp_view: TimestampView) []const u8 {
    setZ(out, if (timestamp_view.local) "Modified: " else "Modified UTC: ");
    if (!entry.info_valid or entry.modified_date == 0) {
        appendZ(out, "unknown");
        return spanZ(out);
    }
    if (!appendFatDateTime(out, entry.modified_date, entry.modified_time, timestamp_view)) appendZ(out, "unknown");
    return spanZ(out);
}

fn driveRoleLine(out: []u8, info: r4os.abi.DriveInfo) []const u8 {
    setZ(out, "Role: ");
    appendZ(out, switch (info.role) {
        1 => "system",
        2 => "data",
        3 => "ram",
        else => "general",
    });
    appendZ(out, " ");
    appendZ(out, switch (info.kind) {
        1 => "RAM",
        2 => "FAT32",
        3 => "NTFS",
        else => "none",
    });
    return spanZ(out);
}

fn driveSizeLine(out: []u8, label: []const u8, bytes: u64) []const u8 {
    var number: [24]u8 = .{0} ** 24;
    setZ(out, label);
    if (bytes == 0) {
        appendZ(out, "unknown");
    } else {
        appendByteSize(out, number[0..], bytes);
    }
    return spanZ(out);
}

fn driveClusterLine(out: []u8, info: r4os.abi.DriveInfo) []const u8 {
    var number: [24]u8 = .{0} ** 24;
    setZ(out, "Clusters: ");
    if (info.total_clusters == 0 or info.cluster_bytes == 0) {
        appendZ(out, "unknown");
    } else {
        appendZ(out, u32Text(number[0..], info.free_clusters));
        appendZ(out, "/");
        appendZ(out, u32Text(number[0..], info.total_clusters));
        appendZ(out, " x ");
        appendByteSize(out, number[0..], info.cluster_bytes);
    }
    return spanZ(out);
}

fn appendByteSize(out: []u8, scratch: []u8, bytes: u64) void {
    const mib = 1024 * 1024;
    const kib = 1024;
    if (bytes >= mib and bytes % mib == 0) {
        appendZ(out, u64Text(scratch, bytes / mib));
        appendZ(out, " MB");
    } else if (bytes >= kib and bytes % kib == 0) {
        appendZ(out, u64Text(scratch, bytes / kib));
        appendZ(out, " KB");
    } else {
        appendZ(out, u64Text(scratch, bytes));
        appendZ(out, " bytes");
    }
}

fn appendFatDateTime(out: []u8, date_raw: u16, time_raw: u16, timestamp_view: TimestampView) bool {
    const utc = r4std.date.decodeFatDateTime(date_raw, time_raw) orelse return false;
    var display = utc;
    if (timestamp_view.local) {
        const state = r4std.date.toTimeState(utc) orelse return false;
        display = r4std.time.localDateTimeAtState(timestamp_view.timezone_index, state) orelse return false;
    }
    var text: [20]u8 = .{0} ** 20;
    const formatted = r4std.date.formatDateTimeMinuteDisplay(text[0..], display, timestamp_view.clock_format);
    if (formatted.len == 0) return false;
    appendZ(out, formatted);
    return true;
}

fn parentPath(path: []u8) void {
    var len = zLen(path);
    while (len > 3 and (path[len - 1] == '\\' or path[len - 1] == '/')) : (len -= 1) {}
    while (len > 3 and path[len - 1] != '\\' and path[len - 1] != '/') : (len -= 1) {}
    if (len <= 3) {
        const letter = if (driveRootLetter(path) != 0) driveRootLetter(path) else 'C';
        setDriveRoot(path, letter);
        return;
    }
    path[len - 1] = 0;
}

fn setDriveRoot(out: []u8, letter: u8) void {
    @memset(out, 0);
    if (out.len < 4) return;
    out[0] = asciiUpper(letter);
    out[1] = ':';
    out[2] = '\\';
    out[3] = 0;
}

fn driveRootLetter(path: []const u8) u8 {
    if (path.len < 2 or path[1] != ':') return 0;
    const letter = asciiUpper(path[0]);
    if (letter < 'A' or letter > 'Z') return 0;
    return letter;
}

fn driveLetterText(letter: u8) []const u8 {
    return switch (asciiUpper(letter)) {
        'A' => "A:",
        'B' => "B:",
        'C' => "C:",
        'D' => "D:",
        'E' => "E:",
        'F' => "F:",
        'G' => "G:",
        'H' => "H:",
        'I' => "I:",
        'J' => "J:",
        'K' => "K:",
        'L' => "L:",
        'M' => "M:",
        'N' => "N:",
        'O' => "O:",
        'P' => "P:",
        'Q' => "Q:",
        'R' => "R:",
        'S' => "S:",
        'T' => "T:",
        'U' => "U:",
        'V' => "V:",
        'W' => "W:",
        'X' => "X:",
        'Y' => "Y:",
        'Z' => "Z:",
        else => "?:",
    };
}

fn setDriveLabel(out: []u8, letter: u8) void {
    @memset(out, 0);
    if (out.len < 3) return;
    out[0] = asciiUpper(letter);
    out[1] = ':';
    out[2] = 0;
}

fn pushHistory(entries: *[history_max]HistoryEntry, count: *usize, entry: HistoryEntry) void {
    if (count.* < entries.len) {
        entries[count.*] = entry;
        count.* += 1;
        return;
    }
    var i: usize = 1;
    while (i < entries.len) : (i += 1) entries[i - 1] = entries[i];
    entries[entries.len - 1] = entry;
}

fn drawMenuText(canvas: r4os.gui.Canvas, scratch: []u8, x: i32, text: []const u8) i32 {
    const w = @as(i32, @intCast(text.len)) * 8 + 16;
    _ = canvas.label(.{
        .rect = .{ .x = x, .y = 5, .w = w, .h = 12 },
        .text = text,
        .fg = black,
        .bg = panel_bg,
    }, scratch);
    return x + w;
}

fn childPath(parent: []const u8, name: []const u8, out: []u8) bool {
    @memset(out, 0);
    if (parent.len == 0 or name.len == 0) return false;
    const needs_sep = parent[parent.len - 1] != '\\' and parent[parent.len - 1] != '/';
    const sep_len: usize = if (needs_sep) 1 else 0;
    if (parent.len + sep_len + name.len + 1 > out.len) return false;
    @memcpy(out[0..parent.len], parent);
    var pos = parent.len;
    if (needs_sep) {
        out[pos] = '\\';
        pos += 1;
    }
    @memcpy(out[pos .. pos + name.len], name);
    out[pos + name.len] = 0;
    return true;
}

fn isRoot(path: []const u8) bool {
    if (path.len == 2 and driveRootLetter(path) != 0) return true;
    return path.len == 3 and driveRootLetter(path) != 0 and (path[2] == '\\' or path[2] == '/');
}

fn validFileName(name: []const u8) bool {
    if (name.len == 0) return false;
    var dot: ?usize = null;
    var i: usize = 0;
    while (i < name.len) : (i += 1) {
        const ch = name[i];
        if (ch == '.') {
            if (dot != null) return false;
            dot = i;
            continue;
        }
        if (!shortNameAllowed(asciiUpper(ch))) return false;
    }
    const base = if (dot) |d| name[0..d] else name;
    const ext = if (dot) |d| name[d + 1 ..] else "";
    if (base.len == 0 or base.len > 8 or ext.len > 3) return false;
    return true;
}

fn shortNameAllowed(ch: u8) bool {
    return (ch >= 'A' and ch <= 'Z') or (ch >= '0' and ch <= '9') or ch == '_' or ch == '-' or ch == '$' or ch == '~';
}

fn tailName(path: []const u8) []const u8 {
    var start: usize = 0;
    var i: usize = 0;
    while (i < path.len) : (i += 1) {
        if (path[i] == '\\' or path[i] == '/') start = i + 1;
    }
    return path[start..];
}

fn endsWithIgnoreCase(value: []const u8, suffix: []const u8) bool {
    if (value.len < suffix.len) return false;
    const start = value.len - suffix.len;
    var i: usize = 0;
    while (i < suffix.len) : (i += 1) {
        if (asciiLower(value[start + i]) != asciiLower(suffix[i])) return false;
    }
    return true;
}

fn startsWithIgnoreCase(value: []const u8, prefix: []const u8) bool {
    if (value.len < prefix.len) return false;
    var i: usize = 0;
    while (i < prefix.len) : (i += 1) {
        if (asciiLower(value[i]) != asciiLower(prefix[i])) return false;
    }
    return true;
}

fn asciiLower(ch: u8) u8 {
    if (ch >= 'A' and ch <= 'Z') return ch + ('a' - 'A');
    return ch;
}

fn asciiUpper(ch: u8) u8 {
    if (ch >= 'a' and ch <= 'z') return ch - ('a' - 'A');
    return ch;
}

fn u32Text(out: []u8, value: u32) []const u8 {
    @memset(out, 0);
    if (out.len == 0) return out[0..0];
    var tmp: [10]u8 = .{0} ** 10;
    var n = value;
    var len: usize = 0;
    while (len < tmp.len) : (len += 1) {
        tmp[len] = '0' + @as(u8, @intCast(n % 10));
        n /= 10;
        if (n == 0) break;
    }
    const count = @min(len + 1, out.len - 1);
    var i: usize = 0;
    while (i < count) : (i += 1) out[i] = tmp[count - 1 - i];
    out[count] = 0;
    return out[0..count];
}

fn u64Text(out: []u8, value: u64) []const u8 {
    @memset(out, 0);
    if (out.len == 0) return out[0..0];
    var tmp: [20]u8 = .{0} ** 20;
    var n = value;
    var len: usize = 0;
    while (len < tmp.len) : (len += 1) {
        tmp[len] = '0' + @as(u8, @intCast(n % 10));
        n /= 10;
        if (n == 0) break;
    }
    const count = @min(len + 1, out.len - 1);
    var i: usize = 0;
    while (i < count) : (i += 1) out[i] = tmp[count - 1 - i];
    out[count] = 0;
    return out[0..count];
}

fn clampI32(value: i32, min_value: i32, max_value: i32) i32 {
    if (value < min_value) return min_value;
    if (value > max_value) return max_value;
    return value;
}

fn zptr(buf: []const u8) [*:0]const u8 {
    return @ptrCast(buf.ptr);
}

fn spanZ(buf: []const u8) []const u8 {
    var len: usize = 0;
    while (len < buf.len and buf[len] != 0) : (len += 1) {}
    return buf[0..len];
}

fn zLen(buf: []const u8) usize {
    return spanZ(buf).len;
}

fn setZ(out: []u8, value: []const u8) void {
    @memset(out, 0);
    if (out.len == 0) return;
    const count = @min(value.len, out.len - 1);
    if (count > 0) @memcpy(out[0..count], value[0..count]);
    out[count] = 0;
}

fn copyZ(out: []u8, value: []const u8) void {
    setZ(out, value);
}

fn appendZ(out: []u8, value: []const u8) void {
    var len = zLen(out);
    if (len >= out.len) return;
    const count = @min(value.len, out.len - len - 1);
    if (count > 0) @memcpy(out[len .. len + count], value[0..count]);
    len += count;
    out[len] = 0;
}
