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

#include <assert.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "../deps/picotest/picotest.h"

#if defined(__cplusplus) && !defined(SIZE_MAX)
#include <limits>
# define SIZE_MAX (std::numeric_limits<std::size_t>::max())
#endif

static int (*orig)(char *str, const char *fmt, ...) = sprintf;
static int (*orign)(char *str, size_t n, const char *fmt, ...) = snprintf;

#if _QRINTF_COUNT_CALL
size_t _qrintf_call_cnt;
# define RESET_CALL_COUNT _qrintf_call_cnt = 0
# define CHECK_CALL_COUNT assert(_qrintf_call_cnt == 1)
#else
# define RESET_CALL_COUNT
# define CHECK_CALL_COUNT
#endif

#define _CHECK(size, fcall, ocall) \
    do { \
        char pbuf[size], qbuf[size]; \
        int plen, qlen; \
        RESET_CALL_COUNT; \
        plen = ocall; \
        qlen = fcall; \
        CHECK_CALL_COUNT; \
        ok(plen == qlen); \
        ok(strcmp(pbuf, qbuf) == 0); \
        if (plen != qlen || strcmp(pbuf, qbuf) != 0) \
            printf("# expected: \"%s\", got: \"%s\"\n", pbuf, qbuf); \
    } while (0)
#define CHECK_SPRINTF(size, ...) _CHECK(size, sprintf(qbuf, __VA_ARGS__), orig(pbuf, __VA_ARGS__))
#define CHECK_SNPRINTF(size, ...) _CHECK(size, snprintf(qbuf, sizeof(qbuf), __VA_ARGS__), orign(pbuf, sizeof(pbuf), __VA_ARGS__))
#define CHECK(...) \
    do { \
        CHECK_SPRINTF(256, __VA_ARGS__); \
        CHECK_SNPRINTF(256, __VA_ARGS__); \
    } while (0)

static void test_simple(void)
{
    CHECK("%c", 'Z');
    CHECK("%3c", 'Z');
    CHECK("%s", "abc");
    CHECK("%3s", "a");
    CHECK("%3s", "abc");
    CHECK("%3s", "abcde");
    CHECK("%03s", "abc");
    CHECK("%03s", "abcde");
    CHECK("%*s", (size_t)3, "ab");
    CHECK("%*s", (size_t)3, "abc");
    CHECK("%*s", (size_t)3, "abcd");
    CHECK("%.*s", 3, "ab");
    CHECK("%.*s", 3, "abc");
    CHECK("%.*s", 3, "abcd");
    CHECK("%x_", 1);
    CHECK("%d%%", 10);
    CHECK("%%%d", 10);
    CHECK("%%d%d", 10);

    CHECK("%s%s", "a,b", "c");
    CHECK("%s%d", "hi" /*hmm */, // test
        3);
    CHECK("%s%d", "a\",b", 123);

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
#ifndef _WIN32
    CHECK_MULTI(size_t, "%zu", 0, SIZE_MAX);
#endif

    CHECK_MULTI(unsigned short, "%hx", 0, USHRT_MAX);
    CHECK_MULTI(unsigned , "%x", 0, UINT_MAX);
    CHECK_MULTI(unsigned long, "%lx", 0, ULONG_MAX);
    CHECK_MULTI(unsigned long long, "%llx", 0, ULLONG_MAX);
#ifndef _WIN32
    CHECK_MULTI(size_t, "%zx", 0, SIZE_MAX);
#endif

    CHECK_MULTI(unsigned short, "%hX", 0, USHRT_MAX);
    CHECK_MULTI(unsigned , "%X", 0, UINT_MAX);
    CHECK_MULTI(unsigned long, "%lX", 0, ULONG_MAX);
    CHECK_MULTI(unsigned long long, "%llX", 0, ULLONG_MAX);
#ifndef _WIN32
    CHECK_MULTI(size_t, "%zX", 0, SIZE_MAX);
#endif

    CHECK_MULTI(int, "%7d", INT_MIN, INT_MAX);
    CHECK_MULTI(int, "%07d", INT_MIN, INT_MAX);
    CHECK_MULTI(unsigned, "%7u", 0, UINT_MAX);
    CHECK_MULTI(unsigned, "%07u", 0, UINT_MAX);
    CHECK_MULTI(unsigned, "%7x", 0, UINT_MAX);
    CHECK_MULTI(unsigned, "%07x", 0, UINT_MAX);

#ifndef _WIN32
    CHECK_SNPRINTF(8, "%s", "abcdef"); /* below the bounds */
    CHECK_SNPRINTF(8, "1234%s", "abcdef"); /* partial write */
    CHECK_SNPRINTF(8, "1234567890%s", "abcdef"); /* no write */

    CHECK_SNPRINTF(3, "%d", 12345);
    CHECK_SNPRINTF(10, "%u.%u.%u.%u", 12, 34, 56, 78);
    CHECK_SNPRINTF(3, "%x", 0xffff);

    CHECK_SNPRINTF(3, "%hx",  USHRT_MAX);
    CHECK_SNPRINTF(3, "%x",   UINT_MAX);
    CHECK_SNPRINTF(3, "%lx",  ULONG_MAX);
    CHECK_SNPRINTF(3, "%llx", ULLONG_MAX);
#endif
}

static void test_composite(void)
{
    CHECK("HTTP/1.1 %d %s", 200, "OK");
}

static void test_issue18(void)
{
    CHECK("%s", (1 ? "," : ""));
}

static void test_issues(void)
{
    subtest("issues/18", test_issue18);
}

int main(int argc, char **argv)
{
    subtest("simple", test_simple);
    subtest("composite", test_composite);
    subtest("issues", test_issues);
    return done_testing();
}
