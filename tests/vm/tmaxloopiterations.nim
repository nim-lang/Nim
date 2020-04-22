discard """
errormsg: "interpretation requires too many iterations; if you are sure this is not a bug in your code"
"""

# issue #9829

macro foo(): untyped  =
  let lines = ["123", "5423"]
  var idx = 0
  while idx < lines.len():
    if lines[idx].len() < 1:
      inc(idx)
      continue

foo()
