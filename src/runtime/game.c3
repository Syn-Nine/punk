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
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------


// launch the compiled game
//-----------------------------------------------------------------------------
fn void? game_launch(Game* game, Cart* cart, Platform* platform) {
	diagnostics_print(INFO, "Launching Game");
	*game = { .cart = cart, .platform = platform };
}


fn void game_frame(Game* game) {
	// determine how many simulation steps to perform
	// for each step
		// process the input event queue
		input_process(&game.input);

}


// release the game resources
//-----------------------------------------------------------------------------
fn void game_shutdown(Game* game) {
	diagnostics_print(INFO, "Shutting Down Game");
	byte_buffer_release(&game.cart.file_bytes);
}