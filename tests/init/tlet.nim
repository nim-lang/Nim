{.experimental: "strictDefs".}

proc bar(x: out string) =
  x = "abc"

proc foo() =
  let x: string
  if true:
    x = "abc"
  else:
    x = "def"
  doAssert x == "abc"

  let y: string
  bar(y)
  doAssert y == "abc"

foo()
