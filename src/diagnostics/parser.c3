//-----------------------------------------------------------------------------
// diagnostics reports for parser
//-----------------------------------------------------------------------------
module punk;

//-----------------------------------------------------------------------------
fn void Diagnostics.report_parser_consume_error(Diagnostics* self, SourceSpan span, String message) {
    Diagnostic d = {
        .severity = ERROR,
        .span = span,
        .message = message
    };
    self.push(d);
}

//-----------------------------------------------------------------------------
fn void Diagnostics.report_parser_expected_expression(Diagnostics* self, Token token) {
    Diagnostic d = {
        .severity = ERROR,
        .span = token.span,
        .message = "expected expression."
    };
    self.push(d);
}

