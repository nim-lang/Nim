import macros

block t9043: # bug #9043
  proc foo[N: static[int]](dims: array[N, int]): string =
    const N1 = N
    const N2 = dims.len
    const ret = $(N, dims.len, N1, N2)
    static: doAssert ret == $(N, dims.len, N1, N2)
    ret

  doAssert foo([1, 2]) == "(2, 2, 2, 2)"

block t4952:
  proc doCheck(tree: NimNode) =
    let res: tuple[n: NimNode] = (n: tree)
    assert: tree.kind == res.n.kind
    for sub in tree:
      doCheck(sub)

  macro id(body: untyped): untyped =
    doCheck(body)

  id(foo((i: int)))

  static:
    let tree = newTree(nnkExprColonExpr)
    let t = (n: tree)
    doAssert: t.n.kind == tree.kind


# bug #19909
type
  SinglyLinkedList[T] = ref object
  SinglyLinkedListObj[T] = ref object


proc addMoved[T](a, b: var SinglyLinkedList[T]) =
  if a.addr != b.addr: discard

proc addMoved[T](a, b: var SinglyLinkedListObj[T]) =
  if a.addr != b.addr: discard

proc main =
  var a: SinglyLinkedList[int]; new a
  var b: SinglyLinkedList[int]; new b
  a.addMoved b

  var a0: SinglyLinkedListObj[int]
  var b0: SinglyLinkedListObj[int]
  a0.addMoved b0

static: main()


# bug #18641

type A = object
  ha1: int
static:
  var a = A()
  var a2 = a.addr
  a2.ha1 = 11
  doAssert a2.ha1 == 11
  a.ha1 = 12
  doAssert a.ha1 == 12
  doAssert a2.ha1 == 12 # ok
static:
  proc fn() =
    var a = A()
    var a2 = a.addr
    a2.ha1 = 11
    doAssert a2.ha1 == 11
    a.ha1 = 12
    doAssert a.ha1 == 12
    doAssert a2.ha1 == 12 # fails
  fn()
