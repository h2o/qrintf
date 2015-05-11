qrintf - sprintf accelerator
======

[![Build Status](https://travis-ci.org/h2o/qrintf.svg?branch=master)](https://travis-ci.org/h2o/qrintf)

The sprintf(3) family is a great set of functions for stringifying various kinds of data.
The drawback is that they are slow.
In certain applications, more than 10% of CPU time is consumed by the functions.
The reason why it is slow is because it parses the given format at run-time.

qrintf is a preprocessor (and a set of runtime functions) that precompiles invocations of sprintf (and snprintf) with constant format strings into specialized forms.

The benchmark below shows the power of qrintf; converting IPv4 address to string becomes more than 10x faster when the preprocessor is applied to the source code.

```
$ gcc -O2 examples/ipv4addr.c
$ time ./a.out 1234567890
result: 73.150.2.210

real	0m2.514s
user	0m2.503s
sys	0m0.003s
$ qrintf gcc -O2 examples/ipv4addr.c
$ time ./a.out 1234567890
result: 73.150.2.210

real	0m0.175s
user	0m0.170s
sys	0m0.002s
```

INSTALL
---

```
make install PREFIX=/usr/local
```

COMMANDS
---

### qrintf

`qrintf` is the command that wraps the C compiler (GCC or clang).

It preprocesses the source files using the preprocessor (by calling the compiler with `-E` option), applies `qrintf-pp`, and then once again invokes the compiler to compile the processed file.

### qrintf-pp

`qrintf-pp` is the filter program that rewrites invocations of `sprintf` to optimized forms.

The command reads a C source file from the standard input, applies the necessary transformations, and prints the result to standard output.

FAQ
---

__Q. License?__

The software is provided under the MIT license.

__Q. Why did you develop qrintf?__

Because sprintf is the bottleneck in some of my applications.  I plan to use it in [H2O](https://github.com/h2o/h2o), an optimized HTTP server/library implementation with support for HTTP/1.x, HTTP/2, websocket.

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
make test CC=gcc
make test CC=clang
```

__Q. Shouldn't such feature be implemented in the compiler?__

Agreed.

__Q. Where can I find more information?__

Please refer to [the developer's weblog](http://blog.kazuhooku.com/search/label/qrintf).
