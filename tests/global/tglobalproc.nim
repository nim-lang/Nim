discard """
output: hi
hi
"""

type X = object
  p: proc() {.nimcall.}

proc main() =
  proc p() =
    echo "hi"

  let a {.global.} = p
  let b {.global.} = X(p: p)
  p()
  b.p()

main()
