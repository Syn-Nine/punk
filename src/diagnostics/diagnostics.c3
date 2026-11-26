//-----------------------------------------------------------------------------
// diagnostic collection and reporting
//-----------------------------------------------------------------------------
module punk;
import std::io;
import std::collections;
import std::core::mem;

//-----------------------------------------------------------------------------
// ENUMERATIONS
//-----------------------------------------------------------------------------

enum Severity : int (String label) {
    INFO    { "INFO" },
    ERROR   { "ERROR" },
    WARNING { "WARNING"},
}

struct SourceSpan {
    int file_id;
    int line;
    int start;
    int end;
}

struct Diagnostic {
    Severity severity;
    SourceSpan span;
    String message;
}

struct Diagnostics (Printable) {
    List{Diagnostic} entries;
    ByteBuffer* file_bytes;
    String file_path;
    bool has_errors;
}



//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

// print info message to console
//-----------------------------------------------------------------------------
fn void Diagnostics.info(Diagnostics* self, String message) {
    io::printfn("[%s] %s", Severity.INFO.label, message);
}


//-----------------------------------------------------------------------------
fn void Diagnostics.destroy(Diagnostics* self) {
    self.entries.free();
}


//-----------------------------------------------------------------------------
fn void Diagnostics.push(Diagnostics* self, Diagnostic d) {
    self.entries.push(d);
    if (d.severity == ERROR) self.has_errors = true;

    // check message formatting
    if (d.message.len > 0) {
        if (d.message[0] >= 'A' && d.message[0] <= 'Z') {
            io::printfn("Diagnostic message starts with a capital letter: %s", d.message);
        }
        if (d.message[d.message.len-1] != '.') {
            io::printfn("Diagnostic message is missing period: %s", d.message);
        }
    }
}


//-----------------------------------------------------------------------------
fn void Diagnostics.report(Diagnostics* self) {
    io::printn("Diagnostics Report:");
    io::printn(self);
}


//-----------------------------------------------------------------------------
fn int find_line_start(String source, int offset) {
    while (offset > 0 && source[offset - 1] != '\n') {
        offset--;
    }
    return offset;
}


//-----------------------------------------------------------------------------
fn int find_line_end(String source, int offset) {
    int start = offset;
    while (offset < source.len && source[offset] != '\n') {
        offset++;
    }
    if (offset > start && source[offset - 1] == '\r') {
        offset--;
    }
    return offset;
}


//-----------------------------------------------------------------------------
fn void append_diagnostic(DString* out, Diagnostic* d, String source, String path) {
    int start = d.span.start;
    int end = d.span.end;
    
    if (start < 0 || end < start || end > source.len || start == end) {
        out.appendf("%s:%s:%d: %s\n", d.severity.label, path, d.span.line, d.message);
        return;
    }

    int line_start = find_line_start(source, start);
    int line_end = find_line_end(source, start);

    // reserve one leading space plus the digits in the line number.
    int gutter = 2;
    for (int n = d.span.line; n >= 10; n /= 10) {
        gutter++;
    }

    if (line_start > 0) {
        int prev_end = line_start - 1;
        int prev_start = find_line_start(source, prev_end);
        if (prev_end > prev_start && source[prev_end - 1] == '\r') {
            prev_end--;
        }
        out.append_char_repeat(' ', gutter);
        out.appendf(" │ %s\n", (String)source[prev_start : prev_end - prev_start]);
    }

    out.appendf(" %d │ %s\n", d.span.line, (String)source[line_start : line_end - line_start]);

    // clip a multiline span to its first line. An empty span gets one caret.
    int caret_start = start < line_end ? start : line_end;
    int caret_end = end < line_end ? end : line_end;
    int caret_count = caret_end > caret_start ? caret_end - caret_start : 1;

    out.append_char_repeat(' ', gutter);
    out.append_string(" │ ");
    for (int i = line_start; i < caret_start; i++) {
        out.append_char(source[i] == '\t' ? '\t' : ' ');
    }
    out.append_char_repeat('^', caret_count);

    out.append_char('\n');
    out.append_char_repeat(' ', gutter);
    out.appendf(" └►%s:%s:%d:%d: %s\n", d.severity.label, path, d.span.line, caret_start - line_start + 1, d.message);
}


//-----------------------------------------------------------------------------
fn sz? Diagnostics.to_format(&self, Formatter* formatter) @dynamic {
    if (self.file_bytes == null) return 0;
    
    DString report = dstring::new(mem);
    defer report.free();

    String source = (String)self.file_bytes.bytes;
    sz written = 0;

    foreach (entry : self.entries) {
        report.clear();
        append_diagnostic(&report, &entry, source, self.file_path);
        written += formatter.print(report.str_view())!;
    }

    return written;
}


