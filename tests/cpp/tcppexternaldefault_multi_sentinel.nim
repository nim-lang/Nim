discard """
  targets: "cpp"
  output: "ok"
"""

# Triggers the ccgtypes apostrophe path with two consecutive sentinel slots,
# exercising the trim loop's ability to drop multiple `, ` separators in a
# row when adjacent template args are all omitted.

{.emit: """/*TYPESECTION*/
template<typename T, int M = 4, int N = 8>
struct Buf { };
""".}

type
  Buf*[T;
       M: static int = cppExternalDefault[int]();
       N: static int = cppExternalDefault[int]()] {.importcpp: "Buf<'0, '1, '2>".} = object

proc main() =
  var b: Buf[cint]
  echo "ok"

main()
