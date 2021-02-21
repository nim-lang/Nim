discard """
action: compile
"""

# https://github.com/nim-lang/Nim/issues/15495

proc f() {.raises: [].} =
  var a: proc ()
  var b: proc ()
  swap(a, b)

f()
