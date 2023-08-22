discard """
  output: "10"
"""

# {. noforward: on .}
{.experimental: "codeReordering".}

proc foo(x: int) =
  bar x

proc bar(x: int) =
  echo x

foo(10)

