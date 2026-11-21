// desktop platform utilities

module punk;
import std::io;
import sdl3;

const usz MAX_SCRIPT_BYTES = 64 * 1024; // 64KiB package code size limit
const usz MAX_FILE_BYTES = 1024 * 1024; // 1MiB size limit for any file
const usz MAX_PACKAGE_ZIP_BYTES = 2 * 1024 * 1024; // 2MiB size limit for entire package zip


struct DesktopPlatform {
	SdlWindow* window;
	SdlRenderer* renderer;
}


// init the desktop-host connection
//-----------------------------------------------------------------------------
fn void? desktop_host_init(DesktopPlatform* platform, Host* host) {
	diagnostics_print(INFO, "Initializing Desktop Host");

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


// shutdown the desktop-host connection
//-----------------------------------------------------------------------------
fn void desktop_host_shutdown(DesktopPlatform* platform, Host* host) {
	diagnostics_print(INFO, "Shutdown Desktop Host");

	sdl3::destroyRenderer(platform.renderer);
	sdl3::destroyWindow(platform.window);
	
	*platform = {};
	*host = {};
}


// load game cart
//-----------------------------------------------------------------------------
fn void? desktop_load_cart(DesktopCart* cart, String path) {
	diagnostics_print(INFO, "Loading Game Cart");
	
	// read game code bytes from disk
	desktop_read_file(path, &cart.file_bytes)!;	
}


// read file bytes
//-----------------------------------------------------------------------------
fn void? desktop_read_file(String path, ByteBuffer* output) => @pool() {
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

	if ((usz)size > MAX_SCRIPT_BYTES) {
		diagnostics_print(ERROR, "Script size limit exceeded");
		return IO_ERROR~;
	}

	char[]? buf = io::read_buffer_to_end(fp, mem::new_array(char, size));
	if (catch err = buf) return IO_ERROR~;
	
	output.bytes = buf;
}