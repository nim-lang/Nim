discard """
action: compile
"""


template withOpenFile(f: untyped, filename: string, mode: FileMode,
                      actions: untyped): untyped =
  block:
    # test that 'f' is implicitly 'injecting':
    var f: File
    if open(f, filename, mode):
      try:
        actions
      finally:
        close(f)
    else:
      quit("cannot open for writing: " & filename)

withOpenFile(txt, "ttempl3.txt", fmWrite):
  writeLine(txt, "line 1")
  txt.writeLine("line 2")

var
  myVar: array[0..1, int]

# Test zero argument template:
template ha: untyped = myVar[0]

ha = 1
echo(ha)


# Test identifier generation:
template prefix(name): untyped = `"hu" name`

var `hu "XYZ"` = "yay"

echo prefix(XYZ)

template typedef(name: untyped, typ: typeDesc) {.dirty.} =
  type
    `T name`* = typ
    `P name`* = ref `T name`

typedef(myint, int)
var x: PMyInt


# Test UFCS

type
  Foo = object
    arg: int

proc initFoo(arg: int): Foo =
  result.arg = arg

template create(typ: typeDesc, arg: untyped): untyped = `init typ`(arg)

var ff = Foo.create(12)

echo ff.arg


import macros

# bug #11494
macro staticForEach(arr: untyped, body: untyped): untyped =
  result = newNimNode(nnkStmtList)
  arr.expectKind(nnkBracket)
  for n in arr:
    let b = copyNimTree(body)
    result.add quote do:
      block:
        type it {.inject.} = `n`
        `b`

template forEveryMatchingEntity*() =
  staticForEach([int, string, float]):
    var a {.inject.}: it
    echo a

forEveryMatchingEntity()
