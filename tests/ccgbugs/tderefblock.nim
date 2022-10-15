discard """
  cmd: "nim c -d:release -d:danger $file"
  matrix: ";--gc:orc"
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
