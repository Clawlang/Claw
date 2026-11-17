const std = @import("std");

const lexer = @import("lexer.zig");

const BUILDER: LexerTreeBuilder = blk: {
    var builder = LexerTreeBuilder{};

    for(@typeInfo(lexer.Token.Tag).@"enum".field_names) |name| {
        if(!std.mem.startsWith(u8, name, "kw_")) break;
        
        //start from index 3 to ignore leading kw_
        builder.addKeyword(name[3..], @field(lexer.Token.Tag, name));
    }

    break :blk builder;
};

pub const tree = LexerTree{ .nodes = BUILDER.nodes[0..BUILDER.node_count] };

pub const LexerTree = struct {
    nodes: []const LexerNode,

    pub fn getKeyword(self: LexerTree, key: []const u8) lexer.Error!lexer.Token.Tag {
        var idx: u32 = 0;

        for (key) |char| {
            const next_idx = self.nodes[idx].children[char];
            if (next_idx != NO_CHILD) {
                idx = next_idx;
            } else {
                return lexer.Error.UnknownKeyword;
            }
        }

        return self.nodes[idx].keyword orelse lexer.Error.UnknownKeyword;
    }
};

const LexerTreeBuilder = struct {
    const MAX_NODES = 4096;

    nodes: [MAX_NODES]LexerNode = @splat(.{}),
    node_count: u16 = 1, // Node 0 is the root

    pub fn getRoot(self: *LexerTreeBuilder) *LexerNode {
        return &self.nodes[0];
    }

    pub fn addKeyword(comptime self: *LexerTreeBuilder, comptime key: []const u8, comptime keyword: lexer.Token.Tag) void {
        var node = self.getRoot();

        for (key) |char| {
            if (node.children[char] == NO_CHILD) {
                if (self.node_count >= MAX_NODES) {
                    @compileError("LexerTree Node Pool Capacity Exceeded!");
                }
                const new_node_index = self.node_count;
                self.node_count += 1;

                node.children[char] = new_node_index;
            }

            node = &self.nodes[node.children[char]];
        }

        node.keyword = keyword;
    }
};

const NO_CHILD: u16 = std.math.maxInt(u16);
const LexerNode = struct {
    keyword: ?lexer.Token.Tag = null,
    children: [256]u16 = @splat(NO_CHILD),
};