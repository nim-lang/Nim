discard """
  output: '''true
(999, 0)
ok 0
ok 1
ok 2
'''
"""


block tissue600:
  for i in 1..1:
    var reported = false
    proc report() =
      reported = true



import sequtils
block tissue1502def:
  let xs: seq[tuple[key: string, val: seq[string]]] = @[("foo", @["bar"])]

  let maps = xs.map(
    proc(x: auto): tuple[typ: string, maps: seq[string]] =
      (x.key, x.val.map(proc(x: string): string = x)))



block tissue1642:
  var i = 0
  proc p() = inc(i)



block tissue1846:
  type
    TBinOp[T] = proc (x,y: T): bool
    THeap[T] = object
      cmp: TBinOp[T]

  proc less[T](x,y: T): bool =
    x < y

  proc initHeap[T](cmp: TBinOp[T]): THeap[T] =
    result.cmp = cmp

  var h = initHeap[int](less[int])
  echo h.cmp(2,3)



block tissue1911:
  proc foo(x: int) : auto =

    proc helper() : int = x
    proc bar() : int = helper()
    proc baz() : int = helper()

    return (bar, baz)

# bug #11523
proc foo(): proc =
  let a = 999
  return proc(): (int, int) =
    return (a, 0)

echo foo()()


block tissue7104:
  proc sp(cb: proc())=
      cb()

  sp:
      var i = 0
      echo "ok ", i
      sp():
          inc i
          echo "ok ", i
          sp do:
              inc i
              echo "ok ", i
