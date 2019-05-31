# D20180828T234921:here
template foo*(iter: untyped): untyped =
  when compiles(iter.unexistingField): 0
  elif compiles(iter.len): 1
  else: 2

proc foo[A]()=
  let a2 = @[10, 11]
  let a3 = foo(pairs(a2))

foo[int]()
