discard """
  file: "tstatret.nim"
  line: 9
  errormsg: "statement not allowed after"
"""
# no statement after return
proc main() =
  return
  echo("huch?") #ERROR_MSG statement not allowed after



