
# 4412
proc default[T](t: typedesc[T]): T {.inline.} = discard

static:
  var x = default(type(0))
