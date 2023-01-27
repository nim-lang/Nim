discard """
  output: "yes"
"""
case 1.0
of 1.0..2.0, 4.0: echo "yes"
of 3.0: discard
else: echo "no"