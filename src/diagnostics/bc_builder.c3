//-----------------------------------------------------------------------------
// diagnostics reports for bytecode builder
//-----------------------------------------------------------------------------
module punk;
import std::io;

//-----------------------------------------------------------------------------
fn void Diagnostics.report_bcbuilder_unknown_instruction(Diagnostics* self, SourceSpan span, IrOp inst) {
    Diagnostic d = {
        .severity = ERROR,
        .component = BC_BUILDER,
        .span = span,
        .message = string::format(mem, "unknown instruction in bc_codegen_instructions `%s`.", inst)
    };
    self.push(d);
}
