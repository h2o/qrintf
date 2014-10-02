/*
 * Copyright (c) 2014 DeNA Co., Ltd.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
#ifndef qrintf_h
#define qrintf_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>

typedef struct qrintf_t {
  char *str;
  size_t off;
} qrintf_t;

static inline qrintf_t _qrintf_init(char *str);
static inline qrintf_t _qrintf_c(qrintf_t ctx, int c);
static inline qrintf_t _qrintf_s(qrintf_t ctx, const char *s);
static inline qrintf_t _qrintf_s_len(qrintf_t ctx, const char *s, size_t l);
qrintf_t _qrintf_u(qrintf_t ctx, unsigned v);
qrintf_t _qrintf_d(qrintf_t ctx, int v);

qrintf_t _qrintf_init(char *str)
{
  struct qrintf_t ret;
  ret.str = str;
  ret.off = 0;
  return ret;
}

qrintf_t _qrintf_c(qrintf_t ctx, int c)
{
    ctx.str[ctx.off++] = c;
    return ctx;
}

qrintf_t _qrintf_s(qrintf_t ctx, const char *s)
{
    for (; *s != '\0'; ++s)
        ctx.str[ctx.off++] = *s;
    return ctx;
}

qrintf_t _qrintf_s_len(qrintf_t ctx, const char *s, size_t l)
{
    for (; l != 0; --l)
        ctx.str[ctx.off++] = *s++;
    return ctx;
}

#ifdef __cplusplus
}
#endif

#endif
