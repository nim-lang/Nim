# Simple program to test the debugger
# compile with --debugger:on

proc someComp(x, y: int): int =
  let a = x+y
  if a > 7:
    let b = a*90
    {.breakpoint.}
    result = b
  {.breakpoint.}

proc pp() =
  var aa = 45
  var bb = "abcdef"
  echo someComp(23, 45)

pp()
