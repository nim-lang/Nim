discard """
  output:'''
foo: 1
foo: 2
bar: 1
bar: 2
foo: 1
foo: 2
bar: 1
bar: 2
bar: 3
bar: 4
bar: 5
bar: 6
bar: 7
bar: 8
bar: 9
'''
"""

# bug #11042
block:
  iterator foo: int =
    for x in 1..2:
      echo "foo: ", x
      for y in 1..2:
        discard

  for x in foo(): discard

  let bar = iterator: int =
    for x in 1..2:
      echo "bar: ", x
      for y in 1..2:
        discard

  for x in bar(): discard


block:
  iterator foo: int =
    for x in 1..2:
      echo "foo: ", x
      for y in 1..2:
        discard

  for x in foo(): discard

  let bar = iterator: int =
    for x in 1..9:
      echo "bar: ", x
      for y in 1..2:
        discard

  for x in bar(): discard