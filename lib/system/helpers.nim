# helpers used system.nim and other modules, avoids code duplication while
# also minimizing symbols exposed in system.nim
#
# TODO: move other things here that should not be exposed in system.nim

proc lineInfoToString(file: string, line, column: int): string =
  file & "(" & $line & ", " & $column & ")"

type InstantiationInfo = tuple[filename: string, line: int, column: int]

proc `$`(info: InstantiationInfo): string =
  # The +1 is needed here
  # instead of overriding `$` (and changing its meaning), consider explicit name.
  lineInfoToString(info.fileName, info.line, info.column+1)

proc isNamedTuple(T: type): bool =
  ## return true for named tuples, false for any other type.
  when T isnot tuple: result = false
  else:
    var t: T
    for name, _ in t.fieldPairs:
      when name == "Field0":
        return compiles(t.Field0)
      else:
        return true
    # empty tuple should be un-named,
    # see https://github.com/nim-lang/Nim/issues/8861#issue-356631191
    return false
