//-----------------------------------------------------------------------------
// scratch memory for game tempory data
//-----------------------------------------------------------------------------
module punk;

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct Scratch {
    char[] bytes;
    int cursor;
}


//-----------------------------------------------------------------------------
fn int Scratch.clone_text(Scratch* self, String text) {
    int length = text.len;
    if (self.cursor >= MAX_SCRATCH_BYTES - length) self.cursor = 0;
    int addr = self.cursor;
    for (int i = 0; i < length; i++) {
        self.bytes[addr + i] = text[i];
    }
    self.cursor += length;
    return addr;
}


