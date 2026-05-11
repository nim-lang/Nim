discard """
  targets: "cpp"
  output: "ok"
"""

# Triggers the ccgtypes branch that handles importcpp names without
# apostrophe placeholders (= the `for _, a in tt.genericInstParams:` loop).
# When the importcpp pattern is just a bare name, ccgtypes synthesizes the
# `<...>` template arg list from the generic params; the sentinel arg must
# be skipped there too.

{.emit: """/*TYPESECTION*/
template<typename T, int N = 1024 / sizeof(T) + 8>
struct Buf { };
""".}

type
  # No apostrophe pattern: importcpp uses the bare name.
  Buf*[T; N: static int = cppExternalDefault[int]()] {.importcpp: "Buf".} = object

proc main() =
  var b: Buf[cint]
  echo "ok"

main()
