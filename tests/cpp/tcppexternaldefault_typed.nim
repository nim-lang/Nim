discard """
  targets: "cpp"
  output: '''
bool default = 8
char default = 4
enum default = 2
'''
"""

# Triggers the static-non-int path of the cppExternalDefault hook in
# `semGenericParamList` (= the default placeholder must adopt the param's
# declared base type, not be hard-coded to `int`).
#
# Each importcpp template has a non-`int` default kind (= bool / char /
# enum). The C++-side defaults all involve `sizeof(T)` so they are not
# Nim-evaluable and must be expressed via `cppExternalDefault`. Without
# the typed-fallback in semtypes, these fail with
# `type mismatch: got 'int' for '0' but expected 'static[bool]'` etc.
#
# (`double` is intentionally excluded: floating-point non-type template
# parameters are forbidden by the C++ standard until C++20, and
# testament defaults to `-std=gnu++17`.)

{.emit: """/*TYPESECTION*/
template<typename T, bool flag = sizeof(T) >= 2>
struct WithBool { int len() const { return flag ? 8 : 1; } };

template<typename T, char tag = (char)(sizeof(T))>
struct WithChar { int len() const { return (int)tag; } };

enum class Mode { A = 0, B = 1, C = 2 };
template<typename T, Mode m = ((sizeof(T) > 2) ? Mode::C : Mode::A)>
struct WithEnum { int len() const { return (int)m; } };
""".}

type
  Mode {.importcpp: "Mode".} = enum
    mA = 0
    mB = 1
    mC = 2

  WithBool*[T; flag: static bool = cppExternalDefault[bool]()]
    {.importcpp: "WithBool<'0, '1>".} = object
  WithChar*[T; tag: static char = cppExternalDefault[char]()]
    {.importcpp: "WithChar<'0, '1>".} = object
  WithEnum*[T; m: static Mode = cppExternalDefault[Mode]()]
    {.importcpp: "WithEnum<'0, '1>".} = object

proc lenB*[T; flag: static bool](b: WithBool[T, flag]): int {.importcpp: "#.len()".}
proc lenC*[T; tag: static char](b: WithChar[T, tag]): int {.importcpp: "#.len()".}
proc lenE*[T; m: static Mode](b: WithEnum[T, m]): int {.importcpp: "#.len()".}

proc main() =
  var b: WithBool[cint]
  echo "bool default = ", b.lenB()   # sizeof(cint)=4 >= 2 -> flag=true -> 8
  var c: WithChar[cint]
  echo "char default = ", c.lenC()   # (char)sizeof(cint) -> 4
  var e: WithEnum[cint]
  echo "enum default = ", e.lenE()   # sizeof(cint)=4 > 2 -> Mode::C = 2

main()
