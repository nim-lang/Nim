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
    try:
      raise newException(ValueError, "not a crash")
    except ValueError:
      discard
  except NilAccessError:
    echo "caught a crash!"

for i in 0..10:
  main()
