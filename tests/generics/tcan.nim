discard """
  output: '''
'''
"""

# Created by Eric Doughty-Papassideris on 2011-02-16.

block talias_generic:
  type
    TGen[T] = object
    TGen2[T] = TGen[T]


block talias_specialised:
  type
    TGen[T] = object
    TSpef = TGen[string]
  var s: TSpef


block tinherit:
  type
    TGen[T] = object of RootObj
      x, y: T
    TSpef[T] = object of TGen[T]

  var s: TSpef[float]
  s.x = 0.4
  s.y = 0.6


block tspecialise:
  type
    TGen[T] {.inheritable.} = object
    TSpef = object of TGen[string]


block tspecialised_equivalent:
  type
    TGen[T] = tuple[a: T]
    TSpef = tuple[a: string]

  var
    a: TGen[string]
    b: TSpef
  a = b
