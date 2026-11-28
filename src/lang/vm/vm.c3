//-----------------------------------------------------------------------------
// virtual machine structures and utilities
//-----------------------------------------------------------------------------
module punk;
import std::collections;
import std::io;

//-----------------------------------------------------------------------------
// CONSTANTS
//-----------------------------------------------------------------------------

const int MAX_FRAME_DEPTH = 1024;
const int MAX_STRING_SCRATCH_BYTES = 64 * 1024;
const int MAX_STACK_SIZE = 64 * 1024 * 1024;


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct VmFrame {
    int function; 
    int register_base;
    int register_count;
    int return_ip;
    int return_register;
}

struct Handler {
    int    function;
    bool has_guard;
}

struct Vm {
    ProgramImage* image;
    Diagnostics* diagnostics;
    RegisterStack stack;
    VmFrame[MAX_FRAME_DEPTH] frames;
    HashMap{int,Handler} handler_lookup;
    char* string_scratch;
    int frame_ptr;
    int inst_ptr;
    int register_count;
}



//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
fn void? Vm.ensure_frame_capacity(Vm* self, int count) {
    if (self.frame_ptr + count >= MAX_FRAME_DEPTH) return VM_ERROR~;
}


//-----------------------------------------------------------------------------
fn void? Vm.init(Vm* self, Diagnostics* diagnostics, ProgramImage* image) {
    self.diagnostics = diagnostics;
    self.image = image;
    self.string_scratch = mem::new_array(char, MAX_STRING_SCRATCH_BYTES);
    self.stack.create()!;
	io::printn("Output:");
}


//-----------------------------------------------------------------------------
fn void Vm.destroy(Vm* self) {
    free(self.string_scratch);
    self.stack.destroy();
}


//-----------------------------------------------------------------------------
fn void? Vm.dispatch_global(Vm* self) {
    int ftn = self.image.func_lookup.get("__global")!;
    self.inst_ptr = self.image.functions[ftn].code_start;
    self.push_root_frame(ftn)!;
    self.execute()!;
    self.pop_root_frame()!;
}


//-----------------------------------------------------------------------------
fn void? Vm.dispatch_if_defined(Vm* self, String name) {
    if (!self.image.func_lookup.has_key(name)) return;
    int ftn = self.image.func_lookup.get(name)!;
    self.inst_ptr = self.image.functions[ftn].code_start;
    self.push_root_frame(ftn)!;
    self.execute()!;
    self.pop_root_frame()!;
}


//-----------------------------------------------------------------------------
fn void? Vm.push_root_frame(Vm* self, int func_idx) {
    VmFunction* func = &self.image.functions[func_idx];
    self.stack.ensure_capacity(func.register_count)!;
    
    VmFrame frame = {
        .function = func_idx,
        .register_base = 0,
        .register_count = func.register_count,
        .return_ip = -1,
        .return_register = -1
    };
    
    self.frames[0] = frame;
    self.frame_ptr = 0;
    self.register_count = frame.register_count;
}


//-----------------------------------------------------------------------------
fn void? Vm.pop_root_frame(Vm* self) {
    self.frame_ptr = -1;
}


//-----------------------------------------------------------------------------
fn VmFrame* Vm.current_frame(Vm* self) {
    return &self.frames[self.frame_ptr];
}


//-----------------------------------------------------------------------------
fn VmValue*? Vm.reg(Vm* self, int idx) {
    if (idx < 0 || idx >= self.stack.capacity) {
        self.diagnostics.report_vm_invalid_register_address(idx, self.stack.capacity);
        return VM_ERROR~;
    }
    return &self.stack.data[self.current_frame().register_base + idx];
}


