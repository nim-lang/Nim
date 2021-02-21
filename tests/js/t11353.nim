discard """
  output: '''
{}
{}
'''
"""

proc foo() =
  var bar: set[int16] = {}
  echo bar
  bar.incl(1)

foo()
foo()
