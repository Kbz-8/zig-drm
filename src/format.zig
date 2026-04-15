const std = @import("std");

pub const Format = enum(u32) {
    pub const big_endian: u32 = 1 << 31;

    invalid = 0,

    c1 = fourccCode('C', '1', ' ', ' '),
    c2 = fourccCode('C', '2', ' ', ' '),
    c4 = fourccCode('C', '4', ' ', ' '),
    c8 = fourccCode('C', '8', ' ', ' '),
    d1 = fourccCode('D', '1', ' ', ' '),
    d2 = fourccCode('D', '2', ' ', ' '),
    d4 = fourccCode('D', '4', ' ', ' '),
    d8 = fourccCode('D', '8', ' ', ' '),
    r1 = fourccCode('R', '1', ' ', ' '),
    r2 = fourccCode('R', '2', ' ', ' '),
    r4 = fourccCode('R', '4', ' ', ' '),
    r8 = fourccCode('R', '8', ' ', ' '),
    r10 = fourccCode('R', '1', '0', ' '),
    r12 = fourccCode('R', '1', '2', ' '),
    r16 = fourccCode('R', '1', '6', ' '),
    rg88 = fourccCode('R', 'G', '8', '8'),
    gr88 = fourccCode('G', 'R', '8', '8'),
    rg1616 = fourccCode('R', 'G', '3', '2'),
    gr1616 = fourccCode('G', 'R', '3', '2'),
    rgb332 = fourccCode('R', 'G', 'B', '8'),
    bgr233 = fourccCode('B', 'G', 'R', '8'),
    xrgb4444 = fourccCode('X', 'R', '1', '2'),
    xbgr4444 = fourccCode('X', 'B', '1', '2'),
    rgbx4444 = fourccCode('R', 'X', '1', '2'),
    bgrx4444 = fourccCode('B', 'X', '1', '2'),
    argb4444 = fourccCode('A', 'R', '1', '2'),
    abgr4444 = fourccCode('A', 'B', '1', '2'),
    rgba4444 = fourccCode('R', 'A', '1', '2'),
    bgra4444 = fourccCode('B', 'A', '1', '2'),
    xrgb1555 = fourccCode('X', 'R', '1', '5'),
    xbgr1555 = fourccCode('X', 'B', '1', '5'),
    rgbx5551 = fourccCode('R', 'X', '1', '5'),
    bgrx5551 = fourccCode('B', 'X', '1', '5'),
    argb1555 = fourccCode('A', 'R', '1', '5'),
    abgr1555 = fourccCode('A', 'B', '1', '5'),
    rgba5551 = fourccCode('R', 'A', '1', '5'),
    bgra5551 = fourccCode('B', 'A', '1', '5'),
    rgb565 = fourccCode('R', 'G', '1', '6'),
    bgr565 = fourccCode('B', 'G', '1', '6'),
    rgb888 = fourccCode('R', 'G', '2', '4'),
    bgr888 = fourccCode('B', 'G', '2', '4'),
    xrgb8888 = fourccCode('X', 'R', '2', '4'),
    xbgr8888 = fourccCode('X', 'B', '2', '4'),
    rgbx8888 = fourccCode('R', 'X', '2', '4'),
    bgrx8888 = fourccCode('B', 'X', '2', '4'),
    argb8888 = fourccCode('A', 'R', '2', '4'),
    abgr8888 = fourccCode('A', 'B', '2', '4'),
    rgba8888 = fourccCode('R', 'A', '2', '4'),
    bgra8888 = fourccCode('B', 'A', '2', '4'),
    xrgb2101010 = fourccCode('X', 'R', '3', '0'),
    xbgr2101010 = fourccCode('X', 'B', '3', '0'),
    rgbx1010102 = fourccCode('R', 'X', '3', '0'),
    bgrx1010102 = fourccCode('B', 'X', '3', '0'),
    argb2101010 = fourccCode('A', 'R', '3', '0'),
    abgr2101010 = fourccCode('A', 'B', '3', '0'),
    rgba1010102 = fourccCode('R', 'A', '3', '0'),
    bgra1010102 = fourccCode('B', 'A', '3', '0'),
    xrgb16161616 = fourccCode('X', 'R', '4', '8'),
    xbgr16161616 = fourccCode('X', 'B', '4', '8'),
    argb16161616 = fourccCode('A', 'R', '4', '8'),
    abgr16161616 = fourccCode('A', 'B', '4', '8'),
    xrgb16161616f = fourccCode('X', 'R', '4', 'H'),
    xbgr16161616f = fourccCode('X', 'B', '4', 'H'),
    argb16161616f = fourccCode('A', 'R', '4', 'H'),
    abgr16161616f = fourccCode('A', 'B', '4', 'H'),
    axbxgxrx106106106106 = fourccCode('A', 'B', '1', '0'),
    yuyv = fourccCode('Y', 'U', 'Y', 'V'),
    yvyu = fourccCode('Y', 'V', 'Y', 'U'),
    uyvy = fourccCode('U', 'Y', 'V', 'Y'),
    vyuy = fourccCode('V', 'Y', 'U', 'Y'),
    ayuv = fourccCode('A', 'Y', 'U', 'V'),
    avuy8888 = fourccCode('A', 'V', 'U', 'Y'),
    xyuv8888 = fourccCode('X', 'Y', 'U', 'V'),
    xvuy8888 = fourccCode('X', 'V', 'U', 'Y'),
    vuy888 = fourccCode('V', 'U', '2', '4'),
    vuy101010 = fourccCode('V', 'U', '3', '0'),
    y210 = fourccCode('Y', '2', '1', '0'),
    y212 = fourccCode('Y', '2', '1', '2'),
    y216 = fourccCode('Y', '2', '1', '6'),
    y410 = fourccCode('Y', '4', '1', '0'),
    y412 = fourccCode('Y', '4', '1', '2'),
    y416 = fourccCode('Y', '4', '1', '6'),
    xvyu2101010 = fourccCode('X', 'V', '3', '0'),
    xvyu12_16161616 = fourccCode('X', 'V', '3', '6'),
    xvyu16161616 = fourccCode('X', 'V', '4', '8'),
    y0l0 = fourccCode('Y', '0', 'L', '0'),
    x0l0 = fourccCode('X', '0', 'L', '0'),
    y0l2 = fourccCode('Y', '0', 'L', '2'),
    x0l2 = fourccCode('X', '0', 'L', '2'),
    yuv420_8bit = fourccCode('Y', 'U', '0', '8'),
    yuv420_10bit = fourccCode('Y', 'U', '1', '0'),
    xrgb8888_a8 = fourccCode('X', 'R', 'A', '8'),
    xbgr8888_a8 = fourccCode('X', 'B', 'A', '8'),
    rgbx8888_a8 = fourccCode('R', 'X', 'A', '8'),
    bgrx8888_a8 = fourccCode('B', 'X', 'A', '8'),
    rgb888_a8 = fourccCode('R', '8', 'A', '8'),
    bgr888_a8 = fourccCode('B', '8', 'A', '8'),
    rgb565_a8 = fourccCode('R', '5', 'A', '8'),
    bgr565_a8 = fourccCode('B', '5', 'A', '8'),
    nv12 = fourccCode('N', 'V', '1', '2'),
    nv21 = fourccCode('N', 'V', '2', '1'),
    nv16 = fourccCode('N', 'V', '1', '6'),
    nv61 = fourccCode('N', 'V', '6', '1'),
    nv24 = fourccCode('N', 'V', '2', '4'),
    nv42 = fourccCode('N', 'V', '4', '2'),
    nv15 = fourccCode('N', 'V', '1', '5'),
    nv20 = fourccCode('N', 'V', '2', '0'),
    nv30 = fourccCode('N', 'V', '3', '0'),
    p210 = fourccCode('P', '2', '1', '0'),
    p010 = fourccCode('P', '0', '1', '0'),
    p012 = fourccCode('P', '0', '1', '2'),
    p016 = fourccCode('P', '0', '1', '6'),
    p030 = fourccCode('P', '0', '3', '0'),
    q410 = fourccCode('Q', '4', '1', '0'),
    q401 = fourccCode('Q', '4', '0', '1'),
    yuv410 = fourccCode('Y', 'U', 'V', '9'),
    yvu410 = fourccCode('Y', 'V', 'U', '9'),
    yuv411 = fourccCode('Y', 'U', '1', '1'),
    yvu411 = fourccCode('Y', 'V', '1', '1'),
    yuv420 = fourccCode('Y', 'U', '1', '2'),
    yvu420 = fourccCode('Y', 'V', '1', '2'),
    yuv422 = fourccCode('Y', 'U', '1', '6'),
    yvu422 = fourccCode('Y', 'V', '1', '6'),
    yuv444 = fourccCode('Y', 'U', '2', '4'),
    yvu444 = fourccCode('Y', 'V', '2', '4'),

    _, // Some formats involved with dmabuf aren't defined here

    pub fn getName(self: Format) [4]u8 {
        const int = @intFromEnum(self);

        return [_]u8{
            @as(u8, (int >> 0) & 0xff),
            @as(u8, (int >> 8) & 0xff),
            @as(u8, (int >> 16) & 0xff),
            @as(u8, (int >> 24) & 0xff),
        };
    }

    pub inline fn toU32(self: Format) u32 {
        return @intFromEnum(self);
    }

    fn fourccCode(a: u8, b: u8, c: u8, d: u8) u32 {
        return @as(u32, a) | (@as(u32, b) << 8) | (@as(u32, c) << 16) | (@as(u32, d) << 24);
    }
};

pub const FormatModifier = packed struct(u64) {
    raw: u56,
    vendor: Vendor,

    pub inline fn fromU64(raw: u64) FormatModifier {
        return @bitCast(raw);
    }

    pub inline fn toU64(self: FormatModifier) u64 {
        return @bitCast(self);
    }

    pub inline fn upper(self: FormatModifier) u32 {
        return @intCast((self.toU64() >> 32) & std.math.maxInt(u32));
    }

    pub inline fn lower(self: FormatModifier) u32 {
        return @intCast(self.toU64() & std.math.maxInt(u32));
    }

    pub fn format(self: FormatModifier, w: *std.Io.Writer) !void {
        const resolved = self.resolve();

        switch (resolved) {
            inline .none, .amd, .nvidia, .arm, .amlogic => |complex, tag| {
                try w.writeAll(@tagName(tag) ++ " { ");
                try complex.formatInner(w);
                try w.writeAll(" }");
            },
            inline else => |simple, tag| try w.print("{t}{{ raw = {x} (unimplemented) }}", .{ tag, simple }),
        }
    }

    pub fn resolve(self: FormatModifier) Resolved {
        return switch (self.vendor) {
            .none => .{ .none = @enumFromInt(self.raw) },
            .intel => .{ .intel = self.raw }, // TODO
            .amd => .{ .amd = .resolve(self.raw) },
            .nvidia => .{ .nvidia = .resolve(self.raw) },
            .samsung => .{ .samsung = self.raw }, // TODO
            .qualcomm => .{ .qualcomm = self.raw }, // TODO
            .vivante => .{ .vivante = self.raw }, // TODO
            .broadcom => .{ .broadcom = self.raw }, // TODO
            .arm => .{ .arm = .resolve(self.raw) },
            .allwinner => .{ .allwinner = self.raw }, // TODO
            .amlogic => .{ .amlogic = .resolve(self.raw) },
            .mtk => .{ .mtk = self.raw }, // TODO
            .apple => .{ .apple = self.raw }, // TODO
        };
    }

    pub const Vendor = enum(u8) {
        none = 0,
        intel = 0x01,
        amd = 0x02,
        nvidia = 0x03,
        samsung = 0x04,
        qualcomm = 0x05,
        vivante = 0x06,
        broadcom = 0x07,
        arm = 0x08,
        allwinner = 0x09,
        amlogic = 0x0a,
        mtk = 0x0b,
        apple = 0x0c,
    };

    pub const Resolved = union(Vendor) {
        none: None,
        intel: u56,
        amd: Amd,
        nvidia: Nvidia,
        samsung: u56,
        qualcomm: u56,
        vivante: u56,
        broadcom: u56,
        arm: Arm,
        allwinner: u56,
        amlogic: Amlogic,
        mtk: u56,
        apple: u56,
    };

    pub const None = enum(u56) {
        linear = 0,
        invalid = 0xffffffffffffff,
        _,

        pub fn formatInner(self: None, w: *std.Io.Writer) !void {
            switch (self) {
                _ => |raw| try w.print("raw = {x} (unknown)", .{raw}),
                inline else => |tag| try w.writeAll(@tagName(tag)),
            }
        }
    };

    pub const Amd = struct {
        tile: Tile,
        ddc: ?Ddc,
        pipe_xor_bits: u3,
        bank_xor_bits: u3,
        packers: u3,
        rb: u3,
        pipe: u3,

        pub fn formatInner(self: Amd, w: *std.Io.Writer) !void {
            try w.writeAll("tile = ");
            switch (self.tile) {
                .legacy => try w.writeAll("legacy,"),
                inline .gfx9, .gfx10, .gfx10_rbplus, .gfx11 => |val, tag| try w.print("{t} {t},", .{ tag, val }),
                .gfx12 => |val| try w.print("gfx12 {t},", .{val}),
            }
        }

        pub fn resolve(raw: u56) Amd {
            const tile_version: TileVersion = @enumFromInt(raw & 0xff);
            const tile_bits: u5 = @intCast((raw >> 8) & 0x1f);
            const tile = switch (tile_version) {
                inline .gfx9,
                .gfx10,
                .gfx10_rbplus,
                .gfx11,
                => |field| @unionInit(Tile, @tagName(field), @enumFromInt(tile_bits)),
                .legacy => Tile{ .legacy = {} },
                .gfx12 => Tile{ .gfx12 = @enumFromInt(tile_bits) },
            };

            const has_ddc = (raw >> 13) & 0x01 == 0x01;
            const ddc = if (has_ddc) @as(Ddc, @bitCast(@as(u7, @intCast((raw >> 14) & 0x7f)))) else null;

            const pipe_xor_bits: u3 = @intCast((raw >> 21) & 0x7);
            const bank_xor_bits: u3 = @intCast((raw >> 24) & 0x7);
            const packers: u3 = @intCast((raw >> 27) & 0x7);
            const rb: u3 = @intCast((raw >> 30) & 0x7);
            const pipe: u3 = @intCast((raw >> 33) & 0x7);

            return Amd{
                .tile = tile,
                .ddc = ddc,
                .pipe_xor_bits = pipe_xor_bits,
                .bank_xor_bits = bank_xor_bits,
                .packers = packers,
                .rb = rb,
                .pipe = pipe,
            };
        }

        pub const TileVersion = enum(u8) {
            legacy = 0,
            gfx9 = 1,
            gfx10 = 2,
            gfx10_rbplus = 3,
            gfx11 = 4,
            gfx12 = 5,
        };

        pub const Tile = union(TileVersion) {
            legacy: void,
            gfx9: Gfx9_11,
            gfx10: Gfx9_11,
            gfx10_rbplus: Gfx9_11,
            gfx11: Gfx9_11,
            gfx12: Gfx12,

            pub const Gfx9_11 = enum(u5) {
                linear = 0,
                @"256b_s" = 1,
                @"256b_d" = 2,
                @"256b_r" = 3,
                @"4kb_z" = 4,
                @"4kb_s" = 5,
                @"4kb_d" = 6,
                @"4kb_r" = 7,
                @"64kb_z" = 8,
                @"64kb_s" = 9,
                @"64kb_d" = 10,
                @"64kb_r" = 11,
                @"64kb_z_t" = 16,
                @"64kb_s_t" = 17,
                @"64kb_d_t" = 18,
                @"64kb_r_t" = 19,
                @"4kb_z_x" = 20,
                @"4kb_s_x" = 21,
                @"4kb_d_x" = 22,
                @"4kb_r_x" = 23,
                @"64kb_z_x" = 24,
                @"64kb_s_x" = 25,
                @"64kb_d_x" = 26,
                @"64kb_r_x" = 27,
                @"256kb_z_x" = 28,
                @"256kb_s_x" = 29,
                @"256kb_d_x" = 30,
                @"256kb_r_x" = 31,
            };

            pub const Gfx12 = enum(u5) {
                linear = 0,
                @"256b_2d" = 1,
                @"4kb_2d" = 2,
                @"64kb_2d" = 3,
                @"256kb_2d" = 4,
                @"4kb_3d" = 5,
                @"64kb_3d" = 6,
                @"256kb_3d" = 7,
            };
        };

        pub const Ddc = packed struct(u7) {
            retile: bool,
            pipe_align: bool,
            independent_64b: bool,
            independent_128b: bool,
            max_compressed_block: Block,
            constant_encode: bool,

            pub const Block = enum(u2) {
                @"64b" = 0,
                @"128b" = 1,
                @"256b" = 2,
            };
        };
    };

    pub const Nvidia = union(enum) {
        tegra_tiled: void,
        block_linear_16bx2_1_gob: void,
        block_linear_16bx2_2_gob: void,
        block_linear_16bx2_4_gob: void,
        block_linear_16bx2_8_gob: void,
        block_linear_16bx2_16_gob: void,
        block_linear_16bx2_32_gob: void,
        block_linear_2d: BlockLinear2D,

        pub fn formatInner(self: Nvidia, w: *std.Io.Writer) !void {
            switch (self) {
                .block_linear_2d => |bl2d| {
                    try w.print("height = {}, ", .{bl2d.height});
                    try w.print("page kind = {}, ", .{bl2d.page_kind});
                    try w.print("gob height = {t}, ", .{bl2d.gob_height});
                    try w.print("page kind generation = {t}, ", .{bl2d.page_kind_generation});
                    try w.print("sector layout = {t}, ", .{bl2d.sector_layout});
                    try w.print("compression type = {t}", .{bl2d.compression_type});
                },
                inline else => |_, tag| try w.writeAll(@tagName(tag)),
            }
        }

        pub fn resolve(raw: u56) Nvidia {
            return switch (raw) {
                1 => .tegra_tiled,
                bl2dCode(0) => .block_linear_16bx2_1_gob,
                bl2dCode(1) => .block_linear_16bx2_2_gob,
                bl2dCode(2) => .block_linear_16bx2_4_gob,
                bl2dCode(3) => .block_linear_16bx2_8_gob,
                bl2dCode(4) => .block_linear_16bx2_16_gob,
                bl2dCode(5) => .block_linear_16bx2_32_gob,
                else => |val| .{ .block_linear_2d = .fromRaw(val) },
            };
        }

        pub const BlockLinear2D = struct {
            height: u16,
            page_kind: u8,
            gob_height: GobHeight,
            page_kind_generation: PageKindGeneration,
            sector_layout: SectorLayout,
            compression_type: CompressionType,

            fn fromRaw(raw: u56) BlockLinear2D {
                const h: u4 = @intCast(raw & 0xf);
                const k: u8 = @intCast((raw >> 12) & 0xff);
                const g: u2 = @intCast((raw >> 20) & 0x3);
                const s: u1 = @intCast((raw >> 22) & 0x1);
                const c: u3 = @intCast((raw >> 23) & 0x7);

                const height: u16 = @as(u16, 1) << h;
                const page_kind: u8 = k;
                const gob_height: GobHeight = switch (g) {
                    1 => .@"4",
                    0, 2 => .@"8",
                    else => unreachable,
                };
                const page_kind_generation: PageKindGeneration = @enumFromInt(g);
                const sector_layout: SectorLayout = @enumFromInt(s);
                const compression_type: CompressionType = @enumFromInt(c);

                return BlockLinear2D{
                    .height = height,
                    .page_kind = page_kind,
                    .gob_height = gob_height,
                    .page_kind_generation = page_kind_generation,
                    .sector_layout = sector_layout,
                    .compression_type = compression_type,
                };
            }

            pub const GobHeight = enum {
                @"4",
                @"8",
                reserved,
            };

            pub const PageKindGeneration = enum {
                @"Fermi - Volta, Tegra K1+",
                @"G80 - GT2XX",
                @"Turing+",
            };

            pub const SectorLayout = enum {
                @"Tegra K1 - Tegra Parker/TX2",
                @"Desktop GPU and Tegra Xavier+",
            };

            pub const CompressionType = enum {
                none,
                @"ROP/3D, layout 1",
                @"ROP/3D, layout 2",
                @"CDE horizontal",
                @"CDE vertical",
            };
        };

        fn bl2dCode(h: u4) u56 {
            return @as(u56, h) | 0x10;
        }
    };

    pub const Arm = union(enum) {
        afbc: Afbc,
        misc: Misc,
        afrc: Afrc,

        pub fn formatInner(self: Arm, w: *std.Io.Writer) !void {
            switch (self) {
                .misc => |misc| try w.writeAll(@tagName(misc)),
                .afbc => |afbc| {
                    try w.print("block size = {t}", .{afbc.block_size});
                    if (afbc.lossless_colorspace_transform) try w.writeAll(", lossless colorspace transform");
                    if (afbc.split) try w.writeAll(", split");
                    if (afbc.sparse) try w.writeAll(", sparse");
                    if (afbc.copy_block_restrict) try w.writeAll(", copy block restrict");
                    if (afbc.tiled) try w.writeAll(", tiled");
                    if (afbc.solid_color_blocks) try w.writeAll(", solid color blocks");
                    if (afbc.double_buffer) try w.writeAll(", double buffer");
                    if (afbc.buffer_content_hints) try w.writeAll(", buffer content hints");
                    if (afbc.uncompressed_storage_mode) try w.writeAll(", uncompressed storage mode");
                },
                .afrc => |afrc| {
                    try w.print("plane 0 coding unit size = {t}, ", .{afrc.plane_0_coding_unit_size});
                    try w.print("planes 1 and 2 coding unit size = {t}, ", .{afrc.plane_1_2_coding_unit_size});
                    try w.print("scan layout = {t}", .{afrc.scan_layout});
                },
            }
        }

        pub fn resolve(raw: u56) Arm {
            const value_mask = 0xfffffffffffff;
            const value: u52 = @intCast(raw & value_mask);
            const raw_category: u4 = @intCast(raw >> 52 & 0xf);
            const category: Category = @enumFromInt(raw_category);

            return switch (category) {
                .afbc => Arm{ .afbc = @bitCast(value) },
                .misc => Arm{ .misc = @enumFromInt(value) },
                .afrc => Arm{ .afrc = @bitCast(value) },
            };
        }

        pub const Category = enum(u4) {
            afbc = 0,
            misc = 1,
            afrc = 2,
        };

        pub const Afbc = packed struct(u52) {
            block_size: BlockSize,
            lossless_colorspace_transform: bool,
            split: bool,
            sparse: bool,
            copy_block_restrict: bool,
            tiled: bool,
            solid_color_blocks: bool,
            double_buffer: bool,
            buffer_content_hints: bool,
            uncompressed_storage_mode: bool,
            _: u39 = 0,

            pub const BlockSize = enum(u4) {
                @"16x16" = 1,
                @"32x8" = 2,
                @"64x4" = 3,
                @"32x8_64x4" = 4,
            };
        };

        pub const Misc = enum(u52) {
            @"16x16_block_u_interleaved" = 1,
        };

        pub const Afrc = packed struct(u52) {
            plane_0_coding_unit_size: CodingUnitSize,
            plane_1_2_coding_unit_size: CodingUnitSize,
            scan_layout: ScanLayout,
            _: u43 = 0,

            pub const CodingUnitSize = enum(u4) {
                @"16" = 1,
                @"24" = 2,
                @"32" = 3,
            };

            pub const ScanLayout = enum(u1) {
                rotation_optimized = 0,
                scanline_optimized = 1,
            };
        };
    };

    pub const Amlogic = packed struct(u56) {
        layout: Layout,
        options: Options,
        _: u40 = 0,

        pub fn formatInner(self: Amlogic, w: *std.Io.Writer) !void {
            try w.print("fbc, layout = {t}", .{self.layout});
            if (self.options.mem_saving) try w.writeAll(", mem-saving");
        }

        pub fn resolve(raw: u56) Amlogic {
            const layout_raw: u8 = @intCast(raw & 0xff);
            const layout: Layout = @enumFromInt(layout_raw);

            const options_raw: u8 = @intCast(raw >> 8 & 0xff);
            const options: Options = @bitCast(options_raw);

            return Amlogic{
                .layout = layout,
                .options = options,
            };
        }

        const Layout = enum(u8) {
            basic = 1,
            scatter = 2,
        };

        const Options = packed struct(u8) {
            mem_saving: bool,
            _: u7 = 0,
        };
    };

    pub const Vivante = packed struct(u56) {
        color_tiling: ColorTiling,
        compression: Compression,
        tile_status: TileStatus,

        // FIXME
        pub fn formatInner(self: Vivante, w: *std.Io.Writer) !void {
            try w.print("{any}", .{self});
        }

        pub fn resolve(raw: u56) Vivante {
            return @bitCast(raw);
        }

        pub const ColorTiling = enum(u48) {
            linear = 0,
            tiled = 1,
            super_tiled = 2,
            split_tiled = 3,
            split_super_tiled = 4,
            _,
        };

        pub const Compression = enum(u4) {
            none = 0,
            dec400 = 1,
            _,
        };

        pub const TileStatus = enum(u4) {
            @"64_4" = 1,
            @"64_2" = 2,
            @"128_4" = 3,
            @"256_4" = 4,
            _,
        };
    };
};
