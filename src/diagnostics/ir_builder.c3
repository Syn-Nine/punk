//-----------------------------------------------------------------------------
// diagnostics reports for ir builder
//-----------------------------------------------------------------------------
module punk;
import std::io;

//-----------------------------------------------------------------------------
fn void Diagnostics.report_irbuilder_dump_unknown_instruction(Diagnostics* self, IrOp op) {
    Diagnostic d = {
        .severity = ERROR,
        .span = {},
        .message = string::format(mem, "unknown instruction in IR dump `%s`.", op)
    };
    self.push(d);
}
