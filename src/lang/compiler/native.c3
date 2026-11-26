// bindings to native function calls
module punk;
import std::io;

alias NativeFnPtr = fn VmValue(Vm*, VmValue[] args);

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct NativeFn {
    String name;
    int min_param_count;
    NativeFnPtr func;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
fn VmValue native_print(Vm* vm, VmValue[] args) {
    DString out = dstring::new(mem); defer out.free();
    foreach (a : args) {
        out.appendf("%s", a);
    }
    io::printn(out);
    return {};
}