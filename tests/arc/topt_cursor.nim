discard """
  output: '''("string here", 80)'''
  cmd: '''nim c --gc:arc --expandArc:main --expandArc:sio --hint:Performance:off $file'''
  nimout: '''--expandArc: main

var
  :tmpD
  :tmpD_1
  :tmpD_2
try:
  var x_cursor = ("hi", 5)
  x_cursor = if cond:
    :tmpD = ("different", 54)
    :tmpD else:
    :tmpD_1 = ("string here", 80)
    :tmpD_1
  echo [
    :tmpD_2 = `$`(x_cursor)
    :tmpD_2]
finally:
  `=destroy`(:tmpD_2)
-- end of expandArc ------------------------
--expandArc: sio

block :tmp:
  var x_cursor
  var f = open("debug.txt", fmRead, 8000)
  try:
    var res
    try:
      res = newStringOfCap(80)
      block :tmp_1:
        while readLine(f, res):
          x_cursor = res
          echo [x_cursor]
    finally:
      `=destroy`(res)
  finally:
    close(f)
-- end of expandArc ------------------------'''
"""

proc main(cond: bool) =
  var x = ("hi", 5) # goal: computed as cursor

  x = if cond:
        ("different", 54)
      else:
        ("string here", 80)

  echo x

main(false)

proc sio =
  for x in lines("debug.txt"):
    echo x

if false:
  sio()
