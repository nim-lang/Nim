discard """
  line: 10
  errormsg: "value returned by statement has to be discarded"
"""

# bug #578

proc test: string =
  result = "blah"
  result[1 .. -1]

echo test()
