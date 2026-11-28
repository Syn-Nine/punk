//-----------------------------------------------------------------------------
// structure and utilities for the bytecode image
//-----------------------------------------------------------------------------
module punk;
import std::io;
import std::collections;

//-----------------------------------------------------------------------------
// ENUMERATIONS
//-----------------------------------------------------------------------------

enum VmOp {
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
    MOV,

    RET,
    RET_VOID,
}

enum VmValueKind {
    INT,
    FLOAT,
}


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct VmInst {
    VmOp op;
    int dst;
    int src1;
    int src2;
    int src3;
}

union VmValueData {
    int ival;
    float fval;
}

struct VmValue (Printable) {
    VmValueKind kind;
    VmValueData data;
}


struct VmFunction {
    String name;
    int code_start;
    int code_count;
    int register_count;
    int param_count;
}

struct ProgramImage {
    List{VmInst} code;
    List{VmValue} statics;
    List{VmFunction} functions;
    List{NativeFn} native_funcs;
    HashMap{String,int} func_lookup;
    HashMap{String,int} native_lookup;
    Diagnostics* diagnostics;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
fn sz? VmValue.to_format(&self, Formatter* formatter) @dynamic {
    DString out = dstring::new(mem); defer out.free();
    switch (self.kind) {
        case INT: out.appendf("%d", self.data.ival);
        case FLOAT: out.appendf("%f", self.data.fval);
        default: break;
    }
    return formatter.print(out.str_view());
}


//-----------------------------------------------------------------------------
fn void? ProgramImage.dump(ProgramImage* image) {

    io::printn("\nImage Dump:");

    for (int ii = 0; ii < image.code.len(); ii++) {
        VmInst* i = &image.code[ii];
        io::printf("%d:", ii);
        switch (i.op) {
            case LOAD_INT:   io::printfn("  %%%d = LOAD_INT %d", i.dst, image.statics[i.src1].data.ival);
            case LOAD_FLOAT: io::printfn("  %%%d = LOAD_FLOAT %f", i.dst, image.statics[i.src1].data.fval);
            //
            case ADD: io::printfn("  %%%d = ADD %%%d, %%%d", i.dst, i.src1, i.src2);
            case SUB: io::printfn("  %%%d = SUB %%%d, %%%d", i.dst, i.src1, i.src2);
            case MUL: io::printfn("  %%%d = MUL %%%d, %%%d", i.dst, i.src1, i.src2);
            case DIV: io::printfn("  %%%d = DIV %%%d, %%%d", i.dst, i.src1, i.src2);
            //
            case NEG: io::printfn("  %%%d = NEG %%%d", i.dst, i.src1);
            case NOT: io::printfn("  %%%d = NOT %%%d", i.dst, i.src1);
            //
            case STOP: io::printfn("  STOP");
            //
            case CALL_NATIVE: io::printfn("  CALL_NATIVE %d, %%%d, %d", i.src1, i.src2, i.src3);
            case MOV: io::printfn("  MOV %%%d, %%%d", i.dst, i.src1);
            //
            case RET: io::printn("  RET");
            case RET_VOID: io::printn("  RET_VOID");
            //
            default:
                image.diagnostics.report_vm_dump_unknown_instruction(i.op);
                io::printn(i.op);
                return BC_ERROR~;
        }
    }

    io::printn("");

}



//-----------------------------------------------------------------------------
fn void ProgramImage.destroy(ProgramImage* image) {
    image.code.free();
    image.statics.free();
    image.functions.free();
    image.native_funcs.free();
    image.native_lookup.free();
}


//-----------------------------------------------------------------------------
fn void ProgramImage.register_native(ProgramImage* image, String name, int min_param_count, NativeFnPtr func) {
    int id = (int)image.native_funcs.len();
    NativeFn new_func = {
        .name = name,
        .min_param_count = min_param_count,
        .func = func
    };
    image.native_funcs.push(new_func);
    image.native_lookup.set(name, id);
}
