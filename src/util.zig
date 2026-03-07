const std = @import("std");

pub fn statPath(path: []const u8) !std.os.linux.Statx {
    const posix_path = try std.posix.toPosixPath(path);
    return stat(std.os.linux.AT.FDCWD, &posix_path, 0);
}

pub fn statFile(fd: std.posix.fd_t) !std.os.linux.Statx {
    return stat(fd, "", std.os.linux.AT.EMPTY_PATH);
}

pub fn stat(fd: std.posix.fd_t, path: [*:0]const u8, flags: u32) !std.os.linux.Statx {
    var stat_buf: std.os.linux.Statx = undefined;
    const rc = std.posix.system.statx(fd, path, flags, .{}, &stat_buf);
    return switch (std.posix.errno(rc)) {
        .SUCCESS => stat_buf,
        .ACCES => error.PermissionDenied,
        .LOOP => error.SymLinkLoop,
        .NAMETOOLONG => error.NameTooLong,
        .NOENT => error.FileNotFound,
        .NOMEM => error.SystemResources,
        .NOTDIR => error.NotADirectory,
        .BADF => unreachable,
        .FAULT => unreachable,
        .INVAL => unreachable,
        else => |err| std.posix.unexpectedErrno(err),
    };
}
