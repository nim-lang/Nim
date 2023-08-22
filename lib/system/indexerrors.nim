# imported by other modules, unlike helpers.nim which is included
# xxx this is now included instead of imported, we should import instead

template formatErrorIndexBound*[T](i, a, b: T): string =
  when defined(standalone):
    "indexOutOfBounds"
  else:
    if b < a: "index out of bounds, the container is empty"
    else: "index " & $i & " not in " & $a & " .. " & $b

template formatErrorIndexBound*[T](i, n: T): string =
  formatErrorIndexBound(i, 0, n)

template formatFieldDefect*(f, discVal): string =
  f & discVal & "'"
