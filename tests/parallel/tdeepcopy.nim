discard """
  output: '''
13 abc
called deepCopy for int
called deepCopy for int
done999 999
'''
"""

import threadpool

block one:
  type
    PBinaryTree = ref object
      le, ri: PBinaryTree
      value: int

  proc main =
    var x: PBinaryTree
    deepCopy(x, PBinaryTree(ri: PBinaryTree(le: PBinaryTree(value: 13))))
    var y: string
    deepCopy y, "abc"
    echo x.ri.le.value, " ", y

  main()


block two:
  type
    Bar[T] = object
      x: T

  proc `=deepCopy`[T](b: ref Bar[T]): ref Bar[T] =
    result.new
    result.x = b.x
    when T is int:
      echo "called deepCopy for int"
    else:
      echo "called deepCopy for something else"

  proc foo(b: ref Bar[int]): int = 999

# test that the disjoint checker deals with 'a = spawn f(); g = spawn f()':

  proc main =
    var dummy: ref Bar[int]
    new(dummy)
    dummy.x = 44
    #parallel:
    let f = spawn foo(dummy)
    let b = spawn foo(dummy)
    echo "done", ^f, " ", ^b

  main()
