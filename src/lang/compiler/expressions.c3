//-----------------------------------------------------------------------------
// data for expressions
//-----------------------------------------------------------------------------
module punk;
import std::collections;

alias ExprId = int;
alias ExprIdList = List{ExprId};

//-----------------------------------------------------------------------------
// ENUMERATIONS
//-----------------------------------------------------------------------------

enum ExprKind : int {
    BINARY, LOGICAL, LITERAL, UNARY, GROUP,
    NOOP,
}



//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct ExprBinary {
    ExprId lhs;
    Token op;
    ExprId rhs;
}

struct ExprGroup {
    ExprId expr;
}

struct ExprLiteral {
    Token value;
}

struct ExprLogical {
    ExprId lhs;
    ExprId rhs;
    Token op;
}

struct ExprUnary {
    Token op;
    ExprId rhs;
}

union ExprData {
    ExprBinary binary_expr;
    ExprGroup group_expr;
    ExprLiteral literal_expr;
    ExprLogical logical_expr;
    ExprUnary unary_expr;
}

struct Expression {
    ExprKind kind;
    ExprData data;
    SourceSpan span;
}


