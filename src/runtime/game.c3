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



struct Game {
    Cart* cart;
    Platform* platform;
    InputState input;
    GameClock clock;
    Graphics graphics;
    Scratch scratch;
    bool first_frame;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------


// launch the compiled game
//-----------------------------------------------------------------------------
fn void? Game.launch(Game* self, Cart* cart, Platform* platform) {
    diagnostics_print(INFO, "Launching Game");
    *self = {
        .cart = cart,
        .platform = platform,
        .first_frame = true,
    };
    self.scratch.bytes = mem::new_array(char, MAX_SCRATCH_BYTES);
    self.graphics.queue.commands = mem::new_array(DrawCmd, MAX_DRAW_QUEUE_SIZE);
}


// platform requests a game step
//-----------------------------------------------------------------------------
fn void? Game.frame(Game* self) {
    if (self.first_frame) {
        self.platform.first_frame();
        self.first_frame = false;
    }
    long delta_ns = self.platform.delta_ticks_ns();
    
    // determine how many simulation steps to perform
    sz steps = self.clock.advance(delta_ns);
    
    // for each step, process the input event queue, dispatch events
    for (sz step = 0; step < steps; step++) {
        self.input.process();
        self.dispatch_bindings()!;
        self.dispatch_update()!;
        self.dispatch_timers()!;
    }

    self.dispatch_draw()!;
}


// release the game resources
//-----------------------------------------------------------------------------
fn void Game.shutdown(Game* self) {
    diagnostics_print(INFO, "Shutting Down Game");
    byte_buffer_release(&self.cart.file_bytes);
}



// run game on-event blocks
//-----------------------------------------------------------------------------
fn void? Game.dispatch_bindings(Game* self) {

}


// run game draw block
//-----------------------------------------------------------------------------
fn void? Game.dispatch_draw(Game* self) => @pool() {
    Graphics* graphics = &self.graphics;
    graphics.begin_frame();
    
    if (graphics.begin_pass((TargetId)0, CLEAR, (Color)Palette.BLACK)) {
        graphics.draw_line(319.0, 0.0, 0.0, 179.0, (Color)Palette.RED, 128);

        graphics.draw_pixel(100.0, 100.0, (Color)Palette.GREEN, 128);

        graphics.draw_rect(20.0, 50.0, 30.0, 50.0, (Color)Palette.WHITE, 128);
        graphics.draw_rect(30.0, 70.0, 30.0, 40.0, (Color)Palette.BRICK, 192);
        
        String text = "test2";
        sz addr = self.scratch.clone_text(text);
        sz length = text.len;
        graphics.draw_text(addr, length, 0.0, 0.0, (Color)Palette.MINT, 192);

        for (sz y = 0; y < 8; y++) {
            for (sz x = 0; x < 8; x++) {
                Color c = (char)(y * 8 + x);
                float x0 = (float)(100 + x * 16);
                float y0 = (float)(10 + y * 16);
                graphics.draw_rect(x0, y0, (float)16, (float)16, c);
                text = string::tformat("%d", c);
                addr = self.scratch.clone_text(text);
                length = text.len;
                if (x < 4) {
                    graphics.draw_text(addr, length, x0, y0, (Color)Palette.WHITE);
                } else {
                    graphics.draw_text(addr, length, x0, y0, (Color)Palette.BLACK);
                }
            }
        }
    }
    graphics.end_pass();
    self.platform.draw(graphics, &self.scratch);

}


// run game update block
//-----------------------------------------------------------------------------
fn void? Game.dispatch_update(Game* self) {

}


// run game every-x timber blocks
//-----------------------------------------------------------------------------
fn void? Game.dispatch_timers(Game* self) {

}




