qrintf - compile-time specialization of sprintf
======

sprintf(3) is a great function for stringifying various kinds of data.
The drawback is that it is slow.
In certain applications, more than 10% of CPU time is consumed by the function.
The reason why it is slow is because it parses the given format at run-time.

qprinf is a preprocessor (and a set of runtime functions) that precompiles invocations of sprintf with constant format strings into specialized forms.

The benchmark below shows the power of qprintf; converting IPv4 address to string becomes 8x faster when the preprocessor is applied to the source code.

```
$ gcc -I lib -O2 examples/ipv4addr.c
$ time ./a.out 1234567890
result: 73.150.2.210

real	0m2.602s
user	0m2.598s
sys	0m0.003s
$ ./qrintf-pp < examples/ipv4addr.c | gcc -Wno-unused-value -x c -O2 -I lib lib/libqrintf.c -
$ time ./a.out 1234567890
result: 73.150.2.210

real	0m0.319s
user	0m0.317s
sys	0m0.002s
```

Note: qprintf is going to be used in [H2O](https://github.com/kazuho/h2o), an optimized HTTP server/library implementation with support for HTTP/1.x, HTTP/2, websocket.
