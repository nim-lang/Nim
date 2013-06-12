import unicode, sequtils

proc test_enums() =
  var o: Tfile
  if o.open("files " & "test.txt", fmWrite):
    o.write("test")
    o.close()

proc test_iterators(filename = "tests.nim") =
  let
    input = readFile(filename)
    letters = toSeq(runes(string(input)))
  for letter in letters: echo int(letter)

const SOME_SEQUENCE = @[1, 2]
type
  bad_string = distinct string
  TPerson = object of TObject
    name*: bad_string
    age: int

proc adder(a, b: int): int =
  result = a + b

type
  PExpr = ref object of TObject ## abstract base class for an expression
  PLiteral = ref object of PExpr
    x: int
  PPlusExpr = ref object of PExpr
    a, b: PExpr

# watch out: 'eval' relies on dynamic binding
method eval(e: PExpr): int =
  # override this base method
  quit "to override!"

method eval(e: PLiteral): int = e.x
method eval(e: PPlusExpr): int = eval(e.a) + eval(e.b)

proc newLit(x: int): PLiteral = PLiteral(x: x)
proc newPlus(a, b: PExpr): PPlusExpr = PPlusExpr(a: a, b: b)

echo eval(newPlus(newPlus(newLit(1), newLit(2)), newLit(4)))
