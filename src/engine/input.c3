//-----------------------------------------------------------------------------
// process input events received from the platform
//-----------------------------------------------------------------------------
module punk;
import std::io;
import std::collections;


//-----------------------------------------------------------------------------
// ENUMERATIONS
//-----------------------------------------------------------------------------

enum InputAction : int {
    UP,
    DOWN,
    LEFT,
    RIGHT,
    FIRE,
    //
    INVALID
}

enum InputEventKind {
    ACTION,
    FOCUS_LOST,
}


//-----------------------------------------------------------------------------
// CONSTANTS
//-----------------------------------------------------------------------------

const ACTION_COUNT = InputAction::len;
const MAX_INPUT_QUEUE_COUNT = 256;


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct ActionState {
    bool pressed;
    bool held;
    bool released;
}

struct InputEvent {
    InputEventKind kind;
    InputAction action;
    bool down;
}

struct InputQueue {
    InputEvent[MAX_INPUT_QUEUE_COUNT] events;
    sz count;
    bool overflowed;
}

struct InputState {
    InputQueue queue;
    bool[ACTION_COUNT] pressed;
    bool[ACTION_COUNT] held;
    bool[ACTION_COUNT] released;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------


// add an event to the input queue
//-----------------------------------------------------------------------------
fn void InputState.push(InputState* input, InputEvent evt) {
    if (input.queue.overflowed) return;
    if (input.queue.count >= MAX_INPUT_QUEUE_COUNT) {
        input.queue.overflowed = true;
        return;
    }

    input.queue.events[input.queue.count] = evt;
    input.queue.count++;
}


// clear action edges
//-----------------------------------------------------------------------------
fn void InputState.clear_edges(InputState* input) {
    input.pressed = {};
    input.released = {};
}


// clear action held and edges
//-----------------------------------------------------------------------------
fn void InputState.clear_held_and_edges(InputState* input) {
    input.held = {};
    input.clear_edges();
}


// clear the input event queue
//-----------------------------------------------------------------------------
fn void InputState.queue_reset(InputState* input) {
    input.clear_held_and_edges();
    input.queue.count = 0;
    input.queue.overflowed = false;
}


// update held and edges for action
//-----------------------------------------------------------------------------
fn void InputState.action_event(InputState* input, InputEvent evt) {
    //io::printn(evt);
    InputAction action = evt.action;
    bool was_held = input.held[action];
    bool is_held = evt.down;
    input.held[action] = is_held;
    if (!was_held && is_held) input.pressed[action] = true;
    if (was_held && !is_held) input.released[action] = true;
}


// update the state of input actions
//-----------------------------------------------------------------------------
fn void InputState.process(InputState* input) {
    input.clear_edges();

    if (input.queue.overflowed) {
        input.queue_reset();
        return;
    }

    for (sz i = 0; i < input.queue.count; i++) {
        InputEvent evt = input.queue.events[i];
        switch (evt.kind) {
            case FOCUS_LOST:
                input.clear_held_and_edges();
            case ACTION:
                input.action_event(evt);
        }
    }

    input.queue.count = 0;
}


// check if an action is held
//-----------------------------------------------------------------------------
fn bool InputState.is_held(InputState* input, InputAction action) {
    return input.held[action];
}


// check if an action was pressed
//-----------------------------------------------------------------------------
fn bool InputState.was_pressed(InputState* input, InputAction action) {
    return input.pressed[action];
}


// check if an action was released
//-----------------------------------------------------------------------------
fn bool InputState.was_released(InputState* input, InputAction action) {
    return input.released[action];
}
