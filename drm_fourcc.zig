/// Corresponds to DRM_FORMAT_* in `<drm/drm_fourcc.h>`
pub const DrmFormat = enum(u32) {
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
};

/// Contains most DRM_FORMAT_MOD* definitions from `<drm/drm_fourcc.h>`
pub const DrmFormatMod = enum(u64) {
    pub const generic_16_16_tile: DrmFormatMod = .samsung_16_16_tile;

    pub const vivante_ts_64_4: u64 = 1 << 48;
    pub const vivante_ts_64_2: u64 = 2 << 48;
    pub const vivante_ts_128_4: u64 = 3 << 48;
    pub const vivante_ts_256_4: u64 = 4 << 48;
    pub const vivante_ts_mask: u64 = 0xf << 48;
    pub const vivante_comp_dec400: u64 = 1 << 52;
    pub const vivante_comp_mask: u64 = 0xf << 52;
    pub const vivante_ext_mask = vivante_ts_mask | vivante_comp_mask;

    pub const afbc_block_size_mask: u4 = 0xf;
    pub const afbc_block_size_16x16: u64 = 1;
    pub const afbc_block_size_32x8: u64 = 2;
    pub const afbc_block_size_64x4: u64 = 3;
    pub const afbc_block_size_32x8_64x4: u64 = 4;
    pub const afbc_ytr: u64 = 1 << 4;
    pub const afbc_split: u64 = 1 << 5;
    pub const afbc_sparse: u64 = 1 << 6;
    pub const afbc_cbr: u64 = 1 << 7;
    pub const afbc_tiled: u64 = 1 << 8;
    pub const afbc_sc: u64 = 1 << 9;
    pub const afbc_db: u64 = 1 << 10;
    pub const afbc_bch: u64 = 1 << 11;
    pub const afbc_usm: u64 = 1 << 12;

    pub const afrc_cu_size_mask: u4 = 0xf;
    pub const afrc_cu_size_16: u64 = 1;
    pub const afrc_cu_size_24: u64 = 2;
    pub const afrc_cu_size_32: u64 = 3;
    pub const afrc_layout_scan: u64 = 1 << 8;

    pub const amlogic_fbc_layout_basic: u64 = 1;
    pub const amlogic_fbc_layout_scatter: u64 = 2;
    pub const amlogic_fbc_option_mem_saving: u64 = 1 << 0;

    pub const amd_tile_ver_gfx9 = 1;
    pub const amd_tile_ver_gfx10 = 2;
    pub const amd_tile_ver_gfx10_rbplus = 3;
    pub const amd_tile_ver_gfx11 = 4;
    pub const amd_tile_ver_gfx12 = 5;
    pub const amd_tile_gfx9_64k_s = 9;
    pub const amd_tile_gfx9_64k_d = 10;
    pub const amd_tile_gfx9_64k_s_x = 25;
    pub const amd_tile_gfx9_64k_d_x = 26;
    pub const amd_tile_gfx9_64k_r_x = 27;
    pub const amd_tile_gfx11_256k_r_x = 31;
    pub const amd_tile_gfx12_256b_2d = 1;
    pub const amd_tile_gfx12_4k_2d = 2;
    pub const amd_tile_gfx12_64k_2d = 3;
    pub const amd_tile_gfx12_256k_2d = 4;
    pub const amd_dcc_block_64b = 0;
    pub const amd_dcc_block_128b = 1;
    pub const amd_dcc_block_256b = 2;
    pub const amd_tile_version_shift = 0;
    pub const amd_tile_version_mask = 0xff;
    pub const amd_tile_shift = 8;
    pub const amd_tile_mask = 0x1f;
    pub const amd_dcc_shift = 13;
    pub const amd_dcc_mask = 0x1;
    pub const amd_dcc_retile_shift = 14;
    pub const amd_dcc_retile_mask = 0x1;
    pub const amd_dcc_pipe_align_shift = 15;
    pub const amd_dcc_pipe_align_mask = 0x1;
    pub const amd_dcc_independent_64b_shift = 16;
    pub const amd_dcc_independent_64b_mask = 0x1;
    pub const amd_dcc_independent_128b_shift = 17;
    pub const amd_dcc_independent_128b_mask = 0x1;
    pub const amd_dcc_max_compressed_block_shift = 18;
    pub const amd_dcc_max_compressed_block_mask = 0x3;
    pub const amd_dcc_constant_encode_shift = 20;
    pub const amd_dcc_constant_encode_mask = 0x1;
    pub const amd_pipe_xor_bits_shift = 21;
    pub const amd_pipe_xor_bits_mask = 0x7;
    pub const amd_bank_xor_bits_shift = 24;
    pub const amd_bank_xor_bits_mask = 0x7;
    pub const amd_packers_shift = 27;
    pub const amd_packers_mask = 0x7;
    pub const amd_rb_shift = 30;
    pub const amd_rb_mask = 0x7;
    pub const amd_pipe_shift = 33;
    pub const amd_pipe_mask = 0x7;

    invalid = 0x00ffffffffffffff,

    linear = fourccModCode(.none, 0),

    intel_x_tiled = fourccModCode(.intel, 1),
    intel_y_tiled = fourccModCode(.intel, 2),
    intel_yf_tiled = fourccModCode(.intel, 3),
    intel_y_tiled_ccs = fourccModCode(.intel, 4),
    intel_yf_tiled_ccs = fourccModCode(.intel, 5),
    intel_y_tiled_gen12_rc_css = fourccModCode(.intel, 6),
    intel_y_tiled_gen12_mc_css = fourccModCode(.intel, 7),
    intel_y_tiled_gen12_rc_css_cc = fourccModCode(.intel, 8),
    intel_4_tiled = fourccModCode(.intel, 9),
    intel_4_tiled_dg2_rc_ccs = fourccModCode(.intel, 10),
    intel_4_tiled_dg2_mc_ccs = fourccModCode(.intel, 11),
    intel_4_tiled_dg2_rc_ccs_cc = fourccModCode(.intel, 12),
    intel_4_tiled_mtl_rc_ccs = fourccModCode(.intel, 13),
    intel_4_tiled_mtl_mc_ccs = fourccModCode(.intel, 14),
    intel_4_tiled_mtl_rc_ccs_cc = fourccModCode(.intel, 15),
    intel_4_tiled_lnl_ccs = fourccModCode(.intel, 16),
    intel_4_tiled_bmg_ccs = fourccModCode(.intel, 17),

    samsung_64_32_tile = fourccModCode(.samsung, 1),
    samsung_16_16_tile = fourccModCode(.samsung, 2),

    qualcomm_compressed = fourccModCode(.qualcomm, 1),
    qualcomm_tiled2 = fourccModCode(.qualcomm, 2),
    qualcomm_tiled3 = fourccModCode(.qualcomm, 3),

    vivante_tiled = fourccModCode(.vivante, 1),
    vivante_super_tiled = fourccModCode(.vivante, 2),
    vivante_split_tiled = fourccModCode(.vivante, 3),
    vivante_split_super_tiled = fourccModCode(.vivante, 4),

    nvidia_tegra_tiled = fourccModCode(.nvidia, 1),
    nvidia_16bx2_block_1_gob = nvidia16Bx2Block(0),
    nvidia_16bx2_block_2_gob = nvidia16Bx2Block(1),
    nvidia_16bx2_block_4_gob = nvidia16Bx2Block(2),
    nvidia_16bx2_block_8_gob = nvidia16Bx2Block(3),
    nvidia_16bx2_block_16_gob = nvidia16Bx2Block(4),
    nvidia_16bx2_block_32_gob = nvidia16Bx2Block(5),

    broadcom_vc4_t_tiled = fourccModCode(.broadcom, 1),
    broadcom_sand32 = fourccModCode(.broadcom, 2),
    broadcom_sand64 = fourccModCode(.broadcom, 3),
    broadcom_sand128 = fourccModCode(.broadcom, 4),
    broadcom_sand256 = fourccModCode(.broadcom, 5),
    broadcom_uif = fourccModCode(.broadcom, 6),

    arm_16x16_block_u_interleaved = armModCode(.misc, 1),

    allwinner_tiled = fourccModCode(.allwinner, 1),

    _, // This enum definately isn't complete so we'll leave it non-exhaustive for now
};

const Vendor = enum(u8) {
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

fn fourccCode(a: u8, b: u8, c: u8, d: u8) u32 {
    return @as(u32, a) | (@as(u32, b) << 8) | (@as(u32, c) << 16) | (@as(u32, d) << 24);
}

fn fourccModCode(vendor: Vendor, value: u56) u64 {
    return (@as(u64, @intFromEnum(vendor)) << 56) | (value & 0x00ffffffffffffff);
}

fn nvidiaBlockLinear2d(c: u3, s: u1, g: u2, k: u8, h: u4) u64 {
    return fourccModCode(.nvidia, @as(u56, 0x10) |
        @as(u56, h & 0xf) |
        (@as(u56, k & 0xff) << 12) |
        (@as(u56, g & 0x3) << 20) |
        (@as(u56, s & 0x1) << 22) |
        (@as(u56, c) & 0x7) << 23);
}

fn nvidia16Bx2Block(v: u4) u64 {
    return nvidiaBlockLinear2d(0, 0, 0, 0, v);
}

const ArmModType = enum(u4) {
    afbc = 0,
    misc = 1,
    afrc = 2,
};

fn armModCode(_type: ArmModType, val: u52) u64 {
    return fourccModCode(.arm, (@as(u64, @intFromEnum(_type)) << 52) | (val & 0x000fffffffffffff));
}

test {
    @import("std").testing.refAllDecls(@This());
}
