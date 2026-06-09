discard """
output: "5"
"""

# bug #25883: C codegen assigns same type hash to tuples with different nesting
# but identical flattened content.
# ((Int[1], Int[2]), Int[13], Int[14]) and ((Int[1], Int[2], Int[13]), Int[14])
# must get distinct C type names.

type
  Int[V: static int] = object

proc main() =
  var b = ((1, 2), 13, 14)
  var c = ((1, 2, 13), 14)
  echo c[0][2]

main()
