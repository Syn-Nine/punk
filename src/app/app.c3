//-----------------------------------------------------------------------------
// entry point for desktop platform
//-----------------------------------------------------------------------------
module punk;
import sdl3;

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

// session owns the game, game cart, and platform
struct Session {
	Game game;
	Cart cart;
	Platform platform;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

// desktop SDL entry
//-----------------------------------------------------------------------------
fn int main(String[] argv) {
    diagnostics_print(INFO, "Launching Punk Desktop");
	return sdl3::enterAppMainCallbacks(argv.len, (ZString*)argv, &sdl_app_init, &sdl_app_iter, &sdl_app_evt, &sdl_app_quit);
}


// initialize SDL, open the window, prepare the renderer
//-----------------------------------------------------------------------------
fn SdlAppResult sdl_app_init(void** appstate, int argc, ZString* argv) {
	
	Session* session = mem::new(Session);
	*appstate = session;
	
	// initialize the desktop session and launch the game
	if (catch err = session_init(session, argc, argv)) return FAILURE;
	
	return CONTINUE;
}


// SDL iteration callaback
//-----------------------------------------------------------------------------
fn SdlAppResult sdl_app_iter(void* appstate) {
	Session* session = appstate;

	game_frame(&session.game);
	
	return CONTINUE;
}


// SDL event callback
//-----------------------------------------------------------------------------
fn SdlAppResult sdl_app_evt(void* appstate, SdlEvent* event) {
	Session* session = appstate;

	switch (event.type) {
		case QUIT: return SUCCESS;
		case WINDOW_FOCUS_LOST:
			input_push(&session.game.input, { .kind = FOCUS_LOST });

		case KEY_DOWN:
			if (event.key.scancode == ESCAPE) return SUCCESS;
			nextcase;
			// fall-through
		case KEY_UP:
			if (event.key.repeat) break;
			
			InputAction action = INVALID;
			switch (event.key.scancode) {
				case UP: 	action = UP;
				case DOWN: 	action = DOWN;
				case LEFT: 	action = LEFT;
				case RIGHT: action = RIGHT;
				case SPACE: action = FIRE;
			}
			if (action == INVALID) break;

			InputEvent evt = {
				.kind = ACTION,
				.action = action,
				.down = event.type == KEY_DOWN,
			};

			input_push(&session.game.input, evt);

	}

	return CONTINUE;
}


// SDL quit callback
//-----------------------------------------------------------------------------
fn void sdl_app_quit(void* appstate, SdlAppResult result) {
	if (appstate != null) {
		Session* session = appstate;
		session_shutdown(session);
	}
}


// initialize the desktop game session and launch the game
//-----------------------------------------------------------------------------
fn void? session_init(Session* session, int argc, ZString* argv) {
	diagnostics_print(INFO, "Initializing Session");
	
	*session = {};
	platform_init(&session.platform)!;

	String path = "./examples/game.punk";
	platform_load_cart(&session.cart, path)!;

	game_launch(&session.game, &session.cart, &session.platform)!;

	// platform
}


// shutdown the desktop game session
//-----------------------------------------------------------------------------
fn void session_shutdown(Session* session) {
	diagnostics_print(INFO, "Shutting Down Punk Desktop");
	
	// free resources
	game_shutdown(&session.game);
	platform_shutdown(&session.platform);
}

