# Helper for tnestasgn.nim: a sink-param routine whose body contains a nested
# proc whose *entire* body is an assignment. Under `nim ic` that nested body is
# a `nfLazyBody` placeholder with kind `nkAsgn` and empty sons. Destructor
# injection's `getPotentialWrites` used `n[0]` (not `n.len`) and IndexDefect'd.

proc consume*(s: sink string) =
  var x = ""
  proc setIt() =
    x = s
  setIt()
  echo x
