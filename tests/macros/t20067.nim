discard """
  output: '''
b.defaultVal = foo
$c.defaultVal = bar
'''
"""

import macros

# #18976

macro getString(identifier): string =
  result = newLit($identifier)
doAssert getString(abc) == "abc"
doAssert getString(`a b c`) == "abc"

# #20067

template defaultVal*(value : typed) {.pragma.}

type A = ref object
  b {.defaultVal: "foo".}: string
  `$c` {.defaultVal: "bar".}: string

let a = A(b: "a", `$c`: "b")

echo "b.defaultVal = " & a.b.getCustomPragmaVal(defaultVal)
echo "$c.defaultVal = " & a.`$c`.getCustomPragmaVal(defaultVal)
