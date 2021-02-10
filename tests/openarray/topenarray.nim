discard """
  targets: "c cpp js"
"""

proc pro[T](a: var openArray[T]) = discard

proc main =
  var a = [1,2,3,4,5]

  pro(toOpenArray(a, 1, 3))
  pro(a.toOpenArray(1,3))

main()
