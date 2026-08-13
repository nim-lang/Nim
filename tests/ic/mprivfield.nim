# Helper for tprivfield.nim: a type with private fields and a generic that
# constructs it (object constructor + nested field access). Under `nim ic` the
# consumer instantiates this generic; `fieldVisible` must not SIGSEGV on a
# NIF-loaded field with a nil owner / synthesized module stub.

type
  Inner = object
    x: int
  Rec* = object
    inner: Inner

proc makeRec*[T](x: T): Rec =
  result = Rec(inner: Inner(x: x))
  result.inner.x = result.inner.x

proc getHidden*(r: Rec): int = r.inner.x
