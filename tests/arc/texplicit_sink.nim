discard """
  output: '''de'''
  cmd: '''nim c --mm:arc --expandArc:main $file'''
  nimout: '''--expandArc: main

var
  a
  b_cursor
try:
  a = f "abc"
  b_cursor = "de"
  `=sink`(a, b_cursor)
  echo [a]
finally:
  `=destroy`(a)
-- end of expandArc ------------------------'''
"""

# bug #20572

proc f(s: string): string = s

proc main =
  var a = f "abc"
  var b = "de"
  `=sink`(a, b)
  echo a

main()
