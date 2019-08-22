discard """
  action: "run"
"""

proc fillWith(sq: var seq[int], n: int, unused: string) =
  sq = @[n]

type
  Object = object of RootObj
    case hasNums: bool
    of true:
      numbers: seq[int]
    of false:
      discard
    always: seq[int]

var obj = Object(hasNums: true)

obj.always.fillWith(5, "unused")
doAssert obj.always == @[5]

obj.numbers.fillWith(3, "unused")
doAssert obj.numbers == @[3]
doAssert obj.always == @[5]
