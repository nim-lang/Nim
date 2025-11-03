discard """
  errormsg: "cannot assign local to global variable"
  line: 14
"""

type X = object
  p: proc() {.closure.}

proc main() =
  var x = "hi"
  proc p() =
    echo x

  let a {.global.} = X(p: p)
  a.p()

main()
