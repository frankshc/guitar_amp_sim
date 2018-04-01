#ifndef VGA_H
#define VGA_H
#define PIXEL_BUFFER ((volatile short *)0x08000000)
void draw_graphic(int x, int y, int width, int length, unsigned short* graphic);

#endif /* VGA_H */

