discard """
  targets: "cpp"
  output: '''
default len = 264
explicit N=4, len = 4
'''
"""

# Core happy-path test for the cppExternalDefault sentinel.
#
# Triggers:
#   - lib/system.nim cppExternalDefault template (declaration only)
#   - semtypes.nim sentinel detection in semGenericParamList
#   - semtypinst.nim flag propagation through handleGenericInvocation
#   - typeallowed.nim tyGenericInvocation + tyGenericParam allow branches
#   - ccgtypes.nim apostrophe slot skip + preceding-comma trim
#
# C++ side defines `struct Buf<T, int N = 1024 / sizeof(T) + 8>`.
# When the user writes `var x: Buf[cint]` the compiler must instantiate
# `Buf<int>` (= no second template arg), so the C++-side default
# expression `1024 / sizeof(int) + 8 = 264` takes effect.

{.emit: """/*TYPESECTION*/
template<typename T, int N = 1024 / sizeof(T) + 8>
struct Buf { int len() const { return N; } };
""".}

type
  Buf*[T; N: static int = cppExternalDefault[int]()] {.importcpp: "Buf<'0, '1>".} = object

proc len*[T; N: static int](b: Buf[T, N]): int {.importcpp: "#.len()".}

proc main() =
  var defaulted: Buf[cint]
  echo "default len = ", defaulted.len()
  var explicit: Buf[cint, 4]
  echo "explicit N=4, len = ", explicit.len()

main()
