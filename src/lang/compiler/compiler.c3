// compiler context and utilities
module punk;
import std::collections;
import std::io;


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct Compiler {
    List{Ast} modules;
    ProgramImage* image;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
fn void? Compiler.compile(Compiler* ctx, Diagnostics* diagnostics, ByteBuffer bytes) {

    Ast ast; defer ast.destroy();
    Parser p;
    p.parse_module(&ast, diagnostics, bytes)!;

    if (ast.statements.len() == 0) return;

    ctx.image = mem::new(ProgramImage);
    ctx.image.diagnostics = diagnostics;
    
    io::printn(ast);


    foreach (s : ast.statements) {
        io::printn(s.kind);
    }

    foreach (e : ast.expressions) {
        io::printn(e.kind);
    }
    
    IrBuilder b;
    b.diagnostics = diagnostics;

    ctx.image.register_native("print", 0, &native_print);
    
    b.image = ctx.image;

    for (int i = 0; i < ast.statements.len(); i++) {
        stmt_codegen(&ast, &b, i)!;
    }
    b.make_halt();
    b.dump()!;
    

    bc_codegen(&b, ctx.image)!;
    ctx.image.dump()!;
    
}


//-----------------------------------------------------------------------------
fn void Compiler.destroy(Compiler* ctx) {
    foreach (m : ctx.modules) {
        m.destroy();
    }
    ctx.modules.free();
}


//-----------------------------------------------------------------------------
fn void? stmt_codegen(Ast* ast, IrBuilder* b, int idx) {
    io::printn("stmt_codegen");
    Statement* stmt = &ast.statements[idx];
    switch (stmt.kind) {
        case CALL_NATIVE: stmt_codegen_call_native(ast, b, stmt.data.call_native_stmt)!;
        case EXPRESSION: expr_codegen(ast, b, stmt.data.expr_stmt.expr)!;
        default:
            b.diagnostics.report_compiler_unexpected_statement_kind(*stmt);
            return IR_ERROR~;
    }
}


fn void? stmt_codegen_call_native(Ast* ast, IrBuilder* b, StmtCallNative stmt) {
    int id = b.image.native_lookup.get(stmt.id)!;
    List{int} values;
    foreach (p : stmt.params) {
        values.push(expr_codegen(ast, b, p)!);
    }
    b.make_call_native(id, values, false);
}


//-----------------------------------------------------------------------------
fn int? expr_codegen(Ast* ast, IrBuilder* b, int idx) {
    Expression* expr = &ast.expressions[idx];
    switch (expr.kind) {
        case BINARY: return expr_codegen_binary(ast, b, expr.data.binary_expr)!;
        case GROUP: return expr_codegen_group(ast, b, expr.data.group_expr)!;
        case LITERAL: return expr_codegen_literal(ast, b, expr.data.literal_expr)!;
        // case LOGICAL: return expr_codegen_logical(ast, expr.data.logical_expr)!;
        case UNARY: return expr_codegen_unary(ast, b, expr.data.unary_expr)!;
        default:
            b.diagnostics.report_compiler_unexpected_expression_kind(*expr);
            break;
    }
    return IR_ERROR~;
}


//-----------------------------------------------------------------------------
fn int? expr_codegen_binary(Ast* ast, IrBuilder* b, ExprBinary expr) {
    io::printn("expr_codegen_binary");
    int lhs = expr_codegen(ast, b, expr.lhs)!;
    int rhs = expr_codegen(ast, b, expr.rhs)!;
    switch (expr.op.kind) {
        case PLUS: return b.make_binary(ADD, lhs, rhs);
        case MINUS: return b.make_binary(SUB, lhs, rhs);
        case STAR: return b.make_binary(MUL, lhs, rhs);
        case SLASH: return b.make_binary(DIV, lhs, rhs);
        default:
            b.diagnostics.report_compiler_unexpected_binary_kind(expr.op);
            break;
    }
    return IR_ERROR~;
}


//-----------------------------------------------------------------------------
fn int? expr_codegen_group(Ast* ast, IrBuilder* b, ExprGroup expr) {
    io::printn("expr_codegen_group");
    return expr_codegen(ast, b, expr.expr)!;
}


//-----------------------------------------------------------------------------
fn int? expr_codegen_literal(Ast* ast, IrBuilder* b, ExprLiteral expr) {
    io::printn("expr_codegen_literal");
    switch (expr.value.kind) {
        case INTEGER: return b.make_int(expr.value.text.to_int()!);
        case FLOAT: return b.make_float(expr.value.text.to_float()!);
        default:
            b.diagnostics.report_compiler_unexpected_value_kind(expr.value);
            break;
    }
    return IR_ERROR~;
}


//-----------------------------------------------------------------------------
fn int? expr_codegen_unary(Ast* ast, IrBuilder* b, ExprUnary expr) {
    io::printn("expr_codegen_unary");
    int rhs = expr_codegen(ast, b, expr.rhs)!;
    switch (expr.op.kind) {
        case BANG: return b.make_not(rhs);
        case MINUS: return b.make_neg(rhs);
        default:
            b.diagnostics.report_compiler_unexpected_unary_kind(expr.op);
            break;
    }
    return IR_ERROR~;
}