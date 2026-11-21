// entry point for desktop platform

module punk;
import std::io;
import sdl3;

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

// holds game code and content
struct DesktopCart {
	ByteBuffer file_bytes;
}


// session owns the game, host interface, platform, and diagnostics objects
struct DesktopSession {
	// Game game;
	Host host;
	DesktopCart cart;
	DesktopPlatform platform;
	SdlWindow* window;
	SdlRenderer* renderer;
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
	
	// initialize the desktop session
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


// initialize the desktop game session
//-----------------------------------------------------------------------------
fn void? desktop_session_init(DesktopSession* session, int argc, ZString* argv) {
	diagnostics_print(INFO, "Initializing Session");
	
	*session = {};
	desktop_host_init(&session.platform, &session.host)!;

	String path = "./examples/game.punk";
	desktop_load_cart(&session.cart, path)!;
}


// shutdown the desktop game session
//-----------------------------------------------------------------------------
fn void desktop_session_shutdown(DesktopSession* session) {
	diagnostics_print(INFO, "Shutdown Punk Desktop");
	
	// free resources
	desktop_host_shutdown(&session.platform, &session.host);
	byte_buffer_release(&session.cart.file_bytes);
}

