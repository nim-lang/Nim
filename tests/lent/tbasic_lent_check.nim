discard """
  targets: "c cpp js"
  output: "1"
"""

proc viewInto(a: array[4, string]): lent string =
  result = a[0]

proc passToVar(x: var string) =
  discard

proc main =
  let x = ["1", "2", "3", "4"]
  echo viewInto(x)
  doAssert(not compiles(passToVar(viewInto(x))))

main()

template main2 = # bug #15958
  proc byLent[T](a: T): lent T = a
  let a = [11,12]
  let b = @[21,23]
  let ss = {1, 2, 3, 5}
  doAssert byLent(a) == [11,12]
  doAssert byLent(a).unsafeAddr == a.unsafeAddr
  doAssert byLent(b) == @[21,23]
  when not defined(js): # pending bug #16073
    doAssert byLent(b).unsafeAddr == b.unsafeAddr
  doAssert byLent(ss) == {1, 2, 3, 5}
  doAssert byLent(ss).unsafeAddr == ss.unsafeAddr

  let r = new(float)
  r[] = 10.0
  when not defined(js): # pending bug #16073
    doAssert byLent(r)[] == 10.0

  when not defined(js): # pending bug https://github.com/timotheecour/Nim/issues/372
    let p = create(float)
    p[] = 20.0
    doAssert byLent(p)[] == 20.0

  proc byLent2[T](a: openarray[T]): lent T = a[0]
  doAssert byLent2(a) == 11
  doAssert byLent2(a).unsafeAddr == a[0].unsafeAddr
  doAssert byLent2(b) == 21
  doAssert byLent2(b).unsafeAddr == b[0].unsafeAddr

  proc byLent3[T](a: varargs[T]): lent T = a[1]
  let 
    x = 10
    y = 20
    z = 30
  doAssert byLent3(x, y, z) == 20

main2()
when false:
  # bug: Error: unhandled exception: 'node' is not accessible using discriminant 'kind' of type 'TFullReg' [FieldDefect]
  static: main2()
