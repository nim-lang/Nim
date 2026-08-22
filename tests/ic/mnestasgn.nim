# Helper for tnestasgn.nim: a `sink`-param routine containing a nested proc
# whose ENTIRE body is a single assignment, so the body node is a bare `nkAsgn`
# rather than an `nkStmtList` — the shape that used to be deferred behind a
# childless placeholder of that same kind.

proc consume*(s: sink string) =
  var x = ""
  proc setIt() =
    x = s
  setIt()
  echo x
