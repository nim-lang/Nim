discard """
  errormsg: "type mismatch: got <Future[system.int], void>"
  line: 20
"""

type
  Future[T] = object
    value: T

proc complete[T](x: T) =
  echo "completed"
  let y = x


proc complete*[T](future: var Future[T], val: T) =
  future.value = val

var a: Future[int]

complete(a):
  echo "yielding void"
