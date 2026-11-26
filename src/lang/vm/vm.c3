// virtual machine structures and utilities
module punk;
import std::collections;
import std::io;

//-----------------------------------------------------------------------------
// CONSTANTS
//-----------------------------------------------------------------------------

const int MAX_FRAME_DEPTH = 1024;
const int MAX_STRING_SCRATCH_BYTES = 64 * 1024;
const int MAX_STACK_SIZE = 64 * 1024 * 1024;


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct VmFrame {
    int function; 
    int register_base;
    int register_count;
    int return_ip;
    int return_register;
}

struct Vm {
    ProgramImage* image;
    Diagnostics* diagnostics;
    RegisterStack stack;
    VmFrame[MAX_FRAME_DEPTH] frames;
    char* string_scratch;
    int frame_ptr;
    int inst_ptr;
    int register_count;
}



//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
fn void? Vm.ensure_frame_capacity(Vm* vm, int count) {
    if (vm.frame_ptr + count >= MAX_FRAME_DEPTH) return VM_ERROR~;
}


//-----------------------------------------------------------------------------
fn void? Vm.init(Vm* vm, Diagnostics* diagnostics, ProgramImage* image) {
    vm.diagnostics = diagnostics;
    vm.image = image; // vm takes ownership
    vm.string_scratch = mem::new_array(char, MAX_STRING_SCRATCH_BYTES);
    vm.stack.create()!;
}


//-----------------------------------------------------------------------------
fn void Vm.destroy(Vm* vm) {
    vm.image.destroy();
    free(vm.image);
    free(vm.string_scratch);
    vm.stack.destroy();
}


//-----------------------------------------------------------------------------
fn void? Vm.run(Vm* vm) {
    vm.inst_ptr = vm.image.functions[vm.image.entry_function].code_start;
    vm.push_root_frame(vm.image.entry_function)!;
    vm.execute()!;
}


//-----------------------------------------------------------------------------
fn void? Vm.push_root_frame(Vm* vm, int func_idx) {
    VmFunction* func = &vm.image.functions[func_idx];
    vm.stack.ensure_capacity(func.register_count)!;
    
    VmFrame frame = {
        .function = func_idx,
        .register_base = 0,
        .register_count = func.register_count,
        .return_ip = -1,
        .return_register = -1
    };
    
    vm.frames[0] = frame;
    vm.frame_ptr = 0;
    vm.register_count = frame.register_count;
}


//-----------------------------------------------------------------------------
fn VmFrame* Vm.current_frame(Vm* vm) {
    return &vm.frames[vm.frame_ptr];
}


//-----------------------------------------------------------------------------
fn VmValue*? Vm.reg(Vm* vm, int idx) {
    if (idx < 0 || idx >= vm.stack.capacity) {
        vm.diagnostics.report_vm_invalid_register_address(idx, vm.stack.capacity);
        return VM_ERROR~;
    }
    return &vm.stack.data[vm.current_frame().register_base + idx];
}


//-----------------------------------------------------------------------------
fn void? Vm.execute(Vm* vm) {
    io::printn("VM Execute:");
    bool debug = false;

    while (vm.frame_ptr >= 0 && !vm.diagnostics.has_errors) {
        VmInst* inst = &vm.image.code[vm.inst_ptr++];
        switch (inst.op) {
            //---------------------------------------------
            case LOAD_CONST:
                if (debug) io::printn("LOAD_CONST");
                VmValue* dst = vm.reg(inst.dst)!;
                *dst = vm.image.constants[inst.src1];

            //---------------------------------------------
            case ADD: nextcase;
            case SUB: nextcase;
            case MUL: nextcase;
            case DIV: 
                if (debug) io::printn("BINARY");
                VmValue* dst = vm.reg(inst.dst)!;
                VmValue* lhs = vm.reg(inst.src1)!;
                VmValue* rhs = vm.reg(inst.src2)!;
                int ival0;
                int ival1;
                float fval0;
                float fval1;
                VmValueKind kind = INT;
                
                if (lhs.kind == INT) {
                    ival0 = lhs.data.ival;
                    fval0 = ival0;
                } else {
                    fval0 = lhs.data.fval;
                    ival0 = (int)fval0;
                    kind = FLOAT;
                }

                if (rhs.kind == INT) {
                    ival1 = rhs.data.ival;
                    fval1 = ival1;
                } else {
                    fval1 = rhs.data.fval;
                    ival1 = (int)fval1;
                    kind = FLOAT;
                }

                dst.kind = kind;
                if (kind == INT) {
                    if (inst.op == ADD) dst.data.ival = ival0 + ival1;
                    if (inst.op == SUB) dst.data.ival = ival0 - ival1;
                    if (inst.op == MUL) dst.data.ival = ival0 * ival1;
                } else if (kind == FLOAT) {
                    if (inst.op == ADD) dst.data.fval = fval0 + fval1;
                    if (inst.op == SUB) dst.data.fval = fval0 - fval1;
                    if (inst.op == MUL) dst.data.fval = fval0 * fval1;
                    if (inst.op == DIV) dst.data.fval = fval0 / fval1;
                }
                

            //---------------------------------------------
            case NEG:
                if (debug) io::printn("NEG");
                VmValue* dst = vm.reg(inst.dst)!;
                VmValue* src = vm.reg(inst.src1)!;
                if (src.kind == INT) {
                    src.data.ival = -src.data.ival;
                } else {
                    src.data.fval = -src.data.fval;
                }
                *dst = *src;

            //---------------------------------------------
            case MOV:
                if (debug) io::printn("MOV");
                VmValue* dst = vm.reg(inst.dst)!;
                VmValue* src = vm.reg(inst.src1)!;
                *dst = *src;

            //---------------------------------------------
            case CALL_NATIVE:
                if (debug) io::printn("CALL_NATIVE");
                VmFrame* frame = vm.current_frame();
                VmValue[] args = vm.stack.data[
                    frame.register_base + inst.src2
                    ..
                    frame.register_base + inst.src2 + inst.src3 - 1
                    ];

                NativeFn* native = &vm.image.native_funcs[inst.src1];
                VmValue result = native.func(vm, args);
                if (inst.dst > -1) *vm.reg(inst.dst)! = result;

            //---------------------------------------------
            case HALT:
                if (debug) io::printn("HALT");
                vm.frame_ptr = -1;

            //---------------------------------------------
            default:
                vm.diagnostics.report_vm_unrecognized_inst_in_executive(*inst);
                return VM_ERROR~;
        }
    }

}
