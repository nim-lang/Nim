# TODO: remove this file. It causes "declared but not used" warnings everywhere.

type InstantiationInfo = tuple[filename: string, line: int, column: int]

proc `$`(info: InstantiationInfo): string =
  info.fileName & "(" & $info.line & ", " & $(info.column+1) & ")"

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
