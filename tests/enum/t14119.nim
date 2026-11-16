discard """
  output: '''
EnumType
EnumType
EnumType
First
'''
"""

# bug #14119: an enum type as `getType` describes it is the existing enum
import std/macros

type EnumType = enum First, Second

macro getType2(typ: typedesc): typedesc =
  result = getType(typ)

proc fun(T: typedesc) =
  type NewTypeDef = getType2(T)
  var y: NewTypeDef = First
  discard y


var x: EnumType
echo First.type
fun(EnumType)
echo First.type
echo EnumType.First.type
x = First
echo x
