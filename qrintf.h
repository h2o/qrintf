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

#include <limits.h>
#include <stddef.h>
#include <stdio.h>

#undef sprintf
#define sprintf qprintf

#define QP_TOSTR(s) _QP_TOSTR(s)
#define _QP_TOSTR(s) #s

typedef struct qrintf_t {
  char *str;
  size_t off;
} qrintf_t;

static inline qrintf_t _qrintf_init(char *str);
static inline qrintf_t _qrintf_c(qrintf_t ctx, int c);
static inline qrintf_t _qrintf_s(qrintf_t ctx, const char *s);
static inline qrintf_t _qrintf_s_len(qrintf_t ctx, const char *s, size_t l);
static inline qrintf_t _qrintf_u(qrintf_t ctx, unsigned v);
static inline qrintf_t _qrintf_d(qrintf_t ctx, int v);

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

qrintf_t _qrintf_u(qrintf_t ctx, unsigned v)
{
    char tmp[sizeof(QP_TOSTR(UINT_MAX)) - 1];
    size_t i = 0;

    if (v == 0) {
        ctx.str[ctx.off++] = '0';
        return ctx;
    }

    do {
        tmp[i++] = '0' + v % 10;
    } while ((v /= 10) != 0);
    do {
        ctx.str[ctx.off++] = tmp[--i];
    } while (i != 0);

    return ctx;
}

qrintf_t _qrintf_d(qrintf_t ctx, int v)
{
    if (v < 0) {
        /* cannot negate INT_MIN */
        if (v == INT_MIN)
            return _qrintf_s_len(ctx, QP_TOSTR(INT_MIN), sizeof(QP_TOSTR(INT_MIN)) - 1);
        ctx.str[ctx.off++] = '-';
        v = -v;
    }

    return _qrintf_u(ctx, (unsigned)v);
}

#ifdef __cplusplus
}
#endif

#endif
