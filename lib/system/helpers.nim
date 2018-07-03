## helpers used system.nim and other modules, avoids code duplication while
## also minimizing symbols exposed in system.nim
#
# TODO: move other things here that should not be exposed in system.nim

const colOffset = 1

proc lineInfoToString(file: string, line, column: int): string =
  file & "(" & $line & ", " & $column & ")"

proc `$`(info: type(instantiationInfo(0))): string =
  # The +1 is needed here
  lineInfoToString(info.fileName, info.line, info.column+colOffset)

when declared(DummyTypeLast):
  # TODO: how to export a single overload?
  # export `$`
  export lineInfoToString
  export colOffset

