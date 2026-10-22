discard """
  matrix: "--parsem:on"
  errormsg: "doSome(o) can raise an unlisted exception: Exception"
  line: 24
"""

# `--parsem:on` variant of tests/effects/teffects9: the overriding method's own
# body is checked after `thisRaises`, so the error is reported at the call.

# bug #8481

type
  ParentObj = ref object of RootObj
  DerivedObj = ref object of ParentObj

method doSome(o: ParentObj) {.base, raises: [].} =
  discard

method doSome(o: DerivedObj) =
  raise newException(Exception, "oops, this raised")

proc thisRaises() {.raises: [].} =
  let o = new(DerivedObj)
  o.doSome()

thisRaises()
