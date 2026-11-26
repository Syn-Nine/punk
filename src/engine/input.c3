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
    int count;
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
fn void InputState.push(InputState* self, InputEvent evt) {
    if (self.queue.overflowed) return;
    if (self.queue.count >= MAX_INPUT_QUEUE_COUNT) {
        self.queue.overflowed = true;
        return;
    }

    self.queue.events[self.queue.count] = evt;
    self.queue.count++;
}


// clear action edges
//-----------------------------------------------------------------------------
fn void InputState.clear_edges(InputState* self) {
    self.pressed = {};
    self.released = {};
}


// clear action held and edges
//-----------------------------------------------------------------------------
fn void InputState.clear_held_and_edges(InputState* self) {
    self.held = {};
    self.clear_edges();
}


// clear the input event queue
//-----------------------------------------------------------------------------
fn void InputState.queue_reset(InputState* self) {
    self.clear_held_and_edges();
    self.queue.count = 0;
    self.queue.overflowed = false;
}


// update held and edges for action
//-----------------------------------------------------------------------------
fn void InputState.action_event(InputState* self, InputEvent evt) {
    //io::printn(evt);
    InputAction action = evt.action;
    bool was_held = self.held[action];
    bool is_held = evt.down;
    self.held[action] = is_held;
    if (!was_held && is_held) self.pressed[action] = true;
    if (was_held && !is_held) self.released[action] = true;
}


// update the state of input actions
//-----------------------------------------------------------------------------
fn void InputState.process(InputState* self) {
    self.clear_edges();

    if (self.queue.overflowed) {
        self.queue_reset();
        return;
    }

    for (int i = 0; i < self.queue.count; i++) {
        InputEvent evt = self.queue.events[i];
        switch (evt.kind) {
            case FOCUS_LOST:
                self.clear_held_and_edges();
            case ACTION:
                self.action_event(evt);
        }
    }

    self.queue.count = 0;
}


// check if an action is held
//-----------------------------------------------------------------------------
fn bool InputState.is_held(InputState* self, InputAction action) {
    return self.held[action];
}


// check if an action was pressed
//-----------------------------------------------------------------------------
fn bool InputState.was_pressed(InputState* self, InputAction action) {
    return self.pressed[action];
}


// check if an action was released
//-----------------------------------------------------------------------------
fn bool InputState.was_released(InputState* self, InputAction action) {
    return self.released[action];
}
