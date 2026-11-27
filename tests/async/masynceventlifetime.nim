import std/asyncdispatch

when defined(gcDestructors):
  type
    Lifetime = object
      destroyed: ptr int
    Token = ref Lifetime

  proc `=destroy`(value: Lifetime) =
    inc value.destroyed[]

proc watch*(ev: AsyncEvent; destroyed: ptr int; cb: Callback) =
  when defined(gcDestructors):
    let token = Token(destroyed: destroyed)
    ev.addEvent(proc(fd: AsyncFD): bool {.gcsafe.} =
      doAssert token.destroyed != nil
      cb(fd))
  else:
    ev.addEvent(cb)

template checkDestroyed*(count, expected: int) =
  when defined(gcDestructors):
    GC_fullCollect()
    doAssert count == expected

proc retireAll*() =
  # These tests have an isolated dispatcher and no unrelated live operations.
  if hasPendingOperations():
    drain(5000)
  doAssert not hasPendingOperations()
