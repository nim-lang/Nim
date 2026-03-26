import std/options
import std/typetraits

when not declared(Result):
  type Result*[T, E] = object
    case ok*: bool
    of true:
      value*: T
    else:
      error*: E

proc ok*[T, E](value: T): Result[T, E] = Result[T, E](ok: true, value: value)
proc err*[T, E](error: E): Result[T, E] = Result[T, E](ok: false, error: error)
proc isOk*[T, E](res: Result[T, E]): bool = res.ok
proc isErr*[T, E](res: Result[T, E]): bool = not res.ok
proc get*[T, E](res: Result[T, E]): T =
  if not res.ok:
    raise newException(ValueError, "result error: " & $res.error)
  res.value
proc getError*[T, E](res: Result[T, E]): E =
  if res.ok:
    raise newException(ValueError, "result ok")
  res.error
proc valueOr*[T, E](res: Result[T, E], fallback: T): T =
  if res.ok: res.value else: fallback
proc valueOr*[T, E](res: Result[T, E], fallback: proc(e: E): T): T =
  if res.ok: res.value else: fallback(res.error)
proc map*[T, E, U](res: Result[T, E], f: proc(x: T): U): Result[U, E] =
  if res.ok:
    ok(f(res.value))
  else:
    err(res.error)

proc flatMap*[T, E, U](res: Result[T, E], f: proc(x: T): Result[U, E]): Result[U, E] =
  if res.ok:
    f(res.value)
  else:
    err(res.error)
