discard """
  file: "tunsafeaddr.nim"
  output: '''12'''
"""

{.emit: """
NI sum(NI* a, NI len) {
  NI i, result = 0;
  for (i = 0; i < len; ++i) result += a[i];
  return result;
}
""".}

proc sum(a: ptr int; len: int): int {.importc, nodecl.}

proc main =
  let foo = [8, 3, 1]
  echo sum(unsafeAddr foo[0], foo.len)

main()
