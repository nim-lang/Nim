discard """
  output: '''10
10.0
1.0hiho'''
"""

# bug #3224
proc f(x: auto): auto =
  result = $(x+10)

proc f(x, y: auto): auto =
  result = $(x+y)


echo f(0)     # prints 10
echo f(0.0)  # prints 10.0

proc `+`(a, b: string): string = a & b

echo f(0.7, 0.3), f("hi", "ho")
