discard """
  errormsg: "cannot evaluate at compile time: x"
  line: 7
"""

proc bla(x:int) =
  when x == 0:
    echo "oops"
  else:
    echo "good"

bla(2)  # echos "oops"

