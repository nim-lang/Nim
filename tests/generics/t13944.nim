discard """
  output: '''
seq[string] 0
seq[bool] 1
seq[string] 2
'''
"""

# bug #13944: an empty container as the default value of a type class
# parameter takes the type of the branch it matches
proc myMegaProc(a: string, b: seq[string] | seq[bool] = @[]) =
  echo typeof(b), " ", b.len
myMegaProc("hello")
myMegaProc("hello", @[true])
myMegaProc("hello", @["a", "b"])
