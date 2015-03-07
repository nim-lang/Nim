import parsecomb

discard """
  output: "-289096"
"""

type Num = int

# forward stuff
var exp3: Parser[string, Num]
var exp = lazy(proc(): Parser[string, Num] = exp3)

var digit = (proc(): Parser[string, Num] =
  result = tok("0").then(unit[string, Num](Num(0)))
  for n in 1..9:
    result = result + tok($n).then(unit[string, Num](Num(n)))
)()

var num = repeat1(digit).map(proc(ds: seq[Num]): Num =
  result = 0
  for d in ds:
    result = result*10 + d)

type Op = proc(a, b: Num): Num

var plusOp = tok("+").then(unit[string, Op](proc(a, b: Num): Num = a + b))
var minusOp = tok("-").then(unit[string, Op](proc(a, b: Num): Num = a - b))
var timesOp = tok("*").then(unit[string, Op](proc(a, b: Num): Num = a*b))
var divideOp = tok("/").then(unit[string, Op](proc(a, b: Num): Num = a div b))

var paren = (tok("(") * exp * tok(")")).map(proc(ler: ((string, Num), string)): Num =
  var (le, r) = ler
  var (l, e) = le
  e)

proc foldOp(a: Num, ob: (Op, Num)): Num =
  var (o, b) = ob
  o(a, b)

var exp0 = paren + num
var exp1 = exp0.leftRec((timesOp + divideOp)*exp0, foldOp)
var exp2 = exp1.leftRec((plusOp + minusOp)*exp1, foldOp)
exp3 = exp2

proc strsplit(s: string): seq[string] =
  result = @[]
  for i in 0 .. s.len - 1:
    result.add($s[i])

var r = exp.run("523-(1243+411/744*1642/1323)*233".strsplit)
case r.kind:
of rkSuccess:
  echo r.output
of rkFailure:
  echo "failed"
