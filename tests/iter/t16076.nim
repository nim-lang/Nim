discard """
  targets: "c js"
  nimout: '''
0
10
'''
  output: '''
0
10
'''
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
      for i in t(nil):
        echo i

    m()


  block: # bug #16076
    type
      R = ref object
        z: int

    iterator foo(x: int; y: R = nil): int {.inline.} =
      if y == nil:
        yield x
      else:
        yield y.z

    for b in foo(10):
      echo b

static: main()
main()
