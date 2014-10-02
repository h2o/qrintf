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
#include <stdint.h>
#include <stdio.h>

#undef sprintf
#define sprintf qprintf

#define QP_TOSTR(s) _QP_TOSTR(s)
#define _QP_TOSTR(s) #s

typedef struct qrintf_t {
  char *str;
  size_t off;
} qrintf_t;

static inline qrintf_t _qrintf_init(char *str)
{
  struct qrintf_t ret;
  ret.str = str;
  ret.off = 0;
  return ret;
}

static inline int _qrintf_finalize(qrintf_t ctx)
{
    return (int)ctx.off;
}

static inline qrintf_t _qrintf_c(qrintf_t ctx, int c)
{
    ctx.str[ctx.off++] = c;
    return ctx;
}

static inline qrintf_t _qrintf_s(qrintf_t ctx, const char *s)
{
    for (; *s != '\0'; ++s)
        ctx.str[ctx.off++] = *s;
    return ctx;
}

static inline qrintf_t _qrintf_s_len(qrintf_t ctx, const char *s, size_t l)
{
    for (; l != 0; --l)
        ctx.str[ctx.off++] = *s++;
    return ctx;
}

#define _QP_SIGNED_F(type, suffix, min, max) \
    static inline qrintf_t _qrintf_ ## suffix (qrintf_t ctx, type v) \
    { \
        char tmp[sizeof(QP_TOSTR(max)) - 1]; \
        size_t i = 0; \
        if (v < 0) { \
            /* cannot negate min */ \
            if (v == min) \
                return _qrintf_s_len(ctx, QP_TOSTR(min), sizeof(QP_TOSTR(min)) - 1); \
            ctx.str[ctx.off++] = '-'; \
            v = -v; \
        } \
        do { \
            tmp[i++] = '0' + v % 10; \
        } while ((v /= 10) != 0); \
        do { \
            ctx.str[ctx.off++] = tmp[--i]; \
        } while (i != 0); \
        return ctx; \
    }

_QP_SIGNED_F(short, hd, SHRT_MIN, SHRT_MAX)
_QP_SIGNED_F(int, d, INT_MIN, INT_MAX)
_QP_SIGNED_F(long, ld, LONG_MIN, LONG_MAX)
_QP_SIGNED_F(long long, lld, LLONG_MIN, LLONG_MAX)

#define _QP_UNSIGNED_F(type, suffix, max) \
    static inline qrintf_t _qrintf_ ## suffix (qrintf_t ctx, type v) \
    { \
        char tmp[sizeof(QP_TOSTR(max)) - 1]; \
        size_t i = 0; \
        do { \
            tmp[i++] = '0' + v % 10; \
        } while ((v /= 10) != 0); \
        do { \
            ctx.str[ctx.off++] = tmp[--i]; \
        } while (i != 0); \
        return ctx; \
    }

_QP_UNSIGNED_F(unsigned short, hu, USHRT_MAX)
_QP_UNSIGNED_F(unsigned, u, UINT_MAX)
_QP_UNSIGNED_F(unsigned long, lu, ULONG_MAX)
_QP_UNSIGNED_F(unsigned long long, llu, ULLONG_MAX)
_QP_UNSIGNED_F(size_t, zu, SIZE_MAX)

#define _QP_HEX_F(type, suffix, uc) \
    static inline qrintf_t _qrintf_ ## suffix (qrintf_t ctx, type v) \
    { \
        char tmp[sizeof(type) * 2]; \
        size_t i = 0; \
        do { \
            tmp[i++] = (uc ? "0123456789ABCDEF" : "0123456789abcdef")[v & 0xf]; \
        } while ((v >>= 4) != 0); \
        do { \
            ctx.str[ctx.off++] = tmp[--i]; \
        } while (i != 0); \
        return ctx; \
    }

_QP_HEX_F(unsigned short, hx, 0)
_QP_HEX_F(unsigned short, hX, 1)
_QP_HEX_F(unsigned, x, 0)
_QP_HEX_F(unsigned, X, 1)
_QP_HEX_F(unsigned long, lx, 0)
_QP_HEX_F(unsigned long, lX, 1)
_QP_HEX_F(unsigned long long, llx, 0)
_QP_HEX_F(unsigned long long, llX, 1)
_QP_HEX_F(size_t, zx, 0)
_QP_HEX_F(size_t, zX, 1)

#ifdef __cplusplus
}
#endif

#endif
