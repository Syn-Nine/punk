//-----------------------------------------------------------------------------
// parser to build AST
//-----------------------------------------------------------------------------
module punk;
import std::io;


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct Parser {
    Lexer lexer;
    Token next;
    Token next_next;
    Ast* ast;
    Diagnostics* diagnostics;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
fn Token? Parser.advance(Parser* p) {
    Token current = p.next;
    p.next = p.next_next;
    p.next_next = p.lexer.scan_token()!;
    return current;
}


//-----------------------------------------------------------------------------
fn bool Parser.check(Parser* p, TokenKind kind) {
    return p.next.kind == kind;
}


//-----------------------------------------------------------------------------
fn bool Parser.check_any(Parser* p, TokenKind... kinds) {
    foreach (k : kinds) {
        if (p.next.kind == k) return true;
    }
    return false;
}


//-----------------------------------------------------------------------------
fn bool Parser.check_next(Parser* p, TokenKind kind) {
    return p.next_next.kind == kind;
}


//-----------------------------------------------------------------------------
fn Token? Parser.consume(Parser* p, TokenKind kind, String message) {
    if (p.next.kind != kind) {
        p.diagnostics.report_parser_consume_error(p.next.span, message);
        return SRC_ERROR~;
    }
    return p.advance()!;
}


//-----------------------------------------------------------------------------
fn void? Parser.consume_eol(Parser* p) {
    if (p.is_at_end()) return;
    p.consume(EOL, "expected end of line.")!;
}


//-----------------------------------------------------------------------------
fn void? Parser.init(Parser* p, Ast* ast, Diagnostics* diagnostics, ByteBuffer buffer) {
    p.diagnostics = diagnostics;
    p.lexer.init(diagnostics, buffer)!;
    p.next = p.lexer.scan_token()!;
    p.next_next = p.lexer.scan_token()!;
    p.ast = ast;
}


//-----------------------------------------------------------------------------
fn bool Parser.is_at_end(Parser* p) {
    return p.peek().kind == EOF;
}


//-----------------------------------------------------------------------------
fn Token Parser.peek(Parser* p) {
    return p.next;
}


//-----------------------------------------------------------------------------
fn StmtId? Parser.parse_module(Parser* p, Ast* ast, Diagnostics* diagnostics, ByteBuffer buffer) {
    diagnostics.info("Parsing Module");
    p.init(ast, diagnostics, buffer)!;
    
    StmtIdList global;
    while (!p.is_at_end()) {
        StmtId id = p.statement()!;
        if (-1 == id) continue;
        StmtKind kind = ast.statements[(sz)id].kind;
        if (kind == CONST || kind == VAR) global.push(id);
    }

    Statement stmt = {
        .kind = BLOCK,
        .data = { .block_stmt = { global }},
    };
    return p.push_stmt(stmt);
}


//-----------------------------------------------------------------------------
fn StmtId? Parser.statement(Parser* p) {

    while (p.check(EOL)) { p.advance()!; } // skip blank lines
    if (p.is_at_end()) return -1; // nothing to do

    if (p.check(L_BRACE)) return p.block_stmt()!;
    if (p.check_any(START)) return p.handler_stmt()!;
    if (p.check(IDENTIFIER) && p.check_next(L_PAREN)) return p.call_stmt()!;
    // if (p.check(CONST)) return p.const_stmt()!;
    // if (p.check(VAR)) return p.var_stmt()!;

    return p.expr_stmt();
}


//-----------------------------------------------------------------------------
fn StmtId? Parser.block_stmt(Parser* p) {
    SourceSpan span;
    span.start = p.peek().span.start;
    p.advance()!; // consume '{'

    StmtIdList body;
    while (!p.is_at_end() && !p.check(R_BRACE)) {
        StmtId id = p.statement()!;
        if (-1 < id) body.push(id);
    }
    
    span.end = p.peek().span.end;
    p.consume(R_BRACE, "expected '}' for block.")!;
    p.consume_eol()!;

    Statement stmt = {
        .kind = BLOCK,
        .data = { .block_stmt = { body }},
        .span = span
    };
    return p.push_stmt(stmt);
}


//-----------------------------------------------------------------------------
fn StmtId? Parser.handler_stmt(Parser* p) {
    Token id = p.advance()!;

    if (!p.check(L_BRACE)) {
        p.diagnostics.report_parser_expected_lbrace_for_handler(p.peek());
        return SRC_ERROR~;
    }
    
    StmtId body = p.statement()!;
    Statement stmt = {
        .kind = HANDLER,
        .data = { .handler_stmt = { .body = body, .name = id.text } },
        .span = id.span
    };
    return p.push_stmt(stmt);
}


//-----------------------------------------------------------------------------
fn StmtId? Parser.call_stmt(Parser* p) {
    Token id = p.advance()!;
    p.advance()!; // consume '('
    ExprIdList params;
    if (!p.check(R_PAREN)) {
        while (true) {
            params.push(p.expression()!);
            if (p.check(R_PAREN)) break;
            p.consume(COMMA, "expected ',' after parameter.")!;
        }
    }
    
    p.consume(R_PAREN, "expected ')' after expression.")!;
    p.consume_eol()!;
    Statement stmt = {
        .kind = CALL_NATIVE,
        .data = { .call_native_stmt = { .id = id.text, .params = params } }
    };
    return p.push_stmt(stmt);
}


//-----------------------------------------------------------------------------
// fn void? Parser.const_stmt(Parser* p) {
//     // io::printn("const_stmt");
//     Token prev = p.advance()!;
// }


//-----------------------------------------------------------------------------
// fn void? Parser.var_stmt(Parser* p) {
//     // io::printn("var_stmt");
//     // format: var id = val
//     p.advance()!; // consume var
//     Token id = p.consume(IDENTIFIER, "expected identifier.")!;
//     p.consume(EQUAL, "expected identifier.")!;
//     ExprId expr = p.expression()!;
//     p.consume_eol()!;
// }


//-----------------------------------------------------------------------------
fn StmtId? Parser.expr_stmt(Parser* p) {
    // io::printn("expr_stmt");
    ExprId expr = p.expression()!;
    Statement stmt = {
        .kind = EXPRESSION,
        .data = { .expr_stmt = { expr } },
        .span = p.ast.expressions[expr].span
    };
    return p.push_stmt(stmt);
}


//-----------------------------------------------------------------------------
fn ExprId? Parser.expression(Parser* p) {
    // io::printn("expression");
    return p.addition()!;
}


//-----------------------------------------------------------------------------
fn ExprId? Parser.addition(Parser* p) {
    ExprId expr = p.multiplication()!;
    while (p.check_any(TokenKind.PLUS, TokenKind.MINUS)) {
        Token op = p.advance()!;
        ExprId rhs = p.multiplication()!;
        expr = p.new_binary_expr(expr, op, rhs);
    }
    return expr;
}


//-----------------------------------------------------------------------------
fn ExprId? Parser.multiplication(Parser* p) {
    ExprId expr = p.power()!;
    while (p.check_any(TokenKind.STAR, TokenKind.SLASH)) {
        Token op = p.advance()!;
        ExprId rhs = p.power()!;
        expr = p.new_binary_expr(expr, op, rhs);
    }
    return expr;
}


//-----------------------------------------------------------------------------
fn ExprId? Parser.power(Parser* p) {
    ExprId expr = p.modulus()!;
    while (p.check(HAT)) {
        Token op = p.advance()!;
        ExprId rhs = p.modulus()!;
        expr = p.new_binary_expr(expr, op, rhs);
    }
    return expr;
}


//-----------------------------------------------------------------------------
fn ExprId? Parser.modulus(Parser* p) {
    ExprId expr = p.unary()!;
    while (p.check(PERCENT)) {
        Token op = p.advance()!;
        ExprId rhs = p.unary()!;
        expr = p.new_binary_expr(expr, op, rhs);
    }
    return expr;
}


//-----------------------------------------------------------------------------
fn ExprId? Parser.unary(Parser* p) {
    if (p.check_any(TokenKind.BANG, TokenKind.MINUS)) {
        Token op = p.advance()!;
        ExprId rhs = p.unary()!;
        return p.new_unary_expr(op, rhs);
    }
    return p.primary();
}


//-----------------------------------------------------------------------------
fn ExprId? Parser.primary(Parser* p) {
    // io::printn("primary");
    
    if (p.check(INTEGER) || p.check(FLOAT) || p.check(STRING) || p.check(ENUM)) {
        return p.new_literal_expr(p.advance()!);
    }

    if (p.check(L_PAREN)) {
        p.advance()!; // consume '('
        ExprId expr = p.expression()!;
        p.consume(R_PAREN, "expected ')' after expression.")!;
        return p.new_group_expr(expr);
    }

    p.diagnostics.report_parser_expected_expression(p.peek());
    return SRC_ERROR~;
}


//-----------------------------------------------------------------------------
fn StmtId Parser.push_stmt(Parser* p, Statement stmt) {
    p.ast.statements.push(stmt);
    return (ExprId)(p.ast.statements.len()-1);
}

//-----------------------------------------------------------------------------
fn ExprId Parser.push_expr(Parser* p, Expression expr) {
    p.ast.expressions.push(expr);
    return (ExprId)(p.ast.expressions.len()-1);
}


//-----------------------------------------------------------------------------
fn ExprId Parser.new_binary_expr(Parser* p, ExprId lhs, Token op, ExprId rhs) {
    Expression expr = {
        .kind = BINARY,
        .data = { .binary_expr = { lhs, op, rhs } }
    };
    return p.push_expr(expr);
}


//-----------------------------------------------------------------------------
fn ExprId Parser.new_group_expr(Parser* p, ExprId value) {
    Expression expr = {
        .kind = GROUP,
        .data = { .group_expr = { .expr = value } }
    };
    return p.push_expr(expr);
}


//-----------------------------------------------------------------------------
fn ExprId Parser.new_literal_expr(Parser* p, Token value) {
    Expression expr = {
        .kind = LITERAL,
        .data = { .literal_expr = { value } }
    };
    return p.push_expr(expr);
}


//-----------------------------------------------------------------------------
fn ExprId Parser.new_unary_expr(Parser* p, Token op, ExprId rhs) {
    Expression expr = {
        .kind = UNARY,
        .data = { .unary_expr = { op, rhs } }
    };
    return p.push_expr(expr);
}