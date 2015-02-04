# Test overloading of procs when used as function pointers

import strutils

proc parseInt(x: float): int {.noSideEffect.} = nil
proc parseInt(x: bool): int {.noSideEffect.} = nil
proc parseInt(x: float32): int {.noSideEffect.} = nil
proc parseInt(x: int8): int {.noSideEffect.} = nil
proc parseInt(x: TFile): int {.noSideEffect.} = nil
proc parseInt(x: char): int {.noSideEffect.} = nil
proc parseInt(x: int16): int {.noSideEffect.} = nil

proc parseInt[T](x: T): int = echo x; 34

type
  TParseInt = proc (x: string): int {.noSideEffect.}

var
  q = TParseInt(parseInt)
  p: TParseInt = parseInt

proc takeParseInt(x: proc (y: string): int {.noSideEffect.}): int =
  result = x("123")

echo "Give a list of numbers (separated by spaces): "
var x = stdin.readline.split.map(parseInt).max
echo x, " is the maximum!"
echo "another number: ", takeParseInt(parseInt)


type
  TFoo[a,b] = object
    lorem: a
    ipsum: b

proc bar[a,b](f: TFoo[a,b], x: a) = echo(x, " ", f.lorem, f.ipsum)
proc bar[a,b](f: TFoo[a,b], x: b) = echo(x, " ", f.lorem, f.ipsum)

discard parseInt[string]("yay")
