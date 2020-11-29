discard """
  exitcode: 1
  targets: "c"
  matrix: "-d:debug; -d:release"
  outputsub: '''t13115.nim(13)           t13115
Error: unhandled exception: This char is'''
  outputsub: ''' and works fine! [Exception]'''
"""

const b_null: char = 0.char
var msg = "This char is `" & $b_null & "` and works fine!"

raise newException(Exception, msg)