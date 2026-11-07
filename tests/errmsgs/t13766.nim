discard """
  errormsg: "invalid type: 'openArray[int]' in this context: tuple"
  line: 8
"""

# bug #13766: an openArray in a tuple constructor
proc bar(a: openArray[int]) =
  discard $(a, 1)
bar(@[1, 2])
