discard """
  targets: "c cpp js"
"""

proc fn1[T](a: openArray[T]): seq[T] =
  for ai in a: result.add ai

proc fn2[T](a: var openArray[T]): seq[T] =
  for ai in a: result.add ai

proc fn3[T](a: var openArray[T]) =
  for i, ai in mpairs(a): ai = i * 10

proc main =
  var a = [1,2,3,4,5]

  doAssert fn1(a.toOpenArray(1,3)) == @[2,3,4]

  doAssert fn2(toOpenArray(a, 1, 3)) == @[2,3,4]
  doAssert fn2(a.toOpenArray(1,3)) == @[2,3,4]

  fn3(a.toOpenArray(1,3))
  when defined(js): discard # xxx bug #15952: `a` left unchanged
  else: doAssert a == [1, 0, 10, 20, 5]

main()
# static: main() # xxx bug #15952: Error: cannot generate code for: mSlice
