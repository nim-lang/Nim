discard """
output: '''
[
1
2
3
]
'''
"""

proc represent(i: int): iterator(): string =
  result = iterator(): string =
    yield $i

proc represent(s: seq[int]): iterator(): string =
  result = iterator(): string =
    yield "["
    for i in s:
      var events = represent(i)
      for event in events():
        yield event
    yield "]"

let s = @[1, 2, 3]
var output = represent(s)

for item in output():
  echo item
