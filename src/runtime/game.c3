//-----------------------------------------------------------------------------
// cross platform game runtime environment
//-----------------------------------------------------------------------------
module punk;
import std::io;

//-----------------------------------------------------------------------------
// CONSTANTS
//-----------------------------------------------------------------------------

const MAX_SCRATCH_BYTES = 64 * 1024;

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

// holds game code and content
struct Cart {
    ByteBuffer file_bytes;
}


struct GameScratch {
    char[] bytes;
    sz cursor;
}


struct Game {
    Cart* cart;
    Platform* platform;
    InputState input;
    GameClock clock;
    Graphics graphics;
    GameScratch scratch;
    bool first_frame;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------


// launch the compiled game
//-----------------------------------------------------------------------------
fn void? Game.launch(Game* game, Cart* cart, Platform* platform) {
    diagnostics_print(INFO, "Launching Game");
    *game = {
        .cart = cart,
        .platform = platform,
        .first_frame = true,
    };
    game.scratch.bytes = mem::new_array(char, MAX_SCRATCH_BYTES);
    game.graphics.queue.commands = mem::new_array(DrawCmd, MAX_DRAW_QUEUE_SIZE);
}


// platform requests a game step
//-----------------------------------------------------------------------------
fn void? Game.frame(Game* game) {
    if (game.first_frame) {
        game.platform.first_frame();
        game.first_frame = false;
    }
    long delta_ns = game.platform.delta_ticks_ns();
    
    // determine how many simulation steps to perform
    sz steps = game.clock.advance(delta_ns);
    
    // for each step, process the input event queue, dispatch events
    for (sz step = 0; step < steps; step++) {
        game.input.process();
        game.dispatch_bindings()!;
        game.dispatch_update()!;
        game.dispatch_timers()!;
    }

    game.dispatch_draw()!;
}


// release the game resources
//-----------------------------------------------------------------------------
fn void Game.shutdown(Game* game) {
    diagnostics_print(INFO, "Shutting Down Game");
    byte_buffer_release(&game.cart.file_bytes);
}



// run game on-event blocks
//-----------------------------------------------------------------------------
fn void? Game.dispatch_bindings(Game* game) {

}


// run game draw block
//-----------------------------------------------------------------------------
fn void? Game.dispatch_draw(Game* game) {
    Graphics* graphics = &game.graphics;
    graphics.begin_frame();
    
    if (graphics.begin_pass((TargetId)0, CLEAR, (Color)Palette.BLACK)) {
        graphics.draw_line(319.0, 0.0, 0.0, 179.0, (Color)Palette.RED, 128);

        graphics.draw_pixel(100.0, 100.0, (Color)Palette.GREEN, 128);

        graphics.draw_rect(20.0, 50.0, 30.0, 50.0, (Color)Palette.WHITE, 128);
        graphics.draw_rect(30.0, 70.0, 30.0, 40.0, (Color)Palette.WHITE, 192);
    }
    graphics.end_pass();
    game.platform.draw(graphics);

}


// run game update block
//-----------------------------------------------------------------------------
fn void? Game.dispatch_update(Game* game) {

}


// run game every-x timber blocks
//-----------------------------------------------------------------------------
fn void? Game.dispatch_timers(Game* game) {

}




