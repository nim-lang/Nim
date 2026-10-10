discard """
  output: "ok"
"""

# bug #7357
import std/macros

macro zip(args: varargs[seq[int]]): untyped =
  result = newStmtList()
  for i, t in args:
    let check = quote do:
      doAssert(`args`[0].len == `t`.len)
    result.add check

zip(@[1, 2], @[2, 2], @[3, 4])
echo "ok"
