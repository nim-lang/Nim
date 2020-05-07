discard """
  output: '''
123xyzabc
destroyed: false
destroyed: false
closed
destroying variable
'''
  cmd: "nim c --gc:arc $file"
"""

proc takeSink(x: sink string): bool = true

proc b(x: sink string): string =
  if takeSink(x):
    return x & "abc"

proc bbb(inp: string) =
  let y = inp & "xyz"
  echo b(y)

bbb("123")


# bug #13691
type Variable = ref object
  value: int

proc `=destroy`(self: var typeof(Variable()[])) =
  echo "destroying variable"

proc newVariable(value: int): Variable =
  result = Variable()
  result.value = value

proc test(count: int) =
  var v {.global.} = newVariable(10)

  var count = count - 1
  if count == 0: return

  test(count)
  echo "destroyed: ", v.isNil

test(3)


#------------------------------------------------------------------------------
# issue #13810

import streams

type
  A = ref AObj
  AObj = object of RootObj
    io: Stream
  B = ref object of A
    x: int

proc `=destroy`(x: var AObj) =
  close(x.io)
  echo "closed"

var x = B(io: newStringStream("thestream"))


#------------------------------------------------------------------------------
# issue #14003

proc cryptCTR*(nonce: var openArray[char]) =
  nonce[1] = 'A'

proc main() =
  var nonce1 = "0123456701234567"
  cryptCTR(nonce1)
  doAssert(nonce1 == "0A23456701234567")
  var nonce2 = "01234567"
  cryptCTR(nonce2.toOpenArray(0, nonce2.len-1))
  doAssert(nonce2 == "0A234567")

main()

# bug #14079
import std/algorithm

let
  n = @["c", "b"]
  q = @[("c", "2"), ("b", "1")]

assert n.sortedByIt(it) == @["b", "c"], "fine"
assert q.sortedByIt(it[0]) == @[("b", "1"), ("c", "2")], "fails under arc"


#------------------------------------------------------------------------------
# issue #14236

type
  MyType = object
    a: seq[int]

proc re(x: static[string]): static MyType = 
  MyType()

proc match(inp: string, rg: static MyType) = 
  doAssert rg.a.len == 0

match("ac", re"a(b|c)")

#------------------------------------------------------------------------------
# issue #14243

type
  Game* = ref object

proc free*(game: Game) =
  let a = 5

proc newGame*(): Game =
  new(result, free)

var game*: Game