const std = @import("std");

const parser = @import("parser.zig");

pub const TokenTag = enum {
    eof,
    identifier,
    literal_string,
    literal_int,

    brace_l,            // {
    brace_r,            // }
    bracket_l,          // [
    bracket_r,          // ]
    comma,              // ,
    dot,                // .
    equals,             // =
};

pub const Token = struct {
    tag: TokenTag,
    lexeme: []u8,
    line: usize,
    col: usize,
};

pub const Lexer = struct {
    source: []u8,
    index: usize,
    line: usize,
    col: usize,

    pub fn init(source: []u8) Lexer {
        return Lexer{ .source = source, .index = 0, .line = 1, .col = 1, };
    }

    pub fn next(self: *Lexer) parser.Error!Token {
        self.skip();

        if(self.index >= self.source.len) {
            //end of file token
            return Token{ .tag = .eof, .lexeme = self.source[self.source.len..self.source.len], .line = self.line, .col = self.col };
        }

        const start = self.index;
        const start_col = self.col;
        const char = self.source[start];

        switch (char) {
            //single character
            '{' => { self.advance(); return Token{ .tag = .brace_l, .lexeme = self.source[start..self.index], .line = self.line, .col = start_col}; },
            '}' => { self.advance(); return Token{ .tag = .brace_r, .lexeme = self.source[start..self.index], .line = self.line, .col = start_col}; },
            '[' => { self.advance(); return Token{ .tag = .bracket_l, .lexeme = self.source[start..self.index], .line = self.line, .col = start_col}; },
            ']' => { self.advance(); return Token{ .tag = .bracket_r, .lexeme = self.source[start..self.index], .line = self.line, .col = start_col}; },
            ',' => { self.advance(); return Token{ .tag = .comma, .lexeme = self.source[start..self.index], .line = self.line, .col = start_col}; },
            '.' => { self.advance(); return Token{ .tag = .dot, .lexeme = self.source[start..self.index], .line = self.line, .col = start_col}; },
            '=' => { self.advance(); return Token{ .tag = .equals, .lexeme = self.source[start..self.index], .line = self.line, .col = start_col}; },

            '"' => { //string literal
                self.advance(); //skip opening quote
                const lit_start = self.index;

                while(self.index < self.source.len and self.source[self.index] != '"') {
                    if(self.source[self.index] == '\n') {
                        self.line += 1;
                        self.col = 1;
                    }
                    self.advance();
                }
                if(self.index >= self.source.len) return parser.Error.EOF;
                const lexeme = self.source[lit_start..self.index];
                self.advance(); //skip closing quote

                return Token{ .tag = .literal_string, .lexeme = lexeme, .line = self.line, .col = start_col };
            },

            '0'...'9' => { //int literal
                const lit_start = self.index;
                while(self.index < self.source.len and isNumeric(self.source[self.index])) {
                    self.advance();
                }
                const lexeme = self.source[lit_start..self.index];
                return Token{ .tag = .literal_int, .lexeme = lexeme, .line = self.line, .col = start_col };
            },

            'A'...'Z', 'a'...'z', '_' => { //identifier
                const lit_start = self.index;
                while(self.index < self.source.len and isIdentifierValid(self.source[self.index])) {
                    self.advance();
                }
                const lexeme = self.source[lit_start..self.index];
                return Token{ .tag = .identifier, .lexeme = lexeme, .line = self.line, .col = start_col };
            },

            else => {
                return parser.Error.UnexpectedCharacter;
            }
        }
    }

    fn advance(self: *Lexer) void {
        self.index += 1;
        self.col += 1;
    }

    /// Skip whitespace.
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

    fn isNumeric(char: u8) bool {
        return char >= '0' and char <= '9';
    }

    fn isIdentifierValid(char: u8) bool {
        return (char >= 'A' and char <= 'Z') or (char >= 'a' and char <= 'z') or char == '_';
    }
};
