discard """
  cmd: "nim cpp $file"
"""

type
  AmbiguousAssign {.importcpp, header: "tcpp_default_ctor_assignment.h".} = object
    x: cint
    y: cstring

proc main =
  var xs = newSeq[AmbiguousAssign](3)
  doAssert xs.len == 3

main()