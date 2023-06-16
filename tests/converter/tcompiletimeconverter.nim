discard """
  nimout: '''
abc
'''
"""

converter foo(x: int): string {.compileTime.} = 
  echo "abc"
  $x

const x: int = 123
let y: string = x
doAssert y == $x
