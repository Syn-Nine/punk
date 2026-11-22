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

enum Palette : char (char r, char g, char b, char a) {
	BLACK 		{ 0, 0, 0, 255 },
	CHARCOAL 	{ 36, 36, 36, 255 },
	ASH 		{ 53, 52, 45, 255 },
	GRAY 		{ 109, 109, 109, 255 },
	MID_GRAY 	{ 146, 146, 146, 255 },
	SILVER 		{ 182, 182, 182, 255 },
	PALE_GRAY 	{ 208, 209, 217, 255 },
	WHITE 		{ 255, 255, 255, 255 },
	ESPRESSO 	{ 40, 27, 21, 255 },
	OXBLOOD 	{ 74, 19, 15, 255 },
	COCOA 		{ 86, 48, 35, 255 },
	TAUPE 		{ 91, 82, 79, 255 },
	BRICK 		{ 167, 49, 37, 255 },
	COPPER 		{ 173, 102, 58, 255 },
	RED 		{ 232, 84, 84, 255 },
	DUSTY_PINK 	{ 188, 122, 134, 255 },
	UMBER 		{ 101, 69, 32, 255 },
	TAN 		{ 126, 90, 60, 255 },
	BRONZE 		{ 137, 117, 64, 255 },
	KHAKI 		{ 165, 148, 82, 255 },
	HONEY 		{ 206, 148, 90, 255 },
	PEACH 		{ 242, 168, 112, 255 },
	GOLD 		{ 245, 207, 90, 255 },
	CREAM 		{ 251, 233, 184, 255 },
	COAL 		{ 19, 22, 16, 255 },
	DARK_OLIVE 	{ 41, 49, 22, 255 },
	PINE 		{ 44, 70, 37, 255 },
	FERN 		{ 56, 120, 48, 255 },
	LEAF 		{ 72, 136, 48, 255 },
	GRASS 		{ 84, 159, 72, 255 },
	SAGE 		{ 165, 184, 112, 255 },
	CITRON 		{ 214, 221, 121, 255 },
	DARK_GREEN 	{ 0, 33, 0, 255 },
	DARK_TEAL 	{ 61, 76, 75, 255 },
	FOREST 		{ 47, 95, 54, 255 },
	GREEN 		{ 3, 113, 12, 255 },
	TEAL 		{ 52, 123, 114, 255 },
	JADE 		{ 0, 132, 24, 255 },
	LIME 		{ 104, 199, 59, 255 },
	MINT 		{ 142, 216, 173, 255 },
	INK 		{ 16, 33, 52, 255 },
	NAVY 		{ 17, 48, 84, 255 },
	DENIM 		{ 33, 71, 118, 255 },
	DEEP_BLUE 	{ 34, 101, 137, 255 },
	OCEAN 		{ 46, 134, 195, 255 },
	CADET_BLUE 	{ 90, 163, 184, 255 },
	SKY 		{ 94, 186, 239, 255 },
	PALE_BLUE 	{ 156, 199, 247, 255 },
	MIDNIGHT 	{ 7, 9, 44, 255 },
	INDIGO 		{ 27, 27, 118, 255 },
	COBALT 		{ 36, 57, 174, 255 },
	IRIS 		{ 99, 107, 222, 255 },
	BLUE 		{ 19, 148, 252, 255 },
	CORNFLOWER 	{ 105, 157, 248, 255 },
	ICE 		{ 191, 227, 250, 255 },
	CYAN 		{ 0, 255, 255, 255 },
	PLUM 		{ 81, 28, 107, 255 },
	MULBERRY 	{ 140, 43, 126, 255 },
	SLATE 		{ 101, 96, 103, 255 },
	VIOLET 		{ 128, 84, 179, 255 },
	ORCHID 		{ 205, 88, 174, 255 },
	MIST 		{ 154, 171, 171, 255 },
	LILAC 		{ 233, 153, 237, 255 },
	BLANK 		{ 255, 0, 255, 0 },
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
fn bool Graphics.begin_pass(Graphics* graphics, TargetId target, LoadOp load, Color color) {
	DrawQueue* q = &graphics.queue;
	if (q.pass_open) q.failed = true;
	if (q.failed) return false;
	q.length = 0; // reset queue
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
fn void Graphics.end_pass(Graphics* graphics) {
	DrawQueue* q = &graphics.queue;
	q.draw({ .kind = END_PASS });
	q.pass_open = false;
}


// command a line
//-----------------------------------------------------------------------------
fn void Graphics.draw_line(Graphics* graphics, float x0, float y0, float x1, float y1, Color color) {
	DrawQueue* q = &graphics.queue;
	DrawCmd cmd = {
		.kind = LINE,
		.data = {
			.line = {
				.from = { x0, y0 },
				.to = { x1, y1 },
				.width = 1.0,
				.color = color
			}
		}
	};
	q.draw(cmd);
}

