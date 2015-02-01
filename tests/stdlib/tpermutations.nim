discard """
  output: '''@[0, 1, 2, 3, 4, 5, 6, 7, 9, 8]
@[0, 1, 2, 3, 4, 5, 6, 8, 7, 9]
@[0, 1, 2, 3, 4, 5, 6, 8, 9, 7]
@[0, 1, 2, 3, 4, 5, 6, 8, 7, 9]
@[0, 1, 2, 3, 4, 5, 6, 7, 9, 8]
@[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]'''
"""
import algorithm

var v = @[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
for i in 1..3:
  v.nextPermutation()
  echo v
for i in 1..3:
  v.prevPermutation()
  echo v
