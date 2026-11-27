discard """
  output: "8191 8191"
"""

# bug #26684: looking up generic instances must not be linear in the number
# of instances (this used to take tens of seconds to compile)
const depth = 12
type Obj[N: static int] = object
  a: int
var count = 0
var sum = 0
proc p[N: static int]() =
  var v: Obj[N]
  v.a = N
  inc count
  sum += ord(v.a == N)
  when N < (1 shl depth):
    p[2 * N]()
    p[2 * N + 1]()
p[1]()
echo count, " ", sum
