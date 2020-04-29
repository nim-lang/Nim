discard """
  errormsg: "index 5 not in 0 .. 2"
"""

var x = @[1, 2, 3]

echo x[5]
x[5] = 8
