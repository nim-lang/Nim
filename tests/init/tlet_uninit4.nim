discard """
  errormsg: "type mismatch: got <string>"
"""

{.experimental: "strictDefs".}

proc foo(x: var string) =
  echo x

proc bar() =
  let x: string
  foo(x)
