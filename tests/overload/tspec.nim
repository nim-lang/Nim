discard """
  output: '''not a var
not a var
a var
B
int
T
int16
T
ref T
123
2
1
@[123, 2, 1]'''
"""

# Things that's even in the spec now!

proc byvar(x: var int) = echo "a var"
proc byvar(x: int) = echo "not a var"
byvar(89)

let letSym = 0
var varSym = 13

byvar(letSym)
byvar(varSym)

type
  A = object of RootObj
  B = object of A
  C = object of B

proc p(obj: A) =
  echo "A"

proc p(obj: B) =
  echo "B"

var c = C()
# not ambiguous, calls 'B', not 'A' since B is a subtype of A
# but not vice versa:
p(c)

proc pp(obj: A, obj2: B) = echo "A B"
proc pp(obj: B, obj2: A) = echo "B A"

# but this is ambiguous:
#pp(c, c)

proc takesInt(x: int) = echo "int"
proc takesInt[T](x: T) = echo "T"
proc takesInt(x: int16) = echo "int16"

takesInt(4) # "int"
var x: int32
takesInt(x) # "T"
var y: int16
takesInt(y) # "int16"
var z: range[0..4] = 0
takesInt(z) # "T"

proc gen[T](x: ref ref T) = echo "ref ref T"
proc gen[T](x: ref T) = echo "ref T"
proc gen[T](x: T) = echo "T"

var ri: ref int
gen(ri) # "ref T"


template rem(x: expr) = discard
#proc rem[T](x: T) = discard

rem unresolvedExpression(undeclaredIdentifier)


proc takeV[T](a: varargs[T]) =
  for x in a: echo x

takeV([123, 2, 1]) # takeV's T is "int", not "array of int"
echo(@[123, 2, 1])
