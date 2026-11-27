discard """
  errormsg: "expression '1' is of type 'int literal(1)' and has to be used (or discarded)"
  line: 9
"""

# bug #13450
proc bar(): int =
  when nimvm: result = 2
  else: 1
echo bar()
