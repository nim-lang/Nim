discard """
  output: "7"
"""

# bug #2023

type
    Obj = object
        iter: iterator (): int8 {.closure.}

iterator test(): int8 {.closure.} =
    yield 7

proc init():Obj=
    result.iter = test

var o = init()
echo(o.iter())
