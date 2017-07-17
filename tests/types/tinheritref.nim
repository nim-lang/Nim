discard """
  output: '''23
1.5
'''
"""

# bug #554, #179

type T[E] =
  ref object
    elem: E

var ob: T[int]

ob = T[int](elem: 23)
echo ob.elem

type
  TTreeIteratorA* = ref object {.inheritable.}

  TKeysIteratorA* = ref object of TTreeIteratorA  #compiles

  TTreeIterator* [T,D] = ref object {.inheritable.}

  TKeysIterator* [T,D] = ref object of TTreeIterator[T,D]  #this not

var
  it: TKeysIterator[int, string] = nil

#bug #5521
type
  Texture = enum
    Smooth
    Coarse

  FruitBase = object of RootObj
    color: int
    case kind: Texture
    of Smooth:
      skin: float64
    of Coarse:
      grain: int

  Apple = object of FruitBase
    width: int
    taste: float64

var x = Apple(kind: Smooth, skin: 1.5)
var u = x.skin
echo u
