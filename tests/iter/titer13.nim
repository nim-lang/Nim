discard """
  output: '''b yields
c yields
a returns
b yields
b returns
c yields


1
2
3
4
'''
"""

block:
  template tloop(iter: untyped) =
    for i in iter():
      echo i

  template twhile(iter: untyped) =
    let it = iter
    while not finished(it):
      echo it()

  iterator a(): auto {.closure.} =
    if true: return "a returns"
    yield "a yields"

  iterator b(): auto {.closure.} =
    yield "b yields"
    if true: return "b returns"

  iterator c(): auto {.closure.} =
    yield "c yields"
    if true: return

  iterator d(): auto {.closure.} =
    if true: return
    yield "d yields"

  tloop(a)
  tloop(b)
  tloop(c)
  tloop(d)
  twhile(a)
  twhile(b)
  twhile(c)
  twhile(d)

block:
  iterator a: auto =
    yield 1
  for x in a():
    echo x

  let b = iterator: int =
    yield 2
  for x in b():
    echo x

  let c = iterator: auto =
    yield 3
  for x in c():
    echo x

block:
  iterator myIter2(): auto {.closure.} =
    yield 4
  for a in myIter2():
    echo a

block t5859:
  proc flatIterator[T](s: openArray[T]): auto {.noSideEffect.}=
    result = iterator(): auto =
      when (T is not seq|array):
        for item in s:
          yield item
      else:
        yield 123456
  # issue #5859
  let it = flatIterator(@[@[1,2], @[3,4]])
