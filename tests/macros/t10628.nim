discard """
  nimout: "x y"
"""

# bug #10628: `bindSym` in the value of a `{.compileTime.}` variable
import macros

type
  Input = object
    symbol: NimNode

proc input(symbol: NimNode): Input =
  Input(symbol: symbol)

let x = 1
let y = 2

let a {.compileTime.} = input(bindSym"x")
let b {.compileTime.} = input(bindSym"y")
static: echo a.symbol.repr, " ", b.symbol.repr
