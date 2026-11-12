//! Common definitions that the entire compiler will use.

/// Language keyword set
pub const Keyword = enum { //dont forget to update Token.Tag type as well.
    //definition
    _fn,
    _type,
    _enum,
    _struct,
    _alias,
    _opaque,
    _var,
    _const,
    _event,
    //control
    _do,
    _on,
    _if,
    _switch,
    _while,
    _for,
    _break,
    _continue,
    _return,
    _defer,
    _errdefer,
    //error handling
    _try,
    _catch,
    _throw,
    //type
    _is,
    _as,
    //misc
    _pub,
    _import,
};

/// Stores a token tag and the location in the character
/// list that it is defined.
pub const Token = struct {
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

    pub const Range = struct {
        start: usize,
        end: usize,
    };

    tag: Tag,
    loc: Range,
};