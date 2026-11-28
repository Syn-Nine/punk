//-----------------------------------------------------------------------------
// utilities for lowering IR into VM bytecode
//-----------------------------------------------------------------------------
module punk;
import std::io;


//-----------------------------------------------------------------------------
fn void? bc_codegen(IrBuilder* b, ProgramImage* image) {
    b.diagnostics.info("Generating Bytecode Image");

    // load static values
    for (int i = 0; i < b.statics.len(); i++) {
        IrValue* src = &b.statics[i];
        if (src.kind == INT) {
            image.statics.push({
                .kind = INT,
                .data = { .ival = src.data.ival }
            });
        } else if (src.kind == FLOAT) {
            image.statics.push({
                .kind = FLOAT,
                .data = { .fval = src.data.fval }
            });
        }
    }

    // gen functions
    for (int i = 0; i < b.funcs.len(); i++) {
        image.func_lookup.set(b.funcs[i].name, i);
        bc_codegen_func(b, image, i)!;
    }
    
}


//-----------------------------------------------------------------------------
fn void? bc_codegen_func(IrBuilder* b, ProgramImage* image, int ftn) {
    VmFunction func = {
        .name = b.funcs[ftn].name,
        .code_start = (int)image.code.len(),
        .register_count = (int)b.funcs[ftn].values.len(),
        .param_count = 0
    };

    for (int i = 0; i < b.funcs[ftn].block_ptrs.len(); i++) {
        int bidx = b.funcs[ftn].block_ptrs[i];
        bc_codegen_block(b, image, ftn, bidx)!;
    }
    
    func.code_count = (int)image.code.len() - func.code_start;
    image.functions.push(func);
}


//-----------------------------------------------------------------------------
fn void? bc_codegen_block(IrBuilder* b, ProgramImage* image, int ftn, int bidx) {

    foreach (ir_inst : b.blocks[bidx].inst) {
        VmInst vm_inst = {
            .dst = ir_inst.dst,
            .src1 = ir_inst.src1,
            .src2 = ir_inst.src2
        };

        switch (ir_inst.op) {
            case LOAD_INT: vm_inst.op = LOAD_INT;
            case LOAD_FLOAT: vm_inst.op = LOAD_FLOAT;
            //
            case ADD: vm_inst.op = ADD;
            case SUB: vm_inst.op = SUB;
            case MUL: vm_inst.op = MUL;
            case DIV: vm_inst.op = DIV;
            //
            case NEG: vm_inst.op = NEG;
            case NOT: vm_inst.op = NOT;
            //
            case STOP: vm_inst.op = STOP;
            //
            case CALL_NATIVE:
                // make mov instructions
                int start_addr = b.funcs[ftn].next_addr();
                int count = ir_inst.src3;
                for (int i = 0; i < count; i++) {
                    IrValue v = b.funcs[ftn].values[(sz)(ir_inst.src2 + i)]; // clone contents
                    b.funcs[ftn].values.push(v); // allocate register
                    VmInst mov_inst = {
                        .op = MOV,
                        .dst = start_addr + i,
                        .src1 = b.operands[(sz)(ir_inst.src2 + i)]
                    };
                    image.code.push(mov_inst);
                }
                vm_inst.op = CALL_NATIVE;
                vm_inst.src1 = ir_inst.src1;
                vm_inst.src2 = start_addr;
                vm_inst.src3 = count;

            //
            case RET: vm_inst.op = RET;
            case RET_VOID: vm_inst.op = RET_VOID;
            //
            default:
                b.diagnostics.report_bcbuilder_unknown_instruction({}, ir_inst.op);
                return IR_ERROR~;
        }

        image.code.push(vm_inst);
    }
}

