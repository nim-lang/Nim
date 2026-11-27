discard """
  output: '''
false
false
'''
"""

# bug #26555: `compiles()` of a const block calling `macros.error` crashed
import std/macros

proc f[T](_: typedesc[T]): seq[int] {.compileTime.} =
  const s = block:
    error "Unsupported"
    @[1]
  s

proc g[T](_: typedesc[T]): string {.compileTime.} =
  const s = block:
    error "Unsupported"
    "abc"
  s

echo compiles(f(int))
echo compiles(g(int))
