discard """
  output: '''before
1
before
2'''
"""

proc fn[T1, T2](a: T1, b: T2) =
  a(1)
  b(2)

fn( (proc(x: int) =
      echo "before" # example block, can span multiple lines
      echo x),
    (proc (y: int) =
      echo "before"
      echo y)
)
