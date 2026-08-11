discard """
  valgrind: true
  cmd: "nim c -d:useMalloc $file"
  matrix: "--mm:arc; --mm:orc"
  disabled: "freebsd"
  disabled: "osx"
  disabled: "openbsd"
  disabled: "windows"
  disabled: "32bit"
"""

import std/options

type Foo = object
  id: string
  items: seq[string]

proc build(x: int): Foo =
  result = Foo(id: "padding-padding", items: @["a", "b", "c"])
  if x < 0:
    raise newException(ValueError, "boom")

proc parseResult(x: int): Foo =
  try:
    result = build(x)
  except CatchableError:
    result = default(Foo)

proc parseVar(x: int; dst: var Foo): bool =
  dst = build(x)
  result = true

proc parseOption(x: int): Option[Foo] =
  result = some(build(x))

const iterations = 10_000

for _ in 0 ..< iterations:
  discard parseResult(-1)

for _ in 0 ..< iterations:
  var dst: Foo
  try:
    discard parseVar(-1, dst)
  except CatchableError:
    discard

for _ in 0 ..< iterations:
  try:
    discard parseOption(-1)
  except CatchableError:
    discard
