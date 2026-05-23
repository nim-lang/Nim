discard """
  errormsg: "'=destroy' is not available for type <X>; routine: main"
  joinable: false
"""

type X = object

proc `=destroy`(x: X) {.error.} =
  discard

proc main() =
  var x = X()

main()