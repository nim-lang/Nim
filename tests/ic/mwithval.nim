# Helper for twithval.nim: a generic `withValue` template that injects the
# unwrapped value, matching libp2p's `Opt.withValue`. Under `nim ic` the
# consumer's expansion used to leave the injected ident untyped
# ("expression '' has no type") because the generic param `T` in the loaded
# template body was not substituted.

type
  Box*[T] = object
    val: T
    has: bool

proc get*[T](o: Box[T]): T = o.val
proc isSome*[T](o: Box[T]): bool = o.has
proc some*[T](v: T): Box[T] = Box[T](val: v, has: true)

template withValue*[T](self: Box[T], value, body: untyped) =
  let temp = (self)
  if temp.isSome:
    let value {.inject, used.} = temp.get()
    body
