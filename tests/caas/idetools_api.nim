import unicode, sequtils, macros, re

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

proc findVowelPosition(text: string) =
  var found = -1
  block loops:
    for i, letter in pairs(text):
      for j in ['a', 'e', 'i', 'o', 'u']:
        if letter == j:
          found = i
          break loops # leave both for-loops
  echo found

findVowelPosition("Zerg") # should output 1, position of vowel.

macro expect*(exceptions: varargs[expr], body: stmt): stmt {.immediate.} =
  ## Expect docstrings
  let exp = callsite()
  template expectBody(errorTypes, lineInfoLit: expr,
                      body: stmt): NimNode {.dirty.} =
    try:
      body
      assert false
    except errorTypes:
      nil

  var body = exp[exp.len - 1]

  var errorTypes = newNimNode(nnkBracket)
  for i in countup(1, exp.len - 2):
    errorTypes.add(exp[i])

  result = getAst(expectBody(errorTypes, exp.lineinfo, body))

proc err =
  raise newException(EArithmetic, "some exception")

proc testMacro() =
  expect(EArithmetic):
    err()

testMacro()
let notAModule = re"(\w+)=(.*)"
