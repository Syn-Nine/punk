//-----------------------------------------------------------------------------
// entry point for desktop platform
//-----------------------------------------------------------------------------
module punk;
import sdl3;

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

// session owns the game, game cart, and platform
struct DesktopSession {
	Game game;
	Cart cart;
	DesktopPlatform platform;
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
	
	DesktopSession* session = mem::new(DesktopSession);
	*appstate = session;
	
	// initialize the desktop session and launch the game
	if (catch err = desktop_session_init(session, argc, argv)) return FAILURE;
	
	return CONTINUE;
}


// SDL iteration callaback
//-----------------------------------------------------------------------------
fn SdlAppResult sdl_app_iter(void* appstate) {
	DesktopSession* session = appstate;
	
	return CONTINUE;
}


// SDL event callback
//-----------------------------------------------------------------------------
fn SdlAppResult sdl_app_evt(void* appstate, SdlEvent* event) {
	DesktopSession* session = appstate;

	switch (event.type) {
		case QUIT: return SUCCESS;
		case KEY_DOWN:
			if (event.key.scancode == ESCAPE) return SUCCESS;
	}

	return CONTINUE;
}


// SDL quit callback
//-----------------------------------------------------------------------------
fn void sdl_app_quit(void* appstate, SdlAppResult result) {
	if (appstate != null) {
		DesktopSession* session = appstate;
		desktop_session_shutdown(session);
	}
}


// initialize the desktop game session and launch the game
//-----------------------------------------------------------------------------
fn void? desktop_session_init(DesktopSession* session, int argc, ZString* argv) {
	diagnostics_print(INFO, "Initializing Session");
	
	*session = {};
	desktop_platform_init(&session.platform)!;

	String path = "./examples/game.punk";
	desktop_load_cart(&session.cart, path)!;

	game_launch(&session.game, &session.cart)!;
}


// shutdown the desktop game session
//-----------------------------------------------------------------------------
fn void desktop_session_shutdown(DesktopSession* session) {
	diagnostics_print(INFO, "Shutting Down Punk Desktop");
	
	// free resources
	game_shutdown(&session.game);
	desktop_platform_shutdown(&session.platform);
}

