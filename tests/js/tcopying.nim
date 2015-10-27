discard """
  output: '''123
'''
"""

type MyArray = array[1, int]

proc changeArray(a: var MyArray) =
    a = [123]

var a : MyArray
changeArray(a)
echo a[0]
