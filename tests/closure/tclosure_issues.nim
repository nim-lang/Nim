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

  sp do ():
      var i = 0
      echo "ok ", i
      sp do ():
          inc i
          echo "ok ", i
          sp do ():
              inc i
              echo "ok ", i

block: # bug #25903
  iterator g: int {.closure.} =
    discard try:
        yield 0
        0
      except IOError, OSError:
        0
  let _ = g

block: # bug #25904
  iterator w: int {.closure.} =
    discard try: 0
      except IOError, OSError:
        yield 0
        0
  let _ = w

block: # bug #26337
  iterator raw(): int {.closure.} =
    try:
      yield 1
    except:
      discard
    yield 2

  let it = raw
  doAssert it() == 1
  doAssert it() == 2

block: # bug #25321
  var p1: proc() {.closure.}
  var p2: proc() {.closure.}
  var p3: proc() {.closure.}
  var seen: seq[string]

  proc makeClosure(): proc(i: int) =
    var arr = @[0, 0, 0]
    var p = proc(i: int) =
      if i == 0:
        p1 = proc() =
          arr[0] = 1
          seen.add $arr
      elif i == 1:
        p2 = proc() =
          arr[1] = 2
          seen.add $arr
        p3 = proc() =
          arr[2] = 3
          seen.add $arr
    return p

  var dostuff = makeClosure()
  dostuff(0) # define p1
  dostuff(1) # define p2, p3
  p1()
  p2()
  p3() # segfaulted if p3 is assigned in the 'elif' block
  doAssert seen == @["@[1, 0, 0]", "@[1, 2, 0]", "@[1, 2, 3]"]
