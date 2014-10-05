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
#include <string.h>

#undef sprintf
#define sprintf _qp_sprintf

#if _QRINTF_COUNT_CALL
extern size_t _qrintf_call_cnt;
#endif

typedef struct qrintf_t {
  char *str;
  size_t off;
} qrintf_t;

static inline qrintf_t _qrintf_init(char *str)
{
    struct qrintf_t ret;
    ret.str = str;
    ret.off = 0;
#if _QRINTF_COUNT_CALL
    ++_qrintf_call_cnt;
#endif
    return ret;
}

static inline int _qrintf_finalize(qrintf_t ctx)
{
    ctx.str[ctx.off] = '\0';
    return (int)ctx.off;
}

static inline qrintf_t _qrintf_c(qrintf_t ctx, int c)
{
    ctx.str[ctx.off++] = c;
    return ctx;
}

static inline qrintf_t _qrintf_width_c(qrintf_t ctx, int fill_ch, int width, int c)
{
    for (; 1 < width; --width)
        ctx.str[ctx.off++] = fill_ch;
    ctx.str[ctx.off++] = c;
    return ctx;
}

static inline qrintf_t _qrintf_s(qrintf_t ctx, const char *s)
{
    for (; *s != '\0'; ++s)
        ctx.str[ctx.off++] = *s;
    return ctx;
}

static inline qrintf_t _qrintf_width_s(qrintf_t ctx, int fill_ch, int width, const char *s)
{
    int slen = strlen(s);
    for (; slen < width; --width)
        ctx.str[ctx.off++] = fill_ch;
    for (; slen != 0; --slen)
        ctx.str[ctx.off++] = *s++;
    return ctx;
}

static inline qrintf_t _qrintf_s_len(qrintf_t ctx, const char *s, size_t l)
{
    for (; l != 0; --l)
        ctx.str[ctx.off++] = *s++;
    return ctx;
}

#define _QP_SIGNED_F(type, suffix, min, max) \
    static inline int _qrintf_ ## suffix ## _core(char *buf, type v) \
    { \
        int i = 0; \
        if (v < 0) { \
            if (v == min) { \
                buf[i++] = '1' + max % 10; \
                v = max / 10; \
            } else { \
                v = -v; \
            } \
        } \
        do { \
            buf[i++] = '0' + v % 10; \
        } while ((v /= 10) != 0); \
        return i; \
    } \
    static inline qrintf_t _qrintf_ ## suffix (qrintf_t ctx, type v) \
    { \
        char buf[sizeof(type) * 3]; \
        int len; \
        if (v < 0) \
            ctx.str[ctx.off++] = '-'; \
        len = _qrintf_ ## suffix ## _core(buf, v); \
        do { \
            ctx.str[ctx.off++] = buf[--len]; \
        } while (len != 0); \
        return ctx; \
    } \
    static inline qrintf_t _qrintf_width_ ## suffix (qrintf_t ctx, int fill_ch, int width, type v) \
    { \
        char buf[sizeof(type) * 3 + 1]; \
        int len = _qrintf_ ## suffix ## _core(buf, v); \
        if (v < 0) { \
            if (fill_ch == ' ') { \
                buf[len++] = '-'; \
            } else { \
                ctx.str[ctx.off++] = '-'; \
                --width; \
            } \
        } \
        for (; len < width; --width) \
            ctx.str[ctx.off++] = fill_ch; \
        do { \
            ctx.str[ctx.off++] = buf[--len]; \
        } while (len != 0); \
        return ctx; \
    }

_QP_SIGNED_F(short, hd, SHRT_MIN, SHRT_MAX)
_QP_SIGNED_F(int, d, INT_MIN, INT_MAX)
_QP_SIGNED_F(long, ld, LONG_MIN, LONG_MAX)
_QP_SIGNED_F(long long, lld, LLONG_MIN, LLONG_MAX)

#define _QP_UNSIGNED_F(type, suffix, max) \
    static inline qrintf_t _qrintf_width_ ## suffix (qrintf_t ctx, int fill_ch, int width, type v) \
    { \
        char tmp[sizeof(type) * 3]; \
        int len = 0; \
        do { \
            tmp[len++] = '0' + v % 10; \
        } while ((v /= 10) != 0); \
        for (; len < width; --width) \
            ctx.str[ctx.off++] = fill_ch; \
        do { \
            ctx.str[ctx.off++] = tmp[--len]; \
        } while (len != 0); \
        return ctx; \
    } \
    static inline qrintf_t _qrintf_ ## suffix (qrintf_t ctx, type v) \
    { \
        return _qrintf_width_ ##suffix (ctx, 0, 0, v); \
    }

_QP_UNSIGNED_F(unsigned short, hu, USHRT_MAX)
_QP_UNSIGNED_F(unsigned, u, UINT_MAX)
_QP_UNSIGNED_F(unsigned long, lu, ULONG_MAX)
_QP_UNSIGNED_F(unsigned long long, llu, ULLONG_MAX)
_QP_UNSIGNED_F(size_t, zu, SIZE_MAX)

#define _QP_ALIGN(x,n)  (((x)+((n)-1))&(~((n)-1)))

#define _QP_HEX_F(type, suffix, uc) \
    static inline qrintf_t _qrintf_width_ ## suffix (qrintf_t ctx, int fill_ch, int width, type v) \
    { \
        int len; \
        if (v != 0) { \
            int bits; \
            if (sizeof(type) == sizeof(unsigned long long)) \
                bits = sizeof(type) * 8 - __builtin_clzll(v); \
            else if (sizeof(type) == sizeof(unsigned long)) \
                bits = sizeof(type) * 8 - __builtin_clzl(v); \
            else \
                bits = sizeof(int) * 8 - __builtin_clz(v); \
            len = (bits + 3) >> 2; \
        } else { \
            len = 1; \
        } \
        for (; len < width; --width) \
            ctx.str[ctx.off++] = fill_ch; \
        len *= 4; \
        do { \
            len -= 4; \
            ctx.str[ctx.off++] = (uc ? "0123456789ABCDEF" : "0123456789abcdef")[(v >> len) & 0xf]; \
        } while (len != 0); \
        return ctx; \
    } \
    static inline qrintf_t _qrintf_ ## suffix (qrintf_t ctx, type v) \
    { \
        return _qrintf_width_ ##suffix (ctx, 0, 0, v); \
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

#undef _QP_ALIGN
#ifdef __cplusplus
}
#endif

#endif
