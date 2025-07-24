type RefObj = ref object

proc `[]`(val: static[int]) = # works with different name/overload or without static arg
  discard

template noRef*(T: typedesc): typedesc = # works without template indirection
  typeof(default(T)[])

proc `=destroy`(x: var noRef(RefObj)) =
  discard

proc foo =
  var x = new RefObj
  doAssert $(x[]) == "()"

# bug #11705
foo()
