discard """
  output: '''4
8'''
  cmd: "nimrod $target --threads:on $options $file"
"""

var
  x, y = 0

proc p1 =
  for i in 0 .. 1_000_000:
    discard

  inc x

proc p2 =
  for i in 0 .. 1_000_000:
    discard

  inc y, 2

for i in 0.. 3:
  spawn(p1())
  spawn(p2())

sync()

echo x
echo y
