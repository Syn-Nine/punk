//-----------------------------------------------------------------------------
// structures and utilities for the intermediate representation
//-----------------------------------------------------------------------------
module punk;
import std::io;
import std::collections;

//-----------------------------------------------------------------------------
// ENUMERATIONS
//-----------------------------------------------------------------------------

enum IrOp {
    LOAD_INT,
    LOAD_FLOAT,

    ADD,
    SUB,
    MUL,
    DIV,

    NEG,
    NOT,

    STOP,

    CALL_NATIVE,

    RET,
    RET_VOID,
}

enum IrValueKind {
    INT, FLOAT,
}

enum IrTermKind {
    OPEN, JUMP, BRANCH, RET_VALUE, RET_VOID,
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

struct IrTerm {
    IrTermKind kind;
    int jmp_tgt;
}

struct IrBlock {
    List{IrInst} inst;
    IrTerm term;
    String name;
    int ftn;
}

struct IrFunction {
    List{int} block_ptrs;
    List{IrValue} values;
    String name;
}

struct IrBuilder {
    List{int} operands;
    List{IrBlock} blocks;
    List{IrFunction} funcs;
    List{IrValue} statics;
    ProgramImage* image;
    Diagnostics* diagnostics;
    int block_ptr;
    int func_ptr;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
fn void IrBuilder.init(IrBuilder* self, Diagnostics* diagnostics, ProgramImage* image) {
    self.diagnostics = diagnostics;
    self.image = image;
}
    

//-----------------------------------------------------------------------------
fn void IrBuilder.destroy(IrBuilder* b) {
    // b.constants.free();
    
    // foreach (b : b.blocks) {
    //     b.inst.free();
    // }
    // b.blocks.free();
    
    // foreach (f : b.funcs) {    
    //     f.values.free();
    //     f.block_ptrs.free();
    // }
    // b.funcs.free();
    
    // b.operands.free();
}


//-----------------------------------------------------------------------------
fn IrBlock* IrBuilder.get_bp(IrBuilder* b) {
    return &b.blocks[b.block_ptr];
}


//-----------------------------------------------------------------------------
fn IrFunction* IrBuilder.get_fp(IrBuilder* b) {
    return &b.funcs[b.func_ptr];
}


//-----------------------------------------------------------------------------
fn int IrFunction.next_addr(IrFunction* fp) {
    return (int)fp.values.len();
}


//-----------------------------------------------------------------------------
fn int IrBuilder.next_static(IrBuilder* b) {
    return (int)b.statics.len();
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_basic_block(IrBuilder* b, String name = "", int func_ptr = -1) {
    int idx = (int)b.blocks.len();
    b.blocks.push({
        .ftn = func_ptr,
        .name = name,
        .term = { .kind = OPEN }
    });
    if (func_ptr > -1) {
        b.funcs[func_ptr].block_ptrs.push(idx);
    }
    return idx;
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_binary(IrBuilder* b, IrOp op, int lhs, int rhs, String name = "") {
    IrFunction* fp = b.get_fp();
    IrBlock* bp = b.get_bp();
    IrValueKind k0 = fp.values[lhs].kind;
    IrValueKind k1 = fp.values[rhs].kind;
    IrValueKind kind = INT;
    if (k0 == FLOAT || k1 == FLOAT) kind = FLOAT;
    if (op == DIV) kind = FLOAT;
    IrValue v = { .kind = kind, .name = name };
    int addr = fp.next_addr();
    fp.values.push(v);
    IrInst inst = { .op = op, .dst = addr, .src1 = lhs, .src2 = rhs };
    bp.inst.push(inst);
    return addr;
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_call_native(IrBuilder* b, int id, List{int} params, bool is_expr) {
    // io::printfn("make_call_native: %d", id);
    IrFunction* fp = b.get_fp();
    IrBlock* bp = b.get_bp();
    int dst = -1;
    if (is_expr) dst = fp.next_addr();
    int op_start = (int)b.operands.len();
    foreach (p : params) {
        b.operands.push(p);
    }
    IrInst inst = { .op = CALL_NATIVE, .dst = dst, .src1 = id, .src2 = op_start, .src3 = (int)params.len() };
    bp.inst.push(inst);
    return 0;
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_float(IrBuilder* b, float value, String name = "") {
    // io::printfn("make_float: %f", value);
    IrFunction* fp = b.get_fp();
    IrBlock* bp = b.get_bp();
    
    IrValue sval = { .kind = FLOAT, .data = { .fval = value }, .constant = true, .name = name };
    int saddr = b.next_static();
    b.statics.push(sval);
    
    IrValue v = { .kind = sval.kind, .name = name };
    int addr = fp.next_addr();
    fp.values.push(v);

    IrInst inst = { .op = LOAD_FLOAT, .dst = addr, .src1 = saddr };
    bp.inst.push(inst);
    return addr;
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_function(IrBuilder* b, String name) {
    int ftn = (int)b.funcs.len();
    b.funcs.push({ .name = name });
    return ftn;
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_int(IrBuilder* b, int value, String name = "") {
    // io::printfn("make_int: %d", value);
    IrFunction* fp = b.get_fp();
    IrBlock* bp = b.get_bp();
    
    IrValue sval = { .kind = INT, .data = { .ival = value }, .constant = true, .name = name };
    int saddr = b.next_static();
    b.statics.push(sval);
    
    IrValue v = { .kind = sval.kind, .name = name };
    int addr = fp.next_addr();
    fp.values.push(v);

    IrInst inst = { .op = LOAD_INT, .dst = addr, .src1 = saddr };
    bp.inst.push(inst);
    return addr;
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_neg(IrBuilder* b, int expr, String name = "") {
    // io::printfn("make_neg: %d", expr);
    IrFunction* fp = b.get_fp();
    IrBlock* bp = b.get_bp();
    IrValueKind kind = fp.values[expr].kind;
    IrValue v = { .kind = kind, .name = name };
    int addr = fp.next_addr();
    fp.values.push(v);
    IrInst inst = { .op = NEG, .dst = addr, .src1 = expr };
    bp.inst.push(inst);
    return addr;
}


//-----------------------------------------------------------------------------
fn int IrBuilder.make_not(IrBuilder* b, int expr, String name = "") {
    // io::printfn("make_not: %d", expr);
    IrFunction* fp = b.get_fp();
    IrBlock* bp = b.get_bp();
    IrValueKind kind = fp.values[expr].kind;
    IrValue v = { .kind = kind, .name = name };
    int addr = fp.next_addr();
    fp.values.push(v);
    IrInst inst = { .op = NOT, .dst = addr, .src1 = expr };
    bp.inst.push(inst);
    return addr;
}


//-----------------------------------------------------------------------------
fn void IrBuilder.make_ret_void(IrBuilder* b) {
    // io::printfn("make_ret_void");
    IrBlock* bp = b.get_bp();
    IrInst inst = { .op = RET_VOID };
    bp.inst.push(inst);
    bp.term = { .kind = RET_VOID };
}


//-----------------------------------------------------------------------------
fn void IrBuilder.make_stop(IrBuilder* b) {
    // io::printfn("make_halt");
    IrBlock* bp = b.get_bp();
    IrInst inst = { .op = STOP };
    bp.inst.push(inst);
}


//-----------------------------------------------------------------------------
fn void IrBuilder.set_block(IrBuilder* b, int idx) {
    b.block_ptr = idx;
}


//-----------------------------------------------------------------------------
fn void IrBuilder.set_function(IrBuilder* b, int idx) {
    b.func_ptr = idx;
}



//-----------------------------------------------------------------------------
fn void? IrBuilder.verify_func(IrBuilder* b, int ftn) {
    // make sure all basic blocks are closed
    for (int i = 0; i < b.funcs[ftn].block_ptrs.len(); i++) {
        int bidx = b.funcs[ftn].block_ptrs[i];
        if (b.blocks[bidx].term.kind == OPEN) {
            String bbname = b.blocks[bidx].name;
            if (bbname.len == 0) bbname = string::format(mem, "BB_%d", bidx);
            b.diagnostics.report_irbuilder_func_failed_bb_closed_check(
                b.funcs[ftn].name,
                bbname
            );
            return IR_ERROR~;
        }
    }
}


//-----------------------------------------------------------------------------
fn void? IrBuilder.dump(IrBuilder* b) {

    io::printn("\nIR Builder Dump:");
    b.dump_statics()!;
    
    for (int i = 0; i < b.funcs.len(); i++) {
        b.dump_func(i)!;
    }

    io::printn("");
}


//-----------------------------------------------------------------------------
fn void? IrBuilder.dump_block(IrBuilder* b, int ftn, int bidx) {
    
    if (b.blocks[bidx].name.len == 0) {
        io::printfn("BB_%d:", bidx);
    } else {
        io::printfn("BB_%s:", b.blocks[bidx].name);
    }

    foreach (i : b.blocks[bidx].inst) {
        switch (i.op) {
            case LOAD_INT:   io::printfn("  %s = LOAD_INT %d", b.dump_value(ftn, i.dst), b.statics[i.src1].data.ival);
            case LOAD_FLOAT: io::printfn("  %s = LOAD_FLOAT %f", b.dump_value(ftn, i.dst), b.statics[i.src1].data.fval);
            //
            case ADD: io::printfn("  %s = ADD %s, %s", b.dump_value(ftn, i.dst), b.dump_value(ftn, i.src1), b.dump_value(ftn, i.src2));
            case SUB: io::printfn("  %s = SUB %s, %s", b.dump_value(ftn, i.dst), b.dump_value(ftn, i.src1), b.dump_value(ftn, i.src2));
            case MUL: io::printfn("  %s = MUL %s, %s", b.dump_value(ftn, i.dst), b.dump_value(ftn, i.src1), b.dump_value(ftn, i.src2));
            case DIV: io::printfn("  %s = DIV %s, %s", b.dump_value(ftn, i.dst), b.dump_value(ftn, i.src1), b.dump_value(ftn, i.src2));
            //
            case NEG: io::printfn("  %s = NEG %s", b.dump_value(ftn, i.dst), b.dump_value(ftn, i.src1));
            case NOT: io::printfn("  %s = NOT %s", b.dump_value(ftn, i.dst), b.dump_value(ftn, i.src1));
            //
            case STOP: io::printn("  STOP");
            //
            case CALL_NATIVE: io::printfn("  CALL_NATIVE %s, operand=%d, count=%d", b.image.native_funcs[i.src1].name, i.src2, i.src3);
            //
            case RET: io::printn("  RET");
            case RET_VOID: io::printn("  RET_VOID");
            //
            default:
                b.diagnostics.report_irbuilder_dump_unknown_instruction(i.op);
                return IR_ERROR~;
        }
    }
}


//-----------------------------------------------------------------------------
fn void? IrBuilder.dump_func(IrBuilder* b, int ftn) {
    
    io::printfn("\nFunction: %s", b.funcs[ftn].name);

    for (int i = 0; i < b.funcs[ftn].block_ptrs.len(); i++) {
        b.dump_block(ftn, b.funcs[ftn].block_ptrs[i])!;
    }
}


//-----------------------------------------------------------------------------
fn void? IrBuilder.dump_statics(IrBuilder* b) {
    io::printn("Static Registers:");
    for (int i = 0; i < b.statics.len(); i++) {
        if (b.statics[i].kind  == INT) {
            io::printfn("  %d: INT:   %d", i, b.statics[i].data.ival);
        }
        else {
            io::printfn("  %d: FLOAT: %f", i, b.statics[i].data.fval);
        }
    }
}


//-----------------------------------------------------------------------------
fn String IrBuilder.dump_value(IrBuilder* b, int ftn, int idx) {
    String ret = b.funcs[ftn].values[idx].name;
    if (ret.len == 0) {
        ret = string::format(mem, "%%%d", idx);
    }
    else {
        ret = string::format(mem, "%%%s", ret);
    }
    return ret;
}