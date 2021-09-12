discard """
  output: '''@[(s1: "333", s2: ""), (s1: "abc", s2: "def"), (s1: "3x", s2: ""), (s1: "3x", s2: ""), (s1: "3x", s2: ""), (s1: "3x", s2: ""), (s1: "lastone", s2: "")]'''
  matrix: "--gc:arc"
  targets: "c cpp"
"""

# bug #13240

type
  Thing = object
    s1: string
    s2: string

var box: seq[Thing]

const c = [Thing(s1: "333"), Thing(s1: "abc", s2: "def")]

for i in 0..high(c):
  box.add c[i]

for i in 0..3:
  box.add Thing(s1: "3x")

box.add Thing(s1: "lastone")

echo box
