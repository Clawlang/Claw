//! Error handling utilities

const std = @import("std");

/// Use either lexeme or col to show where the error happened.
pub const Error = struct {
    /// Error message
    msg: []const u8,
    /// Error detail
    detail: []const u8 = "",
    /// File content buffer
    source: []const u8,
    /// Line the error is on
    line: usize,
    /// Can be any index within the error line
    loc: usize,

    /// Optionally used to show detailed token specific error highlighting. (preferred)
    lexeme: ?[]const u8 = null,
    /// If no lexeme is provided, this field is used to point the caret. (fallback shows no caret)
    col: ?usize = null,
};

/// Throws the given error and terminates the program.
pub fn throw(err: Error) void {
    var line_start: usize = 0;

    var idx = err.loc;
    var s = err.loc;
    while (idx > 0) {
        idx -= 1;
        if (!isWhitespace(err.source[idx])) s = idx;

        if (err.source[idx] == '\n') {
            line_start = s;
            break;
        }
    }
    const col_offset = line_start - idx;

    const line_end = blk: {
        for (err.source[line_start..], line_start..) |ch, i| {
            if (ch == '\n') break :blk i;
        }
        break :blk err.source.len;
    };

    std.debug.print("\x1b[1m\x1b[91m", .{}); //bold red coloring
    std.debug.print("Syntax error on line {d} -> {s}:\n", .{ err.line, err.msg });

    std.debug.print("{s}\n", .{err.detail});

    std.debug.print("\x1b[0m", .{}); //reset
    std.debug.print("   {s}\n", .{err.source[line_start..line_end]});

    const line_start_ptr = err.source.ptr + line_start;
    const token_offset = if (err.lexeme) |lex| lex.ptr - line_start_ptr else 0;

    const token_len = blk: {
        if (err.lexeme) |lex| {
            break :blk lex.len;
        } else if (err.col) |_| {
            break :blk 1;
        } else {
            break :blk 0;
        }
    };

    var printed_so_far: usize = 0;

    //print squiggles
    std.debug.print("\x1b[95m", .{}); //pink coloring
    std.debug.print("   ", .{});
    if (err.lexeme) |_| {
        for (0..token_offset) |_| {
            std.debug.print("~", .{});
        }
        printed_so_far = token_offset;
    } else if (err.col) |col| {
        for (0..col - col_offset) |_| {
            std.debug.print("~", .{});
        }
        printed_so_far = col - col_offset;
    }

    //print caret
    std.debug.print("\x1b[1m", .{}); //bold pink coloring
    for (0..token_len) |_| {
        std.debug.print("^", .{});
    }
    printed_so_far += token_len;

    //print remaining sqiggles
    std.debug.print("\x1b[22m", .{}); //no bold
    const remaining_chars = (line_end - line_start);
    if (remaining_chars > printed_so_far) {
        for (1..(remaining_chars - printed_so_far)) |_| {
            std.debug.print("~", .{});
        }
    }

    //reset and newline
    std.debug.print("\x1b[0m\n", .{});

    //exit
    std.process.exit(1);
}

inline fn isWhitespace(char: u8) bool {
    return switch (char) {
        ' ', '\t', '\r', '\n' => true,
        else => false,
    };
}
