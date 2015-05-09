PREFIX=/usr/local

all:

gen:
	misc/gen-qrintf.h.pl

install:
	install -d $(PREFIX)/bin $(PREFIX)/share/qrintf
	install -m 755 bin/qrintf bin/qrintf-pp $(PREFIX)/bin
	install -m 644 share/qrintf/qrintf.h $(PREFIX)/share/qrintf

test:
	bin/qrintf $(CC) -D_QRINTF_COUNT_CALL=1 -Wall -g -Werror t/test.c -o ./test && ./test

.PHONY: gen install test
