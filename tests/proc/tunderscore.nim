discard """
  targets: "c cpp js"
"""

block:
  proc ok(_, _: int) = discard
  ok(4, 2)

block:
  proc ok(_, _: int) = discard
  ok(4, 2)

block:
  proc ok(_: int, _: float) = discard
  ok(1, 2.0)

block:
  proc ok(_: int, _: float, _: string) = discard
  ok(1, 2.6, "5")

proc main() =
  when defined(js):
    when nimvm:
      return
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
