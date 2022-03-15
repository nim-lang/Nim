import std/assertions

static:
  doAssertRaises(ValueError):
    raise newException(ValueError, "Yes")
