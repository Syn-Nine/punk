//-----------------------------------------------------------------------------
// diagnostics reports for platform
//-----------------------------------------------------------------------------
module punk;

//-----------------------------------------------------------------------------
fn void Diagnostics.report_platform_failed_to_init_sdl(Diagnostics* self, char* message) {
    Diagnostic d = {
        .severity = ERROR,
        .span = {},
        .message = string::format(mem, "failed to initialize SDL: %s.", message)
    };
    self.push(d);
}


//-----------------------------------------------------------------------------
fn void Diagnostics.report_platform_failed_to_read_file(Diagnostics* self, String path) {
    Diagnostic d = {
        .severity = ERROR,
        .span = {},
        .message = string::format(mem, "failed to read file: %s.", path)
    };
    self.push(d);
}

       
//-----------------------------------------------------------------------------
fn void Diagnostics.report_platform_script_size_limit_exceeded(Diagnostics* self, sz size, sz max_size) {
    Diagnostic d = {
        .severity = ERROR,
        .span = {},
        .message = string::format(mem, "script size limit exceeded, size=%d, max=%d.", size, max_size)
    };
    self.push(d);
}
