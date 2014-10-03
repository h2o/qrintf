qrintf - sprintf accelerator
======

sprintf(3) is a great function for stringifying various kinds of data.
The drawback is that it is slow.
In certain applications, more than 10% of CPU time is consumed by the function.
The reason why it is slow is because it parses the given format at run-time.

qrintf is a preprocessor (and a set of runtime functions) that precompiles invocations of sprintf with constant format strings into specialized forms.

The benchmark below shows the power of qrintf; converting IPv4 address to string becomes 13x faster when the preprocessor is applied to the source code.

```
$ gcc -O2 examples/ipv4addr.c
$ time ./a.out 1234567890
result: 73.150.2.210

real	0m2.602s
user	0m2.598s
sys	0m0.003s
$ ./qrintf-gcc -O2 examples/ipv4addr.c
$ time ./a.out 1234567890
result: 73.150.2.210

real	0m0.196s
user	0m0.192s
sys	0m0.003s
```

FAQ
---

__Q. How do I use it?__

Use `qrintf-gcc` in place of `gcc`.  `qrintf-gcc` is a wrapper of GCC that applies `qrintf-pp` (a filter that rewrites invocations of sprintf) during compilation.

__Q. Why did you develop qrintf?__

Because sprintf is the bottleneck in some of my applications.  I plan to use it in [H2O](https://github.com/kazuho/h2o), an optimized HTTP server/library implementation with support for HTTP/1.x, HTTP/2, websocket.

__Q. Is there a list of conversion specifiers that get optimized?__

- `%c`
- `%s`
- `%d` (modifiers: `h`, `l`, `ll`)
- `%u` (modifiers: `h`, `l`, `ll`, `z`)

note: Invocations of sprintf using other conversion specifiers are left as is.

__Q. What about snprintf?__

Patches are welcome.  sprintf has been the initial target simply because, in my case, stringification against preallocated buffer was among those that needed to be optimized.

__Q. How do I run the tests?__

```
./qrintf-gcc -D_QRINTF_COUNT_CALL=1 -Wall -g t/test.c && ./a.out
```

__Q. Shouldn't such feature be implemented in the compiler?__

Agreed.
