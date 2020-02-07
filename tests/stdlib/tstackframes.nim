import std/stackframes

proc main2(n: int) =
  setFrameMsg $(n,)
  if n > 0:
    main2(n-1)

proc main(n: int) =
  setFrameMsg $(n,)
  proc bar() =
    setFrameMsg "in bar "
    doAssert n >= 3
  bar()
  main(n-1)

main(10)
