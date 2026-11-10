discard """
  output: "ok"
"""

# types that refer to themselves behind a pointer, a seq, an Option-like
# variant or a base class are fine and must keep compiling (see #14646)

type
  Tree[T] = object
    item: T
    left, right: ref Tree[T]
  List[T] = object
    item: T
    rest: seq[List[T]]
  Ptr[T] = object
    next: ptr Ptr[T]
  Base[T] = object of RootObj
    x: T
  Derived[T] = object of Base[T]
    y: seq[Derived[T]]
  Arr[T] = object
    items: array[2, ref Arr[T]]

var a: Tree[int]
var b: List[string]
var c: Ptr[int]
var d: Derived[int]
var f: Arr[int]
a.item = 1
b.item = "x"
d.y.add Derived[int]()
doAssert a.item == 1 and b.item == "x" and c.next == nil and d.y.len == 1 and f.items[0] == nil
echo "ok"
