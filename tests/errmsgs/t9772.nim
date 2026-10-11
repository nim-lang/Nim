discard """
  errormsg: "illegal recursion in type 'string'"
  line: 7
"""

# bug #9772: used to crash the compiler
type string = string | char
echo string is string
