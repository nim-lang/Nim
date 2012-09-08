discard """
  output: '''48
hel'''
"""

template optZero{x+x}(x: int): int = x*3
template andthen{`*`(x,3)}(x: int): int = x*4
template optSubstr1{x = substr(x, a, b)}(x: string, a, b: int) = setlen(x, b+1)

var y = 12
echo y+y

var s: array[0..2, string]
s[0] = "hello"
s[0] = substr(s[0], 0, 2)

echo s[0]
