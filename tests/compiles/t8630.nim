discard """
  output: '''
foo
bar
'''
"""

proc test(strings: seq[string]) =
  for s in strings:
    var p3 = unsafeAddr(s)
    echo p3[]

test(@["foo", "bar"])
