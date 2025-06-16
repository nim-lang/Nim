type X = object

proc `=destroy`(x: X) {.error.} =
  discard

proc main() =
  var x = X()

main()