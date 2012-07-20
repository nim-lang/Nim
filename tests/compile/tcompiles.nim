discard """
  output: '''no'''
"""

# test the new 'compiles' feature:

when compiles(4+5.0 * "hallo"):
  echo "yes"
else:
  echo "no"
  

