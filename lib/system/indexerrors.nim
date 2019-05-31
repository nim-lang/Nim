# imported by other modules, unlike helpers.nim which is included

template formatErrorIndexBound*[T](i, a, b: T): string =
  when defined(standalone):
    "indexOutOfBounds"
  else:
    "index " & $i & " not in " & $a & " .. " & $b

template formatErrorIndexBound*[T](i, n: T): string =
  formatErrorIndexBound(i, 0, n)
