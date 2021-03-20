discard """
  errormsg: "request to generate code for .compileTime proc: foo"
"""

# ensure compileTime funcs can't be called from runtime

func foo(a: int): int {.compileTime.} =
  a * a

proc doAThing(): int =
  for i in 0..2:
    result += foo(i)

echo doAThing()
