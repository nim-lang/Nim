discard """
  file: "tropes.nim"
  output: ```0
3

123
3
6
123
123456```
"""
import ropes

var
  r1 = rope("")
  r2 = rope("123")

echo r1.len
echo r2.len

echo r1
echo r2

r1.add("123")
r2.add("456")

echo r1.len
echo r2.len

echo r1
echo r2

