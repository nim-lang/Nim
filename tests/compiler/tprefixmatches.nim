import compiler/prefixmatches
import macros

macro check(val, body: untyped): untyped =
  result = newStmtList()
  expectKind body, nnkStmtList
  for b in body:
    expectKind b, nnkTupleConstr
    expectLen b, 2
    let p = b[0]
    let s = b[1]
    result.add quote do:
      doAssert prefixMatch(`p`, `s`) == `val`

check PrefixMatch.Prefix:
  ("abc", "abc")
  ("a", "abc")
  ("xyz", "X_yzzzZe")

check PrefixMatch.Substr:
  ("b", "abc")
  ("abc", "fooabcabc")
  ("abC", "foo_AB_c")

check PrefixMatch.Abbrev:
  ("abc", "AxxxBxxxCxxx")
  ("xyz", "X_yabcZe")

check PrefixMatch.None:
  ("foobar", "afkslfjd_as")
  ("xyz", "X_yuuZuuZe")
  ("ru", "remotes")
