discard """
  file: "tnewderef.nim"
  output: 3

"""

var x: ref int
new(x)
x[] = 3

echo x[]

