discard """
  output: '''("string here", 80)'''
  cmd: '''nim c --gc:arc --expandArc:main --hint:Performance:off $file'''
  nimout: '''--expandArc: main

var :tmpD
try:
  var x = ("hi", 5)
  x = if cond: ("different", 54) else: ("string here", 80)
  echo [
    :tmpD = `$`(x)
    :tmpD]
finally:
  `=destroy`(:tmpD)
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
