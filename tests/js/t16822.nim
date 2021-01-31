# bug #16822
var scores: seq[(set[char], int)] = @{{'/'} : 10}

var x: set[char]
for item in items(scores):
  x = item[0]

doAssert x == {'/'}

for (chars, value) in items(scores):
  x = chars

doAssert x == {'/'}
