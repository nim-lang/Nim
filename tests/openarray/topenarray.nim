discard """
  targets: "c cpp js"
"""

proc fn1[T](a: openArray[T]): seq[T] =
  for ai in a: result.add ai

proc fn2[T](a: var openArray[T]): seq[T] =
  for ai in a: result.add ai

proc fn3[T](a: var openArray[T]) =
  for i, ai in mpairs(a): ai = i * 10

proc wr[T](a: var openArray[T]; v: T) =
  a[0] = v

proc main =
  var a = [1,2,3,4,5]

  doAssert fn1(a.toOpenArray(1,3)) == @[2,3,4]

  doAssert fn2(toOpenArray(a, 1, 3)) == @[2,3,4]
  doAssert fn2(a.toOpenArray(1,3)) == @[2,3,4]

  fn3(a.toOpenArray(1,3))
  doAssert a == [1, 0, 10, 20, 5]

  block: # bug #15952: `toOpenArray` slices are live views on JS
    # Fixed homogeneous numeric arrays lower to JS typed arrays; seqs and
    # non-numeric fixed arrays lower to plain JS arrays. In all cases a slice
    # passed to a `var openArray` must alias the source so writes propagate
    # (JS: subarray view for typed arrays, {base,off,len} view otherwise).
    var si = @[1, 2, 3, 4, 5]
    fn3(si.toOpenArray(1, 3))
    doAssert si == @[1, 0, 10, 20, 5]
    var ss = ["a", "b", "c", "d", "e"]
    wr(ss.toOpenArray(1, 3), "Z")
    doAssert ss == ["a", "Z", "c", "d", "e"]
    # read-only slicing must still work and never throw, on every backend.
    doAssert fn1(@[1, 2, 3, 4, 5].toOpenArray(1, 3)) == @[2, 3, 4]
    doAssert fn1(["a", "b", "c", "d", "e"].toOpenArray(1, 3)) == @["b", "c", "d"]

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

  block: # bug #23321
    block:
      proc foo(x: openArray[int]) =
        doAssert x[0] == 0

      var d = new array[1, int]
      foo d[].toOpenArray(0, 0)

    block:
      proc foo(x: openArray[int]) =
        doAssert x[0] == 0

      proc task(x: var array[1, int]): var array[1, int] =
        result = x
      var d: array[1, int]
      foo task(d).toOpenArray(0, 0)

    block:
      proc foo(x: openArray[int]) =
        doAssert x[0] == 0

      proc task(x: var array[1, int]): lent array[1, int] =
        result = x
      var d: array[1, int]
      foo task(d).toOpenArray(0, 0)

    block:
      proc foo(x: openArray[int]) =
        doAssert x[0] == 0

      proc task(x: var array[1, int]): ptr array[1, int] =
        result = addr x
      var d: array[1, int]
      foo task(d)[].toOpenArray(0, 0)


main()
static: main()
