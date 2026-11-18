discard """
  output: "0 1 2 0 1 2 0 end"
"""

# bug #9680: `{.goto.}` with a `discard` as the last branch
type T = enum A, B, C, D

var res = ""

proc main =
  var count = 0
  var p {.goto.} = A
  case p
  of A:
    res.add "0 "
    if count < 2:
      p = B
    else:
      p = D
  of B:
    res.add "1 "
    p = C
  of C:
    res.add "2 "
    count += 1
    p = A
  of D:
    discard

main()
res.add "end"
echo res
