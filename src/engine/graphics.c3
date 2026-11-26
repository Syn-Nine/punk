//-----------------------------------------------------------------------------
// utilities for buffering drawing operations
//-----------------------------------------------------------------------------
module punk;

alias TargetId = int;
alias TextureId = int;
alias FontId = int;
alias Color = char; // punk palette color index

//-----------------------------------------------------------------------------
// CONSTANTS
//-----------------------------------------------------------------------------

const MAX_DRAW_QUEUE_SIZE = 64 * 1024;


//-----------------------------------------------------------------------------
// ENUMERATIONS
//-----------------------------------------------------------------------------

enum DrawKind : char {
    BEGIN_PASS, END_PASS, CLEAR, SPRITE, TEXT, LINE, RECT, PIXEL
}

enum LoadOp : char {
    CLEAR, PRESERVE
}


//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct Vec2 { float x; float y; }
struct Rect { float x; float y; float w; float h; }


struct BeginPassCmd {
    TargetId target;
    LoadOp load;
    Color color;
    char opacity;
}

struct ClearCmd {
    Color color;
    char opacity;
}

struct SpriteCmd {
    TextureId texture;
    Rect src;
    Rect dst;
    Color color;
    char opacity;
    bool simple;
}

struct TextCmd {
    FontId font;
    Vec2 pos;
    Color color;
    char opacity;
    int addr;
    int length;
}

struct LineCmd {
    Vec2 from;
    Vec2 to;
    float width;
    Color color;
    char opacity;
}

struct PixelCmd {
    Vec2 pos;
    Color color;
    char opacity;
}

struct RectCmd {
    Rect bounds;
    Color color;
    char opacity;
}

union DrawData {
    BeginPassCmd pass;
    ClearCmd clear;
    SpriteCmd sprite;
    TextCmd text;
    LineCmd line;
    PixelCmd pixel;
    RectCmd rect;
}

struct DrawCmd {
    DrawKind kind;
    DrawData data;
}

struct DrawQueue {
    DrawCmd[] commands;
    int length;
    bool pass_open;
    bool failed;
}

struct Graphics {
    DrawQueue queue;
    int background_color;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

// command a drawing operation
//-----------------------------------------------------------------------------
fn void DrawQueue.draw(DrawQueue* q, DrawCmd cmd) {
    if (q.pass_open) q.push(cmd);
}


// push command to drawing queue
//-----------------------------------------------------------------------------
fn bool DrawQueue.push(DrawQueue* q, DrawCmd cmd) {
    if (q.failed) return false;
    if (q.length >= MAX_DRAW_QUEUE_SIZE) {
        q.failed = true;
        return false;
    }
    q.commands[q.length] = cmd;
    q.length++;
    return true;
}


// setup the command queue
//-----------------------------------------------------------------------------
fn void Graphics.begin_frame(Graphics* self) {
    self.queue.pass_open = false;
    self.queue.failed = false;
}


// start a render target pass
//-----------------------------------------------------------------------------
fn bool Graphics.begin_pass(Graphics* self, TargetId target, LoadOp load, Color color, char opacity = 255) {
    DrawQueue* q = &self.queue;
    if (q.pass_open) q.failed = true;
    if (q.failed) return false;
    q.length = 0; // reset queue
    DrawCmd cmd = {
        .kind = BEGIN_PASS,
        .data = {
            .pass = { target, load, color, opacity }
        }
    };
    if (!q.push(cmd)) return false;
    q.pass_open = true;
    return true;
}


// end the render target pass
//-----------------------------------------------------------------------------
fn void Graphics.end_pass(Graphics* self) {
    DrawQueue* q = &self.queue;
    q.draw({ .kind = END_PASS });
    q.pass_open = false;
}


// command a line
//-----------------------------------------------------------------------------
fn void Graphics.draw_line(Graphics* self, float x0, float y0, float x1, float y1, Color color, char opacity = 255) {
    DrawQueue* q = &self.queue;
    DrawCmd cmd = {
        .kind = LINE,
        .data = {
            .line = {
                .from = { x0, y0 },
                .to = { x1, y1 },
                .width = 1.0,
                .color = color,
                .opacity = opacity
            }
        }
    };
    q.draw(cmd);
}


// command a pixel
//-----------------------------------------------------------------------------
fn void Graphics.draw_pixel(Graphics* self, float x, float y, Color color, char opacity = 255) {
    DrawQueue* q = &self.queue;
    DrawCmd cmd = {
        .kind = PIXEL,
        .data = {
            .pixel = {
                .pos = { x, y },
                .color = color,
                .opacity = opacity
            }
        }
    };
    q.draw(cmd);
}


// command a pixel
//-----------------------------------------------------------------------------
fn void Graphics.draw_rect(Graphics* self, float x, float y, float w, float h, Color color, char opacity = 255) {
    DrawQueue* q = &self.queue;
    DrawCmd cmd = {
        .kind = RECT,
        .data = {
            .rect = {
                .bounds = { x, y, w, h },
                .color = color,
                .opacity = opacity
            }
        }
    };
    q.draw(cmd);
}


// command text drawing
//-----------------------------------------------------------------------------
fn void Graphics.draw_text(Graphics* self, int addr, int length, float x, float y, Color color = 7, char opacity = 255) {
    DrawQueue* q = &self.queue;
    DrawCmd cmd = {
        .kind = TEXT,
        .data = {
            .text = {
                .font = 0,
                .addr = addr,
                .length = length,
                .pos = { x, y },
                .color = color,
                .opacity = opacity
            }
        }
    };
    q.draw(cmd);
}


// command sprite drawing
//-----------------------------------------------------------------------------
fn void Graphics.draw_sprite(Graphics* self, TextureId texture, float x, float y, Color color = 7, char opacity = 255) {
    DrawQueue* q = &self.queue;
    DrawCmd cmd = {
        .kind = SPRITE,
        .data = {
            .sprite = {
                .simple = true,
                .dst = { .x = x, .y = y },
                .texture = texture,
                .color = color,
                .opacity = opacity
            }
        }
    };
    q.draw(cmd);
}