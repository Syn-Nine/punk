//-----------------------------------------------------------------------------
// vm executive loop
//-----------------------------------------------------------------------------
module punk;
import std::io;

//-----------------------------------------------------------------------------
fn void? Vm.execute(Vm* vm) {
    bool debug = false;
    if (debug) io::printn("VM Execute:");

    while (vm.frame_ptr >= 0 && !vm.diagnostics.has_errors) {
        VmInst* inst = &vm.image.code[vm.inst_ptr++];
        if (debug) io::printn(inst.op);
        switch (inst.op) {
            //---------------------------------------------
            case LOAD_INT:
                VmValue* dst = vm.reg(inst.dst)!;
                *dst = vm.image.statics[inst.src1];

            //---------------------------------------------
            case LOAD_FLOAT:
                VmValue* dst = vm.reg(inst.dst)!;
                *dst = vm.image.statics[inst.src1];
                
            //---------------------------------------------
            case ADD: nextcase;
            case SUB: nextcase;
            case MUL: nextcase;
            case DIV: 
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
                VmValue* dst = vm.reg(inst.dst)!;
                VmValue* src = vm.reg(inst.src1)!;
                *dst = *src;

            //---------------------------------------------
            case CALL_NATIVE:
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
            case STOP:
                vm.frame_ptr = -1;

            //---------------------------------------------
            case RET: vm.frame_ptr = -1;
            
            //---------------------------------------------
            case RET_VOID: vm.frame_ptr = -1;

            //---------------------------------------------
            default:
                vm.diagnostics.report_vm_unrecognized_inst_in_executive(*inst);
                return VM_ERROR~;
        }
    }

}
