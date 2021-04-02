# Inside template bodies, ensure return types referencing a param are replaced.
# This helps guarantee that return parameter analysis happens after argument
# analysis.
 
# bug #17433

from std/macros import expandMacros

proc bar(a: typedesc): a = default(a)
doAssert bar(float) == 0.0
doAssert bar(string) == ""

template main =
  proc baz(a: typedesc): a = default(a)
  doAssert baz(float) == 0.0
main()
