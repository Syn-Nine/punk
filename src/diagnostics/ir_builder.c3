//-----------------------------------------------------------------------------
// diagnostics reports for ir builder
//-----------------------------------------------------------------------------
module punk;
import std::io;

//-----------------------------------------------------------------------------
fn void Diagnostics.report_irbuilder_dump_unknown_instruction(Diagnostics* self, IrOp op) {
    Diagnostic d = {
        .severity = ERROR,
        .component = IR_BUILDER,
        .span = {},
        .message = string::format(mem, "unknown instruction in IR dump `%s`.", op)
    };
    self.push(d);
}


//-----------------------------------------------------------------------------
fn void Diagnostics.report_irbuilder_func_failed_bb_closed_check(Diagnostics* self, String ftn, String block) {
    Diagnostic d = {
        .severity = ERROR,
        .component = IR_BUILDER,
        .span = {},
        .message = string::format(mem, "function `%s` basic block `%s` not closed.", ftn, block)
    };
    self.push(d);
}
