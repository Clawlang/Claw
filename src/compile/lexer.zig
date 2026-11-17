const std = @import("std");

const tree = @import("lexertree.zig");

pub const Error = error{
    UnknownKeyword,
    OutOfMemory,
};

/// Stores a token tag and the lexeme it represents.
pub const Token = struct {
    lexeme: []u8,
    tag: Tag,
    line: usize,
    col: usize,

    /// Tags that represent token type
    pub const Tag = enum {
        //control
        eof,
        invalid,
        identifier,

        //literals
        literal_integer,
        literal_float,
        literal_char,
        literal_string,

        //keywords
        kw_fn,
        kw_type,
        kw_enum,
        kw_struct,
        kw_alias,
        kw_opaque,
        kw_var,
        kw_const,
        kw_event,
        kw_do,
        kw_on,
        kw_if,
        kw_switch,
        kw_while,
        kw_for,
        kw_break,
        kw_continue,
        kw_return,
        kw_defer,
        kw_errdefer,
        kw_try,
        kw_catch,
        kw_throw,
        kw_is,
        kw_as,
        kw_pub,
        kw_import,

        //punctuation
        paren_l,            // (
        paren_r,            // )
        brace_l,            // {
        brace_r,            // }
        bracket_l,          // [
        bracket_r,          // ]
        comma,              // ,
        colon,              // :
        semicolon,          // ;
        dot,                // .
        pipe,               // | (can also mean bitwise or)

        //operators
        assign,             // =
        not,                // !
        star,               // *
        plus,               // +
        minus,              // -
        divide,             // /
        less,               // <
        greater,            // >
        less_or_equal,      // <=
        greater_or_equal,   // >=
        equals,             // ==
        not_equals,         // !=
        reference,          // & (can also mean bitwise and)
        optional,           // ?
        range,              // ..
        arrow,              // =>
        plus_assign,        // +=
        minus_assign,       // -=
        multiply_assign,    // *= 
        divide_assign,      // /=
        bitwise_xor,        // ^
        bitwise_not,        // ~
        shift_left,         // <<
        shift_right,        // >>
    };
};

pub const Lexer = struct {
    source: []u8,
    index: usize,
    line: usize,
    col: usize,

    pub fn init(source: []u8) Lexer {
        return Lexer{ .source = source, .index = 0, .line = 1, .col = 1, };
    }

    fn advance(self: *Lexer) void {
        self.index += 1;
        self.col += 1;
    }

    /// Skip whitespace and comments.
    fn skip(self: *Lexer) void {
        while (self.index < self.source.len) {
            const c = self.source[self.index];
            switch (c) {
                ' ', '\t', '\r' => {
                    self.advance();
                },
                '\n' => {
                    self.line += 1;
                    self.col = 1;
                    self.index += 1;
                },
                else => break,
            }
        }
    }
};