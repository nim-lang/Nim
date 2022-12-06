{.experimental: "strictDefs".}

proc bar(x: out string) =
  x = "abc"

proc foo() =
  block:
    let x: string
    if true:
      x = "abc"
    else:
      x = "def"
    doAssert x == "abc"
  block:
    let y: string
    bar(y)
    doAssert y == "abc"
  block:
    let x: string
    if true:
      x = "abc"
      discard "abc"
    else:
      x = "def"
      discard "def"
    doAssert x == "abc"
  block: #
    let x: int
  block: #
    let x: float
    x = 1.234
    doAssert x == 1.234
static: foo()
foo()
