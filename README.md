qrintf - sprintf accelerator
======

[![Build Status](https://travis-ci.org/kazuho/qrintf.svg?branch=master)](https://travis-ci.org/kazuho/qrintf)

The sprintf(3) family is a great set of functions for stringifying various kinds of data.
The drawback is that they are slow.
In certain applications, more than 10% of CPU time is consumed by the functions.
The reason why it is slow is because it parses the given format at run-time.

qrintf is a preprocessor (and a set of runtime functions) that precompiles invocations of sprintf (and snprintf) with constant format strings into specialized forms.

The benchmark below shows the power of qrintf; converting IPv4 address to string becomes 13x faster when the preprocessor is applied to the source code.

```
$ gcc -O2 examples/ipv4addr.c
$ time ./a.out 1234567890
result: 73.150.2.210

real	0m2.602s
user	0m2.598s
sys	0m0.003s
$ qrintf-gcc -O2 examples/ipv4addr.c
$ time ./a.out 1234567890
result: 73.150.2.210

real	0m0.196s
user	0m0.192s
sys	0m0.003s
```

INSTALL
---

```
make install PREFIX=/usr/local
```

COMMANDS
---

### qrintf-gcc

`qrintf-gcc` is the wrapper command for GCC.

It preprocesses the source files using GCC, applies `qrintf-pp`, and compiles the output using GCC.

The command accepts all options that are known by GCC (with the exception of `-no-intgrated-cpp` and `-wrapper`, which are used internally by the command).

### qrintf-pp

`qrintf-pp` is the filter program that rewrites invocations of `sprintf` to optimized forms.

The command reads a C source file from the standard input, applies the necessary transformations, and prints the result to standard output.

FAQ
---

__Q. Why did you develop qrintf?__

Because sprintf is the bottleneck in some of my applications.  I plan to use it in [H2O](https://github.com/kazuho/h2o), an optimized HTTP server/library implementation with support for HTTP/1.x, HTTP/2, websocket.

__Q. Which functions are optimized?__

`sprintf` and `snprintf`.

__Q. Is there a list of conversion specifiers that get optimized?__

- `%c`
- `%s`
- `%d` (modifiers: `h`, `l`, `ll`)
- `%u`,`%x`,`%X` (modifiers: `h`, `l`, `ll`, `z`)

Field widths (including `*`) and `0` flag (for zero padding) are also recognized.

note: Invocations of sprintf using other conversion specifiers are left as is.

__Q. How do I run the tests?__

```
make test
```

note: The test invokes `qrintf-gcc` which in turn invokes `gcc`.  So GCC should exist within the PATH.  `Clang-gcc` is not supported.

__Q. Shouldn't such feature be implemented in the compiler?__

Agreed.
