discard """
  output: '''1
foo
bar
baz
foo
bar
baz
yes
no'''
"""

# bug #1708
let foo = {
  "1" : (bar: @["1"]),
  "2" : (bar: @[])
}

# bug #871

when true:
  import os

  type
    In_out = tuple[src, dest: string, options: ref int]

  let
    nil_var: In_out = ("hey"/"there", "something", nil)
    #nil_var2 = ("hey"/"there", "something", nil)

# bug #1721
const foo2: seq[string] = @[]

echo foo[0][0][0]

proc takeEmpty(x: openArray[string] = []) = discard
takeEmpty()
takeEmpty([])

proc takeEmpty2(x: openArray[string] = @[]) = discard
takeEmpty2()
takeEmpty2([])
takeEmpty2(@[])

#takeEmpty2([nil])

#rawMessage(errExecutionOfProgramFailed, [])

# bug #2470
const
  stuff: seq[string] = @[]

for str in stuff:
  echo "str=", str

# bug #1354
proc foo4[T](more: seq[T] = @[]) =
  var more2 = more

foo4[int]()

proc maino: int =
  var wd: cstring = nil
  inc result

discard maino()

proc varargso(a: varargs[string]) =
  for x in a:
    echo x

varargso(["foo", "bar", "baz"])
varargso("foo", "bar", "baz")


type
  Flago = enum
    tfRequiresInit, tfNotNil

var s: set[Flago] = {tfRequiresInit}

if {tfRequiresInit, tfNotNil} * s != {}:
  echo "yes"
else:
  echo "no"

if {tfRequiresInit, tfNotNil} * s <= {tfNotNil}:
  echo "yes"
else:
  echo "no"
