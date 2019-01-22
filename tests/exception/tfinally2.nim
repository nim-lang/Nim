discard """
output: '''
A
B
C
D
'''
"""
# Test break in try statement:

proc main: int =
  try:
    block AB:
      try:
        try:
          break AB
        finally:
          echo("A")
        echo("skipped")
      finally:
        block B:
          echo("B")
      echo("skipped")
    echo("C")
  finally:
    echo("D")

discard main()
