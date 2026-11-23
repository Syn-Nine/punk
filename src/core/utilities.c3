//-----------------------------------------------------------------------------
// general support utilities
//-----------------------------------------------------------------------------
module punk;
import std::io;


excuse SDL_ERROR, IO_ERROR;


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

// free memory and destroy the byte buffer object
//-----------------------------------------------------------------------------
fn void byte_buffer_release(ByteBuffer* buffer) {
    if (buffer.bytes.ptr != null) {
        mem::free(buffer.bytes.ptr);
    }
    *buffer = {};
}