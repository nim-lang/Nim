discard """
  output: '''12
4'''
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


# bug #3736

proc p(x: seq[int]) = discard x[0].unsafeAddr # works
proc q(x: seq[SomeInteger]) = discard x[0].unsafeAddr # doesn't work

p(@[1])
q(@[1])

main()

# bug #9403

type
  MyObj = ref object
    len: int
    val: UncheckedArray[uint64]

proc spot(x: MyObj): int64 =
  result = cast[UncheckedArray[int64]](x.val)[0]

proc newMyObj(len: int): MyObj =
  unsafeNew(result, sizeof(result[]) + len * sizeof(uint64))
  result.len = len
  result.val[0] = 4u64
  result.val[1] = 8u64

echo spot(newMyObj(2))
