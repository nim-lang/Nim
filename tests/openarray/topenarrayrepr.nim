discard """
  output: "5 - [1]"
"""
type
  TProc = proc (n: int, m: openarray[int64]) {.nimcall.}

proc Foo(x: int, P: TProc) =
  P(x, [ 1'i64 ])

proc Bar(n: int, m: openarray[int64]) =
  echo($n & " - " & repr(m))

Foo(5, Bar) #OUT 5 - [1]
