discard """
  file: "tstreamhelpers.nim"
  output: '''123
123
0
3
3
3
123
123
3
3
123
123='''
"""
import streams
proc progress1(pos: int, size: int): bool =
  echo pos
  echo size
  return false

proc progress2(pos: int, size: int, buf: var seq[byte]): bool =
  echo pos
  echo size
  buf.add('='.ord)
  return false

var input = newStringStream("123")
var output = newStringStream("")

input.copy(output)

input.setPosition(0)
output.setPosition(0)

echo input.readAll
echo output.readAll

input.setPosition(0)
output.setPosition(0)

input.copy(output, 8192, progress1)

input.setPosition(0)
output.setPosition(0)

echo input.readAll
echo output.readAll

input.setPosition(0)
output.setPosition(0)

input.transform(output, 8192, progress2)

input.setPosition(0)
output.setPosition(0)

echo input.readAll
echo output.readAll