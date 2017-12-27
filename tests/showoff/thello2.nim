discard """
  output: '''(a: 3, b: 4, s: "abc")'''
"""

type
  MyObject = object
        a, b: int
        s: string

let obj = MyObject(a: 3, b: 4, s: "abc")
echo obj
