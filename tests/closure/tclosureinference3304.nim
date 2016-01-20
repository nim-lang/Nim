discard """
  output: '''@[1, 2, 5]'''
"""

import future, sequtils

type
  List[T] = ref object
    val: T
  
proc foo[T](l: List[T]): seq[int] =
  @[1,2,3,5].filter(x => x != l.val)

when isMainModule:
  echo(foo(List[int](val: 3)))
