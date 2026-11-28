//-----------------------------------------------------------------------------
// diagnostics reports for bytecode image
//-----------------------------------------------------------------------------
module punk;
import std::io;

//-----------------------------------------------------------------------------
fn void Diagnostics.report_vm_dump_unknown_instruction(Diagnostics* self, VmOp inst) {
    Diagnostic d = {
        .severity = ERROR,
        .component = VM,
        .span = {},
        .message = string::format(mem, "unknown instruction in image dump `%s`.", inst)
    };
    self.push(d);
}


//-----------------------------------------------------------------------------
fn void Diagnostics.report_vm_invalid_register_address(Diagnostics* self, int idx, int capacity) {
    Diagnostic d = {
        .severity = ERROR,
        .component = VM,
        .span = {},
        .message = string::format(mem, "invalid VM register address=%d, capacity=%d.", idx, capacity)
    };
    self.push(d);
}


//-----------------------------------------------------------------------------
fn void Diagnostics.report_vm_unrecognized_inst_in_executive(Diagnostics* self, VmInst inst) {
    Diagnostic d = {
        .severity = ERROR,
        .component = VM,
        .span = {},
        .message = string::format(mem, "unrecognized instruction in VM Executive `%s`.", inst.op)
    };
    self.push(d);
}
