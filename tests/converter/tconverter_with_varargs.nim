
# bug #888

type
  PyRef = object
  PPyRef* = ref PyRef

converter to_py*(i: int) : PPyRef = nil

when false:
  proc to_tuple*(vals: openArray[PPyRef]): PPyRef =
    discard

proc abc(args: varargs[PPyRef]) =
  #let args_tup = to_tuple(args)
  discard

abc(1, 2)

# bug #18350

proc foo(x: int) = discard
proc foo(x: varargs[int]) = discard

foo(42) # this is ok

type D = distinct int

converter toInt(x: D): int = int(x)

foo(D(42)) # but this is ambiguous, somehow
