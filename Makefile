PREFIX=/usr/local
TEST_CFLAGS=-D_QRINTF_COUNT_CALL=1 -Wall -g -Werror
AOUT=./test
ifeq (Windows_NT, $(OS))
AOUT=test.exe
endif

all:

gen:
	misc/gen-qrintf.h.pl

install:
	install -d $(PREFIX)/bin $(PREFIX)/include $(PREFIX)/share/qrintf
	install -m 755 bin/qrintf bin/qrintf-pp $(PREFIX)/bin
	install -m 644 include/qrintf.h $(PREFIX)/include
	install -m 755 share/qrintf/gcc-wrapper $(PREFIX)/share/qrintf

test: test-cc test-cxx

test-cc:
	perl bin/qrintf $(CC)  $(TEST_CFLAGS) t/test.c deps/picotest/picotest.c -o $(AOUT) && $(AOUT)

test-cxx:
	perl bin/qrintf $(CXX) -x c++ $(TEST_CFLAGS) t/test.c deps/picotest/picotest.c -o $(AOUT) && $(AOUT)

.PHONY: gen install test test-cc test-cxx
