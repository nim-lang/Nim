discard """
  output: '''baro0'''
"""

type
  Future[T] = ref object
    data: T
    callback: proc () {.closure.}

proc cbOuter(response: string) {.closure, discardable.} =
  iterator cbIter(): Future[int] {.closure.} =
    for i in 0..7:
      proc foo(): int =
        iterator fooIter(): Future[int] {.closure.} =
          echo response, i
          yield Future[int](data: 17)
        var iterVar = fooIter
        iterVar().data
      yield Future[int](data: foo())

  var iterVar2 = cbIter
  proc cb2() {.closure.} =
    try:
      if not finished(iterVar2):
        let next = iterVar2()
        if next != nil:
          next.callback = cb2
    except:
      echo "WTF"
  cb2()

cbOuter "baro"
