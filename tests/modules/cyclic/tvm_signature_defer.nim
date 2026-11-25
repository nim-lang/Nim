discard """
  matrix: "--deferBodies:on"
  output: "6"
"""

# `--deferBodies:on` defers the body of `helper`, but the signature of `user`
# needs the VM to run it:
proc helper*(): int = 6
proc user*(x: array[helper(), int]): int = x.len
var z: array[6, int]
echo user(z)
