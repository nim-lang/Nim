# Test nested loops and some other things

import
  io

proc andTest() =
  var a = 0 == 5 and 6 == 6

proc incx(x: var int) = # is built-in proc
  x = x + 1

proc decx(x: var int) =
  x = x - 1

proc First(y: var int) =
  var x: int
  i_ncx(x)
  if x == 10:
    y = 0
  else:
    if x == 0:
      incx(x)
    else:
      x=11

proc TestLoops() =
  var i, j: int
  while i >= 0:
    if i mod 3 == 0:
      break
    i = i + 1
    while j == 13:
      j = 13
      break
    break

  while True:
    break


proc Foo(n: int): int =
    var
        a, old: int
        b, c: bool
    F_irst(a)
    if a == 10:
        a = 30
    elif a == 11:
        a = 22
    elif a == 12:
        a = 23
    elif b:
        old = 12
    else:
        a = 40

    #
    b = false or 2 == 0 and 3 == 9
    a = 0 + 3 * 5 + 6 + 7 + +8 # 36
    while b:
        a = a + 3
    a = a + 5
    io.write(stdout, "Hallo!")


# We should come till here :-)
discard Foo(345)
