// structures and utilities for the intermediate representation
module punk;
import std::io;
import std::collections;

//-----------------------------------------------------------------------------
// ENUMERATIONS
//-----------------------------------------------------------------------------

enum IrOp {
    ADD,
    SUB,
    MUL,
    DIV,

    NEG,
    NOT,

    HALT,

    CALL_NATIVE,
}


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct IrInst {
    IrOp op;
    int dst;
    int src1;
    int src2;
    int src3;
}

enum IrValueKind {
    INT, FLOAT,
}

union IrValueData {
    int ival;
    float fval;
}

struct IrValue {
    IrValueKind kind;
    IrValueData data;
    String name;
    bool constant;
}

struct IrBuilder {
    List{int} constants;
    List{IrValue} values;
    List{IrInst} inst;
    List{int} operands;
    ProgramImage* image;
    Diagnostics* diagnostics;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

fn void IrBuilder.destroy(IrBuilder* b) {
    b.constants.free();
    b.values.free();
    b.inst.free();
    b.operands.free();
}

//-----------------------------------------------------------------------------
fn int IrBuilder.next_addr(IrBuilder* b) {
    return (int)b.values.len();
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_binary(IrBuilder* b, IrOp op, int lhs, int rhs, String name = "") {
    IrValueKind k0 = b.values[lhs].kind;
    IrValueKind k1 = b.values[rhs].kind;
    IrValueKind kind = INT;
    if (k0 == FLOAT || k1 == FLOAT) kind = FLOAT;
    if (op == DIV) kind = FLOAT;
    IrValue v = { .kind = kind, .name = name };
    int addr = b.next_addr();
    b.values.push(v);
    IrInst inst = { .op = op, .dst = addr, .src1 = lhs, .src2 = rhs };
    b.inst.push(inst);
    return addr;
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_call_native(IrBuilder* b, int id, List{int} params, bool is_expr) {
    // io::printfn("make_call_native: %d", id);
    int dst = -1;
    if (is_expr) dst = b.next_addr();
    int op_start = (int)b.operands.len();
    foreach (p : params) {
        b.operands.push(p);
    }
    IrInst inst = { .op = CALL_NATIVE, .dst = dst, .src1 = id, .src2 = op_start, .src3 = (int)params.len() };
    b.inst.push(inst);
    return 0;
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_float(IrBuilder* b, float value, String name = "") {
    // io::printfn("make_float: %f", value);
    IrValue v = { .kind = FLOAT, .data = { .fval = value }, .constant = true, .name = name };
    int addr = b.next_addr();
    b.constants.push(addr);
    b.values.push(v);
    return addr;
}


//-----------------------------------------------------------------------------
fn void IrBuilder.make_halt(IrBuilder* b) {
    // io::printfn("make_halt");
    IrInst inst = { .op = HALT };
    b.inst.push(inst);
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_int(IrBuilder* b, int value, String name = "") {
    // io::printfn("make_int: %d", value);
    IrValue v = { .kind = INT, .data = { .ival = value }, .constant = true, .name = name };
    int addr = b.next_addr();
    b.constants.push(addr);
    b.values.push(v);
    return addr;
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_neg(IrBuilder* b, int expr, String name = "") {
    // io::printfn("make_neg: %d", expr);
    IrValueKind kind = b.values[expr].kind;
    IrValue v = { .kind = kind, .name = name };
    int addr = b.next_addr();
    b.values.push(v);
    IrInst inst = { .op = NEG, .dst = addr, .src1 = expr };
    b.inst.push(inst);
    return addr;
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_not(IrBuilder* b, int expr, String name = "") {
    // io::printfn("make_not: %d", expr);
    IrValueKind kind = b.values[expr].kind;
    IrValue v = { .kind = kind, .name = name };
    int addr = b.next_addr();
    b.values.push(v);
    IrInst inst = { .op = NOT, .dst = addr, .src1 = expr };
    b.inst.push(inst);
    return addr;
}


//-----------------------------------------------------------------------------
fn void? IrBuilder.dump(IrBuilder* b) {

    io::printn("\nIR Builder Dump:");

    foreach (c : b.constants) {
        if (b.values[c].kind == INT) {
            io::printfn("%s = CONST %d", b.dump_value(c), b.values[c].data.ival);
        }
        else {
            io::printfn("%s = CONST %f", b.dump_value(c), b.values[c].data.fval);
        }
    }
    

    io::printn("--");

    foreach (i : b.inst) {
        switch (i.op) {
            case ADD: io::printfn("%s = ADD %s, %s", b.dump_value(i.dst), b.dump_value(i.src1), b.dump_value(i.src2));
            case SUB: io::printfn("%s = SUB %s, %s", b.dump_value(i.dst), b.dump_value(i.src1), b.dump_value(i.src2));
            case MUL: io::printfn("%s = MUL %s, %s", b.dump_value(i.dst), b.dump_value(i.src1), b.dump_value(i.src2));
            case DIV: io::printfn("%s = DIV %s, %s", b.dump_value(i.dst), b.dump_value(i.src1), b.dump_value(i.src2));
            //
            case NEG: io::printfn("%s = NEG %s", b.dump_value(i.dst), b.dump_value(i.src1));
            case NOT: io::printfn("%s = NOT %s", b.dump_value(i.dst), b.dump_value(i.src1));
            //
            case HALT: io::printfn("HALT");
            //
            case CALL_NATIVE: io::printfn("CALL_NATIVE %s, %d, %d", b.image.native_funcs[i.src1].name, i.src2, i.src3);
            //
            default:
                b.diagnostics.report_irbuilder_dump_unknown_instruction(i.op);
                return IR_ERROR~;
        }
    }
}


//-----------------------------------------------------------------------------
fn String IrBuilder.dump_value(IrBuilder* b, int idx) {
    String ret = b.values[idx].name;
    if (ret.len == 0) {
        ret = string::format(mem, "%%%d", idx);
    }
    else {
        ret = string::format(mem, "%%%s", ret);
    }
    return ret;
}