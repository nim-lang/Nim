discard """
  matrix: "--hintAsError:XCannotRaiseY"
"""

# bug #22792: the `raises` list of a generic covers all of its instances
{.push hint[XCannotRaiseY]:on.}

proc foo(f: int) {.raises: [].} =
  discard

proc foo(f: float) {.raises: [IOError].} =
  raise newException(IOError, "Test")

proc bar(f: int | float) {.raises: [IOError].} =
  foo(f)

bar(42)

proc baz(f: int | float) {.raises: [IOError].} =
  when f is int:
    discard
  else:
    raise newException(IOError, "Test")

baz(42)
