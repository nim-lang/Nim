discard """
  output: "23"
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

