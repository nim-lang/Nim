discard """
  output: '''
1
[a, b]
2
[c, d]
4
[e, f]'''
"""

# issue 5045

type size1 = enum a, b
echo sizeof(size1)
echo repr([a, b])

type size2 = enum c=0, d=20000
echo sizeof(size2)
echo repr([c, d])

type size4 = enum e=0, f=2000000000
echo sizeof(size4)
echo repr([e, f])
