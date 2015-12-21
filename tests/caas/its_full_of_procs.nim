import unicode, sequtils

# This example shows that idetools returns proc as signature for everything
# which can be called. While a clever person would use the second column to
# differentiate between procs, methods and others, why does the output contain
# incorrect information?

type
  TThing = object of TObject
  TUnit = object of TThing
    x: int

method collide(a, b: TThing) {.inline.} =
  quit "to override!"

method collide(a: TThing, b: TUnit) {.inline.} =
  echo "1"

method collide(a: TUnit, b: TThing) {.inline.} =
  echo "2"

var
  a, b: TUnit

let
  input = readFile("its_full_of_procs.nim")
  letters = toSeq(runes(string(input)))

collide(a, b) # output: 2
