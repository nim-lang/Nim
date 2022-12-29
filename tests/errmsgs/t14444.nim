discard """
  matrix: "--hints:off"
  exitcode: "1"
  output: '''
t14444.nim(13)           t14444
fatal.nim(54)            sysFatal
Error: unhandled exception: index out of bounds, the container is empty [IndexDefect]
'''
"""

when true: # bug #14444
  var i: string
  i[10] = 'j'
  echo i
