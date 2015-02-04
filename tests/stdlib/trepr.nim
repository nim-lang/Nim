discard """
  file: "trepr.nim"
  output: "{a, b}{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}"
"""

type
  TEnum = enum
    a, b

var val = {a, b}
stdout.write(repr(val))
stdout.writeln(repr({'a'..'z', 'A'..'Z'}))

type
  TObj {.pure, inheritable.} = object
    data: int
  TFoo = ref object of TObj
    d2: float
var foo: TFoo
new(foo)

when false:
  # cannot capture this output as it contains a memory address :-/
  echo foo.repr
#var testseq: seq[string] = @[
#  "a", "b", "c", "d", "e"
#]
#echo(repr(testseq))

