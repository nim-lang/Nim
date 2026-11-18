discard """
  output: "Hello\nTest passed: 11"
"""
import macros

var foo {.compileTime.} = 0

static:
  addCompileTimeExitProc() do() -> NimNode:
    let f = ident"foo"
    result = quote do:
      proc test() =
        echo "Test passed: ", static(foo)
      test()

static:
  foo = 10
  inc foo

echo "Hello"
