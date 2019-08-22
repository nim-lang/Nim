discard """
  output: '''17
17
17
17
17
17
'''
"""

# bug #1593

{.emit: """
#include <stdarg.h>
#include <stdio.h>

void foo(int n, ...) {
  NI64 k;
  int i;
  va_list argp;
  va_start(argp, n);
  for (i = 1; i <= n; i++) {
    k = va_arg(argp, NI64);
    printf("%lld\n", (long long)k);
  }
  va_end(argp);
}
""".}

proc foo(x: cint) {.importc, varargs, nodecl.}

proc main() =
  const k = 17'i64
  foo(6, k, k, k, k, k, k)
main()
