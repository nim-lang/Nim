discard """
  joinable: false
  output: '''
1
2
3
4
'''
"""

import mcyclic_b {.cyclic.}

type
  A* = object
    b*: B      # embeds a type of the partner module by value
    next*: ref B

proc fromA*(): int = 1

proc useB*(b: B): int = fromB()

echo fromA()
echo useB(B())
echo takeA(A(b: B(x: 4)))
echo A(b: B(x: 4)).b.x
