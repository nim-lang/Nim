
type NoCopy = object
  v: string
proc `=copy`(a: var NoCopy, b: NoCopy) {.error.}

proc sinkMe(v: sink NoCopy) =
  echo v.v

proc iter(v: sink NoCopy): iterator(): int =
  iterator(): int =
    yield 1
    sinkMe(v)

proc brokenIter(v: sink NoCopy): iterator(): int =
  iterator(): int =
    for i in 0..<10:
      yield 1
      sinkMe(v)

proc main() =
  let vvv = iter(NoCopy(v: "test"))
  for i in vvv():
    echo i

  let vvv2 = brokenIter(NoCopy(v: "test"))
  for i in vvv2():
    echo i

main()
