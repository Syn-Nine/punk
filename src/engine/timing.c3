//-----------------------------------------------------------------------------
// translate platform delta time into clock and timer updates
//-----------------------------------------------------------------------------
module punk;

//-----------------------------------------------------------------------------
// CONSTANTS
//-----------------------------------------------------------------------------

const long CLOCK_STEP_NS = 16_666_667;
const long MAX_DELTA_NS = 250_000_000;
const int MAX_CATCH_UP = 5; // ticks per frame


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
fn int GameClock.advance(GameClock* self, long delta_ns) {
    if (delta_ns < 1) return 0;
    self.accumulator_ns += min(delta_ns, MAX_DELTA_NS);
    int steps = whole_steps(self.accumulator_ns, CLOCK_STEP_NS);
    self.accumulator_ns -= steps * CLOCK_STEP_NS;
    return steps > MAX_CATCH_UP ? MAX_CATCH_UP : steps;
}


// helper for moving in whole steps
//-----------------------------------------------------------------------------
fn int whole_steps(long elapsed, long step) {
    return (int)(elapsed / step);
}