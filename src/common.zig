/// Common definitions that the entire compiler will use.

/// Language keyword set
pub const Keyword = enum {
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