discard """
  output: '''12'''
"""

{.emit: """
long sum(long* a, long len) {
  long i, result = 0;
  for (i = 0; i < len; ++i) result += a[i];
  return result;
}
""".}

proc sum(a: ptr int; len: int): int {.importc, nodecl.}

proc main =
  let foo = [8, 3, 1]
  echo sum(unsafeAddr foo[0], foo.len)

main()
