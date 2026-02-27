const std = @import("std");
const fmt = @import("format.zig");
const log = std.log.scoped(.drm);

pub const sys = @import("sys.zig");
pub const Format = fmt.Format;
pub const FormatModifiers = fmt.FormatModifiers;
pub const ModeInfo = sys.mode.ModeInfo;

pub fn nodeIsDrm(io: std.Io, major: u32, minor: u32) bool {
    const drm_node_path_format = "/sys/dev/char/{d}:{d}/device/drm";

    var path_buf: [64]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, drm_node_path_format, .{ major, minor }) catch unreachable;

    _ = std.Io.Dir.cwd().statFile(io, path, .{}) catch return false;

    return true;
}

pub fn parseSubsystemType(io: std.Io, major: u32, minor: u32) !sys.BusType {
    var path_buf: [std.os.linux.PATH_MAX]u8 = undefined;
    var path = std.ArrayList(u8).initBuffer(&path_buf);
    path.printAssumeCapacity("/sys/dev/char/{d}:{d}/device", .{major, minor});
    path.appendSliceAssumeCapacity("/subsystem");

    const bus_types = [_]struct{name: []const u8, bus_type: sys.BusType}{
        .{ .name = "/pci", .bus_type = .pci },
        .{ .name = "/usb", .bus_type = .usb },
        .{ .name = "/platform", .bus_type = .platform },
        .{ .name = "/spi", .bus_type = .platform },
        .{ .name = "/host1x", .bus_type = .host1x },
        .{ .name = "/virtio", .bus_type = .virtio },
        .{ .name = "/faux", .bus_type = .faux },
    };

    var link_buf: [std.os.linux.PATH_MAX]u8 = undefined;
    const link_len = try std.Io.Dir.cwd().readLink(io, path.items, &link_buf);
    const link = link_buf[0..link_len];

    const last = std.mem.findScalarLast(u8, link, '/') orelse unreachable;
    const name = link[last..];
    if (name.len == 0) return error.InvalidDevice;

    const bus_type = for (bus_types) |bus_type| {
        if (std.mem.eql(u8, bus_type.name, name)) break bus_type;
    } else return error.InvalidDevice;

    /* Try to get the parent (underlying) device type */
    if (subsystem_type == DRM_BUS_VIRTIO) {
        /* Assume virtio-pci on error */
        if (!realpath(path, real_path))
            return DRM_BUS_VIRTIO;
        strncat(path, "/..", PATH_MAX);
        subsystem_type = get_subsystem_type(path);
        if (subsystem_type < 0)
            return DRM_BUS_VIRTIO;
     }
    return subsystem_type;
}

pub const Device = struct {
    nodes: [3][]const u8,
    available_nodes: packed struct(u3) {
        primary: bool = false,
        /// Deprecated
        control: bool = false,
        render: bool = false,
    },
    bus_info: union(sys.BusType) {
        pci: sys.PciBusInfo,
        usb: sys.UsbBusInfo,
        platform: sys.PlatformBusInfo,
        host1x: sys.Host1xBusInfo,
        faux: sys.FauxBusInfo,
    },
    device_info: union(sys.BusType) {
        pci: sys.PciDeviceInfo,
        usb: sys.UsbDeviceInfo,
        platform: sys.PlatformDeviceInfo,
        host1x: sys.Host1xDeviceInfo,
        faux: sys.FauxDeviceInfo,
    },

    pub const GetFromDevIdFlags = packed struct {
        get_pci_revision: bool = false,
    };

    const dev_t = std.posix.dev_t;
    pub fn devMajor(dev: dev_t) u32 {
        return ((dev & @as(dev_t, 0x00000000000fff00)) >> 8) |
            ((dev & @as(dev_t, 0xfffff00000000000)) >> 32);
    }

    pub fn devMinor(dev: dev_t) u32 {
        return ((dev & @as(dev_t, 0x00000000000000ff)) >> 0) |
            ((dev & @as(dev_t, 0x00000ffffff00000)) >> 12);
    }

    pub fn makeDev(major: u32, minor: u32) dev_t {
        return (@as(dev_t, major & 0x00000fff) << 8) |
            (@as(dev_t, major & 0xfffff000) << 32) |
            (@as(dev_t, minor & 0x000000ff) << 0) |
            (@as(dev_t, minor & 0xffffff00) << 12);
    }

    pub fn getFromDevId(io: std.Io, devid: std.posix.dev_t, flags: GetFromDevIdFlags) !Device {
        var local_devices: [256]Device = undefined;

        const major = devMajor(devid);
        const minor = devMinor(devid);

        if (!nodeIsDrm(io, major, minor))
            return error.NotDrmDevice;

        // subsystem_type = drmParseSubsystemType(maj, min);
        // if (subsystem_type < 0)
        //     return subsystem_type;

        // sysdir = opendir(DRM_DIR_NAME);
        // if (!sysdir)
        //     return -errno;

        // i = 0;
        // while ((dent = readdir(sysdir))) {
        //     ret = process_device(&d, dent->d_name, subsystem_type, true, flags);
        //     if (ret)
        //         continue;

        //     if (i >= MAX_DRM_NODES) {
        //         fprintf(stderr, "More than %d drm nodes detected. "
        //                 "Please report a bug - that should not happen.\n"
        //                 "Skipping extra nodes\n", MAX_DRM_NODES);
        //         break;
        //     }
        //     local_devices[i] = d;
        //     i++;
        // }
        // node_count = i;

        // drmFoldDuplicatedDevices(local_devices, node_count);

        // *device = NULL;

        // for (i = 0; i < node_count; i++) {
        //     if (!local_devices[i])
        //         continue;

        //     if (drm_device_has_rdev(local_devices[i], find_rdev))
        //         *device = local_devices[i];
        //     else
        //         drmFreeDevice(&local_devices[i]);
        // }

        // closedir(sysdir);
        // if (*device == NULL)
        //     return -ENODEV;
        // return 0;
    }
};

pub const Card = struct {
    handle: std.Io.File,

    pub const OpenError = std.Io.File.OpenError || std.Io.Dir.OpenError;

    pub fn open(io: std.Io, path: []const u8) OpenError!Card {
        if (std.fs.path.isAbsolute(path))
            return Card{ .handle = try std.Io.Dir.openFileAbsolute(io, path, .{ .mode = .read_write }) };

        const dir = try std.Io.Dir.openDirAbsolute(io, "/dev/dri", .{});
        defer dir.close(io);

        return Card{ .handle = try dir.openFile(io, path, .{ .mode = .read_write }) };
    }

    pub const OpenAutoError = OpenError || std.Io.Dir.Iterator.Error || error{NoDevicesFound};

    pub fn openAuto(io: std.Io) OpenAutoError!Card {
        const dir = try std.Io.Dir.openDirAbsolute(io, "/dev/dri", .{ .iterate = true });
        defer dir.close(io);

        var it = dir.iterateAssumeFirstIteration();
        while (try it.next(io)) |entry| if (entry.kind == .character_device)
            return Card{ .handle = try dir.openFile(io, entry.name, .{ .mode = .read_write }) };

        return error.NoDevicesFound;
    }

    pub fn close(self: Card, io: std.Io) void {
        self.handle.close(io);
    }

    pub fn handleEvents(
        self: Card,
        io: std.Io,
        callback: fn (Card, Event, anytype) anyerror!void,
        args: anytype,
    ) anyerror!void {
        var buf: [4096]u8 = undefined;
        const read = try self.handle.readStreaming(io, &.{&buf});
        if (read == 0) return error.EndOfStream;

        var offset: usize = 0;
        while (offset < read) {
            if (read - offset < @sizeOf(sys.Event)) return error.IncompleteEvent;

            const ev: *align(1) const sys.Event = std.mem.bytesAsValue(
                sys.Event,
                buf[offset..][0..@sizeOf(sys.Event)],
            );

            offset += ev.length;

            const event = Event.parse(ev);
            try callback(self, event, args);
        }
    }

    pub fn setClientCapability(self: Card, capability: sys.ClientCapability, value: u64) sys.IoctlError!void {
        var set_cap = sys.SetClientCap{
            .capability = capability,
            .value = value,
        };
        try sys.ioctl(self.handle.handle, .set_client_cap, &set_cap);
    }

    pub fn getCapability(self: Card, capability: sys.Capability) sys.IoctlError!u64 {
        var get_cap = sys.GetCap{
            .capability = capability,
            .value = 0,
        };
        try sys.ioctl(self.handle.handle, .get_cap, &get_cap);
        return get_cap.value;
    }

    pub fn createModesettingPropertyBlob(self: Card, data: []const u8) sys.IoctlError!u32 {
        var create = std.mem.zeroInit(sys.mode.CreateBlob, .{
            .length = @as(u32, @intCast(data.len)),
            .data = @intFromPtr(data.ptr),
        });
        try sys.ioctl(self.handle.handle, .mode_createpropblob, &create);
        return create.blob_id;
    }

    // BEGIN MODESETTING API

    pub const GetResourcesError = sys.IoctlError || error{OutOfMemory};

    pub fn getModesettingResourcesAlloc(
        self: Card,
        gpa: std.mem.Allocator,
    ) GetResourcesError!ModesettingResources {
        while (true) {
            var res = std.mem.zeroes(sys.mode.CardRes);
            try sys.ioctl(self.handle.handle, .mode_getresources, &res);

            var ret = ModesettingResources{
                .min_width = res.min_width,
                .max_width = res.max_width,
                .min_height = res.min_height,
                .max_height = res.max_height,
                .fbs = &.{},
                .crtcs = &.{},
                .connectors = &.{},
                .encoders = &.{},
            };

            ret.fbs = try gpa.alloc(u32, res.count_fbs);
            errdefer gpa.free(ret.fbs);
            res.fb_id_ptr = @intFromPtr(ret.fbs.ptr);

            ret.crtcs = try gpa.alloc(u32, res.count_crtcs);
            errdefer gpa.free(ret.crtcs);
            res.crtc_id_ptr = @intFromPtr(ret.crtcs.ptr);

            ret.connectors = try gpa.alloc(u32, res.count_connectors);
            errdefer gpa.free(ret.connectors);
            res.connector_id_ptr = @intFromPtr(ret.connectors.ptr);

            ret.encoders = try gpa.alloc(u32, res.count_encoders);
            errdefer gpa.free(ret.encoders);
            res.encoder_id_ptr = @intFromPtr(ret.encoders.ptr);

            const cached = res;
            try sys.ioctl(self.handle.handle, .mode_getresources, &res);

            if (cached.count_fbs < res.count_fbs or
                cached.count_crtcs < res.count_crtcs or
                cached.count_connectors < res.count_connectors or
                cached.count_encoders < res.count_encoders)
            {
                gpa.free(ret.encoders);
                gpa.free(ret.connectors);
                gpa.free(ret.crtcs);
                gpa.free(ret.fbs);
                continue;
            }

            return ret;
        }
    }

    pub fn getModesettingResourcesBuffered(
        self: Card,
        fbs: []u32,
        crtcs: []u32,
        connectors: []u32,
        encoders: []u32,
    ) GetResourcesError!ModesettingResources {
        var res = sys.mode.CardRes{
            .min_width = 0,
            .max_width = 0,
            .min_height = 0,
            .max_height = 0,
            .count_fbs = @intCast(fbs.len),
            .fb_id_ptr = @intFromPtr(fbs.ptr),
            .count_crtcs = @intCast(crtcs.len),
            .crtc_id_ptr = @intFromPtr(crtcs.ptr),
            .count_connectors = @intCast(connectors.len),
            .connector_id_ptr = @intFromPtr(connectors.ptr),
            .count_encoders = @intCast(encoders.len),
            .encoder_id_ptr = @intFromPtr(encoders.ptr),
        };
        try sys.ioctl(self.handle.handle, .mode_getresources, &res);

        if (res.count_fbs > fbs.len or
            res.count_crtcs > crtcs.len or
            res.count_connectors > connectors.len or
            res.count_encoders > encoders.len)
            return error.OutOfMemory;

        return ModesettingResources{
            .min_width = res.min_width,
            .max_width = res.max_width,
            .min_height = res.min_height,
            .max_height = res.max_height,
            .fbs = fbs[0..res.count_fbs],
            .crtcs = crtcs[0..res.count_crtcs],
            .connectors = connectors[0..res.count_connectors],
            .encoders = encoders[0..res.count_encoders],
        };
    }

    pub const GetConnectorError = sys.IoctlError || error{OutOfMemory};

    pub fn getConnectorAlloc(self: Card, gpa: std.mem.Allocator, id: u32) GetConnectorError!Connector {
        while (true) {
            var get_conn = std.mem.zeroInit(sys.mode.GetConnector, .{ .connector_id = id });
            try sys.ioctl(self.handle.handle, .mode_getconnector, &get_conn);
            const cached = get_conn;

            const encoders = try gpa.alloc(u32, get_conn.count_encoders);
            errdefer gpa.free(encoders);

            const modes = try gpa.alloc(sys.mode.ModeInfo, get_conn.count_modes);
            errdefer gpa.free(modes);

            const props = try gpa.alloc(u32, get_conn.count_props);
            errdefer gpa.free(props);
            const prop_values = try gpa.alloc(u64, get_conn.count_props);
            errdefer gpa.free(prop_values);

            get_conn.encoders_ptr = @intFromPtr(encoders.ptr);
            get_conn.modes_ptr = @intFromPtr(modes.ptr);
            get_conn.props_ptr = @intFromPtr(props.ptr);
            get_conn.prop_values_ptr = @intFromPtr(prop_values.ptr);

            try sys.ioctl(self.handle.handle, .mode_getconnector, &get_conn);

            if (cached.count_encoders < get_conn.count_encoders or
                cached.count_modes < get_conn.count_modes or
                cached.count_props < get_conn.count_props)
            {
                gpa.free(prop_values);
                gpa.free(props);
                gpa.free(modes);
                gpa.free(encoders);
                continue;
            }

            return Connector{
                .id = id,
                .encoder_id = get_conn.encoder_id,
                .connection = @enumFromInt(get_conn.connection),
                // Unsure why libdrm does this conversion,
                // but we'll follow suite for compatability.
                .subpixel = @enumFromInt(get_conn.subpixel + 1),
                .encoders = encoders[0..get_conn.count_encoders],
                .modes = modes[0..get_conn.count_modes],
                .props = props[0..get_conn.count_props],
                .prop_values = prop_values[0..get_conn.count_props],
                .mm_width = get_conn.mm_width,
                .mm_height = get_conn.mm_height,
                .type = get_conn.connector_type,
                .type_id = get_conn.connector_type_id,
            };
        }
    }

    pub fn getConnectorBuffered(
        self: Card,
        encoders: []u32,
        modes: []sys.mode.ModeInfo,
        props: []u32,
        prop_values: []u64,
        id: u32,
    ) GetConnectorError!Connector {
        std.debug.assert(props.len == prop_values.len);
        var get_conn = std.mem.zeroInit(sys.mode.GetConnector, .{
            .connector_id = id,
            .count_encoders = @as(u32, @intCast(encoders.len)),
            .encoders_ptr = @intFromPtr(encoders.ptr),
            .count_modes = @as(u32, @intCast(modes.len)),
            .modes_ptr = @intFromPtr(modes.ptr),
            .count_props = @as(u32, @intCast(props.len)),
            .props_ptr = @intFromPtr(props.ptr),
            .prop_values_ptr = @intFromPtr(prop_values.ptr),
        });
        try sys.ioctl(self.handle.handle, .mode_getconnector, &get_conn);

        if (get_conn.count_encoders > encoders.len or
            get_conn.count_modes > modes.len or
            get_conn.count_props > props.len)
            return error.OutOfMemory;

        return Connector{
            .id = id,
            .encoder_id = get_conn.encoder_id,
            .connection = @enumFromInt(get_conn.connection),
            .subpixel = @enumFromInt(get_conn.subpixel + 1),
            .encoders = encoders[0..get_conn.count_encoders],
            .modes = modes[0..get_conn.count_modes],
            .props = props[0..get_conn.count_props],
            .prop_values = prop_values[0..get_conn.count_props],
            .mm_width = get_conn.mm_width,
            .mm_height = get_conn.mm_height,
            .type = get_conn.connector_type,
            .type_id = get_conn.connector_type_id,
        };
    }

    pub fn getEncoder(self: Card, id: u32) sys.IoctlError!Encoder {
        var get_encoder = std.mem.zeroInit(sys.mode.GetEncoder, .{ .encoder_id = id });
        try sys.ioctl(self.handle.handle, .mode_getencoder, &get_encoder);

        return Encoder{
            .id = id,
            .type = get_encoder.encoder_type,
            .crtc_id = get_encoder.crtc_id,
            .possible_crtcs = get_encoder.possible_crtcs,
            .possible_clones = get_encoder.possible_clones,
        };
    }

    pub const GetCrtcError = sys.IoctlError;

    pub fn getCrtc(self: Card, id: u32) GetCrtcError!Crtc {
        var crtc = std.mem.zeroInit(sys.mode.Crtc, .{ .crtc_id = id });
        try sys.ioctl(self.handle.handle, .mode_getcrtc, &crtc);

        return Crtc{
            .id = id,
            .fb_id = crtc.fb_id,
            .x = crtc.x,
            .y = crtc.y,
            .gamma_size = crtc.gamma_size,
            .mode = if (crtc.mode_valid != 0) crtc.mode else null,
        };
    }

    pub fn setCrtc(
        self: Card,
        id: u32,
        fb_id: u32,
        x: u32,
        y: u32,
        connectors: []u32,
        mode: ?sys.mode.ModeInfo,
    ) sys.IoctlError!void {
        var crtc = std.mem.zeroInit(sys.mode.Crtc, .{
            .crtc_id = id,
            .fb_id = fb_id,
            .x = x,
            .y = y,
            .count_connectors = @as(u32, @intCast(connectors.len)),
            .set_connectors_ptr = @intFromPtr(connectors.ptr),
        });
        if (mode) |m| {
            crtc.mode_valid = 1;
            crtc.mode = m;
        }
        try sys.ioctl(self.handle.handle, .mode_setcrtc, &crtc);
    }

    pub fn createDumbBuffer(self: Card, width: u32, height: u32, bpp: u32) sys.IoctlError!DumbBuffer {
        var create = std.mem.zeroInit(sys.mode.CreateDumb, .{
            .width = width,
            .height = height,
            .bpp = bpp,
        });
        try sys.ioctl(self.handle.handle, .mode_create_dumb, &create);

        return DumbBuffer{
            .handle = create.handle,
            .width = create.width,
            .height = create.height,
            .stride = create.pitch,
            .size = @intCast(create.size),
        };
    }

    pub fn destroyDumbBuffer(self: Card, handle: u32) sys.IoctlError!void {
        var destroy = sys.mode.DestroyDumb{ .handle = handle };
        try sys.ioctl(self.handle.handle, .mode_destroy_dumb, &destroy);
    }

    pub fn mapDumbBuffer(self: Card, dumb: DumbBuffer, offset: usize) sys.IoctlError!usize {
        var map = sys.mode.MapDumb{ .handle = dumb.handle, .pad = 0, .offset = offset };
        try sys.ioctl(self.handle.handle, .mode_map_dumb, &map);
        return @intCast(map.offset);
    }

    pub fn addFb2(
        self: Card,
        width: u32,
        height: u32,
        format: fmt.Format,
        handles: [4]u32,
        pitches: [4]u32,
        offsets: [4]u32,
        flags: u32, // FIXME: add flags type
    ) sys.IoctlError!u32 {
        var cmd = std.mem.zeroInit(sys.mode.FbCmd2, .{
            .width = width,
            .height = height,
            .pixel_format = @intFromEnum(format),
            .handles = handles,
            .pitches = pitches,
            .offsets = offsets,
            .flags = flags,
        });
        try sys.ioctl(self.handle.handle, .mode_addfb2, &cmd);
        return cmd.fb_id;
    }

    pub fn removeFb(self: Card, fb: u32) sys.IoctlError!void {
        try sys.ioctl(self.handle.handle, .mode_rmfb, &fb);
    }

    pub fn pageFlip(
        self: Card,
        crtc_id: u32,
        fb_id: u32,
        flags: sys.mode.PageFlipFlags,
        data: ?*anyopaque,
    ) sys.IoctlError!void {
        var flip = sys.mode.CrtcPageFlip{
            .crtc_id = crtc_id,
            .fb_id = fb_id,
            .flags = flags,
            .reserved = 0,
            .user_data = @intFromPtr(data),
        };
        try sys.ioctl(self.handle.handle, .mode_page_flip, &flip);
    }

    pub const GetPlaneResourcesError = sys.IoctlError || error{OutOfMemory};

    pub fn getPlaneResourcesAlloc(self: Card, gpa: std.mem.Allocator) GetPlaneResourcesError!PlaneResources {
        while (true) {
            var res = std.mem.zeroes(sys.mode.GetPlaneRes);
            try sys.ioctl(self.handle.handle, .mode_getplaneresources, &res);
            const cached = res;

            const planes = try gpa.alloc(u32, res.count_planes);
            errdefer gpa.free(planes);
            res.plane_id_ptr = @intFromPtr(planes.ptr);

            try sys.ioctl(self.handle.handle, .mode_getplaneresources, &res);
            if (res.count_planes > cached.count_planes) {
                gpa.free(planes);
                continue;
            }

            return PlaneResources{ .planes = planes };
        }
    }

    pub fn getPlaneResourcesBuffered(self: Card, plane_buf: []u32) GetPlaneResourcesError!PlaneResources {
        var res = sys.mode.GetPlaneRes{
            .count_planes = plane_buf.len,
            .plane_id_ptr = @intFromPtr(plane_buf.ptr),
        };
        try sys.ioctl(self.handle.handle, .mode_getplaneresources, &res);
        if (res.count_planes > plane_buf.len) return error.OutOfMemory;
        return PlaneResources{ .planes = plane_buf[0..res.count_planes] };
    }

    pub const GetPlaneError = sys.IoctlError || error{OutOfMemory};

    pub fn getPlaneAlloc(self: Card, gpa: std.mem.Allocator, id: u32) GetPlaneError!Plane {
        while (true) {
            var get = std.mem.zeroInit(sys.mode.GetPlane, .{ .plane_id = id });
            try sys.ioctl(self.handle.handle, .mode_getplane, &get);
            const cached = get;

            const formats = try gpa.alloc(u32, get.count_format_types);
            errdefer gpa.free(formats);
            get.format_type_ptr = @intFromPtr(formats.ptr);

            try sys.ioctl(self.handle.handle, .mode_getplane, &get);
            if (get.count_format_types > cached.count_format_types) {
                gpa.free(formats);
                continue;
            }

            return Plane{
                .id = id,
                .formats = formats,
                .crtc_id = get.crtc_id,
                .fb_id = get.fb_id,
                .crtc_x = 0,
                .crtc_y = 0,
                .x = 0,
                .y = 0,
                .possible_crtcs = get.possible_crtcs,
                .gamma_size = get.gamma_size,
            };
        }
    }

    pub fn getPlaneBuffered(self: Card, format_buf: []u32, id: u32) GetPlaneError!Plane {
        var get = std.mem.zeroInit(sys.mode.GetPlane, .{
            .plane_id = id,
            .count_format_types = format_buf.len,
            .format_types_ptr = @intFromPtr(format_buf.ptr),
        });

        try sys.ioctl(self.handle.handle, .mode_getplane, &get);
        if (get.count_format_types > format_buf.len) return error.OutOfMemory;

        return Plane{
            .id = id,
            .formats = format_buf[0..get.count_format_types],
            .crtc_id = get.crtc_id,
            .fb_id = get.fb_id,
            .crtc_x = 0,
            .crtc_y = 0,
            .x = 0,
            .y = 0,
            .possible_crtcs = get.possible_crtcs,
            .gamma_size = get.gamma_size,
        };
    }

    pub const GetObjectPropertiesError = sys.IoctlError || error{OutOfMemory};

    pub fn getObjectPropertiesAlloc(
        self: Card,
        gpa: std.mem.Allocator,
        object_id: u32,
        object_type: sys.mode.ObjType,
    ) GetObjectPropertiesError!ObjectProperties {
        while (true) {
            var get = std.mem.zeroInit(sys.mode.ObjGetProperties, .{
                .obj_id = object_id,
                .obj_type = object_type,
            });
            try sys.ioctl(self.handle.handle, .mode_obj_getproperties, &get);
            const cached = get;

            const keys = try gpa.alloc(u32, get.count_props);
            errdefer gpa.free(keys);
            get.props_ptr = keys.ptr;

            const values = try gpa.alloc(u64, get.count_props);
            errdefer gpa.free(values);
            get.prop_values_ptr = values.ptr;

            try sys.ioctl(self.handle.handle, .mode_obj_getproperties, &get);
            if (get.count_props > cached.count_props) {
                gpa.free(keys);
                gpa.free(values);
                continue;
            }

            return ObjectProperties{
                .keys = keys,
                .values = values,
            };
        }
    }

    pub fn getObjectPropertiesBuffered(
        self: Card,
        key_buf: []u32,
        value_buf: []u64,
        object_id: u32,
        object_type: sys.mode.ObjType,
    ) GetObjectPropertiesError!ObjectProperties {
        var get = sys.mode.ObjGetProperties{
            .obj_id = object_id,
            .obj_type = object_type,
            .count_props = @intCast(@min(key_buf.len, value_buf.len)),
            .props_ptr = @intFromEnum(key_buf.ptr),
            .prop_values_ptr = @intFromEnum(value_buf.ptr),
        };
        try sys.ioctl(self.handle.handle, .mode_obj_getproperties, &get);
        if (get.count_props > @min(key_buf.len, value_buf.len)) return error.OutOfMemory;

        return ObjectProperties{
            .keys = key_buf[0..get.count_props],
            .values = value_buf[0..get.count_props],
        };
    }
};

pub const Event = union(enum) {
    vblank: Vblank,
    flip_complete: Vblank,
    crtc_sequence: CrtcSequence,

    pub fn parse(event: *align(1) const sys.Event) Event {
        return switch (event.type) {
            inline .vblank, .flip_complete => |tag| @unionInit(Event, @tagName(tag), ev: {
                const vblank: *align(1) const sys.EventVblank = @ptrCast(@alignCast(event));
                break :ev .{
                    .user_data = @ptrFromInt(vblank.user_data),
                    .sec = vblank.tv_sec,
                    .usec = vblank.tv_usec,
                    .sequence = vblank.sequence,
                    .crtc_id = vblank.crtc_id,
                };
            }),
            .crtc_sequence => Event{ .crtc_sequence = ev: {
                const crtc_sequence: *align(1) const sys.EventCrtcSequence = @ptrCast(@alignCast(event));
                break :ev .{
                    .user_data = @ptrFromInt(crtc_sequence.user_data),
                    .ns = crtc_sequence.time_ns,
                    .sequence = crtc_sequence.sequence,
                };
            } },
        };
    }

    pub const Vblank = struct {
        user_data: *anyopaque,
        sec: u32,
        usec: u32,
        sequence: u32,
        crtc_id: u32,
    };

    pub const CrtcSequence = struct {
        user_data: *anyopaque,
        ns: i64,
        sequence: u64,
    };
};

pub const Connection = enum(u32) {
    connected = 1,
    disconnected = 2,
    unknown = 3,
};

pub const Subpixel = enum(u32) {
    unknown = 1,
    horizontal_rgb = 2,
    horizontal_bgr = 3,
    vertical_rgb = 4,
    vertical_bgr = 5,
    none = 6,
};

pub const ModesettingResources = struct {
    min_width: u32,
    max_width: u32,
    min_height: u32,
    max_height: u32,
    fbs: []const u32,
    crtcs: []const u32,
    connectors: []const u32,
    encoders: []const u32,

    pub fn deinit(self: ModesettingResources, gpa: std.mem.Allocator) void {
        gpa.free(self.encoders);
        gpa.free(self.connectors);
        gpa.free(self.crtcs);
        gpa.free(self.fbs);
    }
};

pub const Connector = struct {
    id: u32,
    encoder_id: u32,
    connection: Connection,
    mm_width: u32,
    mm_height: u32,
    subpixel: Subpixel,
    encoders: []const u32,
    modes: []const sys.mode.ModeInfo,
    props: []const u32,
    prop_values: []const u64,
    type: sys.mode.ConnectorType,
    type_id: u32,

    pub fn deinit(self: Connector, gpa: std.mem.Allocator) void {
        gpa.free(self.prop_values);
        gpa.free(self.props);
        gpa.free(self.modes);
        gpa.free(self.encoders);
    }
};

pub const Encoder = struct {
    id: u32,
    type: sys.mode.EncoderType,
    crtc_id: u32,
    possible_crtcs: u32,
    possible_clones: u32,
};

pub const Crtc = struct {
    id: u32,
    fb_id: u32,
    x: u32,
    y: u32,
    gamma_size: u32,
    mode: ?sys.mode.ModeInfo,
};

pub const DumbBuffer = struct {
    handle: u32,
    width: u32,
    height: u32,
    stride: u32,
    size: usize,
};

pub const PlaneResources = struct {
    planes: []const u32,

    pub fn deinit(self: PlaneResources, gpa: std.mem.Allocator) void {
        gpa.free(self.planes);
    }
};

pub const Plane = struct {
    id: u32,
    formats: []const u32,
    crtc_id: u32,
    fb_id: u32,
    crtc_x: u32,
    crtc_y: u32,
    x: u32,
    y: u32,
    possible_crtcs: u32,
    gamma_size: u32,

    pub fn deinit(self: Plane, gpa: std.mem.Allocator) void {
        gpa.free(self.formats);
    }
};

pub const ObjectProperties = struct {
    keys: []const u32,
    values: []const u64,

    pub fn deinit(self: ObjectProperties, gpa: std.mem.Allocator) void {
        gpa.free(self.keys);
        gpa.free(self.values);
    }
};

test {
    std.testing.refAllDecls(@This());
}
