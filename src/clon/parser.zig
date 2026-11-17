const std = @import("std");
const lex = @import("lexer.zig");

pub const ClonObject = std.ArrayList(ClonField);
pub const ClonArray = std.ArrayList(ClonValue);

pub const Error = error {
    //parser errors
    UnexpectedToken,

    //other
    FloatParsingError,
    IntParsingError,
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
    key: []const u8,
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

    fn advance(self: *Parser) void {
        self.current = self.peek;
        self.peek = self.lexer.next() catch |err| {
            self.throw(err, "");
            return;
        };
    }

    /// Expect a token, if expectation is not met, terminates
    /// and outputs an error message to the terminal.
    fn expect(self: *Parser, tag: lex.Token.Tag) Error!void {
        if(self.current.tag != tag) {
            self.throw(Error.UnexpectedToken, self.allocator.print("Expected Token: \"{s}\", Found \"{s}\" Instead.", .{getTokenLabel(tag), getTokenLabel(self.current.tag)}) catch {
                self.throw(Error.OutOfMemory, "");
                return Error.OutOfMemory;
            });
            return Error.UnexpectedToken;
        }
        self.advance();
    }

    /// Expect a token, if expectation is not met, terminates
    /// and outputs an error message to the terminal.
    /// 
    /// Returns the lexeme of the current tag
    fn getExpect(self: *Parser, tag: lex.Token.Tag) Error![]const u8 {
        const lexeme = self.current.lexeme;
        try self.expect(tag);

        return lexeme;
    }

    fn parseObject(self: *Parser) Error!ClonObject {
        try self.expect(.brace_l);
        var obj = ClonObject.empty;
        errdefer obj.deinit(self.allocator);

        while(self.current.tag != .brace_r and self.current.tag != .eof) {
            if(self.current.tag == .dot) self.advance(); //skip . for starting fields.

            const identity = try self.getExpect(.identifier);

            try self.expect(.equals);

            const val = try self.parseValue();
            try obj.append(self.allocator, ClonField{ .key = identity, .value = val });

            if(self.current.tag == .comma) {
                self.advance();
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
                self.advance();
            }
        }

        try self.expect(.bracket_r);
        return arr;
    }

    fn parseValue(self: *Parser) Error!ClonValue {
        switch (self.current.tag) {
            .literal_string => { //string
                const lexeme = self.current.lexeme;
                self.advance();
                return ClonValue{ .string = lexeme };
            },
            .literal_int => { //number
                const start = self.current.lexeme;
                self.advance();
                if(self.current.tag == .dot) { //float
                    self.advance();
                    const end = try self.getExpect(.literal_int);

                    const strlist = [_][]const u8{ start, ".", end };
                    const floatstr = std.mem.concat(self.allocator, u8, &strlist) catch {self.throw(Error.OutOfMemory, ""); return Error.OutOfMemory;};
                    defer self.allocator.free(floatstr);

                    defer self.advance();

                    return ClonValue{ .float = std.fmt.parseFloat(f32, floatstr) catch {self.throw(Error.FloatParsingError,  floatstr); return Error.FloatParsingError;} };
                } else { //int
                    return ClonValue{ .integer = std.fmt.parseInt(i32, start, 0) catch {self.throw(Error.IntParsingError, start); return Error.IntParsingError;} };
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
                defer self.advance();
                
                if(std.mem.eql(u8, lexeme, "true")) {
                    return ClonValue{ .bool = true };
                } else if(std.mem.eql(u8, lexeme, "false")) {
                    return ClonValue{ .bool = false };
                } else {
                    self.throw(Error.UnexpectedToken, "Expected Boolean Literal");
                    return Error.UnexpectedToken;
                }
            },
            else => {
                self.throw(Error.UnexpectedToken, self.allocator.print("Found \"{s}\"", .{getTokenLabel(self.current.tag)}) catch {
                    self.throw(Error.OutOfMemory, "");
                    return Error.OutOfMemory;
                });
                return Error.UnexpectedToken;
            }
        }
    }

    /// Throws the given error and terminates the program.
    pub fn throw(self: *Parser, err: Error, detail: []const u8) void {
        const msg = getErrMsg(err);

        const line_start: usize = blk: {
            const loc = self.current.lexeme.ptr - self.lexer.source.ptr;
            var i = loc;
            while (i > 0) {
                i -= 1;
                if (self.lexer.source[i] == '\n') {
                    break :blk i + 1;
                }
            }
            break :blk 0;
        };

        const line_end: usize = blk: {
            for(self.lexer.source[line_start..], line_start..) |ch, i| {
                if(ch == '\n') break :blk i;
            }
            break :blk self.lexer.source.len;
        };

        std.debug.print("\x1b[1m\x1b[91m", .{}); //bold red coloring
        std.debug.print("Error on line {d} -> {s}:\n", .{ self.current.line, msg });

        std.debug.print("{s}\n", .{ detail });

        std.debug.print("\x1b[0m", .{}); //reset
        std.debug.print("   {s}\n", .{ self.lexer.source[line_start..line_end] });
        
        std.debug.print("\x1b[91m", .{}); //red coloring
        //print squiggles
        std.debug.print("   ", .{});
        for(0..line_end - line_start) |_| {
            std.debug.print("~", .{});
        }

        //print caret
        std.debug.print("\n   ", .{});
        for(1..self.current.col) |_| {
            std.debug.print(" ", .{});
        }
        std.debug.print("\x1b[1m\x1b[95m", .{}); //bold pink coloring
        std.debug.print("^\n", .{});

        //exit
        std.process.exit(1);
    }
};

pub fn parse(clon: []u8, allocator: std.mem.Allocator) !ClonValue {
    var parser = try Parser.init(clon, allocator);
    return try parser.parseValue();
}

pub fn getTokenLabel(tag: lex.Token.Tag) []const u8 {
    return switch (tag) {
        .identifier => "Identifier",
        .brace_l => "{",
        .brace_r => "}",
        .bracket_l => "[",
        .bracket_r => "]",
        .dot => ".",
        .comma => ",",
        .equals => "Assignment",
        .literal_int => "Numeric Literal",
        .literal_string => "String Literal",
        .eof => "EOF",
    };
}

pub fn getErrMsg(err: Error) []const u8 {
    return switch (err) {
        Error.UnexpectedToken => "Unexpected Token",

        Error.IntParsingError => "Error Parsing Integer Literal",
        Error.FloatParsingError => "Error Parsing Float Literal",

        Error.OutOfMemory => "Out Of Memory :(",
    };
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