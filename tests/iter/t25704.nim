import std/[sugar, strutils]

type Res[T] = tuple[a: int, b: string]
iterator test(): Res[string] =
  yield (1, "")

for (i, s) in test():
  static:
    echo typeof(i)
    echo typeof(s)
  let
    a: int = i
    b: string = s
