const std = @import("std");
const c = @cImport(@cInclude("stdlib.h"));

const zipfile = @embedFile("./App.zip");
const unzip = @embedFile("./unzip");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();

    // Create tmpdir
    const tmpdir_name = try std.fmt.allocPrintZ(a, "/tmp/foo_XXXXXX", .{});
    defer a.free(tmpdir_name);

    const tmpdir = c.mkdtemp(tmpdir_name);
    //std.debug.print("tmpdir is: {s}\n", .{tmpdir});

    // Change directores to tmpdir
    const tmpdir_real = try std.fmt.allocPrint(a, "{s}", .{tmpdir});
    defer a.free(tmpdir_real);
    var tmpdir_handle = try std.fs.cwd().openDir(tmpdir_real, .{});
    defer tmpdir_handle.close();

    try tmpdir_handle.setAsCwd();

    // Write out our zip file
    const file = try std.fs.cwd().createFile("App.zip", .{});
    try file.writeAll(zipfile);
    file.close(); // cant defer

    // Write out unzip
    const unzipfile = try std.fs.cwd().createFile("unzip", .{});
    try unzipfile.writeAll(unzip);
    unzipfile.close(); // cant defer

    // Make unzip executable
    _ = std.c.chmod("./unzip", 755);

    // Create and change to AppDir
    try std.fs.cwd().makeDir("./AppDir");

    var appdir_handle = try std.fs.cwd().openDir("./AppDir", .{});
    defer appdir_handle.close();

    try appdir_handle.setAsCwd();

    // Unzip our executable with unzip
    var cmd = std.process.Child.init(&[_][]const u8{ "../unzip", "-qq", "../App.zip" }, a);
    try cmd.spawn();
    _ = try cmd.wait();

    // Set our environment variable
    const env = try std.fmt.allocPrintZ(a, "APPDIR={s}/AppDir/", .{tmpdir_real});
    defer a.free(env);
    _ = c.putenv(env);

    // Execute our AppRun
    var apprun = std.process.Child.init(&[_][]const u8{"./AppRun"}, a);
    try apprun.spawn();
    _ = apprun.wait() catch |err| {
        std.debug.print("Couldn't run AppRun: {any}\n", .{err});
        std.process.exit(1);
    };

    // Remove the temp dir
    try std.process.changeCurDir("/tmp");
    try std.fs.cwd().deleteTree(tmpdir_real);
}
