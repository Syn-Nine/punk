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
    Color tint;
    char opacity;
}

struct TextCmd {
    FontId font;
    Vec2 pos;
    Color color;
    char opacity;
    sz scratch_addr;
    sz length;
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

union DrawPayload {
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
    DrawPayload data;
}

struct DrawQueue {
    DrawCmd[] commands;
    sz length;
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
fn void Graphics.begin_frame(Graphics* graphics) {
    graphics.queue.pass_open = false;
    graphics.queue.failed = false;
}


// start a render target pass
//-----------------------------------------------------------------------------
fn bool Graphics.begin_pass(Graphics* graphics, TargetId target, LoadOp load, Color color, char opacity = 255) {
    DrawQueue* q = &graphics.queue;
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
fn void Graphics.end_pass(Graphics* graphics) {
    DrawQueue* q = &graphics.queue;
    q.draw({ .kind = END_PASS });
    q.pass_open = false;
}


// command a line
//-----------------------------------------------------------------------------
fn void Graphics.draw_line(Graphics* graphics, float x0, float y0, float x1, float y1, Color color, char opacity = 255) {
    DrawQueue* q = &graphics.queue;
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
fn void Graphics.draw_pixel(Graphics* graphics, float x, float y, Color color, char opacity = 255) {
    DrawQueue* q = &graphics.queue;
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
fn void Graphics.draw_rect(Graphics* graphics, float x, float y, float w, float h, Color color, char opacity = 255) {
    DrawQueue* q = &graphics.queue;
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

