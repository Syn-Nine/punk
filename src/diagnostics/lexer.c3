//-----------------------------------------------------------------------------
// diagnostics reports for lexer
//-----------------------------------------------------------------------------
module punk;

//-----------------------------------------------------------------------------
fn void Diagnostics.report_lexer_unexpected_character(Diagnostics* self, SourceSpan span, char c) {
    Diagnostic d = {
        .severity = ERROR,
        .component = LEXER,
        .span = span,
        .message = string::format(mem, "unexpected character `%c`", c)
    };
    self.push(d);
}

