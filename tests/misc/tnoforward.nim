discard """
  disabled: true
"""

{. noforward: on .}

proc foo(x: int) =
  bar x

proc bar(x: int) =
  echo x

foo(10)

