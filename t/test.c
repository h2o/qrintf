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

#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "../deps/picotest/picotest.h"

static void test_simple(void);
static void test_composite(void);

#define PICOTEST_FUNCS test_simple,test_composite
#include "../deps/picotest/picotest.c"

static int (*orig)(char *str, const char *fmt, ...) = sprintf;

#define CHECK(...) \
    do { \
        char pbuf[256], qbuf[256]; \
        int plen, qlen; \
        plen = orig(pbuf, __VA_ARGS__); \
        qlen = sprintf(qbuf, __VA_ARGS__); \
        ok(plen == qlen); \
        ok(strcmp(pbuf, qbuf) == 0); \
    } while (0)

void test_simple()
{
    CHECK("%c", 'Z');
    CHECK("%s", "abc");

#define CHECK_MULTI(type, conv, min, max) \
    CHECK(conv, (type)0); \
    CHECK(conv, (type)12345); \
    CHECK(conv, (type)-12345); \
    CHECK(conv, (type)min); \
    CHECK(conv, (type)max);

    CHECK_MULTI(short, "%hd", SHRT_MIN, SHRT_MAX);
    CHECK_MULTI(int, "%d", INT_MIN, INT_MAX);
    CHECK_MULTI(long, "%ld", LONG_MIN, LONG_MAX);
    CHECK_MULTI(long long, "%lld", LLONG_MIN, LLONG_MAX);

    CHECK_MULTI(short, "%hi", SHRT_MIN, SHRT_MAX);
    CHECK_MULTI(int, "%i", INT_MIN, INT_MAX);
    CHECK_MULTI(long, "%li", LONG_MIN, LONG_MAX);
    CHECK_MULTI(long long, "%lli", LLONG_MIN, LLONG_MAX);

    CHECK_MULTI(unsigned short, "%hu", 0, USHRT_MAX);
    CHECK_MULTI(unsigned , "%u", 0, UINT_MAX);
    CHECK_MULTI(unsigned long, "%lu", 0, ULONG_MAX);
    CHECK_MULTI(unsigned long long, "%llu", 0, ULLONG_MAX);
    CHECK_MULTI(size_t, "%zu", 0, SIZE_MAX);

    CHECK_MULTI(unsigned short, "%hx", 0, USHRT_MAX);
    CHECK_MULTI(unsigned , "%x", 0, UINT_MAX);
    CHECK_MULTI(unsigned long, "%lx", 0, ULONG_MAX);
    CHECK_MULTI(unsigned long long, "%llx", 0, ULLONG_MAX);
    CHECK_MULTI(size_t, "%zx", 0, SIZE_MAX);

    CHECK_MULTI(unsigned short, "%hX", 0, USHRT_MAX);
    CHECK_MULTI(unsigned , "%X", 0, UINT_MAX);
    CHECK_MULTI(unsigned long, "%lX", 0, ULONG_MAX);
    CHECK_MULTI(unsigned long long, "%llX", 0, ULLONG_MAX);
    CHECK_MULTI(size_t, "%zX", 0, SIZE_MAX);
}

void test_composite()
{
    CHECK("HTTP/1.1 %d %s", 200, "OK");
}
