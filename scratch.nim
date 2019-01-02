

import macros

macro defPacket*(typeNameN: untyped, typeFields: untyped): untyped =
  echo typeNameN.treeRepr
  echo typeFields.treeRepr

template idpacket(pktName, id, s2c, c2s: untyped) =
  let `H pktName`* {.inject.} = id
  defPacket(`Sc pktName`, s2c)
  defPacket(`Cs pktName`, c2s)

idPacket(ZoneQuery, 'Q',
  tuple[playerCount: uint16], ##i should include a time here or something
  tuple[pad: char = '\0'])

# output:
#
#  AccQuoted
#    Ident "Sc"
#    Ident "ZoneQuery"
#  TupleTy
#    CommentStmt "i should include a time here or something"     <----- PROBLEM !!!
#    IdentDefs
#      Ident "playerCount"
#      Ident "uint16"
#      Empty
#  AccQuoted
#    Ident "Cs"
#    Ident "ZoneQuery"
#  TupleTy
#    IdentDefs
#      Ident "pad"
#      Ident "char"
#      CharLit 0

type
  MyEnum = enum
    val1
    val2
    val3

proc foobar(arg: MyEnum): void =
  case arg
  of val1:
    echo "foo1" # ## wrong doc comment
  of val2:
    echo "foo2"
  of val3:
    echo "foo3"

foobar(val2)

proc foobar2(): string =
  ## Some useless docs here.
  assert 1 == 1 ## TODO: this comment is illegal
  result = "123"
