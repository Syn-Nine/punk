// diagnostic collection and reporting

module punk;
import std::collections;
import std::io;

enum Severity {
	INFO,
	ERROR,
}
EnumMap{Severity,String} severity2text = {{"INFO", "ERROR"}};


// print diagnostic message to console
//-----------------------------------------------------------------------------
fn void diagnostics_print(Severity severity, String message) {
	io::printfn("[%s] %s", severity2text[severity], message);
}
