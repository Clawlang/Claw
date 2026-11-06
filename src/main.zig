const std = @import("std");
const clap = @import("clap");

pub fn main(init: std.process.Init) !u8 {
    const allocator = init.gpa;
    const io = init.io;

    const params = comptime clap.parseParamsComptime(
        \\-h, --help                Display help and exit.
        \\--list-targets            Lists all available compilation targets.
        \\--list-release            Lists available release modes. (optimization targets)
        \\-o, --output <FILE>       Specify output binary path.
        \\-t, --target <str>        Specify target os and instruction set. Defaults to 'native'.
        \\-r, --release <str>       Specify target release mode. Defaults to 'Debug'.
        \\--print-ast               Dump the abstract syntax tree to stdout.
        \\<FILE>                    The input .clon build file.
        \\
    );

    const parser = .{
        .FILE = clap.parsers.string,
        .string = clap.parsers.string,
        .str = clap.parsers.string,
        .u8 = clap.parsers.int(u8, 0),
        .u16 = clap.parsers.int(u16, 0),
        .u32 = clap.parsers.int(u32, 0),
        .u64 = clap.parsers.int(u64, 0),
        .usize = clap.parsers.int(usize, 0),
        .i8 = clap.parsers.int(i8, 0),
        .i16 = clap.parsers.int(i16, 0),
        .i32 = clap.parsers.int(i32, 0),
        .i64 = clap.parsers.int(i64, 0),
        .isize = clap.parsers.int(isize, 0),
        .f32 = clap.parsers.float(f32),
        .f64 = clap.parsers.float(f64),
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parser, init.minimal.args, .{
        .diagnostic = &diag,
        .allocator = allocator,
    }) catch |err| {
        try diag.reportToFile(io, .stderr(), err);
        return 1;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        std.debug.print("Usage: claw [options] <FILE>\n\nOptions:\n", .{});
        var buffered_writer = std.Io.File.stdout().writerStreaming(io, &struct {
            var buf: [4096]u8 = undefined;
        }.buf);
        const stdout = &buffered_writer.interface;

        try clap.help(stdout, clap.Help, &params, .{});
        try buffered_writer.flush();
        return 0;
    }

    if (@field(res.args, "list-targets") != 0) {
        return 0;
    }

    if (@field(res.args, "list-release") != 0) {
        return 0;
    }

    const srcPath = res.positionals[0] orelse {
        std.debug.print("Error: no build file provided.\n", .{});
        return 1;
    };

    _ = std.Io.Dir.cwd().openFile(io, srcPath, .{}) catch |err| switch (err) {
        std.Io.File.OpenError.FileNotFound => {
            std.debug.print("Error: provided build file does not exist.\n", .{});
            return 1;
        },
        else => return err,
    };

    std.debug.print("Compilation Complete!\n", .{});
    return 0;
}
