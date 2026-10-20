discard """
  output: '''
5
false
Hello
'''
"""

# bug #9289: indexing a value whose type is a concept matched by a string
type
  StringLike = concept c
    var i: int
    c[i] is char
    c.len is int

proc test(s: StringLike) =
  echo s.len
  echo s[0] == '2'
  var res = ""
  for x in s:
    res.add x
  echo res

test("Hello")
