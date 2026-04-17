discard """
  cmd: '''nim c --mm:arc --expandArc:foo $file'''
  nimout: '''
--expandArc: foo

var broken_cursor
block :tmp:
  var i
  var i_1 = 0
  let L = len(seq[Large](broken_cursor))
  block :tmp_1:
    while i_1 < L:
      i = seq[Large](broken_cursor)[i_1]
      discard i
      {.push, overflowChecks: false.}
      inc(i_1, 1)
      {.pop.}
-- end of expandArc ------------------------
'''
"""


type
  Large = array[1024, byte]
  List = distinct seq[Large]

proc foo =
  var
    broken: List
  for i in seq[Large](broken):
    discard i

foo()