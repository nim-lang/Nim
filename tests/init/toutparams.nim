discard """
  matrix: "--warningAsError:ProveInit"
"""

{.experimental: "strictdefs".}

proc foo(x: out int) =
  x = 1

proc bar(x: out int) =
  foo(x)

var s: int
bar(s)
