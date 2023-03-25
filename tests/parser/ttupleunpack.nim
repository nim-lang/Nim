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

block: # nested unpacking
  block: # simple let
    let (a, (b, c), d) = (1, (2, 3), 4)
    doAssert (a, b, c, d) == (1, 2, 3, 4)
    let foo = (a, (b, c), d)
    let (a2, (b2, c2), d2) = foo
    doAssert (a, b, c, d) == (a2, b2, c2, d2)

  block: # var and assignment
    var (x, (y, z), t) = ('a', (true, @[123]), "abc")
    doAssert (x, y, z, t) == ('a', true, @[123], "abc")
    (x, (y, z), t) = ('b', (false, @[456]), "def")
    doAssert (x, y, z, t) == ('b', false, @[456], "def")

  block: # very nested
    let (_, (_, (_, (_, (_, a))))) = (1, (2, (3, (4, (5, 6)))))
    doAssert a == 6

  block: # const
    const (a, (b, c), d) = (1, (2, 3), 4)
    doAssert (a, b, c, d) == (1, 2, 3, 4)
    const foo = (a, (b, c), d)
    const (a2, (b2, c2), d2) = foo
    doAssert (a, b, c, d) == (a2, b2, c2, d2)
  
  block: # evaluation semantics preserved between literal and not literal
    var s: seq[string]
    block: # literal
      let (a, (b, c), d) = ((s.add("a"); 1), ((s.add("b"); 2), (s.add("c"); 3)), (s.add("d"); 4))
      doAssert (a, b, c, d) == (1, 2, 3, 4)
      doAssert s == @["a", "b", "c", "d"]
    block: # underscore
      s = @[]
      let (a, (_, c), _) = ((s.add("a"); 1), ((s.add("b"); 2), (s.add("c"); 3)), (s.add("d"); 4))
      doAssert (a, c) == (1, 3)
      doAssert s == @["a", "b", "c", "d"]
    block: # temp
      s = @[]
      let foo = ((s.add("a"); 1), ((s.add("b"); 2), (s.add("c"); 3)), (s.add("d"); 4))
      let (a, (b, c), d) = foo
      doAssert (a, b, c, d) == (1, 2, 3, 4)
      doAssert s == @["a", "b", "c", "d"]

block: # unary assignment unpacking
  var a: int
  (a,) = (1,)
  doAssert a == 1
