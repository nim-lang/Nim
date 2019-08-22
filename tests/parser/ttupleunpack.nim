proc returnsTuple(): (int, int, int) = (4, 2, 3)

proc main2 =
  let (x, _, z) = returnsTuple()

proc main() =

  proc foo(): tuple[x, y, z: int] =
    return (4, 2, 3)

  var (x, _, y) = foo()
  doAssert x == 4
  doAssert y == 3

  var (a, _, _) = foo()
  doAssert a == 4

  var (aa, _, _) = foo()
  doAssert aa == 4

  iterator bar(): tuple[x, y, z: int] =
    yield (1,2,3)

  for x, y, _ in bar():
    doAssert x == 1
    doAssert y == 2

main()
main2()
