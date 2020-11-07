discard """
  targets: "c js"
  errormsg: "cstring doesn't support `[]=` operator!"
"""

var x = cstring"abcd"
x[0] = 'x'