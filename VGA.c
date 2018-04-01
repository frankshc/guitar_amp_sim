#include "VGA.h"
void draw_graphic(int x, int y, int width, int length, unsigned short* graphic){
    int offset, row, col;
    /* Draw a box; assume that the coordinates are valid */
    for (row = y; row <y + width; row++){
        for (col = x; col < x + length; col++){
        offset = (row<<9) + col;
        *(PIXEL_BUFFER + offset) = *graphic; // compute halfword address, set pixel
        ++graphic;
        }
    }
}
