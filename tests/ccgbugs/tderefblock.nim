discard """
  matrix: "--mm:refc -d:release -d:danger;--mm:orc -d:useMalloc -d:release -d:danger"
  output: "42"
"""

# bug #20107

type Foo = object
  a, b, c, d: uint64

proc c(i: uint64): Foo =
  Foo(a: i, b: i, c: i, d: i)

func x(f: Foo): lent Foo {.inline.} =
  f

proc m() =
  let f = block:
    let i = c(42)
    x(i)

  echo $f.a

m()

block: # bug #21540
  type
    Option = object
      val: string
      has: bool

  proc some(val: string): Option =
    result.has = true
    result.val = val

  # Remove lent and it works
  proc get(self: Option): lent string =
    result = self.val

  type
    StringStream = ref object
      data: string
      pos: int

  proc readAll(s: StringStream): string =
    result = newString(s.data.len)
    copyMem(addr(result[0]), addr(s.data[0]), s.data.len)

  proc newStringStream(s: string = ""): StringStream =
    new(result)
    result.data = s

  proc parseJson(s: string): string =
    let stream = newStringStream(s)
    result = stream.readAll()

  proc main =
    let initialFEN = block:
      let initialFEN = some parseJson("startpos")
      initialFEN.get

    doAssert initialFEN == "startpos"

  main()

import std/[
    json,
    options
]

block: # bug #21540
  let cheek = block:
    let initialFEN = some("""{"initialFen": "startpos"}""".parseJson{"initialFen"}.getStr)
    initialFEN.get

  doAssert cheek == "startpos"
