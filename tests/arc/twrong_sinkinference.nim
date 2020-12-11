discard """
  cmd: "nim c --gc:arc $file"
  errormsg: "type mismatch: got <proc (a: string, b: sink string){.noSideEffect, gcsafe, locks: 0.}>"
  line: 18
"""

type
  Foo = proc (a, b: string)

proc take(x: Foo) =
  x("a", "b")

proc willSink(a, b: string) = # {.nosinks.} =
  var arr: array[3, string]
  var x = a
  arr[0] = b

take willSink
