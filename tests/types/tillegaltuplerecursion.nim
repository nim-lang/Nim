discard """
  errormsg: "illegal recursion in type"
"""

# This is one big illegal type cycle. It doesn't really matter at
# what line the error is reported, nor what name is picked to point
# out the illegal recursion.

type
  MyType0 = ref tuple
    children: MyType1

  MyType1 = ref tuple
    children: array[10, MyType2]

  MyType2 = ref tuple
    children: seq[MyType3]

  MyType3 = ref tuple
    children: UncheckedArray[MyType4]

  MyType4 = ref tuple
    children: MyType5

  MyType5 = tuple
    children: array[10, MyType6]

  MyType6 = tuple
    children: seq[MyType7]

  MyType7 = tuple
    children: UncheckedArray[MyType8]

  MyType8 = tuple
    children: ptr MyType9

  MyType9 = tuple
    children: MyType10

  MyType10 = distinct seq[MyType0]
