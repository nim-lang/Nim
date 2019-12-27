discard """
  errormsg: "unreachable statement after 'return' statement or '{.noReturn.}' proc"
  file: "tstatret.nim"
  line: 9
"""
# no statement after return
proc main() =
  return
  echo("huch?") #ERROR_MSG statement not allowed after
