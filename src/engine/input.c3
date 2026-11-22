//-----------------------------------------------------------------------------
// process input events received from the platform
//-----------------------------------------------------------------------------
module punk;
import std::io;

//-----------------------------------------------------------------------------
// STRUCTURES
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


const ACTION_COUNT = InputAction::len;
const MAX_INPUT_QUEUE_COUNT = 256;

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
fn void input_push(InputState* input, InputEvent evt) {
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
fn void input_clear_edges(InputState* input) {
	input.pressed = {};
	input.released = {};
}


// clear action held and edges
//-----------------------------------------------------------------------------
fn void input_clear_held_and_edges(InputState* input) {
	input.held = {};
	input_clear_edges(input);
}


// clear the input event queue
//-----------------------------------------------------------------------------
fn void input_queue_reset(InputState* input) {
	input_clear_held_and_edges(input);
	input.queue.count = 0;
	input.queue.overflowed = false;
}


// update held and edges for action
//-----------------------------------------------------------------------------
fn void input_action_event(InputState* input, InputEvent evt) {
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
fn void input_process(InputState* input) {
	input_clear_edges(input);

	if (input.queue.overflowed) {
		input_queue_reset(input);
		return;
	}

	for (sz i = 0; i < input.queue.count; i++) {
		InputEvent evt = input.queue.events[i];
		switch (evt.kind) {
			case FOCUS_LOST:
				input_clear_held_and_edges(input);
			case ACTION:
				input_action_event(input, evt);
		}
	}

	input.queue.count = 0;
}


// check if an action is held
//-----------------------------------------------------------------------------
fn bool input_is_held(InputState* input, InputAction action) {
	return input.held[action];
}


// check if an action was pressed
//-----------------------------------------------------------------------------
fn bool input_was_pressed(InputState* input, InputAction action) {
	return input.pressed[action];
}


// check if an action was released
//-----------------------------------------------------------------------------
fn bool input_was_released(InputState* input, InputAction action) {
	return input.released[action];
}
