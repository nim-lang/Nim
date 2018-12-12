template formatErrorIndexBound*[T](i, a, b: T): string =
  "index out of bounds: (a:" & $a & ") <= (i:" & $i & ") <= (b:" & $b & ") "

template formatErrorIndexBound*[T](i, n: T): string =
  "index out of bounds: (i:" & $i & ") <= (n:" & $n & ") "
