block:
  defer:
    let a = 42
  doAssert not declared(a)

proc lol() =
  defer:
    let a = 42
  doAssert not declared(a)

lol()
