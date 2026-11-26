//-----------------------------------------------------------------------------
// font loading and rendering
//-----------------------------------------------------------------------------
module punk;
import sdl3;


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct Glyph {
    SdlFRect rect;
    int x_offset;
    int y_offset;
    int advance;
}

struct Fonts {
    SdlRenderer* renderer;
    SdlTexture* texture;
    int height;
    Glyph[256] glyphs;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
fn void? Fonts.init(Fonts* self, SdlRenderer* renderer, int[] data) {
    if (renderer == null || data.len < 4) return FONT_ERROR~;
    
    int height = data[0];
    int image_width = data[1];
    int image_height = data[2];
    int glyph_count = data[3];

    if (height <= 0 || image_width <= 0 || image_height <= 0 || glyph_count <= 0 || glyph_count > 256) {
        return FONT_ERROR~;
    }

    int pixel_start = 4 + glyph_count * 8;
    if (data.len < pixel_start || (long)image_width * image_height > (long)data.len - pixel_start) {
        return FONT_ERROR~;
    }

    *self = { .renderer = renderer, .height = height };
    
    for (int i = 0; i < glyph_count; i++) {
        int offset = 4 + i * 8;
        int id = data[offset];
        if (id < 0 || id >= 256) return FONT_ERROR~;
        
        Glyph* glyph = &self.glyphs[id];
        glyph.rect = {
            (float)data[offset + 1],
            (float)data[offset + 2],
            (float)data[offset + 3],
            (float)data[offset + 4],
        };
        glyph.x_offset = data[offset + 5];
        glyph.y_offset = data[offset + 6];
        glyph.advance = data[offset + 7];
    }

    SdlSurface* surface = sdl3::createSurface(image_width, image_height, RGBA32);
    if (surface == null) return FONT_ERROR~;
    defer sdl3::destroySurface(surface);

    if (!sdl3::lockSurface(surface)) return FONT_ERROR~;

    char* pixels = (char*)surface.pixels;
    for (int row = 0; row < image_height; row++) {
        char* dst = pixels + row * surface.pitch;
        int src = pixel_start + row * image_width;

        for (int col = 0; col < image_width; col++) {
            char value = (char)data[src + col];
            int channel = col * 4;
            dst[channel + 0] = value;
            dst[channel + 1] = value;
            dst[channel + 2] = value;
            dst[channel + 3] = value;
        }
    }

    sdl3::unlockSurface(surface);

    self.texture = sdl3::createTextureFromSurface(renderer, surface);
    if (self.texture == null) return FONT_ERROR~;
    
    if (!sdl3::setTextureScaleMode(self.texture, NEAREST) ||
        !sdl3::setTextureBlendMode(self.texture, BLEND))
    {
        sdl3::destroyTexture(self.texture);
        return FONT_ERROR~;
    }
}


//-----------------------------------------------------------------------------
fn void Fonts.shutdown(Fonts* self) {
    if (self.texture != null) sdl3::destroyTexture(self.texture);
    *self = {};
}


//-----------------------------------------------------------------------------
fn bool Fonts.draw_text(Fonts* self, Scratch* scratch, int addr, int length, float x, float y) {
    return self.draw_text_rgba(scratch, addr, length, x, y, 255, 255, 255, 255);
}


//-----------------------------------------------------------------------------
fn bool Fonts.draw_text_rgba(Fonts* self, Scratch* scratch, int addr, int length, float x, float y, char r, char g, char b, char a)
{
    if (self.texture == null ||
        !sdl3::setTextureColorMod(self.texture, r, g, b) ||
        !sdl3::setTextureAlphaMod(self.texture, a))
    {
        return false;
    }

    float start_x = x;

    for (int i = 0; i < length; i++) {
        char ch = scratch.bytes[addr + i];
        if (ch == '\n') {
            x = start_x;
            y += (float)self.height;
            continue;
        }

        Glyph* glyph = &self.glyphs[ch];
        if (ch != ' ' && glyph.rect.w > 0.0f && glyph.rect.h > 0.0f) {
            SdlFRect dst = {
                x + (float)glyph.x_offset,
                y + (float)glyph.y_offset,
                glyph.rect.w,
                glyph.rect.h,
            };

            if (!sdl3::renderTexture(self.renderer, self.texture, &glyph.rect, &dst)) return false;
        }

        x += (float)glyph.advance;
    }

    return true;
}