//-----------------------------------------------------------------------------
// compiler context and utilities
//-----------------------------------------------------------------------------
module punk;
import std::collections;
import std::io;


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct Compiler {
    List{Ast} modules;
    ProgramImage* image;
    Diagnostics* diagnostics;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
fn void? Compiler.compile(Compiler* self, ProgramImage* image, ByteBuffer bytes) {

    Ast ast; defer ast.destroy();
    Parser p;
    StmtId global_block = p.parse_module(&ast, self.diagnostics, bytes)!;
    if (ast.statements.is_empty()) {
        self.diagnostics.report_compiler_module_is_empty();
    }
    
    bool debug = false;
    if (debug) {
        io::printn("AST:");
        io::printn(ast);

        io::printn("\nStatements:");
        foreach (s : ast.statements) {
            io::printn(s.kind);
        }

        io::printn("\nExpressions:");
        foreach (e : ast.expressions) {
            io::printn(e.kind);
        }
    }
    
    self.image = image;
    self.image.register_native("print", 0, &native_print);
    
    IrBuilder b;
    b.init(self.diagnostics, self.image);
    
    self.diagnostics.info("Compiling Game");

    // codegen handlers
    for (int s = 0; s < ast.statements.len(); s++) {
        if (ast.statements[s].kind == HANDLER) {
            handler_codegen(&ast, &b, s)!;
        }
    }

    global_codegen(&ast, &b, global_block)!;
    b.dump()!;

    bc_codegen(&b, self.image)!;
    self.image.dump()!;
}


//-----------------------------------------------------------------------------
fn void Compiler.destroy(Compiler* self) {
    foreach (m : self.modules) {
        m.destroy();
    }
    self.modules.free();
}


//-----------------------------------------------------------------------------
fn void? global_codegen(Ast* ast, IrBuilder* b, int idx) {
    int ftn = b.make_function("__global");
    b.set_function(ftn);

    int bb = b.make_basic_block("entry", ftn);
    b.set_block(bb);

    stmt_codegen(ast, b, idx)!;
    
    b.make_ret_void();
    b.verify_func(ftn)!;
}


//-----------------------------------------------------------------------------
fn void? handler_codegen(Ast* ast, IrBuilder* b, int idx) {
    StmtHandler* stmt = &ast.statements[idx].data.handler_stmt;
    
    int ftn = b.make_function(stmt.name);
    b.set_function(ftn);

    int bb = b.make_basic_block("entry", ftn);
    b.set_block(bb);

    stmt_codegen(ast, b, stmt.body)!;
    
    b.make_ret_void();
    b.verify_func(ftn)!;
}


//-----------------------------------------------------------------------------
fn void? stmt_codegen(Ast* ast, IrBuilder* b, int idx) {
    // io::printn("stmt_codegen");
    Statement* stmt = &ast.statements[idx];
    switch (stmt.kind) {
        case BLOCK: stmt_codegen_block(ast, b, stmt.data.block_stmt)!;
        case CALL_NATIVE: stmt_codegen_call_native(ast, b, stmt.data.call_native_stmt)!;
        case EXPRESSION: expr_codegen(ast, b, stmt.data.expr_stmt.expr)!;
        default:
            b.diagnostics.report_compiler_unexpected_statement_kind(*stmt);
            return IR_ERROR~;
    }
}


//-----------------------------------------------------------------------------
fn void? stmt_codegen_block(Ast* ast, IrBuilder* b, StmtBlock stmt) {
    foreach (s : stmt.body) {
        stmt_codegen(ast, b, s)!;
    }
}


//-----------------------------------------------------------------------------
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
    // io::printn("expr_codegen_binary");
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
    // io::printn("expr_codegen_group");
    return expr_codegen(ast, b, expr.expr)!;
}


//-----------------------------------------------------------------------------
fn int? expr_codegen_literal(Ast* ast, IrBuilder* b, ExprLiteral expr) {
    // io::printn("expr_codegen_literal");
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
    // io::printn("expr_codegen_unary");
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