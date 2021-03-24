discard """
  targets: "c js"
"""

proc main() =
  block: # bug #17485
    type
      O = ref object
        i: int

    iterator t(o: O): int =
      if o != nil:
        yield o.i
      yield 0

    proc m =
      var data = ""
      for i in t(nil):
        data.addInt i

      doAssert data == "0"

    m()


  block: # bug #16076
    type
      R = ref object
        z: int

    var data = ""

    iterator foo(x: int; y: R = nil): int {.inline.} =
      if y == nil:
        yield x
      else:
        yield y.z

    for b in foo(10):
      data.addInt b

    doAssert data == "10"

static: main()
main()
