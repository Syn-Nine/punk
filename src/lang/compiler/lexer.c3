//-----------------------------------------------------------------------------
// game code to token lexer
//-----------------------------------------------------------------------------
module punk;
import std::io;
import std::collections;

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct Lexer {
    Diagnostics* diagnostics;
    ByteBuffer buffer;
    int file;
    int current;
    int start;
    int line;
    HashMap{String,TokenKind} keywords;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
fn void? Lexer.init(Lexer* lex, Diagnostics* diagnostics, ByteBuffer buffer) {
    lex.diagnostics = diagnostics;
    lex.buffer = buffer;
    lex.keywords["const"] = CONST;
    lex.keywords["pi"] = PI;
    lex.keywords["true"] = TRUE;
    lex.keywords["false"] = FALSE;
    lex.keywords["start"] = START;
    lex.keywords["stop"] = STOP;
    lex.keywords["var"] = VAR;
    lex.line = 1;
}


//-----------------------------------------------------------------------------
fn bool is_alpha(char c) {
    return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '_';
}


//-----------------------------------------------------------------------------
fn bool is_digit(char c) {
    return c >= '0' && c <= '9';
}


//-----------------------------------------------------------------------------
fn bool is_alpha_numeric(char c) {
    return is_alpha(c) || is_digit(c);
}


//-----------------------------------------------------------------------------
fn char Lexer.advance(Lexer* lex) {
    lex.current++;
    return lex.buffer.bytes[lex.current - 1];
}


//-----------------------------------------------------------------------------
fn bool Lexer.is_at_end(Lexer* lex) {
    return lex.current >= lex.buffer.bytes.len;
}


//-----------------------------------------------------------------------------
fn bool Lexer.match(Lexer* lex, char c) {
    if (lex.is_at_end()) return false;
    if (lex.buffer.bytes[lex.current] != c) return false;
    lex.advance();
    return true;
}


//-----------------------------------------------------------------------------
fn char Lexer.peek(Lexer* lex) {
    if (lex.is_at_end()) return '\0';
    return lex.buffer.bytes[lex.current];
}


//-----------------------------------------------------------------------------
fn char Lexer.peek_next(Lexer* lex) {
    if (lex.current + 1 < (int)lex.buffer.bytes.len) return lex.buffer.bytes[lex.current + 1];
    return '\0';
}


//-----------------------------------------------------------------------------
fn Token Lexer.new_token(Lexer* lex, TokenKind kind) {
    String text = (String)lex.buffer.bytes[lex.start..lex.current-1];
    SourceSpan span = { lex.file, lex.line, lex.start, lex.current };
    return { kind, text, span };
}


//-----------------------------------------------------------------------------
fn Token Lexer.decimal(Lexer* lex) {
    // consume . and continue
    lex.advance();
    while (is_digit(lex.peek())) { lex.advance(); }
    return lex.new_token(FLOAT);
}


//-----------------------------------------------------------------------------
fn Token Lexer.enumval(Lexer* lex) {
    while (is_alpha_numeric(lex.peek())) { lex.advance(); }
    return lex.new_token(ENUM);
}


//-----------------------------------------------------------------------------
fn Token Lexer.identifier(Lexer* lex) {
    while (is_alpha_numeric(lex.peek())) { lex.advance(); }
    String text = (String)lex.buffer.bytes[lex.start..lex.current-1];
    TokenKind? kind = lex.keywords[text];
    if (catch err = kind) return lex.new_token(IDENTIFIER);
    return lex.new_token(kind);
}


//-----------------------------------------------------------------------------
fn Token Lexer.number(Lexer* lex) {
    while (is_digit(lex.peek())) { lex.advance(); }
    if (lex.peek() == '.' && is_digit(lex.peek_next())) return lex.decimal();
    return lex.new_token(INTEGER);
}


//-----------------------------------------------------------------------------
fn bool is_whitespace(char c) {
    return c == ' ' || c == '\t' || c == '\r';
}


//-----------------------------------------------------------------------------
fn Token? Lexer.scan_token(Lexer* lex) {

    if (lex.is_at_end()) return lex.new_token(EOF);

    // strip whitespace
    char c = '\0';
    do { c = lex.advance(); }
    while (!lex.is_at_end() && is_whitespace(c));
    lex.start = lex.current-1;
    
    switch (c) {
        // single character tokens
        case ',': return lex.new_token(COMMA);
        case '(': return lex.new_token(L_PAREN);
        case ')': return lex.new_token(R_PAREN);
        case '{': return lex.new_token(L_BRACE);
        case '}': return lex.new_token(R_BRACE);
        case '[': return lex.new_token(L_BRACKET);
        case ']': return lex.new_token(R_BRACKET);
        case '+': return lex.new_token(PLUS);
        case '-': return lex.new_token(MINUS);
        case '*': return lex.new_token(STAR);
        case '/': return lex.new_token(SLASH);
        case '^': return lex.new_token(HAT);
        case '%': return lex.new_token(PERCENT);
        case ';': return lex.new_token(EOL);
        case ':': return is_alpha(lex.peek()) ? lex.enumval() : SRC_ERROR~;
        case '.': return is_digit(lex.peek()) ? lex.decimal() : SRC_ERROR~;
        case '=': return lex.match('=') ? lex.new_token(EQUAL_EQUAL) : lex.new_token(EQUAL);
        case '!': return lex.match('=') ? lex.new_token(BANG_EQUAL) : lex.new_token(BANG);
        case '<': return lex.match('=') ? lex.new_token(LESS_EQUAL) : lex.new_token(LESS);
        case '>': return lex.match('=') ? lex.new_token(GREATER_EQUAL) : lex.new_token(GREATER);
        case '&': return lex.match('&') ? lex.new_token(AND) : SRC_ERROR~;
        case '|': return lex.match('|') ? lex.new_token(OR) : SRC_ERROR~;
        case '\n': 
            lex.line++;
            return lex.new_token(EOL);
        case '#':
            while (!lex.is_at_end() && c != '\n') { c = lex.advance(); }
            return lex.new_token(EOL);

        default:
            if (is_digit(c)) {
                return lex.number();
            }
            else if (is_alpha(c)) {
                return lex.identifier();
            }

            // unexpected character
            SourceSpan span = {
                .file_id = 0,
                .line = lex.line,
                .start = lex.start,
                .end = lex.current
            };
            lex.diagnostics.report_lexer_unexpected_character(span, c);
            return SRC_ERROR~;
    }

    // STRING,
    
}