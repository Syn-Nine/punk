//-----------------------------------------------------------------------------
// diagnostics reports for compiler
//-----------------------------------------------------------------------------
module punk;


//-----------------------------------------------------------------------------
fn void Diagnostics.report_compiler_module_is_empty(Diagnostics* self) {
    Diagnostic d = {
        .severity = WARNING,
        .component = COMPILER,
        .span = {},
        .message = string::format(mem, "module is empty.")
    };
    self.push(d);
}


//-----------------------------------------------------------------------------
fn void Diagnostics.report_compiler_unexpected_binary_kind(Diagnostics* self, Token token) {
    Diagnostic d = {
        .severity = ERROR,
        .component = COMPILER,
        .span = token.span,
        .message = string::format(mem, "unexpected binary token kind `%s`.", token.kind)
    };
    self.push(d);
}


//-----------------------------------------------------------------------------
fn void Diagnostics.report_compiler_unexpected_expression_kind(Diagnostics* self, Expression expr) {
    Diagnostic d = {
        .severity = ERROR,
        .component = COMPILER,
        .span = expr.span,
        .message = string::format(mem, "unexpected expression kind `%s`.", expr.kind)
    };
    self.push(d);
}


//-----------------------------------------------------------------------------
fn void Diagnostics.report_compiler_unexpected_statement_kind(Diagnostics* self, Statement stmt) {
    Diagnostic d = {
        .severity = ERROR,
        .component = COMPILER,
        .span = stmt.span,
        .message = string::format(mem, "unexpected statement kind `%s`.", stmt.kind)
    };
    self.push(d);
}


//-----------------------------------------------------------------------------
fn void Diagnostics.report_compiler_unexpected_unary_kind(Diagnostics* self, Token token) {
    Diagnostic d = {
        .severity = ERROR,
        .component = COMPILER,
        .span = token.span,
        .message = string::format(mem, "unexpected unary token kind `%s`.", token.kind)
    };
    self.push(d);
}


//-----------------------------------------------------------------------------
fn void Diagnostics.report_compiler_unexpected_value_kind(Diagnostics* self, Token token) {
    Diagnostic d = {
        .severity = ERROR,
        .component = COMPILER,
        .span = token.span,
        .message = string::format(mem, "unexpected value token kind `%s`.", token.kind)
    };
    self.push(d);
}
