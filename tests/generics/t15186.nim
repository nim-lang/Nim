discard """
  errormsg: "illegal recursion in type 'Node'"
  line: 41
  matrix: "--errorMax:20"
  nimout: '''
t15186.nim(37, 17) Error: illegal recursion in type 'ViaTuple'
t15186.nim(38, 17) Error: illegal recursion in type 'ViaArray'
t15186.nim(39, 10) Error: illegal recursion in type 'A'
t15186.nim(40, 16) Error: illegal recursion in type 'Derived'
t15186.nim(41, 16) Error: illegal recursion in type 'Node'
'''
"""

# bug #15186: the same as #14646, through a `ref object` that contains the recursive
# object, and without constructing it. The other ways a generic object can hold itself
# by value (a tuple, an array, two objects, a base class) are reported too.

type
  Node[T] = object
    item: T
    next: Node[T]
  Bag*[T] = ref object
    first: Node[T]
  ViaTuple[T] = object
    f: (int, ViaTuple[T])
  ViaArray[T] = object
    f: array[2, ViaArray[T]]
  A[T] = object
    b: B[T]
  B[T] = object
    a: A[T]
  Base[T] = object of RootObj
    x: Derived[T]
  Derived[T] = object of Base[T]
    y: int

var v1: ViaTuple[int]
var v2: ViaArray[int]
var v3: A[int]
var v4: Derived[int]
var b = new(Bag[int])
