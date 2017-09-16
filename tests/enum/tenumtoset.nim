discard """
  output: '''0eA
3x
65536eC
60z
61fB
75fC'''
"""

type
  E = enum
    eA
    eB = (3, "x")
    eC = 65536
  F = enum
    fA = (60, "z")
    fB
    fC = 75
for x in E.toSet: echo x.ord, x
for x in F.toSet: echo x.ord, x