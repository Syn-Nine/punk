//-----------------------------------------------------------------------------
// cross platform game runtime environment
//-----------------------------------------------------------------------------
module punk;
import std::io;

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

// holds game code and content
struct Cart {
	ByteBuffer file_bytes;
}


struct Game {
	Cart* cart;
	Platform* platform;
	InputState input;
	bool first_frame;
	GameClock clock;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------


// launch the compiled game
//-----------------------------------------------------------------------------
fn void? game_launch(Game* game, Cart* cart, Platform* platform) {
	diagnostics_print(INFO, "Launching Game");
	*game = {
		.cart = cart,
		.platform = platform,
		.first_frame = true,
	};
}


// platform requests a game step
//-----------------------------------------------------------------------------
fn void game_frame(Game* game) {
	if (game.first_frame) {
		platform_first_frame(game.platform);	
		game.first_frame = false;
	}
	long delta_ns = platform_delta_ticks_ns(game.platform);

	// determine how many simulation steps to perform
	sz steps = clock_advance(&game.clock, delta_ns);
	
	// for each step
	for (sz step = 0; step < steps; step++) {
		// process the input event queue
		input_process(&game.input);

	}

}


// release the game resources
//-----------------------------------------------------------------------------
fn void game_shutdown(Game* game) {
	diagnostics_print(INFO, "Shutting Down Game");
	byte_buffer_release(&game.cart.file_bytes);
}