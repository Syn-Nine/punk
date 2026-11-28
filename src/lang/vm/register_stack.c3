//-----------------------------------------------------------------------------
// structure and utilities for the register stack
//-----------------------------------------------------------------------------
module punk;
import std::io;


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct RegisterStack {
    VmValue* data;
    int count;
    int capacity;
}


//-----------------------------------------------------------------------------
fn void? RegisterStack.create(RegisterStack* stack) {
    // io::printn("Creating Register Stack");
    stack.ensure_capacity(1024)!;
}


//-----------------------------------------------------------------------------
fn void? RegisterStack.ensure_capacity(RegisterStack* stack, int count) {
    int req_capacity = stack.count + count;
    if (req_capacity < stack.capacity) return;
    if (req_capacity > MAX_STACK_SIZE) return VM_ERROR~;
    int new_capacity = stack.capacity == 0 ? 1024 : stack.capacity * 2;
    while (new_capacity < req_capacity) { new_capacity *= 2; }
    stack.data = realloc(stack.data, VmValue::size * new_capacity);
    stack.capacity = new_capacity;
    // io::printfn("New Register Stack Capacity: %d", new_capacity);
}


//-----------------------------------------------------------------------------
fn void RegisterStack.destroy(RegisterStack* stack) {
    free(stack.data);
}