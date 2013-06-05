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
