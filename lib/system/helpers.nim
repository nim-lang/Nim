## helpers used system.nim and other modules, avoids code duplication while
## also minimizing symbols exposed in system.nim
#
# TODO: move other things here that should not be exposed in system.nim

# NOTE: currently line info line numbers start with 1,
# but column numbers start with 0, however most editors expect
# first column to be 1, so we need to +1 here
const colOffset = 1

const colEmpty = -1

proc lineInfoToString(file: string, line, col = colEmpty): string =
  when defined(locationFormatSublime):
    # file:line:col is understood by sublimetext and other editors
    result = file & ":" & $line
    if col > 0:
      result.add ":" & $col
  else:
    # this format is understood by other text editors: it is the same that
    # Borland and Freepascal use
    result = file & "(" & $line
    if col > 0:
      result.add ", " & $col
    result.add ")"
  result.add " "

type InstantiationInfo = tuple[filename: string, line: int, column: int]

proc `$`(info: InstantiationInfo): string =
  lineInfoToString(info.fileName, info.line, info.column+colOffset)

when declared(systemWasImported):
  # TODO: how to export a single overload? (eg: above `$` overload)
  export lineInfoToString
  export colOffset
