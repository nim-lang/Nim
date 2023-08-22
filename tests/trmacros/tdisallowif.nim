discard """
  errormsg: "usage of 'disallowIf' is an {.error.} defined at tdisallowif.nim(10, 1)"
  line: 24
"""

template optZero{x+x}(x: int): int = x*3
template andthen{`*`(x,3)}(x: int): int = x*4
template optSubstr1{x = substr(x, 0, b)}(x: string, b: int) = setlen(x, b+1)

template disallowIf{
  if cond: action
  else: action2
}(cond: bool, action, action2: typed) {.error.} = action

var y = 12
echo y+y

var s: array[0..2, string]
s[0] = "hello"
s[0] = substr(s[0], 0, 2)

echo s[0]

if s[0] != "hi":
  echo "do it"
  echo "more branches"
else:
  discard
