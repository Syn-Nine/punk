//-----------------------------------------------------------------------------
// desktop platform utilities
//-----------------------------------------------------------------------------
module punk;
import std::io;
import sdl3;

//-----------------------------------------------------------------------------
// CONSTANTS
//-----------------------------------------------------------------------------

const sz MAX_SCRIPT_BYTES = 64 * 1024; // 64KiB package code size limit
const sz MAX_FILE_BYTES = 1024 * 1024; // 1MiB size limit for any file
const sz MAX_PACKAGE_ZIP_BYTES = 2 * 1024 * 1024; // 2MiB size limit for entire package zip


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct Platform {
	SdlWindow* window;
	SdlRenderer* renderer;
	long prev_ticks;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

// init the desktop platform layer
//-----------------------------------------------------------------------------
fn void? platform_init(Platform* platform) {
	diagnostics_print(INFO, "Initializing Desktop Platform");

	*platform = {};
	
	if (!sdl3::init({ .video = true })) {
		diagnostics_print(ERROR, string::tformat("Failed to initialize SDL: %s", sdl3::getError()));
		return SDL_ERROR~;
	}

	if (!sdl3::createWindowAndRenderer(
		"examples/demo/snake",
		320 * 4,
		180 * 4,
		{ .resizable = true },
		&platform.window,
		&platform.renderer
	)) return SDL_ERROR~;

	sdl3::setWindowPosition(platform.window, (int)sdl3::windowpos_centered(), (int)sdl3::windowpos_centered());
	sdl3::setRenderLogicalPresentation(platform.renderer, 320, 180, LETTERBOX);
	sdl3::setRenderVSync(platform.renderer, (SdlRendererVSync)1);
	

}


// shutdown the desktop platform layer
//-----------------------------------------------------------------------------
fn void platform_shutdown(Platform* platform) {
	diagnostics_print(INFO, "Shutting Down Desktop Platform");

	sdl3::destroyRenderer(platform.renderer);
	sdl3::destroyWindow(platform.window);
	
	*platform = {};
}


// load game cart
//-----------------------------------------------------------------------------
fn void? platform_load_cart(Cart* cart, String path) {
	diagnostics_print(INFO, "Loading Game Cart");
	
	// read game code bytes from disk
	platform_read_file(path, &cart.file_bytes)!;	

	// compile game code

}


// platform state that must be initialized on the first game frame
//-----------------------------------------------------------------------------
fn void platform_first_frame(Platform* platform) {
	platform.prev_ticks = (long)sdl3::getTicksNS();
}


// number of nanoseconds passed since last call
//-----------------------------------------------------------------------------
fn long platform_delta_ticks_ns(Platform* platform) {
	long prev = platform.prev_ticks;
	long now = (long)sdl3::getTicksNS();
	platform.prev_ticks = now;
	return now - prev;
}


// read file bytes
//-----------------------------------------------------------------------------
fn void? platform_read_file(String path, ByteBuffer* output) => @pool() {
	diagnostics_print(INFO, "Reading File: ".concat(tmem, path));
	*output = {};

	// check if file exists
	File? fp = file::open(path, "rb");
	if (catch err = fp) {
		diagnostics_print(ERROR, "Failed to read file: ".concat(tmem, path));
		return IO_ERROR~;
	}
	defer fp.close();

	long? size = fp.size();
	if (catch err = size) return IO_ERROR~;

	if (size > MAX_SCRIPT_BYTES) {
		diagnostics_print(ERROR, "Script size limit exceeded");
		return IO_ERROR~;
	}

	char[]? buf = io::read_buffer_to_end(fp, mem::new_array(char, size));
	if (catch err = buf) return IO_ERROR~;
	
	output.bytes = buf;
}