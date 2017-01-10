discard """
  outputsub: '''tproper_stacktrace.nim(7) tproper_stacktrace'''
  exitcode: 1
"""

template fuzzy(x) =
  echo x[] != 9

var p: ptr int
fuzzy p

