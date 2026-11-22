//-----------------------------------------------------------------------------
// translate platform delta time into clock and timer updates
//-----------------------------------------------------------------------------
module punk;

//-----------------------------------------------------------------------------
// CONSTANTS
//-----------------------------------------------------------------------------

const long CLOCK_STEP_NS = 16_666_667;
const long MAX_DELTA_NS = 250_000_000;
const long MAX_CATCH_UP = 5; // ticks per frame


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct GameClock {
	long step_ns;
	long accumulator_ns;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

// move the clock accumulator forward and return number of steps to simulate
//-----------------------------------------------------------------------------
fn long GameClock.advance(GameClock* clock, long delta_ns) {
	if (delta_ns < 1) return 0;
	clock.accumulator_ns += min(delta_ns, MAX_DELTA_NS);
	long steps = whole_steps(clock.accumulator_ns, CLOCK_STEP_NS);
	clock.accumulator_ns -= steps * CLOCK_STEP_NS;
	return steps > MAX_CATCH_UP ? MAX_CATCH_UP : steps;
}


// helper for moving in whole steps
//-----------------------------------------------------------------------------
fn long whole_steps(long elapsed, long step) {
	return elapsed / step;
}