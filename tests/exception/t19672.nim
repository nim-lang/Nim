discard """
  errormsg: '''expression '123' is of type 'int literal(123)' and has to be used (or discarded)
'''
"""

let (_, _) = try: ("a", 1) except: ("b", 2)

try:
  123
finally:
  echo "Finally block"
