discard """
  output: "1"
"""

# bug #1708
let foo = {
  "1" : (bar: @["1"]),
  "2" : (bar: @[])
}

# bug #871

when true:
  import os

  type
    In_out = tuple[src, dest, options: string]

  let
    nil_var: In_out = ("hey"/"there", "something", nil)
    #nil_var2 = ("hey"/"there", "something", nil)

# bug #1721
const foo2: seq[string] = @[]

echo foo[0][0][0]
