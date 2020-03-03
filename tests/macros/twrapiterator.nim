
import macros

# bug #7093

macro foobar(arg: untyped): untyped =
  let procDef = quote do:
    proc foo(): void =
      echo "bar"


  result = newStmtList(
    arg, procDef
  )

  echo result.repr

iterator bar(): int {.foobar.} =
  discard
