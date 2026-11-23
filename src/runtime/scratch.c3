//-----------------------------------------------------------------------------
// scratch memory for game tempory data
//-----------------------------------------------------------------------------
module punk;

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct Scratch {
    char[] bytes;
    sz cursor;
}


//-----------------------------------------------------------------------------
fn sz Scratch.clone_text(Scratch* self, String text) {
	sz length = text.len;
	if (self.cursor >= MAX_SCRATCH_BYTES - length) self.cursor = 0;
	sz addr = self.cursor;
	for (sz i = 0; i < length; i++) {
		self.bytes[addr + i] = text[i];
	}
	self.cursor += length;
	return addr;
}


