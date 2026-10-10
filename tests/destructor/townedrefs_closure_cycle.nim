discard """
  errormsg: "cannot produce an 'owned' closure: its environment can be part of a cycle via the captured 'w'"
  line: 12
"""
# the environment of an owned closure must be acyclic
{.experimental: "ownedRefs".}
type
  Widget = ref object
    onClick: proc ()

proc bad(w: Widget): owned proc () =
  result = proc () = echo w.onClick == nil

discard bad(Widget())
