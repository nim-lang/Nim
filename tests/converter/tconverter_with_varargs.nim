
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
