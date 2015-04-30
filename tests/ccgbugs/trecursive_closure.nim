# bug #2233
type MalType = object
  fun: proc: MalType

proc f(x: proc: MalType) =
  discard x()

f(nil)
