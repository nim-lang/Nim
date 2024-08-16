discard """
  errormsg: "'x' cannot be assigned to"
  line: 10
"""

proc bug14498 =
  var a = @['a', 'b', 'c', 'd', 'e', 'f']

  for x in a:
    x = 'c'

  echo a

bug14498()
