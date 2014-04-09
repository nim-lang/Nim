#! strongSpaces

discard """
  output: '''35
77
(Field0: 1, Field1: 2, Field2: 2)
ha
true
tester args
all
all args
'''
"""

echo 2+5 * 5

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
  if foo+4 * 4 == 8 and b&c | 9  ++
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
