
var x: int = 2

echo x
# bug #9144

proc a() =
  while true:
    discard
    # comment 1

  # comment 2
  discard

# bug #15596
discard ## comment 3

discard # comment 4


# bug #20553

let `'hello` = 12
echo `'hello`


proc `'u4`(n: string) =
  # The leading ' is required.
  discard
