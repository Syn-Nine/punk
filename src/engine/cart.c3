// data structures and utilities for the game cart
module punk;
import std::io;


struct Cart {
    ByteBuffer file_bytes;
    Diagnostics* diagnostics;
    ProgramImage* image;
}


fn void? Cart.compile(Cart* self) {
    // allocate and init the program image
    self.image = mem::new(ProgramImage);
    self.image.diagnostics = self.diagnostics;

    // compile the image using the cart file buffer
    Compiler compiler; defer compiler.destroy();
    compiler.diagnostics = self.diagnostics;
    compiler.compile(self.image, self.file_bytes)!;
}


fn void Cart.destroy(Cart* self) {
    self.image.destroy();
    free(self.image);
    byte_buffer_release(&self.file_bytes);
}