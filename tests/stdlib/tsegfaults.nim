discard """
  output: '''caught a crash!
caught a crash!
caught a crash!
caught a crash!
caught a crash!
caught a crash!
caught a crash!
caught a crash!
caught a crash!
caught a crash!
caught a crash!'''
"""

import segfaults

proc main =
  try:
    var x: ptr int
    echo x[]
  except NilAccessError:
    echo "caught a crash!"

for i in 0..10:
  main()
