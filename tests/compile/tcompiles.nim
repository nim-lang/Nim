discard """
  output: '''obj has '==': false
int has '==': true
false
true
true
no'''
"""

# test the new 'compiles' feature:

template supports(opr, x: expr): bool {.immediate.} =
  compiles(opr(x)) or compiles(opr(x, x))

type
  TObj = object

var
  myObj {.compileTime.}: TObj

echo "obj has '==': ", supports(`==`, myObj)
echo "int has '==': ", supports(`==`, 45)

echo supports(`++`, 34)
echo supports(`not`, true)
echo supports(`+`, 34)

when compiles(4+5.0 * "hallo"):
  echo "yes"
else:
  echo "no"
