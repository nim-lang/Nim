discard """
  file: "tarraytype.nim"
  output: '''true
true
false
'''
"""

type StringArray[N] = array[N, string]
type IntArray[N] = array[N, int]

let a = ["a", "b"]

echo a is array
echo a is StringArray
echo a is IntArray

#echo StringArray is array  ## BUG: expected true returns false

