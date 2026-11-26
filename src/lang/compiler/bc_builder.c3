// utilities for lowering IR into VM bytecode
module punk;
import std::io;


//-----------------------------------------------------------------------------
fn void? bc_codegen(IrBuilder* b, ProgramImage* image) {

    VmFunction entry = {
        .name = "entry",
        .code_start = (int)image.code.len(),
        .register_count = (int)b.values.len(),
        .param_count = 0
    };
    bc_codegen_constants(b, image)!;
    bc_codegen_instructions(b, image)!;
    entry.code_count = (int)image.code.len() - entry.code_start;

    image.functions.push(entry);
    image.entry_function = 0;
}


//-----------------------------------------------------------------------------
fn void? bc_codegen_constants(IrBuilder* b, ProgramImage* image) {
    foreach (reg : b.constants) {
        IrValue* value = &b.values[reg];
        VmValue constant;

        switch (value.kind) {
            case INT:
                constant = {
                    .kind = INT,
                    .data = { .ival = value.data.ival }
                };
            case FLOAT:
                constant = {
                    .kind = FLOAT,
                    .data = { .fval = value.data.fval }
                };
            default: return IR_ERROR~;
        }

        int addr = (int)image.constants.len();
        image.constants.push(constant);
        VmInst inst = {
            .op = LOAD_CONST,
            .dst = reg,
            .src1 = addr
        };
        image.code.push(inst);        
    }
}


//-----------------------------------------------------------------------------
fn void? bc_codegen_instructions(IrBuilder* b, ProgramImage* image) {
    foreach (ir_inst : b.inst) {
        VmInst vm_inst = {
            .dst = ir_inst.dst,
            .src1 = ir_inst.src1,
            .src2 = ir_inst.src2
        };

        switch (ir_inst.op) {
            case ADD: vm_inst.op = ADD;
            case SUB: vm_inst.op = SUB;
            case MUL: vm_inst.op = MUL;
            case DIV: vm_inst.op = DIV;
            //
            case NEG: vm_inst.op = NEG;
            case NOT: vm_inst.op = NOT;
            //
            case HALT: vm_inst.op = HALT;
            //
            case CALL_NATIVE:
                // make mov instructions
                int start_addr = b.next_addr();
                int count = ir_inst.src3;
                for (int i = 0; i < count; i++) {
                    IrValue v = b.values[(sz)(ir_inst.src2 + i)]; // clone contents
                    b.values.push(v); // allocate register
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


            default:
                b.diagnostics.report_bcbuilder_unknown_instruction({}, ir_inst.op);
                return IR_ERROR~;
        }

        image.code.push(vm_inst);
    }
}

