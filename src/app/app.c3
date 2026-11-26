//-----------------------------------------------------------------------------
// entry point for desktop platform
//-----------------------------------------------------------------------------
module punk;
import sdl3;
import std::io;

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

// session owns the game, game cart, and platform
struct Session {
    Game game;
    Cart cart;
    Platform platform;
    Diagnostics diagnostics;
    bool initialized;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

// desktop SDL entry
//-----------------------------------------------------------------------------
fn int main(String[] argv) {
    return sdl3::enterAppMainCallbacks(argv.len, (ZString*)argv, &sdl_app_init, &sdl_app_iter, &sdl_app_evt, &sdl_app_quit);
}


// initialize SDL, open the window, prepare the renderer
//-----------------------------------------------------------------------------
fn SdlAppResult sdl_app_init(void** appstate, int argc, ZString* argv) {
    
    Session* session = mem::new(Session);
    *appstate = session;
    *session = {};

    session.diagnostics.info("Launching Punk Desktop");
    
    // initialize the desktop session and launch the game
    if (catch err = session.init(argc, argv)) return FAILURE;
    session.initialized = true;
    
    return CONTINUE;
}


// SDL iteration callaback
//-----------------------------------------------------------------------------
fn SdlAppResult sdl_app_iter(void* appstate) {
    Session* session = appstate;

    if (catch err = session.game.frame()) return FAILURE;
    
    session.platform.present();

    if (session.diagnostics.has_errors) return FAILURE;
    
    return CONTINUE;
}


// SDL event callback
//-----------------------------------------------------------------------------
fn SdlAppResult sdl_app_evt(void* appstate, SdlEvent* event) {
    Session* session = appstate;
    InputState* input = &session.game.input;

    switch (event.type) {
        case QUIT: return SUCCESS;
        case WINDOW_FOCUS_LOST:
            input.push({ .kind = FOCUS_LOST });

        case KEY_DOWN:
            if (event.key.scancode == ESCAPE) return SUCCESS;
            nextcase;
            // fall-through
        case KEY_UP:
            if (event.key.repeat) break;
            
            InputAction action = INVALID;
            switch (event.key.scancode) {
                case UP:     action = UP;
                case DOWN:     action = DOWN;
                case LEFT:     action = LEFT;
                case RIGHT: action = RIGHT;
                case SPACE: action = FIRE;
            }
            if (action == INVALID) break;

            InputEvent evt = {
                .kind = ACTION,
                .action = action,
                .down = event.type == KEY_DOWN,
            };

            input.push(evt);

    }

    return CONTINUE;
}


// SDL quit callback
//-----------------------------------------------------------------------------
fn void sdl_app_quit(void* appstate, SdlAppResult result) {
    if (appstate != null) {
        Session* session = appstate;
        session.shutdown();
    }
}


// initialize the desktop game session and launch the game
//-----------------------------------------------------------------------------
fn void? Session.init(Session* self, int argc, ZString* argv) {
    self.diagnostics.info("Initializing Session");
    
    self.platform.init(&self.diagnostics)!;

    String path = "./examples/game.punk";
    self.diagnostics.file_path = path;
    self.platform.load_cart(&self.cart, path)!;
    
    self.game.launch(&self.cart, &self.platform)!;
}


// shutdown the desktop game session
//-----------------------------------------------------------------------------
fn void Session.shutdown(Session* self) {
    self.diagnostics.info("Shutting Down Punk Desktop");

    if (self.initialized) {
        // free resources
        self.game.shutdown();
        self.platform.shutdown();
    }

    self.diagnostics.report();
    self.diagnostics.destroy();
    defer byte_buffer_release(&self.cart.file_bytes);
}

