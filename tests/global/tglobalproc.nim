discard """
output: "hi\nhi"
"""

type X = object
  p: proc() {.nimcall.}

proc main() =
  proc p() =
    echo "hi"

  let a {.global.} = p
  let b {.global.} = X(p: p)
  a()
  b.p()

main()
