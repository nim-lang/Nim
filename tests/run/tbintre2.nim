discard """
  file: "tbintre2.nim"
  output: "helloworld99110223"
"""
# Same test, but check module boundaries

import tbintree

var
  root: PBinaryTree[string]
  x = newNode("hello")
add(root, x)
add(root, "world")
if find(root, "world"):
  for str in items(root):
    stdout.write(str)
else:
  stdout.writeln("BUG")

var
  r2: PBinaryTree[int]
add(r2, newNode(110))
add(r2, 223)
add(r2, 99)
for y in items(r2):
  stdout.write(y)

#OUT helloworld99110223



