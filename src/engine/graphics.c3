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
    BEGIN_PASS, END_PASS, CLEAR, SPRITE, TEXT, LINE, RECT
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
}

struct ClearCmd {
	Color color;
}

struct SpriteCmd {
    TextureId texture;
    Rect src;
    Rect dst;
    Color tint;
}

struct TextCmd {
    FontId font;
    Vec2 pos;
    Color color;
    sz scratch_addr;
    sz length;
}

struct LineCmd {
    Vec2 from;
    Vec2 to;
    float width;
    Color color;
}

struct RectCmd {
    Rect bounds;
    Color color;
}

union DrawPayload {
    BeginPassCmd pass;
    ClearCmd clear;
    SpriteCmd sprite;
    TextCmd text;
    LineCmd line;
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
fn bool DrawQueue.draw(DrawQueue* q, DrawCmd cmd) {
	if (!q.pass_open) {
		q.failed = true;
		return false;
	}
	return q.push(cmd);
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
	graphics.queue.length = 0;
	graphics.queue.pass_open = false;
	graphics.queue.failed = false;
}


// flush the command queue
//-----------------------------------------------------------------------------
fn void Graphics.end_frame(Graphics* graphics) {

}


// start a render target pass
//-----------------------------------------------------------------------------
fn bool Graphics.begin_pass(Graphics* graphics, TargetId target, LoadOp load, Color color) {
	DrawQueue* q = &graphics.queue;
	if (q.pass_open) q.failed = true;
	if (q.failed) return false;
	DrawCmd cmd = {
		.kind = BEGIN_PASS,
		.data = {
			.pass = { target, load, color }
		}
	};
	if (!q.push(cmd)) return false;
	q.pass_open = true;
	return true;
}


// end the render target pass
//-----------------------------------------------------------------------------
fn bool Graphics.end_pass(Graphics* graphics) {
	DrawQueue* q = &graphics.queue;
	DrawCmd cmd = { .kind = END_PASS };
	if (!q.draw(cmd)) return false;
	q.pass_open = false;
	return true;
}




// fn bool DrawQueue.text(DrawQueue* q, FontId font, Vec2 pos,
//                        Color color, String value)
// {
//     if (q.failed) return false;

//     if (value.len > q.text_bytes.len - q.text_used)
//     {
//         q.failed = true;
//         return false;
//     }

//     usz offset = q.text_used;
//     if (!q.draw({
//         .kind = DrawKind.TEXT,
//         .data = { .text = { font, pos, color, offset, value.len } },
//     })) return false;

//     for (usz i = 0; i < value.len; i++)
//     {
//         q.text_bytes[offset + i] = value[i];
//     }

//     q.text_used += value.len;
//     return true;
// }



// // Pass 1: draw into the persistent tracks target.
// q.begin_pass(tracks,
//              reset_tracks ? LoadOp.CLEAR : LoadOp.PRESERVE,
//              0x00000000);

// q.draw({
//     .kind = DrawKind.LINE,
//     .data = { .line = { { 48, 90 }, { 60, 94 }, 2.0, 0x282828FF } },
// });

// q.end_pass();

// // Pass 2: draw into the main canvas.
// q.begin_pass((TargetId)0, LoadOp.CLEAR, 0x606068FF);

// q.draw({
//     .kind = DrawKind.SPRITE,
//     .data = { .sprite = {
//         tracks_image, { 0, 0, 320, 180 }, { 0, 0, 320, 180 }, 0xFFFFFFFF,
//     } },
// });

// q.draw({
//     .kind = DrawKind.SPRITE,
//     .data = { .sprite = {
//         car_atlas, { 0, 0, 16, 12 }, { 60, 88, 16, 12 }, 0xFFFFFFFF,
//     } },
// });

// q.draw({
//     .kind = DrawKind.RECT,
//     .data = { .rect = { { 4, 4, 82, 14 }, 0x181818FF } },
// });

// q.text(hud_font, { 8, 7 }, 0xFFFFFFFF, "LAP 1 / 3");
// q.end_pass();


// q.draw({
//     .kind = DrawKind.CLEAR,
//     .data = { .clear_color = 0x101820FF },
// });