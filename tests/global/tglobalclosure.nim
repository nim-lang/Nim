discard """
  errormsg: "cannot assign local to global variable"
  line: 11
"""

proc main() =
  var x = "hi"
  proc p() =
    echo x

  let a {.global.} = p
  p()

main()
