const std = @import("std");
const lex = @import("lexer.zig");

pub const ClonObject = std.ArrayList(ClonField);
pub const ClonArray = std.ArrayList(ClonValue);

pub const Error = error {
    //parser errors
    UnexpectedToken,
    ExpectedIdentifier,
    ExpectedAssignment,

    //lexer errors
    UnexpectedCharacter,
    EOF,

    //other
    OutOfMemory,
};

pub const ClonValue = union(enum) {
    string: []u8,
    integer: i32,
    float: f32,
    bool: bool,
    object: ClonObject,
    array: ClonArray,
};

pub const ClonField = struct {
    key: []u8,
    value: ClonValue,
};

pub const Parser = struct {
    lexer: lex.Lexer,
    current: lex.Token,
    peek: lex.Token,
    allocator: std.mem.Allocator,

    pub fn init(clon: []u8, allocator: std.mem.Allocator) Error!Parser {
        var lexer = lex.Lexer.init(clon);
        const first = try lexer.next();
        const second = try lexer.next();

        return Parser{
            .lexer = lexer,
            .current = first,
            .peek = second,
            .allocator = allocator,
        };
    }

    fn advance(self: *Parser) !void {
        self.current = self.peek;
        self.peek = try self.lexer.next();
    }

    fn expect(self: *Parser, tag: lex.TokenTag) Error!void {
        if(self.current.tag != tag) {
            return Error.UnexpectedToken;
        }
        try self.advance();
    }

    fn parseObject(self: *Parser) Error!ClonObject {
        try self.expect(.brace_l);
        var obj = ClonObject.empty;
        errdefer obj.deinit(self.allocator);

        while(self.current.tag != .brace_r and self.current.tag != .eof) {
            if(self.current.tag == .dot) try self.advance(); //skip . for starting fields.
            if(self.current.tag != .identifier) {
                return Error.ExpectedIdentifier;
            }
            const lexeme = self.current.lexeme;
            try self.advance();

            self.expect(.equals) catch return Error.ExpectedAssignment;

            const val = try self.parseValue();
            try obj.append(self.allocator, ClonField{ .key = lexeme, .value = val });

            if(self.current.tag == .comma) {
                try self.advance();
            }
        }

        try self.expect(.brace_r);
        return obj;
    }

    fn parseArray(self: *Parser) Error!ClonArray {
        try self.expect(.bracket_l);
        var arr = ClonArray.empty;
        errdefer arr.deinit(self.allocator);

        while(self.current.tag != .bracket_r and self.current.tag != .eof) {
            const val = try self.parseValue();
            try arr.append(self.allocator, val);

            if(self.current.tag == .comma) {
                try self.advance();
            }
        }

        try self.expect(.bracket_r);
        return arr;
    }

    fn parseValue(self: *Parser) Error!ClonValue {
        switch (self.current.tag) {
            .literal_string => { //string
                const lexeme = self.current.lexeme;
                try self.advance();
                return ClonValue{ .string = lexeme };
            },
            .literal_int => { //number
                const lexeme = self.current.lexeme;
                try self.advance();
                if(self.current.tag == .dot) { //float
                    if(self.peek.tag != .literal_int) {
                        return Error.UnexpectedToken;
                    }

                    const strlist = [_][]u8{ lexeme, self.current.lexeme, self.peek.lexeme };
                    const floatstr = std.mem.concat(self.allocator, u8, &strlist) catch return Error.OutOfMemory;
                    defer self.allocator.free(floatstr);

                    inline for(0..2) |_| { //advance twice
                        try self.advance();
                    }

                    return ClonValue{ .float = std.fmt.parseFloat(f32, floatstr) catch return Error.UnexpectedCharacter };
                } else { //int
                    return ClonValue{ .integer = std.fmt.parseInt(i32, lexeme, 0) catch return Error.UnexpectedCharacter };
                }
            },
            .brace_l => { //object
                return ClonValue{ .object = try self.parseObject() };
            },
            .bracket_l => { //object
                return ClonValue{ .array = try self.parseArray() };
            },
            .identifier => { //bool (hopefully)
                const lexeme = self.current.lexeme;
                try self.advance();
                
                if(std.mem.eql(u8, lexeme, "true")) {
                    return ClonValue{ .bool = true };
                } else if(std.mem.eql(u8, lexeme, "false")) {
                    return ClonValue{ .bool = false };
                } else {
                    return Error.UnexpectedToken;
                }
            },
            else => {
                return Error.UnexpectedToken;
            }
        }
    }
};

pub fn parse(clon: []u8, allocator: std.mem.Allocator) !ClonValue {
    var parser = try Parser.init(clon, allocator);
    return try parser.parseValue();
}

pub fn print(clon: ClonValue) void {
    switch(clon) {
        .string => std.debug.print("{s}\n", .{ clon.string }),
        .integer => std.debug.print("{d}\n", .{ clon.integer }),
        .float => std.debug.print("{d}\n", .{ clon.float }),
        .bool => std.debug.print("{}\n", .{ clon.bool }),
        .array => |a| {
            std.debug.print("[\n", .{});
            for(a.items) |i| {
                const t = switch(i) {
                    .string => "string",
                    .integer => "int",
                    .float => "float",
                    .bool => "bool",
                    .array => "array",
                    .object => "object",
                };
                
                std.debug.print("   ({s}) ", .{t}); //indentation
                print(i);
            }
            std.debug.print("]\n", .{});
        },
        .object => |o| {
            std.debug.print("{{\n", .{});
            for(o.items) |i| {
                const t = switch(i.value) {
                    .string => "string",
                    .integer => "int",
                    .float => "float",
                    .bool => "bool",
                    .array => "array",
                    .object => "object",
                };
                std.debug.print("   {s}: {s} = ", .{ i.key, t });
                print(i.value);
            }
            std.debug.print("}}\n", .{});
        }
    }
}