#! strongSpaces

discard """
  output: '''35
true
true
4
true
1
false
77
(Field0: 1, Field1: 2, Field2: 2)
ha
true
tester args
all
all args
19
-3
false
-2
'''
"""

echo 2+5 * 5

# Keyword operators
echo 1 + 16 shl 1 == 1 + (16 shl 1)
echo 2 and 1  in  {0, 30}
echo 2+2 * 2 shr 1
echo false  or  2 and 1  in  {0, 30}

proc `^`(a, b: int): int = a + b div 2
echo 19 mod 16 ^ 4  +  2 and 1
echo 18 mod 16 ^ 4 > 0

# echo $foo gotcha
let foo = 77
echo $foo

echo (1, 2, 2)

template `&`(a, b: int): expr = a and b
template `|`(a, b: int): expr = a - b
template `++`(a, b: int): expr = a + b == 8009

when true:
  let b = 66
  let c = 90
  let bar = 8000
  if foo+4 * 4 == 8  and  b&c | 9  ++
      bar:
    echo "ho"
  else:
    echo "ha"

  let booA = foo+4 * 4  -  b&c | 9  +
      bar
  # is parsed as
  let booB = ((foo+4)*4) - ((b&c) | 9) + bar

  echo booA == booB


template `|`(a, b): expr = (if a.len > 0: a else: b)

const
  tester = "tester"
  args = "args"

echo tester & " " & args|"all"
echo "all"  |  tester & " " & args
echo "all"|tester & " " & args

# Test arrow like operators. See also tests/macros/tclosuremacro.nim
proc `+->`(a, b: int): int = a + b*4
template `===>`(a, b: int): expr = a - b shr 1

echo 3 +-> 2 + 2 and 4
var arrowed = 3+->2 + 2 and 4  # arrowed = 4
echo arrowed ===> 15
echo (2 * 3+->2) == (2*3 +-> 2)
echo arrowed ===> 2 + 3+->2
