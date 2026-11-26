//-----------------------------------------------------------------------------
// desktop platform utilities
//-----------------------------------------------------------------------------
module punk;
import std::io;
import sdl3;


//-----------------------------------------------------------------------------
// ENUMERATIONS
//-----------------------------------------------------------------------------

enum RscKind : char {
    TEXTURE,
}


//-----------------------------------------------------------------------------
// CONSTANTS
//-----------------------------------------------------------------------------

const int MAX_SCRIPT_BYTES = 256 * 1024; // 256KiB package code size limit
const int MAX_FILE_BYTES = 1024 * 1024; // 1MiB size limit for any file
const int MAX_PACKAGE_ZIP_BYTES = 64 * 1024 * 1024; // 64MiB size limit for entire package zip
const int MAX_RESOURCE_COUNT = 1024;

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct RscTexture {
    SdlTexture* ptr;
    int width;
    int height;
}

union RscData {
    RscTexture texture;
}

struct Resource {
    RscKind kind;
    RscData data;
}

struct Resources {
    Resource[] db;
    int count;
}

struct Platform {
    SdlWindow* window;
    SdlRenderer* renderer;
    SdlTexture* framebuffer;
    Diagnostics* diagnostics;
    Resources resources;
    Fonts fonts;
    long prev_ticks;
}



//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

// push resource into database
//-----------------------------------------------------------------------------
fn int? Resources.push(Resources* self, Resource rsc) {
    if (self.count >= MAX_RESOURCE_COUNT) return RSC_ERROR~;
    self.db[self.count] = rsc;
    self.count++;
    return self.count - 1;
}


// init the desktop platform layer
//-----------------------------------------------------------------------------
fn void? Platform.init(Platform* self, Diagnostics* diagnostics) {
    self.diagnostics = diagnostics;
    self.diagnostics.info("Initializing Desktop Platform");
    
    if (!sdl3::init({ .video = true })) {
        self.diagnostics.report_platform_failed_to_init_sdl(sdl3::getError());
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
    self.diagnostics.info("Shutting Down Desktop Platform");

    self.fonts.shutdown();

    for (int i = 0; i < self.resources.count; i++) {
        Resource* rsc = &self.resources.db[i];
        switch (rsc.kind) {
            case TEXTURE:
                if (rsc.data.texture.ptr != null) {
                    sdl3::destroyTexture(rsc.data.texture.ptr);
                    rsc.data.texture.ptr = null;
                }
            
            default: break;
        }
    }

    sdl3::destroyRenderer(self.renderer);
    sdl3::destroyWindow(self.window);
    
    *self = {};
}


// load game cart
//-----------------------------------------------------------------------------
fn void? Platform.load_cart(Platform* self, Cart* cart, String path) {
    self.diagnostics.info("Loading Game Cart");
    
    // read game code bytes from disk
    self.read_file(path, &cart.file_bytes)!;
    self.diagnostics.file_bytes = &cart.file_bytes;

    // compile game code
    Compiler compiler; defer compiler.destroy();
    compiler.compile(self.diagnostics, cart.file_bytes)!;

    Vm vm; defer vm.destroy();
    vm.init(self.diagnostics, compiler.image)!;
    
    vm.run()!;

}


// load image
//-----------------------------------------------------------------------------
fn int? Platform.load_png(Platform* self, String path) {
    self.diagnostics.info(string::tformat("Loading PNG: \"%s\"", path));
    
    SdlSurface* surf = sdl3::loadPNG(path);
    if (surf == null) return IO_ERROR~;
    defer sdl3::destroySurface(surf);

    SdlTexture* tex = sdl3::createTextureFromSurface(self.renderer, surf);
    if (tex == null) return SDL_ERROR~;

    Resource rsc = {
        .kind = TEXTURE,
        .data = {
            .texture = {
                .ptr = tex,
                .width = surf.w,
                .height = surf.h
            }
        }
    };
    
    int id = self.resources.push(rsc)!;
    return id;
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
    for (int i = 0; i < graphics.queue.length; i++) {
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

            case SPRITE:
                SpriteCmd* data = &cmd.data.sprite;
                if (data.texture < 0 || data.texture >= MAX_RESOURCE_COUNT) continue;
                Palette pal = (Palette)(data.color % 64);
                char alpha = pal.a;
                if (data.opacity < 255) alpha = data.opacity;
                Resource* rsc = &self.resources.db[(int)data.texture];
                if (rsc.kind != TEXTURE) continue;
                self.draw_sprite_simple(&rsc.data.texture, data.dst.x, data.dst.y, pal.r, pal.g, pal.b, alpha);

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



// sprite drawing helper
//-----------------------------------------------------------------------------
fn void Platform.draw_sprite_simple(Platform* self, RscTexture* tex, float x, float y, char r, char g, char b, char a) {
    if (tex.ptr == null ||
        !sdl3::setTextureColorMod(tex.ptr, r, g, b) ||
        !sdl3::setTextureAlphaMod(tex.ptr, a))
    {
        return;
    }

    SdlFRect dst = { x, y, tex.width, tex.height };
    sdl3::renderTexture(self.renderer, tex.ptr, null, &dst);
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
fn void? Platform.read_file(Platform* self, String path, ByteBuffer* output) {
    self.diagnostics.info(string::tformat("Reading File: \"%s\"", path));
    *output = {};

    // check if file exists
    File? fp = file::open(path, "rb");
    if (catch err = fp) {
        self.diagnostics.report_platform_failed_to_read_file(path);
        return IO_ERROR~;
    }
    defer fp.close();

    long? size = fp.size();
    if (catch err = size) return IO_ERROR~;

    if (size > MAX_SCRIPT_BYTES) {
        self.diagnostics.report_platform_script_size_limit_exceeded(size, MAX_SCRIPT_BYTES);
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