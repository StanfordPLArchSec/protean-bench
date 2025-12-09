#include <stdlib.h>
#include <stdio.h>

int fib(int n) {
  if (n < 2) {
    return n;
  } else {
    return fib(n - 1) + fib(n - 2);
  }
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    fprintf(stderr, "usage: %s n\n", argv[0]);
    return EXIT_FAILURE;
  }
  const int n = atoi(argv[1]);
  const int result = fib(n);
  printf("%d\n", result);
}
