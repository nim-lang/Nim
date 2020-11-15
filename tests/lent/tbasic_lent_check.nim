discard """
  targets: "c cpp"
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


#------------------------------------------------------------------------------
# issue #15958

block:
  proc byLent[T](a: T): lent T = a
  let a = [11,12]
  doAssert byLent(a) == [11,12]
  doAssert byLent(a).unsafeAddr == a.unsafeAddr

  proc byLent2[T](a: openarray[T]): lent T = a[0]
  doAssert byLent2(a) == 11
  doAssert byLent2(a).unsafeAddr == a[0].unsafeAddr

  proc byLent3[T](a: varargs[T]): lent T = a[1]
  let 
    x = 10
    y = 20
    z = 30
  doAssert byLent3(x, y, z) == 20

