discard """
  matrix: "--mm:refc; --mm:arc; --mm:orc"
  output: '''42
55
42
42
42
42'''
"""

# bug #25993 : an object constructor assigned to a location zeroed the
# destination before evaluating a field value that reads from inside that same
# destination, so `tp.h = H(a: tp.h.a)` produced `a == 0`.

type
  Inner = object
    a: int
    b: int
  Mid = object
    inner: Inner
    x: int
  RefT = ref object
    h: Inner
    other: Inner
    m: Mid

# --------------------------------------------------------------------------
# bug demonstrations: each printed 0 before the fix
# --------------------------------------------------------------------------

proc refDotField(v: int) =
  # dest `t.h` is a field of a ref; value reads `t.h.a` (nested in dest)
  let t = RefT()
  t.h.a = v
  t.h = Inner(a: t.h.a)
  echo t.h.a

proc nestedConstr(v: int) =
  # dest `t.m`; nested constructor value reads `t.m.inner.a` (nested in dest)
  let t = RefT()
  t.m.inner.a = v
  t.m = Mid(inner: Inner(a: t.m.inner.a), x: 0)
  echo t.m.inner.a

proc refDeepField(v: int) =
  # dest `t.m.inner`; value reads `t.m.inner.a` (nested in dest)
  let t = RefT()
  t.m.inner.a = v
  t.m.inner = Inner(a: t.m.inner.a)
  echo t.m.inner.a

var gT: RefT

proc readsField(t: RefT): int = t.h.a

proc viaCall(v: int) =
  # read of dest hidden behind a call whose argument is the root ref
  let t = RefT()
  t.h.a = v
  t.h = Inner(a: readsField(t))
  echo t.h.a

proc viaClosureGlobal(v: int) =
  # read of dest hidden behind a closure reaching it through a global
  let t = RefT()
  t.h.a = v
  gT = t
  let cl = proc(): int = gT.h.a
  t.h = Inner(a: cl())
  echo t.h.a

proc viaClosureCapture(v: int) =
  # read of dest hidden behind a closure that captures the root ref
  let t = RefT()
  t.h.a = v
  let cl = proc(): int = t.h.a
  t.h = Inner(a: cl())
  echo t.h.a

refDotField(42)
nestedConstr(55)
refDeepField(42)
viaCall(42)
viaClosureGlobal(42)
viaClosureCapture(42)
