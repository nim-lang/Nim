discard """
  output: '''concrete 88'''
"""

# Another regression triggered by changed closure computations:

proc foo[T](x: proc(): T) =
  echo "generic ", x()

proc foo(x: proc(): int) =
  echo "concrete ", x()

# note the following 'proc' is not .closure!
foo(proc (): auto {.nimcall.} = 88)

# bug #3499 last snippet fixed
# bug 705  last snippet fixed
