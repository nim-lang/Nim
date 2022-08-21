discard """
  errormsg: "can raise an unlisted exception: ref Exception"
  line: 16
"""

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
