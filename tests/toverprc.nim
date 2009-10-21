# Test overloading of procs when used as function pointers

import strutils

proc parseInt(x: float): int = nil
proc parseInt(x: bool): int = nil
proc parseInt(x: float32): int = nil
proc parseInt(x: int8): int = nil
proc parseInt(x: TFile): int = nil
proc parseInt(x: char): int = nil
proc parseInt(x: int16): int = nil

type
  TParseInt = proc (x: string): int

var
  q = TParseInt(parseInt)
  p: TParseInt = parseInt

proc takeParseInt(x: proc (y: string): int): int = 
  result = x("123")
  
echo "Give a list of numbers (separated by spaces): "
var x = stdin.readline.split.each(parseInt).maxecho x, " is the maximum!"echo "another number: ", takeParseInt(parseInt)

