discard """
  nimout: "static 10\ndynamic\nstatic 20\n"
  output: "s\nd\nd\ns"
"""

type
  semistatic[T] =
    static[T] or T

template isStatic*(x): bool =
  compiles(static(x))

proc foo(x: semistatic[int]) =
  when isStatic(x):
    static: echo "static ", x
    echo "s"
  else:
    static: echo "dynamic"
    echo "d"

foo 10

var
  x = 10
  y: int

foo x
foo y

foo 20

