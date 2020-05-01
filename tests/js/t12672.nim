discard """
  output: ""
"""

proc foo =
  var x: seq[seq[int]]
  for row in x.mitems:
    let i = 1
    echo row
    inc row[i-1]

foo()
