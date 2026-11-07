discard """
  targets: "c js"
  output: '''
[4, 2, 1] 2
[4, 2, 1] 2
[4, 2, 1] 1
'''
"""

# bug #14587: a default value that refers to another parameter and needs a
# conversion to the parameter's type
proc f1(a: openArray[int], s: int = high(a)) =
  echo $a & " " & $s
proc f2(a: openArray[int], s: Natural = high(a)) =
  echo $a & " " & $s
let a = [4, 2, 1]
f1(a)
f2(a)
f2(a, 1)
