import sequtils

# filter proc test
let
  colors = @["red", "yellow", "black"]
  f1 = filter(colors, proc(x: string): bool = x.len < 6)
  f2 = filter(colors) do (x: string) -> bool : x.len > 5
doAssert f1 == @["red", "black"]
doAssert f2 == @["yellow"]

# filter iterator test
let numbers = @[1, 4, 5, 8, 9, 7, 4]
doAssert toSeq(filter(numbers, proc (x: int): bool = x mod 2 == 0)) ==
  @[4, 8, 4]

# filterIt test
let
  temperatures = @[-272.15, -2.0, 24.5, 44.31, 99.9, -113.44]
  acceptable = filterIt(temperatures, it < 50 and it > -10)
  notAcceptable = filterIt(temperatures, it > 50 or it < -10)
doAssert acceptable == @[-2.0, 24.5, 44.31]
doAssert notAcceptable == @[-272.15, 99.9, -113.44]

# keepItIf test
var candidates = @["foo", "bar", "baz", "foobar"]
keepItIf(candidates, it.len == 3 and it[0] == 'b')
doAssert candidates == @["bar", "baz"]
