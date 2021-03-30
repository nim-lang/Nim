discard """
  targets: "c cpp js"
"""

proc main() =
  var x = 0

  block:
    proc foo(_, _: int) = x += 5

    foo(1, 2)
    doAssert x == 5

  block:
    proc foo(_: int, _: float) = x += 5

    foo(1, 2)
    doAssert x == 10

  block:
    proc foo(_: int, _: float, _: string) = x += 5

    foo(1, 2, "5")
    doAssert x == 15


static: main()
main()
