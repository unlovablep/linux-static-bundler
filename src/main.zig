const std = @import("std");
const c = @cImport(@cInclude("stdlib.h"));

const tarfile = @embedFile("./App.txz");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const pwd = try std.fs.cwd().realpathAlloc(a, "./");
    defer a.free(pwd);

    // Create tmpdir
    const tmpdir_name = try std.fmt.allocPrintZ(a, "/tmp/bundle_XXXXXX", .{});
    defer a.free(tmpdir_name);

    const tmpdir = c.mkdtemp(tmpdir_name);
    //std.debug.print("tmpdir is: {s}\n", .{tmpdir});

    // Change directores to tmpdir
    const tmpdir_real = try std.fmt.allocPrint(a, "{s}", .{tmpdir});
    defer a.free(tmpdir_real);
    var tmpdir_handle = try std.fs.cwd().openDir(tmpdir_real, .{});
    defer tmpdir_handle.close();

    try tmpdir_handle.setAsCwd();

    // Create and change to AppDir
    try std.fs.cwd().makeDir("./AppDir");

    var appdir_handle = try std.fs.cwd().openDir("./AppDir", .{});
    defer appdir_handle.close();

    try appdir_handle.setAsCwd();

    // Untar our executable
    try txz(a, tarfile, "./");

    // Set our environment variables
    const env = try std.fmt.allocPrintZ(a, "APPDIR={s}/AppDir/", .{tmpdir_real});
    defer a.free(env);
    _ = c.putenv(env);

    const envpwd = try std.fmt.allocPrintZ(a, "TOPDIR={s}/", .{pwd});
    defer a.free(envpwd);
    _ = c.putenv(envpwd);

    // set $ARGS
    const args = try std.process.argsAlloc(a);
    defer std.process.argsFree(a, args);

    var buf = std.ArrayList(u8).init(a);
    defer buf.deinit();

    var firstarg: [:0]u8 = undefined;
    defer a.free(firstarg);
    var first: bool = false;
    for (args) |arg| {
        if (!first) {
            first = true;
            // $SELF is for argv[0]
            firstarg = try std.fmt.allocPrintZ(a, "SELF={s}", .{arg[0..arg.len]});
        } else {
            const str = try std.fmt.allocPrintZ(a, "{s} ", .{arg});
            defer a.free(str);
            try buf.appendSlice(str);
        }
    }
    _ = c.putenv(firstarg);

    const argslice = try buf.toOwnedSlice();
    defer a.free(argslice);

    const envargs = try std.fmt.allocPrintZ(a, "ARGS={s}", .{argslice});
    defer a.free(envargs);
    _ = c.putenv(envargs);

    // Make everything executable
    try recurse_chmod(a, c.strtoul("0755", 0, 8));

    // Execute our AppRun
    var apprun = std.process.Child.init(&[_][]const u8{"./AppRun"}, a);
    try apprun.spawn();
    _ = apprun.wait() catch |err| {
        std.debug.print("Couldn't run AppRun: {any}\n", .{err});
        std.process.exit(1);
    };

    // Remove the temp dir
    try std.process.changeCurDir("/tmp");
    //try std.fs.cwd().deleteTree(tmpdir_real);
}

// Extract a tar.xz under a directory
// file is the literal file contents
fn txz(a: std.mem.Allocator, file: []const u8, outdirname: []const u8) !void {
    var fbs = std.io.fixedBufferStream(file);
    var reader = std.io.bufferedReader(fbs.reader());

    var decompressed = try std.compress.xz.decompress(a, reader.reader());
    defer decompressed.deinit();

    var outdir = try std.fs.cwd().openDir(outdirname, .{});
    defer outdir.close();

    try std.tar.pipeToFileSystem(outdir, decompressed.reader(), .{ .mode_mode = .ignore });
}

fn recurse_chmod(a: std.mem.Allocator, mode: c_ulong) !void {
    var dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer dir.close();

    var dirIterator = dir.iterate();
    while (try dirIterator.next()) |dirContent| {
        if (dirContent.kind == .directory) {
            // set the current dir to the subdir
            var subdir = try std.fs.cwd().openDir(dirContent.name, .{});
            defer subdir.close();
            try subdir.setAsCwd();
            // recurse
            try recurse_chmod(a, mode);
            // re-set the cwd
            try dir.setAsCwd();
        } else {
            // chmod +x
            const name = try std.fmt.allocPrintZ(a, "{s}", .{dirContent.name});
            defer a.free(name);
            _ = std.c.chmod(name, mode);
        }
    }
}
