// structure and utilities for the bytecode image
module punk;
import std::io;
import std::collections;

//-----------------------------------------------------------------------------
// ENUMERATIONS
//-----------------------------------------------------------------------------

enum VmOp {
    LOAD_CONST,

    ADD,
    SUB,
    MUL,
    DIV,

    NEG,
    NOT,

    HALT,

    CALL_NATIVE,
    MOV,
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
    List{VmValue} constants;
    List{VmFunction} functions;
    List{NativeFn} native_funcs;
    HashMap{String,int} native_lookup;
    Diagnostics* diagnostics;
    int entry_function;
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

    foreach (i : image.code) {
        switch (i.op) {
            case LOAD_CONST:
                VmValue* constant = &image.constants[i.src1];
                if (constant.kind == INT) {
                    io::printfn("%%%d = LOAD_CONST %d", i.dst, constant.data.ival);
                }
                else {
                    io::printfn("%%%d = LOAD_CONST %f", i.dst, constant.data.fval);
                }
            
            case ADD: io::printfn("%%%d = ADD %%%d, %%%d", i.dst, i.src1, i.src2);
            case SUB: io::printfn("%%%d = SUB %%%d, %%%d", i.dst, i.src1, i.src2);
            case MUL: io::printfn("%%%d = MUL %%%d, %%%d", i.dst, i.src1, i.src2);
            case DIV: io::printfn("%%%d = DIV %%%d, %%%d", i.dst, i.src1, i.src2);
            //
            case NEG: io::printfn("%%%d = NEG %%%d", i.dst, i.src1);
            case NOT: io::printfn("%%%d = NOT %%%d", i.dst, i.src1);
            //
            case HALT: io::printfn("HALT");
            //
            case CALL_NATIVE: io::printfn("CALL_NATIVE %d, %%%d, %d", i.src1, i.src2, i.src3);
            case MOV: io::printfn("MOV %%%d, %%%d", i.dst, i.src1);
            //
            default:
                image.diagnostics.report_vm_dump_unknown_instruction(i.op);
                io::printn(i.op);
                return BC_ERROR~;
        }
    }
}



//-----------------------------------------------------------------------------
fn void ProgramImage.destroy(ProgramImage* image) {
    image.code.free();
    image.constants.free();
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
