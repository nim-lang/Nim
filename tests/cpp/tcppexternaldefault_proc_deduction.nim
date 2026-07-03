discard """
  targets: "cpp"
  output: "ok"
"""

# Triggers the proc generic deduction path:
#   - seminst.nim hook 1 (sentinel-default param has no entry in pt)
#   - seminst.nim hook 2 (isUnresolvedStatic case for the same param)
#   - semtypinst.nim lookupTypeVar hook (lookup nil for sentinel param)
#
# Without these hooks the call to `take` below errors with
# `cannot instantiate: 'N'` because the proc-side N param cannot be
# deduced from a value bound by the cppExternalDefault sentinel.

{.emit: """/*TYPESECTION*/
template<typename T, int N = 1024 / sizeof(T) + 8>
struct Buf { };
""".}

type
  Buf*[T; N: static int = cppExternalDefault[int]()] {.importcpp: "Buf<'0, '1>".} = object

proc take*[T; N: static int](b: Buf[T, N]) {.importcpp: "(void)#".}

proc main() =
  var b: Buf[cint]
  take(b)
  echo "ok"

main()
