discard """
  output: '''true
true'''
"""

# bug #2489

let a = [1]
let b = [1]
echo a == b

# bug #2498
var x: array[0, int]
var y: array[0, int]
echo x == y
