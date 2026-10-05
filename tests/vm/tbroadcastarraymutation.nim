type
  Container = object
    numbers: seq[int]
    text: string
    chars: set[char]

  Variant = object
    case enabled: bool
    of false:
      numbers: seq[int]
    else:
      discard

  Index = enum
    index0, index1, index2, index3, index4, index5, index6, index7,
    index8, index9, index10, index11, index12, index13, index14, index15,
    index16, index17, index18, index19, index20, index21, index22, index23,
    index24, index25, index26, index27, index28, index29, index30, index31,
    index32

  Outer = object
    values: array[33, seq[int]]

proc directSeq(): array[33, seq[int]] =
  result[32].add 1

proc directStringChar(): array[33, string] =
  result[32].add 'a'

proc directStringString(): array[33, string] =
  result[32].add "ab"

proc directSet(): array[33, set[char]] =
  result[32].incl 'a'

proc fieldSeq(): array[33, Container] =
  result[32].numbers.add 1

proc fieldStringChar(): array[33, Container] =
  result[32].text.add 'a'

proc fieldStringString(): array[33, Container] =
  result[32].text.add "ab"

proc fieldSet(): array[33, Container] =
  result[32].chars.incl 'a'

proc nestedSeq(): array[33, array[33, seq[int]]] =
  result[32][32].add 1

proc checkedFieldSeq(): array[33, Variant] =
  result[32].numbers.add 1

proc enumIndexSeq(): array[Index, seq[int]] =
  result[index32].add 1

proc rangeIndexSeq(): array[10..42, seq[int]] =
  result[42].add 1

proc firstIndexSeq(): array[33, seq[int]] =
  result[0].add 1

proc middleIndexSeq(): array[33, seq[int]] =
  result[16].add 1

proc objectArraySeq(): Outer =
  result.values[32].add 1

proc singleEvaluation(): tuple[values: array[33, seq[int]], evaluations: int] =
  var evaluations = 0
  proc index(): int =
    inc evaluations
    32
  result.values[index()].add 1
  result.evaluations = evaluations

proc test =
  let direct = directSeq()
  doAssert direct[0].len == 0
  doAssert direct[31].len == 0
  doAssert direct[32] == @[1]
  doAssert directStringChar()[32] == "a"
  doAssert directStringString()[32] == "ab"
  doAssert 'a' in directSet()[32]
  doAssert fieldSeq()[32].numbers == @[1]
  doAssert fieldStringChar()[32].text == "a"
  doAssert fieldStringString()[32].text == "ab"
  doAssert 'a' in fieldSet()[32].chars
  doAssert nestedSeq()[32][32] == @[1]
  doAssert checkedFieldSeq()[32].numbers == @[1]
  doAssert enumIndexSeq()[index32] == @[1]
  doAssert rangeIndexSeq()[42] == @[1]
  doAssert firstIndexSeq()[0] == @[1]
  doAssert middleIndexSeq()[16] == @[1]
  doAssert objectArraySeq().values[32] == @[1]
  let evaluated = singleEvaluation()
  doAssert evaluated.values[32] == @[1]
  doAssert evaluated.evaluations == 1

static: test()
test()
