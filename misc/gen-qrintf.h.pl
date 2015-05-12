#! /usr/bin/perl

# Copyright (c) 2014,2015 DeNA Co., Ltd., Masahiro, Ide, Kazuho Oku
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

use strict;
use warnings;
use Text::MicroTemplate qw(build_mt);

sub build_d {
    return build_mt(template => << 'EOT', escape_func => undef)->(@_);
? my ($check, $type, $suffix) = @_;
static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_<?= $suffix ?>(qrintf_<?= $check ?>_t ctx, <?= $type ?> v)
{
    unsigned <?= $type ?> val = v >= 0 ? v : -(unsigned <?= $type ?>)v;
    int sign = v < 0;
    if (sizeof(<?= $type ?>) < sizeof(long long)) {
        return _qrintf_<?= $check ?>_long_core(ctx, 0, 0, (unsigned long)val, sign);
    }
    else {
        assert(sizeof(<?= $type ?>) == sizeof(long long));
        return _qrintf_<?= $check ?>_long_long_core(ctx, 0, 0, (unsigned long long)val, sign);
    }
}

static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_width_<?= $suffix ?>(qrintf_<?= $check ?>_t ctx, int fill_ch, int width, <?= $type ?> v)
{
    unsigned <?= $type ?> val = v >= 0 ? v : -(unsigned <?= $type ?>)v;
    int sign = v < 0;
    if (sizeof(<?= $type ?>) < sizeof(long long)) {
        return _qrintf_<?= $check ?>_long_core(ctx, fill_ch, width, (unsigned long)val, sign);
    }
    else {
        assert(sizeof(<?= $type ?>) == sizeof(long long));
        return _qrintf_<?= $check ?>_long_long_core(ctx, fill_ch, width, (unsigned long long)val, sign);
    }
}
EOT
}

sub build_u {
    my ($check, $type, $suffix) = @_;
    return build_mt(template => << 'EOT', escape_func => undef)->($check, $type, $suffix);
? my ($check, $type, $suffix) = @_;

static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_<?= $suffix ?>(qrintf_<?= $check ?>_t ctx, <?= $type ?> v)
{
    if (sizeof(<?= $type ?>) < sizeof(long long)) {
        return _qrintf_<?= $check ?>_long_core(ctx, 0, 0, (unsigned long)v, 0);
    }
    else {
        assert(sizeof(<?= $type ?>) == sizeof(long long));
        return _qrintf_<?= $check ?>_long_long_core(ctx, 0, 0, (unsigned long long)v, 0);
    }
}

static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_width_<?= $suffix ?>(qrintf_<?= $check ?>_t ctx, int fill_ch, int width, <?= $type ?> v)
{
    if (sizeof(<?= $type ?>) < sizeof(long long)) {
        return _qrintf_<?= $check ?>_long_core(ctx, fill_ch, width, (unsigned long)v, 0);
    }
    else {
        assert(sizeof(<?= $type ?>) == sizeof(long long));
        return _qrintf_<?= $check ?>_long_long_core(ctx, 0, 0, (unsigned long long)v, 0);
    }
}
EOT
}

sub build_x {
    my ($check, $type, $suffix, $with_width) = @_;
    return build_mt(template => << 'EOT', escape_func => undef)->($check, $type, $suffix, $with_width ? '_width' : '');
? my ($check, $type, $suffix, $width) = @_;
static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?><?= $width ?>_<?= $suffix ?>(qrintf_<?= $check ?>_t ctx<?= $width ? ", int fill_ch, int width" : "" ?>, <?= $type ?> v, const char *chars)
{
    size_t len;
? if ($check eq 'chk') {
    size_t rest = 0;
? }
    if (v != 0) {
        int bits;
        if (sizeof(<?= $type ?>) == sizeof(unsigned long long))
            bits = sizeof(unsigned long long) * 8 - __builtin_clzll(v);
        else if (sizeof(<?= $type ?>) == sizeof(unsigned long))
            bits = sizeof(unsigned long) * 8 - __builtin_clzl(v);
        else
            bits = sizeof(int) * 8 - __builtin_clz(v);
        len = (bits + 3) >> 2;
    } else {
        len = 1;
    }
? if ($width) {
    ctx = _qrintf_<?= $check ?>_fill(ctx, fill_ch, len, width);
? }
? if ($check eq 'chk') {
    if (ctx.off + len > ctx.size) {
        rest = ctx.off + len - ctx.size;
        len -= rest;
        v >>= rest * 4;
    }
? }
    len *= 4;
    do {
        len -= 4;
        ctx.str[ctx.off++] = chars[(v >> len) & 0xf];
    } while (len != 0);
? if ($check eq 'chk') {
    ctx.off += rest;
? }
    return ctx;
}
EOT
}

open my $fh, '>', 'include/qrintf.h'
    or die "failed to open include/qrintf.h:$!";

print $fh build_mt(template => << 'EOT', escape_func => undef)->(\&build_d, \&build_u, \&build_x)->as_string;
? my ($build_d, $build_u, $build_x) = @_;
/* DO NOT EDIT!  Automatically generated by misc/gen-printf.h.pl */
/*
 * Copyright (c) 2014,2015 DeNA Co., Ltd., Masahiro, Ide, Kazuho Oku
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
#if !defined(QRINTF_INCLUDE_COUNT)
# define QRINTF_INCLUDE_COUNT 1
#elif QRINTF_INCLUDE_COUNT==1
# undef QRINTF_INCLUDE_COUNT
# define QRINTF_INCLUDE_COUNT 2
#elif QRINTF_INCLUDE_COUNT==2
# undef QRINTF_INCLUDE_COUNT
# define QRINTF_INCLUDE_COUNT 3
#endif

#if (!defined(QRINTF_NO_AUTO_INCLUDE) && QRINTF_INCLUDE_COUNT==1) || (defined(QRINTF_NO_AUTO_INCLUDE) && QRINTF_INCLUDE_COUNT==2)

#ifdef __cplusplus
extern "C" {
#endif

#include <limits.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#undef sprintf
#define sprintf(...) _qp_sprintf(__VA_ARGS__)
#undef snprintf
#define snprintf(...) _qp_snprintf(__VA_ARGS__)

#if _QRINTF_COUNT_CALL
extern size_t _qrintf_call_cnt;
#endif

typedef struct qrintf_nck_t {
    char *str;
    size_t off;
} qrintf_nck_t;

typedef struct qrintf_chk_t {
    char *str;
    size_t off;
    size_t size;
} qrintf_chk_t;

static inline qrintf_nck_t _qrintf_nck_init(char *str)
{
    qrintf_nck_t ctx;
    ctx.str = str;
    ctx.off = 0;
#if _QRINTF_COUNT_CALL
    ++_qrintf_call_cnt;
#endif
    return ctx;
}

static inline qrintf_chk_t _qrintf_chk_init(char *str, size_t size)
{
    qrintf_chk_t ctx;
    ctx.str = str;
    ctx.off = 0;
    ctx.size = size;
#if _QRINTF_COUNT_CALL
    ++_qrintf_call_cnt;
#endif
    return ctx;
}

static inline int _qrintf_nck_finalize(qrintf_nck_t ctx)
{
    ctx.str[ctx.off] = '\0';
    return (int)ctx.off;
}

static inline int _qrintf_chk_finalize(qrintf_chk_t ctx)
{
    ctx.str[ctx.off < ctx.size ? ctx.off : ctx.size - 1] = '\0';
    return (int)ctx.off;
}

static inline qrintf_nck_t _qrintf_nck_s_len(qrintf_nck_t ctx, const char *s, size_t l)
{
    for (; l != 0; --l)
        ctx.str[ctx.off++] = *s++;
    return ctx;
}

static inline qrintf_chk_t _qrintf_chk_s_len(qrintf_chk_t ctx, const char *s, size_t l)
{
    size_t off = ctx.off;
    ctx.off += l;
    if (off + l <= ctx.size) {
    } else if (off < ctx.size) {
        l = ctx.size - off;
    } else {
        goto Exit;
    }
    for (; l != 0; --l)
        ctx.str[off++] = *s++;
Exit:
    return ctx;
}

static inline qrintf_nck_t _qrintf_nck_fill(qrintf_nck_t ctx, int ch, size_t len, int width)
{
    for (; len < (size_t)width; --width)
        ctx.str[ctx.off++] = ch;
    return ctx;
}

static inline qrintf_chk_t _qrintf_chk_fill(qrintf_chk_t ctx, int ch, size_t len, int width)
{
    if (len < (size_t)width) {
        size_t off = ctx.off, l = (size_t)width - len;
        ctx.off += l;
        if (off + l <= ctx.size) {
        } else if (off < ctx.size) {
            l = ctx.size - off;
        } else {
            goto Exit;
        }
        for (; l != 0; --l)
            ctx.str[off++] = ch;
    }
Exit:
    return ctx;
}

static inline qrintf_nck_t _qrintf_nck_s(qrintf_nck_t ctx, const char *s)
{
    for (; *s != '\0'; ++s)
        ctx.str[ctx.off++] = *s;
    return ctx;
}

static inline qrintf_chk_t _qrintf_chk_s(qrintf_chk_t ctx, const char *s)
{
    return _qrintf_chk_s_len(ctx, s, strlen(s));
}

? for my $check (qw(nck chk)) {
?   my $push = $check eq 'chk' ? sub { "do { int ch = $_[0]; if (ctx.off < ctx.size) ctx.str[ctx.off] = ch; ++ctx.off; } while (0)" } : sub { "ctx.str[ctx.off++] = $_[0]" };
static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_c(qrintf_<?= $check ?>_t ctx, int c)
{
    <?= $push->(q{c}) ?>;
    return ctx;
}

static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_width_c(qrintf_<?= $check ?>_t ctx, int fill_ch, int width, int c)
{
    ctx = _qrintf_<?= $check ?>_fill(ctx, fill_ch, 1, width);
    <?= $push->(q{c}) ?>;
    return ctx;
}

static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_width_s(qrintf_<?= $check ?>_t ctx, int fill_ch, int width, const char *s)
{
    int slen = strlen(s);
    ctx = _qrintf_<?= $check ?>_fill(ctx, fill_ch, slen, width);
    return _qrintf_<?= $check ?>_s_len(ctx, s, slen);
}
? }

static inline qrintf_nck_t _qrintf_nck_maxwidth_s(qrintf_nck_t ctx, int maxwidth, const char *s)
{
    for (; maxwidth != 0 && *s != '\0'; --maxwidth, ++s)
        ctx.str[ctx.off++] = *s;
    return ctx;
}

static inline qrintf_chk_t _qrintf_chk_maxwidth_s(qrintf_chk_t ctx, int maxwidth, const char *s)
{
    size_t len = 0;
    for (; maxwidth != 0 && s[len] != '\0'; --maxwidth, ++len)
        ;
    return _qrintf_chk_s_len(ctx, s, len);
}

static inline const char *_qrintf_get_digit_table(void)
{
    static const char digits_table[] = {
        "00010203040506070809"
        "10111213141516171819"
        "20212223242526272829"
        "30313233343536373839"
        "40414243444546474849"
        "50515253545556575859"
        "60616263646566676869"
        "70717273747576777879"
        "80818283848586878889"
        "90919293949596979899"
    };
    return digits_table;
}

/* from http://graphics.stanford.edu/~seander/bithacks.html#IntegerLog10 */
static inline unsigned _qrintf_ilog10u32(unsigned long v)
{
#define LOG2(N) ((unsigned)((sizeof(long) * 8) - __builtin_clzl((N)-1)))
    static const unsigned long ilog10table[] = {
        1UL,
        10UL,
        100UL,
        1000UL,
        10000UL,
        100000UL,
        1000000UL,
        10000000UL,
        100000000UL,
        1000000000UL,
        ULONG_MAX,
    };
    if (v != 0) {
        unsigned t;
        assert(sizeof(long) == sizeof(int));
        t = ((LOG2(v) + 1) * 1233) / 4096;
        return t + (v >= ilog10table[t]);
    }
    else {
        return 1;
    }
#undef LOG2
}

static inline unsigned _qrintf_ilog10ull(unsigned long long v)
{
#define LOG2(N) ((unsigned)((sizeof(long long) * 8) - __builtin_clzll((N)-1)))
    static const unsigned long long ilog10table[] = {
        1ULL,
        10ULL,
        100ULL,
        1000ULL,
        10000ULL,
        100000ULL,
        1000000ULL,
        10000000ULL,
        100000000ULL,
        1000000000ULL,
        10000000000ULL,
        100000000000ULL,
        1000000000000ULL,
        10000000000000ULL,
        100000000000000ULL,
        1000000000000000ULL,
        10000000000000000ULL,
        100000000000000000ULL,
        1000000000000000000ULL,
        10000000000000000000ULL,
        ULLONG_MAX,
    };
    if (v != 0) {
        unsigned t;
        assert(sizeof(long long) == 8);
        t = ((LOG2(v) + 1) * 1233) / 4096;
        return t + (v >= ilog10table[t]);
    }
    else {
        return 1;
    }
#undef LOG2
}

static inline unsigned _qrintf_ilog10ul(unsigned long v)
{
    if (sizeof(long) == 4) {
        return _qrintf_ilog10u32(v);
    }
    else if (sizeof(long) == 8) {
        assert(sizeof(long) == sizeof(long long));
        return _qrintf_ilog10ull((unsigned long long)v);
    }
    else {
        assert(0 && "size of `long` is not 32bit nor 64bit");
    }
}

static inline void _qrintf_long_core(char *p, unsigned long val)
{
    const char *digits = _qrintf_get_digit_table();
    while (val >= 100) {
        unsigned idx = val % 100 * 2;
        *--p = digits[idx + 1];
        *--p = digits[idx];
        val /= 100;
    }
    if (val < 10) {
        *--p = '0' + val;
    } else {
        *--p = digits[val * 2 + 1];
        *--p = digits[val * 2];
    }
}

static inline void _qrintf_long_long_core(char *p, unsigned long long val)
{
    const char *digits = _qrintf_get_digit_table();
    while (val >= 100) {
        unsigned idx = val % 100 * 2;
        *--p = digits[idx + 1];
        *--p = digits[idx];
        val /= 100;
    }
    if (val < 10) {
        *--p = '0' + val;
    } else {
        *--p = digits[val * 2 + 1];
        *--p = digits[val * 2];
    }
}

static inline qrintf_nck_t _qrintf_nck_long_core(qrintf_nck_t ctx, int fill_ch, int width, unsigned long val, int sign)
{
    int len = _qrintf_ilog10ul(val);
    int wlen = len;
    if (fill_ch == ' ') {
        ctx = _qrintf_nck_fill(ctx, fill_ch, len + sign, width);
    }
    if (sign) {
        ctx.str[ctx.off++] = '-';
        width -= 1;
    }
    if (fill_ch == '0') {
        ctx = _qrintf_nck_fill(ctx, fill_ch, len, width);
    }

    _qrintf_long_core(ctx.str + ctx.off + wlen, val);
    ctx.off += len;
    return ctx;
}

static inline qrintf_nck_t _qrintf_nck_long_long_core(qrintf_nck_t ctx, int fill_ch, int width, unsigned long long val, int sign)
{
    int len = _qrintf_ilog10ull(val);
    int wlen = len;
    if (fill_ch == ' ') {
        ctx = _qrintf_nck_fill(ctx, fill_ch, len + sign, width);
    }
    if (sign) {
        ctx.str[ctx.off++] = '-';
        width -= 1;
    }
    if (fill_ch == '0') {
        ctx = _qrintf_nck_fill(ctx, fill_ch, len, width);
    }

    _qrintf_long_long_core(ctx.str + ctx.off + wlen, val);
    ctx.off += len;
    return ctx;
}

static inline qrintf_chk_t _qrintf_chk_long_core(qrintf_chk_t ctx, int fill_ch, int width, unsigned long val, int sign)
{
    int len = _qrintf_ilog10ul(val);
    int wlen = len;
    if (ctx.off + wlen + sign > ctx.size) {
        int n = ctx.off + wlen + sign - ctx.size;
        wlen -= n;
        while (n-- != 0) {
            val /= 10;
        }
    }
    if (fill_ch == ' ') {
        ctx = _qrintf_chk_fill(ctx, fill_ch, len + sign, width);
    }
    if (sign && ctx.off + 1 < ctx.size) {
        ctx.str[ctx.off++] = '-';
        width -= 1;
    }
    if (fill_ch == '0') {
        ctx = _qrintf_chk_fill(ctx, fill_ch, len, width);
    }

    _qrintf_long_core(ctx.str + ctx.off + wlen, val);
    ctx.off += len;
    return ctx;
}


static inline qrintf_chk_t _qrintf_chk_long_long_core(qrintf_chk_t ctx, int fill_ch, int width, unsigned long long val, int sign)
{
    int len = _qrintf_ilog10ull(val);
    int wlen = len;
    if (ctx.off + wlen + sign > ctx.size) {
        int n = ctx.off + wlen + sign - ctx.size;
        wlen -= n;
        while (n-- != 0) {
            val /= 10;
        }
    }
    if (fill_ch == ' ') {
        ctx = _qrintf_chk_fill(ctx, fill_ch, len + sign, width);
    }
    if (sign && ctx.off + 1 < ctx.size) {
        ctx.str[ctx.off++] = '-';
        width -= 1;
    }
    if (fill_ch == '0') {
        ctx = _qrintf_chk_fill(ctx, fill_ch, len, width);
    }

    _qrintf_long_long_core(ctx.str + ctx.off + wlen, val);
    ctx.off += len;
    return ctx;
}

? for my $check (qw(nck chk)) {
<?= $build_d->($check, "short", "hd") ?>
<?= $build_d->($check, "int", "d",) ?>
<?= $build_d->($check, "long", "ld") ?>
<?= $build_d->($check, "long long", "lld") ?>
<?= $build_u->($check, "unsigned short", "hu") ?>
<?= $build_u->($check, "unsigned", "u") ?>
<?= $build_u->($check, "unsigned long", "lu") ?>
<?= $build_u->($check, "unsigned long long", "llu") ?>
<?= $build_u->($check, "size_t", "zu") ?>
?   for my $with_width (0..1) {
<?= $build_x->($check, "unsigned short", "hx", $with_width) ?>
<?= $build_x->($check, "unsigned", "x", $with_width) ?>
<?= $build_x->($check, "unsigned long", "lx", $with_width) ?>
<?= $build_x->($check, "unsigned long long", "llx", $with_width) ?>
<?= $build_x->($check, "size_t", "zx", $with_width) ?>
?   }
? }

#ifdef __cplusplus
}
#endif

#endif
EOT
close $fh;
