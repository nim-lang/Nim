discard """
  cmd: '''nim c -d:nimAllocStats --gc:arc $file'''
  output: '''(allocCount: 102, deallocCount: 102)'''
"""

type
  FutureBase = ref object
    someData: string

const
  # Just to occupy some RAM
  BigData = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

iterator mainIter(): FutureBase {.closure.} =
  for x in 0 .. 100:
    var internalTmpFuture = FutureBase(someData: BigData)
    yield internalTmpFuture

proc main() =
  var nameIterVar = mainIter
  var next = nameIterVar()
  while not isNil(next):
    next = nameIterVar()
    if not isNil(next):
      doAssert next.someData.len == 97
    # GC_unref(next)
    # If you uncomment the GC_ref above,
    # the program basically uses no memory after the run.
    # but crashes with refc, which might indicate
    # that arc/orc simply never frees the result of "next"?
    if finished(nameIterVar):
      break

main()
GC_fullCollect()
echo getAllocStats()
