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

    fn fourccCode(a: u8, b: u8, c: u8, d: u8) u32 {
        return @as(u32, a) | (@as(u32, b) << 8) | (@as(u32, c) << 16) | (@as(u32, d) << 24);
    }
};

pub const FormatModifiers = packed struct(u64) {
    raw: u56,
    vendor: Vendor,

    pub fn resolve(self: FormatModifiers) Resolved {
        return switch (self.vendor) {
            .none => .{ .none = .resolve(self.raw) },
            .intel => .{ .intel = self.raw }, // TODO
            .amd => .{ .amd = self.raw }, // TODO
            .nvidia => .{ .nvidia = .resolve(self.raw) },
            .samsung => .{ .samsung = self.raw }, // TODO
            .qualcomm => .{ .qualcomm = self.raw }, // TODO
            .vivante => .{ .vivante = self.raw }, // TODO
            .broadcom => .{ .broadcom = self.raw }, // TODO
            .arm => .{ .arm = self.raw }, // TODO
            .allwinner => .{ .allwinner = self.raw }, // TODO
            .amlogic => .{ .amlogic = self.raw }, // TODO
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
        amd: u56,
        nvidia: Nvidia,
        samsung: u56,
        qualcomm: u56,
        vivante: u56,
        broadcom: u56,
        arm: u56,
        allwinner: u56,
        amlogic: u56,
        mtk: u56,
        apple: u56,
    };

    pub const None = union(enum) {
        invalid: void,
        unknown: u56,

        pub fn resolve(raw: u56) None {
            return switch (raw) {
                0xffffffffffffff => .invalid,
                else => |val| .{ .unknown = val },
            };
        }
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
};
