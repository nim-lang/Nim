discard """
  output: "12"
"""

proc foo(x: int): int = x-1
proc foo(x, y: int): int = x-y

let x = foo 7.foo,  # comment here
            foo(1, foo 8)
#  12 =       6     -     -6
echo x

