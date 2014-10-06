#! /usr/bin/perl

# Copyright (c) 2014 DeNA Co., Ltd.
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
? my ($check, $type, $suffix, $min, $max) = @_;
? if ($check eq 'nck') {
static inline char *_qrintf_<?= $suffix ?>_core(char *p, <?= $type ?> v)
{
    if (v < 0) {
        if (v == <?= $min ?>) {
            *--p = '1' + <?= $max ?> % 10;
            v = <?= $max ?> / 10;
        } else {
            v = -v;
        }
    }
    do {
        *--p = '0' + v % 10;
    } while ((v /= 10) != 0);
    return p;
}
? }
? my $push = $check eq 'chk' ? sub { "do { int ch = $_[0]; if (ctx.off < ctx.size) ctx.str[ctx.off] = ch; ++ctx.off; } while (0)" } : sub { "ctx.str[ctx.off++] = $_[0]" };

static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_<?= $suffix ?>(qrintf_<?= $check ?>_t ctx, <?= $type ?> v)
{
    char buf[sizeof(<?= $type ?>) * 3], *p;
    if (v < 0) {
        <?= $push->(q{'-'}) ?>;
    }
    p = _qrintf_<?= $suffix ?>_core(buf + sizeof(buf), v);
    do {
        <?= $push->(q{*p++}) ?>;
    } while (p != buf + sizeof(buf));
    return ctx;
}

static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_width_<?= $suffix ?>(qrintf_<?= $check ?>_t ctx, int fill_ch, int width, <?= $type ?> v)
{
    char buf[sizeof(<?= $type ?>) * 3 + 1], *p = _qrintf_<?= $suffix ?>_core(buf + sizeof(buf), v);
    int len;
    if (v < 0) {
        if (fill_ch == ' ') {
            *--p = '-';
        } else {
            <?= $push->(q{'-'}) ?>;
            --width;
        }
    }
    len = buf + sizeof(buf) - p;
    for (; len < width; --width) {
        <?= $push->(q{fill_ch}) ?>;
    }
    do {
        <?= $push->(q{*p++}) ?>;
    } while (p != buf + sizeof(buf));
    return ctx;
}
EOT
}

sub build_u {
    my ($check, $type, $suffix, $max, $with_width) = @_;
    return build_mt(template => << 'EOT', escape_func => undef)->($check, $type, $suffix, $max, $with_width ? '_width' : '');
? my ($check, $type, $suffix, $max, $width) = @_;
? my $push = $check eq 'chk' ? sub { "do { int ch = $_[0]; if (ctx.off < ctx.size) ctx.str[ctx.off] = ch; ++ctx.off; } while (0)" } : sub { "ctx.str[ctx.off++] = $_[0]" };
static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?><?= $width ?>_<?= $suffix ?>(qrintf_<?= $check ?>_t ctx<?= $width ? ", int fill_ch, int width" : "" ?>, <?= $type ?> v)
{
    char tmp[sizeof(<?= $type ?>) * 3], *p = tmp + sizeof(tmp);
    do {
        *--p = '0' + v % 10;
    } while ((v /= 10) != 0);
? if ($width) {
    {
        int len = tmp + sizeof(tmp) - p;
        for (; len < width; --width) {
            <?= $push->(q{fill_ch}) ?>;
        }
    }
? }
    do {
        <?= $push->(q{*p++}) ?>;
    } while (p != tmp + sizeof(tmp));
    return ctx;
}
EOT
}

sub build_x {
    my ($check, $type, $suffix, $with_width) = @_;
    return build_mt(template => << 'EOT', escape_func => undef)->($check, $type, $suffix, $with_width ? '_width' : '');
? my ($check, $type, $suffix, $width) = @_;
? my $push = $check eq 'chk' ? sub { "do { int ch = $_[0]; if (ctx.off < ctx.size) ctx.str[ctx.off] = ch; ++ctx.off; } while (0)" } : sub { "ctx.str[ctx.off++] = $_[0]" };
static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?><?= $width ?>_<?= $suffix ?>(qrintf_<?= $check ?>_t ctx<?= $width ? ", int fill_ch, int width" : "" ?>, <?= $type ?> v)
{
    int len;
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
    for (; len < width; --width) {
        <?= $push->(q{fill_ch}) ?>;
    }
? }
    len *= 4;
    do {
        len -= 4;
        <?= $push->(sprintf(q{(%s)[(v >> len) & 0xf]}, $suffix =~ /X$/ ? '"0123456789ABCDEF"' : '"0123456789abcdef"')) ?>;
    } while (len != 0);
    return ctx;
}
EOT
}

open my $fh, '>', 'share/qrintf/qrintf.h'
    or die "failed to open share/qrintf/qrintf.h:$!";

print $fh build_mt(template => << 'EOT', escape_func => undef)->(\&build_d, \&build_u, \&build_x)->as_string;
? my ($build_d, $build_u, $build_x) = @_;
/* DO NOT EDIT!  Automatically generated by misc/gen-printf.h.pl */
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
#undef snprintf
#define snprintf _qp_snprintf

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

? for my $check (qw(nck chk)) {
?   my $push = $check eq 'chk' ? sub { "do { int ch = $_[0]; if (ctx.off < ctx.size) ctx.str[ctx.off] = ch; ++ctx.off; } while (0)" } : sub { "ctx.str[ctx.off++] = $_[0]" };
static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_c(qrintf_<?= $check ?>_t ctx, int c)
{
    <?= $push->(q{c}) ?>;
    return ctx;
}

static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_width_c(qrintf_<?= $check ?>_t ctx, int fill_ch, int width, int c)
{
    for (; 1 < width; --width) {
        <?= $push->(q{fill_ch}) ?>;
    }
    <?= $push->(q{c}) ?>;
    return ctx;
}

static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_s(qrintf_<?= $check ?>_t ctx, const char *s)
{
    for (; *s != '\0'; ++s) {
        <?= $push->(q{*s}) ?>;
    }
    return ctx;
}

static inline qrintf_<?= $check ?>_t _qrintf_<?= $check ?>_width_s(qrintf_<?= $check ?>_t ctx, int fill_ch, int width, const char *s)
{
    int slen = strlen(s);
    for (; slen < width; --width) {
        <?= $push->(q{fill_ch}) ?>;
    }
    for (; slen != 0; --slen) {
        <?= $push->(q{*s++}) ?>;
    }
    return ctx;
}
? }

? for my $check (qw(nck chk)) {
<?= $build_d->($check, "short", "hd", "SHRT_MIN", "SHRT_MAX") ?>
<?= $build_d->($check, "int", "d", "INT_MIN", "INT_MAX") ?>
<?= $build_d->($check, "long", "ld", "LONG_MIN", "LONG_MAX") ?>
<?= $build_d->($check, "long long", "lld", "LLONG_MIN", "LLONG_MAX") ?>
?   for my $with_width (0..1) {
<?= $build_u->($check, "unsigned short", "hu", "USHRT_MAX", $with_width) ?>
<?= $build_u->($check, "unsigned", "u", "UINT_MAX", $with_width) ?>
<?= $build_u->($check, "unsigned long", "lu", "ULONG_MAX", $with_width) ?>
<?= $build_u->($check, "unsigned long long", "llu", "ULLONG_MAX", $with_width) ?>
<?= $build_u->($check, "size_t", "zu", "SIZE_MAX", $with_width) ?>
?   }
?   for my $suffix (qw(x X)) {
?     for my $with_width (0..1) {
<?= $build_x->($check, "unsigned short", "h$suffix", $with_width) ?>
<?= $build_x->($check, "unsigned", "$suffix", $with_width) ?>
<?= $build_x->($check, "unsigned long", "l$suffix", $with_width) ?>
<?= $build_x->($check, "unsigned long long", "ll$suffix", $with_width) ?>
<?= $build_x->($check, "size_t", "z$suffix", $with_width) ?>
?     }
?   }
? }

#ifdef __cplusplus
}
#endif

#endif
EOT
close $fh;
