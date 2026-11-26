// data structure for a module's abstract syntax tree
module punk;
import std::collections;


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct Global { Token id; ExprId expr; }


struct Ast {
    List{Global} globals;
    List{Expression} expressions;
    List{Statement} statements;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

fn void Ast.destroy(Ast* ast) {
    ast.globals.free();
    ast.expressions.free();
    ast.statements.free();
}