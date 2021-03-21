# Inside template bodies, ensure return types referencing a param are replaced.
# This helps guarantee that return parameter analysis happens after argument
# analysis.
 
# bug #17433

from std/macros import expandMacros

proc bar(a: typedesc): a = default(a)
assert bar(float) == 0.0
assert bar(string) == ""

template main =
  proc baz(a: typedesc): a = default(a)
  assert baz(float) == 0.0
main()
