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
  when defined(js):
    proc sameAddress[T](a, b: T): bool {.importjs: "(# === #)".}
  else:
    template sameAddress(a, b): bool = a.unsafeAddr == b.unsafeAddr
  proc byLent[T](a: T): lent T = a
  let a = [11,12]
  let b = @[21,23]
  let ss = {1, 2, 3, 5}
  doAssert byLent(a) == [11,12]
  doAssert sameAddress(byLent(a), a)
  doAssert byLent(b) == @[21,23]
  # bug #16073
  doAssert sameAddress(byLent(b), b)
  doAssert byLent(ss) == {1, 2, 3, 5}
  doAssert sameAddress(byLent(ss), ss)

  let r = new(float)
  r[] = 10.0
  # bug #16073
  doAssert byLent(r)[] == 10.0

  when not defined(js): # pending bug https://github.com/timotheecour/Nim/issues/372
    let p = create(float)
    p[] = 20.0
    doAssert byLent(p)[] == 20.0

  proc byLent2[T](a: openArray[T]): lent T = a[0]
  doAssert byLent2(a) == 11
  doAssert sameAddress(byLent2(a), a[0])
  doAssert byLent2(b) == 21
  doAssert sameAddress(byLent2(b), b[0])

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
