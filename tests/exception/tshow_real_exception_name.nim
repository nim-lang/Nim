discard """
  outputsub: "CustomChildError"
  exitcode: 1
"""

type
  CustomError* = object of Exception
  CustomChildError* = object of CustomError

  FutureBase* = ref object of RootObj
    error*: ref Exception

  Future*[T] = ref object of FutureBase
    v: T

proc fail[T](future: Future[T], error: ref Exception) =
  future.error = error

proc w1(): Future[int] =
  result = Future[int]()
  result.fail(newException(CustomChildError, "abc"))

proc main =
  var fut = w1()
  if true:
    raise fut.error

main()
