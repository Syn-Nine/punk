//-----------------------------------------------------------------------------
// data structures to hold statements
//-----------------------------------------------------------------------------
module punk;
import std::collections;

alias StmtId = int;
alias StmtIdList = List{StmtId};

enum StmtKind : int {
    BLOCK,
    BREAK,
    CALL_NATIVE,
    CALL_FN,
    CONST,
    CONTINUE,
    EXPRESSION,
    FORMAT,
    FUNCTION,
    HANDLER,
    IF,
    RETURN,
    VAR,
    WHILE,
}


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct StmtBlock {
    StmtIdList body;
}

struct StmtCallNative {
    String id;
    ExprIdList params;
}

struct StmtConst {
    Token id;
    ExprId expr;
}

struct StmtExpr {
    ExprId expr;
}

struct StmtHandler {
    StmtId body;
    ExprId guard;
    String name;
    bool has_guard;
}

struct StmtVar {
    Token id;
    ExprId expr;
}

struct StmtWhile {
    ExprId condition;
    ExprId post;
    StmtId body;
}

union StmtData {
    StmtBlock block_stmt;
    StmtCallNative call_native_stmt;
    StmtConst const_stmt;
    StmtExpr expr_stmt;
    StmtHandler handler_stmt;
    StmtVar   var_stmt;
    StmtWhile while_stmt;
}

struct Statement {
    StmtKind kind;
    StmtData data;
    SourceSpan span;
}

