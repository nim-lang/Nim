
var x: int = 2

echo x
# bug #9144

proc a() =
  while true:
    discard
    # comment 1

  # comment 2
  discard
