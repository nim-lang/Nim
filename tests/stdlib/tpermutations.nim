discard """
  output: '''@[0, 2, 1]
@[1, 0, 2]
@[1, 2, 0]
@[2, 0, 1]
@[2, 1, 0]
@[2, 0, 1]
@[1, 2, 0]
@[1, 0, 2]
@[0, 2, 1]
@[0, 1, 2]'''
"""
import algorithm

var v = @[0, 1, 2]
while v.nextPermutation():
  echo v
while v.prevPermutation():
  echo v
