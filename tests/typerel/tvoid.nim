discard """
  output: '''12
empty
he, no return type;
abc a string
ha'''
"""

proc ReturnT[T](x: T): T =
  when T is void:
    echo "he, no return type;"
  else:
    result = x & " a string"

proc nothing(x, y: void): void =
  echo "ha"

proc callProc[T](p: proc (x: T) {.nimcall.}, x: T) =
  when T is void:
    p()
  else:
    p(x)

proc intProc(x: int) =
  echo x

proc emptyProc() =
  echo "empty"

callProc[int](intProc, 12)
callProc[void](emptyProc)


ReturnT[void]()
echo ReturnT[string]("abc")
nothing()

