discard """
  output: '''("string here", 80)'''
  cmd: '''nim c --gc:arc --expandArc:main --hint:Performance:off $file'''
  nimout: '''--expandArc: main

var
  :tmpD
  :tmpD_1
  :tmpD_2
try:
  var x = ("hi", 5)
  x = if cond:
    :tmpD = ("different", 54)
    :tmpD else:
    :tmpD_1 = ("string here", 80)
    :tmpD_1
  echo [
    :tmpD_2 = `$`(x)
    :tmpD_2]
finally:
  `=destroy`(:tmpD_2)
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
