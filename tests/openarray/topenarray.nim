discard """
  targets: "c cpp js"
"""

proc fn1[T](a: openArray[T]): seq[T] =
  for ai in a: result.add ai

proc fn2[T](a: var openArray[T]): seq[T] =
  for ai in a: result.add ai

proc fn3[T](a: var openArray[T]) =
  for i, ai in mpairs(a): ai = i * 10

proc bug20865 =  # bug #20985
  var ok = false
  try:
    var x: array[0, int]
    var p: pointer = addr x
    echo toOpenArray(cast[ptr array[0, int]](p)[], 0, 1)[0]
  except IndexDefect:
    ok = true
  doAssert ok, "bug 20865"

proc bug20987 = # bug #20987
  var ok = false
  try:
    var v: array[1, byte]
    var p = cast[ptr array[0, byte]](addr v)
    echo toOpenArray(p[], 1, 2)
  except IndexDefect:
    ok = true
  doAssert ok, "bug 20987"

when not defined(js):
  bug20865()
  bug20987()

proc main =
  var a = [1,2,3,4,5]

  doAssert fn1(a.toOpenArray(1,3)) == @[2,3,4]

  doAssert fn2(toOpenArray(a, 1, 3)) == @[2,3,4]
  doAssert fn2(a.toOpenArray(1,3)) == @[2,3,4]

  fn3(a.toOpenArray(1,3))
  when defined(js): discard # xxx bug #15952: `a` left unchanged
  else: doAssert a == [1, 0, 10, 20, 5]

  block: # bug #12521
    block:
      type slice[T] = openArray[T]

      # Proc using that alias
      proc testing(sl: slice[int]): seq[int] =
        for item in sl:
          result.add item

      let mySeq = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
      doAssert testing(mySeq) == mySeq
      doAssert testing(mySeq[2..^2]) == mySeq[2..^2]

    block:
      type slice = openArray[int]

      # Proc using that alias
      proc testing(sl: slice): seq[int] =
        for item in sl:
          result.add item

      let mySeq = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
      doAssert testing(mySeq) == mySeq
      doAssert testing(mySeq[2..^2]) == mySeq[2..^2]


main()
static: main()
