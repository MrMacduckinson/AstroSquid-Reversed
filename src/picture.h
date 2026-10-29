#ifndef ASTRO_PICTURE_H
#define ASTRO_PICTURE_H
#include <stddef.h>
#include <stdint.h>
/* Top-to-bottom RGB rows, 1..640 by 1..480; alpha is QuickDraw zero.
 * PICT payload, without the file's512-byte prefix. Caller frees *output. */
int astro_picture_encode(const unsigned char *rgb,size_t stride,unsigned width,unsigned height,
                         unsigned char **output,size_t *size);
/* Default original window: finite clip, black foreground, raw xRGB with FF padding. */
int astro_picture_window_encode(const unsigned char *rgb,size_t stride,unsigned width,unsigned height,
                                unsigned char **output,size_t *size);
/* Fullscreen top-down RGBA: preserve alpha, raw ARGB and infinite clip. */
int astro_picture_fullscreen_encode(const unsigned char *rgba,size_t stride,unsigned width,unsigned height,
                                    unsigned char **output,size_t *size);
/* Original open-file metadata; the application saveScreenshot caller applies it. */
enum { ASTRO_PICTURE_TYPE=0x50494354, ASTRO_PICTURE_CREATOR=0x3f3f3f3f };
int astro_picture_filename(uint32_t mac_seconds,char *name,size_t capacity);
/* Same ownership contract; includes the native512-byte zero file prefix. */
int astro_picture_file_encode(const unsigned char *rgb,size_t stride,unsigned width,unsigned height,
                              unsigned char **output,size_t *size);
#endif
