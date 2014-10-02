#include <stdio.h>
#include "qrintf.h"

int main(int argc, char **argv)
{
  char buf[sizeof("255.255.255.255")];
  int i;
  unsigned addr;

  if (sscanf(argv[1], "%u", &addr) != 1) {
    fprintf(stderr, "usage: %s <addr-as-number>\n", argv[0]);
    return 1;
  }

  for (i = 0; i != 10000000; ++i) {
    sprintf(buf, "%d.%d.%d.%d", (addr >> 24) & 0xff, (addr >> 16) & 0xff, (addr >> 8) & 0xff, addr & 0xff);
  }

  printf("result: %s\n", buf);

  return 0;
}
