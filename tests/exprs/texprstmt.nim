discard """
  errormsg: "expression 'result[1 .. BackwardsIndex(1)]' is of type 'string' and has to be used (or discarded)"
  line: 10
"""

# bug #578

proc test: string =
  result = "blah"
  result[1 .. ^1]

echo test()
