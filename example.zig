const std = @import("std");
const drm = @import("drm");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    const card = try drm.Card.openAuto(io);
    defer card.close(io);

    std.log.info("Using drm.Card.getModeAlloc...", .{});
    const mode_res_1 = try card.getModeAlloc(gpa);
    defer mode_res_1.deinit(gpa);

    std.log.info("Min dimensions: {d}x{d}.", .{ mode_res_1.min_width, mode_res_1.min_height });
    std.log.info("Max dimensions: {d}x{d}.", .{ mode_res_1.max_width, mode_res_1.max_height });

    std.log.info("Got {d} fbs: {any}.", .{ mode_res_1.fbs.len, mode_res_1.fbs });
    std.log.info("Got {d} crtcs: {any}.", .{ mode_res_1.crtcs.len, mode_res_1.crtcs });
    std.log.info("Got {d} connectors: {any}.", .{ mode_res_1.connectors.len, mode_res_1.connectors });
    std.log.info("Got {d} encoders: {any}.", .{ mode_res_1.encoders.len, mode_res_1.encoders });

    var fb_buf: [16]u32 = undefined;
    var crtc_buf: [16]u32 = undefined;
    var connector_buf: [16]u32 = undefined;
    var encoder_buf: [16]u32 = undefined;

    std.log.info("Using drm.Card.getModeBuffered...", .{});
    const mode_res_2 = try card.getModeBuffered(&fb_buf, &crtc_buf, &connector_buf, &encoder_buf);

    std.log.info("Min dimensions: {d}x{d}.", .{ mode_res_2.min_width, mode_res_2.min_height });
    std.log.info("Max dimensions: {d}x{d}.", .{ mode_res_2.max_width, mode_res_2.max_height });

    std.log.info("Got {d} fbs: {any}.", .{ mode_res_2.fbs.len, mode_res_2.fbs });
    std.log.info("Got {d} crtcs: {any}.", .{ mode_res_2.crtcs.len, mode_res_2.crtcs });
    std.log.info("Got {d} connectors: {any}.", .{ mode_res_2.connectors.len, mode_res_2.connectors });
    std.log.info("Got {d} encoders: {any}.", .{ mode_res_2.encoders.len, mode_res_2.encoders });
}
