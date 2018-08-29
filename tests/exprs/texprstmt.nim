discard """
  line: 10
  errormsg: "expression 'result[1 .. ^1]' is of type 'string' and has to be discarded"
"""

# bug #578

proc test: string =
  result = "blah"
  result[1 .. ^1]

echo test()
