test:
	./qrintf-gcc -D_QRINTF_COUNT_CALL=1 -Wall -g -Werror t/test.c -o ./test && ./test

.PHONY: test
