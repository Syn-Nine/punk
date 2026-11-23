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
    SdlTexture* framebuffer;
    Fonts fonts;
    long prev_ticks;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

// init the desktop platform layer
//-----------------------------------------------------------------------------
fn void? Platform.init(Platform* self) {
    diagnostics_print(INFO, "Initializing Desktop Platform");

    *self = {};
    
    if (!sdl3::init({ .video = true })) {
        diagnostics_print(ERROR, string::tformat("Failed to initialize SDL: %s", sdl3::getError()));
        return SDL_ERROR~;
    }

    if (!sdl3::createWindowAndRenderer(
        "Punk Engine Demo",
        320 * 4,
        180 * 4,
        { .resizable = true },
        &self.window,
        &self.renderer
    )) return SDL_ERROR~;

    sdl3::setWindowPosition(self.window, (int)sdl3::windowpos_centered(), (int)sdl3::windowpos_centered());
    sdl3::setRenderLogicalPresentation(self.renderer, 320, 180, LETTERBOX);
    sdl3::setRenderVSync(self.renderer, (SdlRendererVSync)1);

    self.framebuffer = sdl3::createTexture(self.renderer, RGBA8888, TARGET, 320, 180);
    sdl3::setTextureScaleMode(self.framebuffer, NEAREST);

    self.fonts.init(self.renderer, tamzen16_fnt[..])!;
}


// shutdown the desktop platform layer
//-----------------------------------------------------------------------------
fn void Platform.shutdown(Platform* self) {
    diagnostics_print(INFO, "Shutting Down Desktop Platform");

    self.fonts.shutdown();
    sdl3::destroyRenderer(self.renderer);
    sdl3::destroyWindow(self.window);
    
    *self = {};
}


// load game cart
//-----------------------------------------------------------------------------
fn void? platform_load_cart(Cart* cart, String path) {
    diagnostics_print(INFO, "Loading Game Cart");
    
    // read game code bytes from disk
    platform_read_file(path, &cart.file_bytes)!;    

    // compile game code

}


// number of nanoseconds passed since last call
//-----------------------------------------------------------------------------
fn long Platform.delta_ticks_ns(Platform* self) {
    long prev = self.prev_ticks;
    long now = (long)sdl3::getTicksNS();
    self.prev_ticks = now;
    return now - prev;
}


// convert graphics queue into native drawing commands
//-----------------------------------------------------------------------------
fn void Platform.draw(Platform* self, Graphics* graphics, Scratch* scratch) {
    if (graphics.queue.failed || graphics.queue.length == 0) return;
    if (graphics.queue.commands[0].kind != BEGIN_PASS) return;
    
    SdlRenderer* renderer = self.renderer;
    DrawQueue* q = &graphics.queue;
    for (sz i = 0; i < graphics.queue.length; i++) {
        DrawCmd* cmd = &q.commands[i];
        switch (cmd.kind) {
            case BEGIN_PASS:
                if (cmd.data.pass.target == (TargetId)0) {
                    sdl3::setRenderTarget(renderer, self.framebuffer);
                    sdl3::setRenderDrawBlendMode(renderer, BLEND);

                    if (cmd.data.pass.load == CLEAR) {
                        self.set_draw_color(cmd.data.pass.color, cmd.data.pass.opacity);
                        sdl3::setRenderDrawColor(self.renderer, 0, 0, 0, 255);
                        sdl3::renderClear(renderer);
                    }
                }
            case LINE:
                LineCmd* data = &cmd.data.line;
                self.set_draw_color(data.color, data.opacity);
                sdl3::renderLine(renderer, data.from.x, data.from.y, data.to.x, data.to.y);

            case PIXEL:
                PixelCmd* data = &cmd.data.pixel;
                self.set_draw_color(data.color, data.opacity);
                sdl3::renderPoint(renderer, data.pos.x, data.pos.y);

            case RECT:
                RectCmd* data = &cmd.data.rect;
                self.set_draw_color(data.color, data.opacity);
                SdlFRect rect = { data.bounds.x, data.bounds.y, data.bounds.w, data.bounds.h };
                sdl3::renderFillRect(renderer, &rect);

            case TEXT:
                TextCmd* data = &cmd.data.text;
                Palette pal = (Palette)(data.color % 64);
                char alpha = pal.a;
                if (data.opacity < 255) alpha = data.opacity;
                self.fonts.draw_text_rgba(scratch, data.addr, data.length, data.pos.x, data.pos.y, pal.r, pal.g, pal.b, alpha);

            default: break;
        }
    }
}


// platform state that must be initialized on the first game frame
//-----------------------------------------------------------------------------
fn void Platform.first_frame(Platform* self) {
    self.prev_ticks = (long)sdl3::getTicksNS();
}


// draw framebuffer
//-----------------------------------------------------------------------------
fn void Platform.present(Platform* self) {
    SdlRenderer* renderer = self.renderer;
    sdl3::setRenderTarget(renderer, null);
    sdl3::setRenderDrawBlendMode(renderer, NONE);
    SdlFRect rect = { 0, 0, 320, 180 };
    sdl3::renderTexture(renderer, self.framebuffer, null, &rect);
    sdl3::renderPresent(renderer);
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


// set SDL drawing color to mapped punk palette color
//-----------------------------------------------------------------------------
fn void Platform.set_draw_color(Platform* self, Color color, char opacity) {
    Palette pal = (Palette)(color % 64);
    if (opacity < 255) {
        sdl3::setRenderDrawColor(self.renderer, pal.r, pal.g, pal.b, opacity);
    } else {
        sdl3::setRenderDrawColor(self.renderer, pal.r, pal.g, pal.b, pal.a);
    }
}