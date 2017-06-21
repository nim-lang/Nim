discard """
output: "12"
"""

# https://github.com/nim-lang/Nim/issues/5864

proc defaultStatic(s: openarray, N: static[int] = 1): int = N
proc defaultGeneric[T](a: T = 2): int = a

let a = [1, 2, 3, 4].defaultStatic()
let b = defaultGeneric()

echo a, b

