discard """
  output: "0false12"
"""

# Test multiple generic instantiation of generic proc vars:

proc threadProcWrapper[TMsg]() =
  var x: TMsg
  stdout.write($x)

#var x = threadProcWrapper[int]
#x()

#var y = threadProcWrapper[bool]
#y()

threadProcWrapper[int]()
threadProcWrapper[bool]()

type
  TFilterProc[T,D] = proc (item: T, env:D): bool {.nimcall.}

proc filter[T,D](data: seq[T], env:D, pred: TFilterProc[T,D]): seq[T] =
  result = @[]
  for e in data:
    if pred(e, env): result.add(e)

proc predTest(item: int, value: int): bool =
  return item <= value

proc test(data: seq[int], value: int): seq[int] =
  return filter(data, value, predTest)

for x in items(test(@[1,2,3], 2)):
  stdout.write(x)

stdout.write "\n"
