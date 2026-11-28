//-----------------------------------------------------------------------------
// token enumeration and utilities
//-----------------------------------------------------------------------------
module punk;
import std::collections;

//-----------------------------------------------------------------------------
// ENUMERATIONS
//-----------------------------------------------------------------------------

enum TokenKind {
    // syntax
    COMMA, MINUS, PLUS, STAR, SLASH, HAT, PERCENT,
    L_PAREN, R_PAREN, L_BRACE, R_BRACE, L_BRACKET, R_BRACKET,
    BANG, EQUAL, GREATER, LESS, OR, AND,
    BANG_EQUAL, EQUAL_EQUAL, GREATER_EQUAL, LESS_EQUAL,
    IDENTIFIER, STRING, INTEGER, FLOAT, ENUM,
    
    // keywords
    CONST,
    FALSE, 
    TRUE,
    PI,
    START,
    STOP,
    VAR,
    
    //
    EOL,
    EOF,
    INVALID,
}

alias TokenKindList = List{TokenKind};

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct Token {
    TokenKind kind;
    String text;
    SourceSpan span;
}