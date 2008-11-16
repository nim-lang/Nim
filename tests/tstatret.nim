# no statement after return
proc main() =
  return
  echo("huch?") #ERROR_MSG statement not allowed after

