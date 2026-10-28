#ifndef ASTRO_PICTURE_H
#define ASTRO_PICTURE_H
#include <stddef.h>
/* Top-to-bottom RGB rows, 1..640 by 1..480; alpha is QuickDraw zero.
 * PICT payload, without the file's512-byte prefix. Caller frees *output. */
int astro_picture_encode(const unsigned char *rgb,size_t stride,unsigned width,unsigned height,
                         unsigned char **output,size_t *size);
#endif
