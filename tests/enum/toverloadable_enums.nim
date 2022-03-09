discard """
  output: '''B
0
E2-B'''
joinable: false
"""

{.experimental: "overloadableEnums".}

type
  E1 = enum
    value1,
    value2
  E2 = enum
    value1,
    value2 = 4

const
  Lookuptable = [
    E1.value1: "1",
    value2: "2"
  ]

when false:
  const
    Lookuptable: array[E1, string] = [
      value1: "1",
      value2: "2"
    ]


proc p(e: E1): int =
  # test that the 'case' statement is smart enough:
  case e
  of value1: echo "A"
  of value2: echo "B"


let v = p value2 # ERROR: ambiguous!
# (value2|value2)  nkClosedSymChoice -> nkSym

proc x(p: int) = discard
proc x(p: string) = discard

proc takeCallback(param: proc(p: int)) = discard

takeCallback x

echo ord v

block: # https://github.com/nim-lang/RFCs/issues/8
  type
    Enum1 = enum
      A, B, C
    Enum2 = enum
      A, Z

  proc f(e: Enum1): int = ord(e)
  proc g(e: Enum2): int = ord(e)

  proc h(e: Enum1): int = ord(e)
  proc h(e: Enum2): int = ord(e)

  let fA = f(A) # Type of A is well defined
  let gA = g(A) # Same as above

  let hA1 = h(Enum1.A) # A requires disambiguation
  let hA2 = h(Enum2.A) # Similarly
  let hA3 = h(B)
  let hA4 = h(B)
  let x = ord(Enum1.A) # Also
  doAssert fA == 0
  doAssert gA == 0
  doAssert hA1 == 0
  doAssert hA2 == 0
  doAssert x == 0
  doAssert hA3 == 1
  doAssert hA4 == 1

# bug #18769
proc g3[T](x: T, e: E2): int =
  case e
  of value1: echo "E2-A"        # Error: type mismatch: got 'E1' for 'value1' but expected 'E2 = enum'
  of value2: echo "E2-B"

let v5 = g3(99, E2.value2)
