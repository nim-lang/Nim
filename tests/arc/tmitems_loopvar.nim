discard """
  output: '''a
b
c
a
b
c'''
"""

# A `var T` loop variable (here from `mitems`) declared inside an enclosing
# loop must not be reset by dereferencing: at module scope it is emitted as a
# global, and the in-loop reset path used `resetLoc`, which dereferenced the
# still-uninitialized borrowed pointer and crashed with a SIGSEGV.

for p in @["abc", "123"]:
  var testA = @["a", "b", "c"]
  for l in testA.mitems:
    echo(l)

# also exercise actual mutation through the borrowed reference
block:
  var ok = true
  for p in @["x", "y"]:
    var s = @[1, 2, 3]
    for l in s.mitems:
      l += 10
    if s != @[11, 12, 13]: ok = false
  doAssert ok
