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
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------


// launch the compiled game
//-----------------------------------------------------------------------------
fn void? game_launch(Game* game, Cart* cart) {
	diagnostics_print(INFO, "Launching Game");
	*game = { .cart = cart };


}


// release the game resources
//-----------------------------------------------------------------------------
fn void game_shutdown(Game* game) {
	diagnostics_print(INFO, "Shutting Down Game");
	byte_buffer_release(&game.cart.file_bytes);
}