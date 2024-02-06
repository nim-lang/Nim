discard """
  action: compile
"""

template mytoSeq*(iter: untyped): untyped =
  var result: seq[typeof(iter)]# = @[]
  for x in iter:
    result.add(x)
  result

iterator test(dir:int): int =
  yield 1234

iterator walkGlobKinds (): int =
  let dir2 = 123
  let it = mytoSeq(test(dir2))  

proc main()=
    let it = iterator(): int=
      for path in walkGlobKinds():
          yield path
main()
