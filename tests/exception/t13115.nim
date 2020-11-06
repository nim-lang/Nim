discard """
  exitcode: 1
  output: '''t13115.nim(11)           t13115
Error: unhandled exception: This char is `
` and works fine! [Exception]'''
"""

const b_null: char = 0.char
var msg = "This char is `" & $b_null & "` and works fine!"

raise newException(Exception, msg)