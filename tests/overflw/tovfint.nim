discard """
  file: "tovfint.nim"
  output: "works!"
"""
# this tests the new overflow literals

var
  i: int
i = int(0xffffffff'i32)
when defined(cpu64):
  if i == -1:
    write(stdout, "works!\N")
  else:
    write(stdout, "broken!\N")
else:
  if i == -1:
    write(stdout, "works!\N")
  else:
    write(stdout, "broken!\N")

#OUT works!


