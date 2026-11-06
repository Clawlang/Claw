const tree = @import("lexertree.zig");

pub const Error = error{
    UnknownKeyword,
    OutOfMemory,
};