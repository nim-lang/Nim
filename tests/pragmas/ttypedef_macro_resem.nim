discard """
  nimout: '''
got: default
got: abc
'''
"""

import std/macros

macro fooReorder(body: untyped, a: static string = "default"): untyped =
  echo "got: ", a
  result = body

macro foo(args: varargs[untyped]): untyped =
  var reordered = newNimNode(nnkCall, args)
  reordered.add bindSym"fooReorder"
  let last = args.len - 1
  reordered.add args[last]
  for i in 0 ..< last:
    reordered.add args[i]
  result = reordered

type
  Obj1 {.foo.} = object
    x: int
  Obj2 {.foo: "abc".} = object
    y: int

let x = Obj1(x: 123)
let y = Obj2(y: 456)
