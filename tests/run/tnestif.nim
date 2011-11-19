discard """
  file: "tnestif.nim"
  output: "i == 2"
"""
# test nested ifs

var
    x, y: int
x = 2
if x == 0:
    write(stdout, "i == 0")
    if y == 0:
        write(stdout, x)
    else:
        write(stdout, y)
elif x == 1:
    write(stdout, "i == 1")
elif x == 2:
    write(stdout, "i == 2")
else:
    write(stdout, "looks like Python")
#OUT i == 2


