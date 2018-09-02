discard """
  output: "Hello"
"""

type
  T = ref int

let r = new(string)
r[] = "Hello"
echo r[]
