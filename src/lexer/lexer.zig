const std = @import("std");

const common = @import("../common.zig");
const tree = @import("lexertree.zig");

pub const Error = error{
    UnknownKeyword,
    OutOfMemory,
};

pub fn tokenize(chars: []u8, allocator: std.mem.Allocator) !std.ArrayList(common.Token) {
    var out = std.ArrayList(common.Token).empty;
    errdefer out.deinit(allocator);

    _ = chars;
    
    return out;
}