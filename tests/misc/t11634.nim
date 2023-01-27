discard """
  action: reject
  nimout: '''
t11634.nim(20, 7) Error: cannot destructure to compile time variable
'''
"""

type Foo = ref object
  val: int

proc divmod(a, b: Foo): (Foo, Foo) =
  (
    Foo(val: a.val div b.val),
    Foo(val: a.val mod b.val)
  )

block:
  let a {.compileTime.} = Foo(val: 2)
  let b {.compileTime.} = Foo(val: 3)
  let (c11634 {.compileTime.}, d11634 {.compileTime.}) = divmod(a, b)
