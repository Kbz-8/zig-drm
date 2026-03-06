const std = @import("std");
const drm = @import("drm");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    // const device = drm.Device.getFromDevId(io, gpa, drm.makeDev(226, 0), .{}) catch
    //     try drm.Device.getFromDevId(io, gpa, drm.makeDev(226, 1), .{});

    // const card = try device.openNode(io);

    const card = try drm.Card.openAuto(io, .primary);
    const device = try card.getDevice(io, gpa, .{});
    std.log.info("Device node path: {s}.", .{device.nodePath()});

    defer card.close(io);
    const res = try card.getModesettingResources(gpa);
    defer res.deinit(gpa);

    const connector = try chooseConnector(card, gpa, res.connectors);
    defer connector.deinit(gpa);
    std.log.info("Selected connector {}.", .{connector.id});

    const mode = chooseMode(connector.modes);
    std.log.info("Selected mode {}x{}@{}.", .{ mode.hdisplay, mode.vdisplay, mode.vrefresh });

    const encoder = try card.getEncoder(connector.encoder_id);
    std.log.info("Selected encoder {} (type: {t}).", .{ encoder.id, encoder.type });

    const crtc = try card.getCrtc(encoder.crtc_id);
    std.log.info("Selected crtc {} (mode valid: {}).", .{ crtc.id, crtc.mode != null });
}

fn chooseConnector(
    card: drm.Card,
    gpa: std.mem.Allocator,
    connectors: []const u32,
) !drm.Connector {
    for (connectors) |id| {
        const connector = try card.getConnector(gpa, id);
        if (connector.connection == .connected) return connector;
        connector.deinit(gpa);
    }
    return error.NoConnectedConnectors;
}

fn chooseMode(modes: []const drm.sys.mode.ModeInfo) drm.sys.mode.ModeInfo {
    var best = modes[0];
    const best_score = @as(u64, best.hdisplay) * @as(u64, best.vdisplay) * @as(u64, best.vrefresh);
    for (modes) |mode| {
        const score = @as(u64, mode.hdisplay) * @as(u64, mode.vdisplay) * @as(u64, mode.vrefresh);
        if (score > best_score) best = mode;
    }
    return best;
}
