discard """
  cmd: "nim cpp $file"
  action: "compile"
"""

# Bug Report 1: {.importcpp.} on =wasMoved generates invalid preprocessor directive #.


type CppRef* {.importcpp, bycopy, noInit, header: "m25800.h".} = object

proc `=destroy`(x: var CppRef) {.importcpp: "#.~CppRef()".}
proc `=wasMoved`(x: var CppRef) {.importcpp: "#.reset()".}
proc `=copy`(dest: var CppRef; src: CppRef) {.importcpp: "dest = src".}
proc `=sink`(dest: var CppRef; src: CppRef) {.importcpp: "dest = std::move(src)".}

# This triggers =wasMoved when passing to sink parameter
proc consume(x: sink CppRef) = discard

proc test() =
  var x: CppRef
  consume(move(x))  # =wasMoved MUST be called here after the move

test()