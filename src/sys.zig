const std = @import("std");
const IOCTL = std.os.linux.IOCTL;

pub const IoctlError = std.Io.Cancelable || std.posix.UnexpectedError;

pub fn ioctl(file: std.Io.File, io: std.Io, request: Request, arg: ?*anyopaque) IoctlError!void {
    const result = try io.operate(.{ .device_io_control = .{
        .file = file,
        .code = @intFromEnum(request),
        .arg = arg,
    } });

    const rc = if (@import("builtin").link_libc)
        @as(c_int, @intCast(result.device_io_control))
    else
        @as(usize, @bitCast(@as(isize, @intCast(result.device_io_control))));

    return switch (std.posix.errno(rc)) {
        .SUCCESS => {},
        else => |e| std.posix.unexpectedErrno(e),
    };
}

pub const Request = enum(u32) {
    version = drm_iowr(0x00, Version),
    get_unique = drm_iowr(0x01, Unique),
    get_magic = drm_ior(0x02, Auth),
    irq_busid = drm_iowr(0x03, IrqBusid),
    get_map = drm_iowr(0x04, Map),
    get_client = drm_iowr(0x05, Client),
    get_stats = drm_ior(0x06, Stats),
    set_version = drm_iowr(0x07, SetVersion),
    // modeset_ctl = drm_iow(0x08, drm_modeset_ctl),
    // gem_close = drm_iow(0x09, drm_gem_close),
    // gem_flink = drm_iowr(0x0a, drm_gem_flink),
    // gem_open = drm_iowr(0x0b, drm_gem_open),
    get_cap = drm_iowr(0x0c, GetCap),
    set_client_cap = drm_iow(0x0d, SetClientCap),
    set_unique = drm_iow(0x10, Unique),
    auth_magic = drm_iow(0x11, Auth),
    // block = drm_iowr(0x12, drm_block),
    // unblock = drm_iowr(0x13, drm_block),
    // control = drm_iow(0x14, drm_control),
    add_map = drm_iowr(0x15, Map),
    // add_bufs = drm_iowr(0x16, drm_buf_desc),
    // mark_bufs = drm_iow(0x17, drm_buf_desc),
    // info_bufs = drm_iowr(0x18, drm_buf_info),
    // map_bufs = drm_iowr(0x19, drm_buf_map),
    // free_bufs = drm_iow(0x1a, drm_buf_free),
    rm_map = drm_iow(0x1b, Map),
    // set_sarea_ctx = drm_iow(0x1c, drm_ctx_priv_map),
    // get_sarea_ctx = drm_iowr(0x1d, drm_ctx_priv_map),
    set_master = drm_io(0x1e),
    drop_master = drm_io(0x1f),
    add_ctx = drm_iowr(0x20, Ctx),
    rm_ctx = drm_iowr(0x21, Ctx),
    mod_ctx = drm_iow(0x22, Ctx),
    get_ctx = drm_iowr(0x23, Ctx),
    switch_ctx = drm_iow(0x24, Ctx),
    new_ctx = drm_iow(0x25, Ctx),
    res_ctx = drm_iowr(0x26, CtxRes),
    // add_draw = drm_iowr(0x27, drm_draw),
    // rm_draw = drm_iowr(0x28, drm_draw),
    // dma = drm_iowr(0x29, drm_dma),
    // lock = drm_iow(0x2a, drm_lock),
    // unlock = drm_iow(0x2b, drm_lock),
    // finish = drm_iow(0x2c, drm_lock),
    // prime_handle_to_fd = drm_iowr(0x2d, drm_prime_handle),
    // prime_fd_to_handle = drm_iowr(0x2e, drm_prime_handle),
    agp_acquire = drm_io(0x30),
    agp_release = drm_io(0x31),
    // agp_enable = drm_iow(0x32, drm_agp_mode),
    // agp_info = drm_ior(0x33, drm_agp_info),
    // agp_alloc = drm_iowr(0x34, drm_agp_buffer),
    // agp_free = drm_iow(0x35, drm_agp_buffer),
    // agp_bind = drm_iow(0x36, drm_agp_binding),
    // agp_unbind = drm_iow(0x37, drm_agp_binding),
    // sg_alloc = drm_iowr(0x38, drm_scatter_gather),
    // sg_free = drm_iow(0x39, drm_scatter_gather),
    // wait_vblank = drm_iowr(0x3a, drm_wait_vblank),
    // crtc_get_sequence = drm_iowr(0x3b, drm_crtc_get_sequence),
    // crtc_queue_sequence = drm_iowr(0x3c, drm_crtc_queue_sequence),
    // update_draw = drm_iow(0x3f, drm_update_draw),
    mode_getresources = drm_iowr(0xA0, mode.CardRes),
    mode_getcrtc = drm_iowr(0xA1, mode.Crtc),
    mode_setcrtc = drm_iowr(0xA2, mode.Crtc),
    mode_cursor = drm_iowr(0xA3, mode.Cursor),
    mode_getgamma = drm_iowr(0xA4, mode.CrtcLut),
    mode_setgamma = drm_iowr(0xA5, mode.CrtcLut),
    mode_getencoder = drm_iowr(0xA6, mode.GetEncoder),
    mode_getconnector = drm_iowr(0xA7, mode.GetConnector),
    mode_getproperty = drm_iowr(0xAA, mode.GetProperty),
    mode_setproperty = drm_iowr(0xAB, mode.ConnectorSetProperty),
    mode_getpropblob = drm_iowr(0xAC, mode.GetBlob),
    mode_getfb = drm_iowr(0xAD, mode.FbCmd),
    mode_addfb = drm_iowr(0xAE, mode.FbCmd),
    mode_rmfb = drm_iowr(0xAF, c_uint),
    mode_page_flip = drm_iowr(0xB0, mode.CrtcPageFlip),
    mode_dirtyfb = drm_iowr(0xB1, mode.FbDirtyCmd),
    mode_create_dumb = drm_iowr(0xB2, mode.CreateDumb),
    mode_map_dumb = drm_iowr(0xB3, mode.MapDumb),
    mode_destroy_dumb = drm_iowr(0xB4, mode.DestroyDumb),
    mode_getplaneresources = drm_iowr(0xB5, mode.GetPlaneRes),
    mode_getplane = drm_iowr(0xB6, mode.GetPlane),
    mode_setplane = drm_iowr(0xB7, mode.SetPlane),
    mode_addfb2 = drm_iowr(0xB8, mode.FbCmd2),
    mode_obj_getproperties = drm_iowr(0xB9, mode.ObjGetProperties),
    mode_obj_setproperty = drm_iowr(0xBA, mode.ObjSetProperty),
    mode_cursor2 = drm_iowr(0xBB, mode.Cursor2),
    mode_atomic = drm_iowr(0xBC, mode.Atomic),
    mode_createpropblob = drm_iowr(0xBD, mode.CreateBlob),
    mode_destroypropblob = drm_iowr(0xBE, mode.DestroyBlob),
    // syncobj_create = drm_iowr(0xBF, drm_syncobj_create),
    // syncobj_destroy = drm_iowr(0xC0, drm_syncobj_destroy),
    // syncobj_handle_to_fd = drm_iowr(0xC1, drm_syncobj_handle),
    // syncobj_fd_to_handle = drm_iowr(0xC2, drm_syncobj_handle),
    // syncobj_wait = drm_iowr(0xC3, drm_syncobj_wait),
    // syncobj_reset = drm_iowr(0xC4, drm_syncobj_array),
    // syncobj_signal = drm_iowr(0xC5, drm_syncobj_array),
    mode_create_lease = drm_iowr(0xC6, mode.CreateLease),
    mode_list_lessees = drm_iowr(0xC7, mode.ListLessees),
    mode_get_lease = drm_iowr(0xC8, mode.GetLease),
    mode_revoke_lease = drm_iowr(0xC9, mode.RevokeLease),
    // syncobj_timeline_wait = drm_iowr(0xCA, drm_syncobj_timeline_wait),
    // syncobj_query = drm_iowr(0xCB, drm_syncobj_timeline_array),
    // syncobj_transfer = drm_iowr(0xCC, drm_syncobj_transfer),
    // syncobj_timeline_signal = drm_iowr(0xCD, drm_syncobj_timeline_array),
    mode_getfb2 = drm_iowr(0xCE, mode.FbCmd2),
    // syncobj_eventfd = drm_iowr(0xCF, drm_syncobj_eventfd),
    mode_closefb = drm_iowr(0xD0, mode.CloseFb),
    // set_client_name = drm_iowr(0xD1, drm_set_client_name),
    // gem_change_handle = drm_iowr(0xD2, drm_gem_change_handle),

    const io_type = 'd';

    fn drm_io(nr: u8) u32 {
        return IOCTL.IO(io_type, nr);
    }

    fn drm_ior(nr: u8, comptime T: type) u32 {
        return IOCTL.IOR(io_type, nr, T);
    }

    fn drm_iow(nr: u8, comptime T: type) u32 {
        return IOCTL.IOW(io_type, nr, T);
    }

    fn drm_iowr(nr: u8, comptime T: type) u32 {
        return IOCTL.IOWR(io_type, nr, T);
    }
};

pub const Magic = c_uint;

pub const Context = c_ulong;

pub const Version = extern struct {
    version_major: c_int,
    version_minor: c_int,
    version_patch: c_int,
    name_len: c_ulong,
    name: [*:0]const u8,
    date_len: c_ulong,
    date: [*:0]const u8,
    desc_len: c_ulong,
    desc: [*:0]const u8,
};

pub const Unique = extern struct {
    unique_len: c_ulong,
    unique: [*:0]const u8,
};

pub const Auth = extern struct {
    magic: Magic,
};

pub const IrqBusid = extern struct {
    irq: c_int,
    busnum: c_int,
    devnum: c_int,
    funcnum: c_int,
};

pub const Map = extern struct {
    offset: c_ulong,
    size: c_ulong,
    type: MapType,
    flags: MapFlags,
    handle: *anyopaque,
    mtrr: c_int,
};

pub const MapType = enum(c_int) {
    frame_buffer = 0,
    registers = 1,
    shm = 2,
    agp = 3,
    scatter_gather = 4,
    consistent = 5,
};

pub const MapFlags = packed struct(c_int) {
    restricted: bool = false,
    read_only: bool = false,
    locked: bool = false,
    kernel: bool = false,
    write_combining: bool = false,
    contains_lock: bool = false,
    removable: bool = false,
    driver: bool = false,
    _: @Int(.signed, @bitSizeOf(c_int) - 8) = 0,
};

pub const Client = extern struct {
    idx: c_int,
    auth: c_int,
    pid: c_ulong,
    uid: c_ulong,
    magic: Magic,
    iocs: c_ulong,
};

pub const Stats = extern struct {
    count: c_ulong,
    data: [15]Stat,
};

pub const Stat = extern struct {
    value: c_ulong,
    type: StatType,
};

pub const StatType = enum(c_int) {
    lock,
    opens,
    closes,
    ioctls,
    locks,
    unlocks,
    value,
    byte,
    count,
    irq,
    primary,
    secondary,
    dma,
    special,
    missed,
};

pub const SetVersion = extern struct {
    di_major: c_int,
    di_minor: c_int,
    dd_major: c_int,
    dd_minor: c_int,
};

pub const GetCap = extern struct {
    capability: Capability,
    value: u64,
};

pub const Capability = enum(u64) {
    dumb_buffer = 0x1,
    vblank_high_crtc = 0x2,
    dumb_preferred_depth = 0x3,
    dumb_buffer_shadow = 0x4,
    prime = 0x5,
    timestamp_monotonic = 0x6,
    async_page_flip = 0x7,
    cursor_width = 0x8,
    cursor_height = 0x9,
    addfbd_modifiers = 0x10,
    page_flip_target = 0x11,
    crtc_in_vblank_event = 0x12,
    syncobj = 0x13,
    syncobj_timeline = 0x14,
    atomic_async_page_flip = 0x15,
};

pub const SetClientCap = extern struct {
    capability: ClientCapability,
    value: u64,
};

pub const ClientCapability = enum(u64) {
    stereo_3d = 1,
    universal_planes = 2,
    atomic = 3,
    aspect_ratio = 4,
    writeback_connectors = 5,
    cursor_plane_hotspot = 6,
};

pub const Ctx = extern struct {
    handle: Context,
    flags: CtxFlags,
};

pub const CtxFlags = packed struct(c_int) {
    preserved: bool = false,
    @"2d_only": bool = false,
    _: @Int(.signed, @bitSizeOf(c_int) - 2) = 0,
};

pub const CtxRes = extern struct {
    count: c_int,
    contexts: [*]Ctx,
};

pub const Event = extern struct {
    type: EventType,
    length: u32,
};

pub const EventType = enum(u32) {
    vblank = 0x01,
    flip_complete = 0x02,
    crtc_sequence = 0x03,
};

pub const EventVblank = extern struct {
    base: Event,
    user_data: u64,
    tv_sec: u32,
    tv_usec: u32,
    sequence: u32,
    crtc_id: u32,
};

pub const EventCrtcSequence = extern struct {
    base: Event,
    user_data: u64,
    time_ns: i64,
    sequence: u64,
};

pub const mode = struct {
    pub const display_mode_len = 32;
    pub const prop_name_len = 32;

    pub const CardRes = extern struct {
        fb_id_ptr: u64,
        crtc_id_ptr: u64,
        connector_id_ptr: u64,
        encoder_id_ptr: u64,
        count_fbs: u32,
        count_crtcs: u32,
        count_connectors: u32,
        count_encoders: u32,
        min_width: u32,
        max_width: u32,
        min_height: u32,
        max_height: u32,
    };

    pub const Crtc = extern struct {
        set_connectors_ptr: u64,
        count_connectors: u32,
        crtc_id: u32,
        fb_id: u32,
        x: u32,
        y: u32,
        gamma_size: u32,
        mode_valid: u32,
        mode: ModeInfo,
    };

    pub const CrtcLut = extern struct {
        crtc_id: u32,
        gamma_size: u32,
        red: u64,
        green: u64,
        blue: u64,
    };

    pub const ModeInfo = extern struct {
        clock: u32,
        hdisplay: u16,
        hsync_start: u16,
        hsync_end: u16,
        htotal: u16,
        hskew: u16,
        vdisplay: u16,
        vsync_start: u16,
        vsync_end: u16,
        vtotal: u16,
        vscan: u16,
        vrefresh: u32,
        flags: ModeFlags,
        type: ModeType,

        name: [display_mode_len]u8,
    };

    pub const ModeType = packed struct(u32) {
        _deprecated0: u1 = 0,
        _deprecated1: u1 = 0,
        _deprecated2: u1 = 0,
        preferred: bool = false,
        _deprecated4: u1 = 0,
        userdef: bool = false,
        driver: bool = false,
        _: u25 = 0,
    };

    pub const ModeFlags = packed struct(u32) {
        phsync: bool = false,
        nhsync: bool = false,
        pvsync: bool = false,
        nvsync: bool = false,
        interlace: bool = false,
        dblscan: bool = false,
        csync: bool = false,
        pcsync: bool = false,
        ncsync: bool = false,
        hskew: bool = false,
        _deprecated10: u1 = 0,
        _deprecated11: u1 = 0,
        dblclk: bool = false,
        clkdiv2: bool = false,
        _: u18 = 0,
    };

    pub const Cursor = extern struct {
        flags: u32,
        crtc_id: u32,
        x: i32,
        y: i32,
        width: u32,
        height: u32,
        handle: u32,
    };

    pub const GetEncoder = extern struct {
        encoder_id: u32,
        encoder_type: EncoderType,
        crtc_id: u32,
        possible_crtcs: u32,
        possible_clones: u32,
    };

    pub const EncoderType = enum(u32) {
        none = 0,
        dac = 1,
        tmds = 2,
        lvds = 3,
        tvdac = 4,
        virtual = 5,
        dsi = 6,
        dpmst = 7,
        dpi = 8,
    };

    pub const GetConnector = extern struct {
        encoders_ptr: u64,
        modes_ptr: u64,
        props_ptr: u64,
        prop_values_ptr: u64,
        count_modes: u32,
        count_props: u32,
        count_encoders: u32,
        encoder_id: u32,
        connector_id: u32,
        connector_type: ConnectorType,
        connector_type_id: u32,
        connection: u32,
        mm_width: u32,
        mm_height: u32,
        subpixel: u32,
        pad: u32,
    };

    pub const ConnectorType = enum(u32) {
        unknown = 0,
        vga = 1,
        dvi_i = 2,
        dvi_d = 3,
        dvi_a = 4,
        composite = 5,
        svideo = 6,
        lvds = 7,
        component = 8,
        din = 9,
        display_port = 10,
        hdmi_a = 11,
        hdmi_b = 12,
        tv = 13,
        e_dp = 14,
        virtual = 15,
        dsi = 16,
        dpi = 17,
        writeback = 18,
        spi = 19,
        usb = 20,
    };

    pub const GetProperty = extern struct {
        values_ptr: u64,
        enum_blob_ptr: u64,
        prop_id: u32,
        flags: u32,
        name: [prop_name_len]u8,
        count_values: u32,
        count_enum_blobs: u32,
    };

    pub const ConnectorSetProperty = extern struct {
        value: u64,
        prop_id: u32,
        connector_id: u32,
    };

    pub const GetBlob = extern struct {
        blob_id: u32,
        length: u32,
        data: u64,
    };

    pub const FbCmd = extern struct {
        fb_id: u32,
        width: u32,
        height: u32,
        pitch: u32,
        bpp: u32,
        depth: u32,
        handle: u32,
    };

    pub const CrtcPageFlip = extern struct {
        crtc_id: u32,
        fb_id: u32,
        flags: PageFlipFlags,
        reserved: u32,
        user_data: u64,
    };

    pub const PageFlipFlags = packed struct(u32) {
        event: bool = false,
        async: bool = false,
        target_absolute: bool = false,
        target_relative: bool = false,
        _: u28 = 0,
    };

    pub const FbDirtyCmd = extern struct {
        fb_id: u32,
        flags: u32,
        color: u32,
        num_clips: u32,
        clips_ptr: u64,
    };

    pub const CreateDumb = extern struct {
        height: u32,
        width: u32,
        bpp: u32,
        flags: u32,
        handle: u32,
        pitch: u32,
        size: u64,
    };

    pub const MapDumb = extern struct {
        handle: u32,
        pad: u32,
        offset: u64,
    };

    pub const DestroyDumb = extern struct {
        handle: u32,
    };

    pub const GetPlaneRes = extern struct {
        plane_id_ptr: u64,
        count_planes: u32,
    };

    pub const GetPlane = extern struct {
        plane_id: u32,
        crtc_id: u32,
        fb_id: u32,
        possible_crtcs: u32,
        gamma_size: u32,
        count_format_types: u32,
        format_type_ptr: u64,
    };

    pub const SetPlane = extern struct {
        plane_id: u32,
        crtc_id: u32,
        fb_id: u32,
        flags: u32,
        crtc_x: i32,
        crtc_y: i32,
        crtc_w: u32,
        crtc_h: u32,
        src_x: u32,
        src_y: u32,
        src_h: u32,
        src_w: u32,
    };

    pub const FbCmd2 = extern struct {
        fb_id: u32,
        width: u32,
        height: u32,
        pixel_format: u32,
        flags: u32,
        handles: [4]u32,
        pitches: [4]u32,
        offsets: [4]u32,
        modifiers: [4]u64,
    };

    pub const ObjGetProperties = extern struct {
        props_ptr: u64,
        prop_values_ptr: u64,
        count_props: u32,
        obj_id: u32,
        obj_type: ObjType,
    };

    pub const ObjType = enum(u32) {
        crtc = 0xcccccccc,
        connector = 0xc0c0c0c0,
        encoder = 0xe0e0e0e0,
        mode = 0xdededede,
        property = 0xb0b0b0b0,
        fb = 0xfbfbfbfb,
        blob = 0xbbbbbbbb,
        plane = 0xeeeeeeee,
        any = 0,
    };

    pub const ObjSetProperty = extern struct {
        value: u64,
        prop_id: u32,
        obj_id: u32,
        obj_type: u32,
    };

    pub const Cursor2 = extern struct {
        flags: u32,
        crtc_id: u32,
        x: i32,
        y: i32,
        width: u32,
        height: u32,
        handle: u32,
        hot_x: i32,
        hot_y: i32,
    };

    pub const Atomic = extern struct {
        flags: u32,
        count_objs: u32,
        objs_ptr: u64,
        count_props_ptr: u64,
        props_ptr: u64,
        prop_values_ptr: u64,
        reserved: u64,
        user_data: u64,
    };

    pub const CreateBlob = extern struct {
        data: u64,
        length: u32,
        blob_id: u32,
    };

    pub const DestroyBlob = extern struct {
        blob_id: u32,
    };

    pub const CreateLease = extern struct {
        object_ids: u64,
        object_count: u32,
        flags: u32,
        lessee_id: u32,
        fd: u32,
    };

    pub const ListLessees = extern struct {
        count_lessees: u32,
        pad: u32,
        lessees_ptr: u64,
    };

    pub const GetLease = extern struct {
        count_objects: u32,
        pad: u32,
        objects_ptr: u64,
    };

    pub const RevokeLease = extern struct {
        lessee_id: u32,
    };

    pub const CloseFb = extern struct {
        fb_id: u32,
        pad: u32,
    };
};
