discard """
  matrix: "--mm:orc; --mm:orc -d:release; --mm:refc; --mm:arc -d:release"
  output: '''xxxx
ABCD
zzzz
abxx
LMxx
abxx
abcdef
abcd
394
bbbb
wxxx
qqqq'''
"""

# The `nimPrepareStrMutationV2` call that guards `s[i] = v` is hoisted in front
# of a loop when the loop only ever touches `s` as `s[...]`, so that the loop
# body contains no call and the C compiler can vectorize it (#26118).
# Everything below checks that the hoist does not fire when something in the
# loop -- or in the loop condition -- can put a string literal back into `s`.

proc setLit(s: var string) = s = "LMNO"

proc plain(): string =
  result = newString(4)
  for i in 0..3: result[i] = 'x'

proc fromLiteral(): string =
  var s = "abcd"                  # literal payload: has to be copied once
  for i in 0..3: s[i] = char(ord('A') + i)
  result = s

proc lenInBound(): string =
  var s = "abcd"
  for i in 0 ..< s.len: s[i] = 'z'
  result = s

proc reassignedInLoop(): string =
  var s = newString(4)
  for i in 0..3:
    s[i] = 'x'
    if i == 1: s = "abcd"         # whole assignment inside the loop
  result = s

proc varArgInLoop(): string =
  var s = newString(4)
  for i in 0..3:
    s[i] = 'x'
    if i == 1: setLit(s)          # `var` argument inside the loop
  result = s

proc addrInLoop(): string =
  var s = newString(4)
  for i in 0..3:
    s[i] = 'x'
    if i == 1:
      let p = addr s
      p[] = "abcd"
  result = s

proc nested(): string =
  result = newString(6)
  for i in 0..1:
    for j in 0..2:
      result[i*3 + j] = char(ord('a') + i*3 + j)

proc zeroTrip(): string =
  var s = "abcd"
  for i in 0 ..< 0: s[i] = 'q'    # never runs; must not corrupt the literal
  result = s

proc readOnlyLiteral(): int =
  let s = "abcd"
  for i in 0..3: result += ord(s[i])   # only read: must not copy

proc mixedReadWrite(): string =
  var s = newString(4)
  for i in 0..3:
    s[i] = 'a'
    if s[i] == 'a': s[i] = 'b'
  result = s

proc whileCondTouches(): string =
  var s = newString(4)
  var i = 0
  while (if i == 2: (s = "wxyz"; true) else: i < 4):
    s[i] = 'x'
    inc i
    if i >= 4: break
  result = s

iterator viaClosure(): char {.closure.} =
  var s = "abcd"
  for i in 0..3:
    s[i] = 'q'
    yield s[i]

proc closureIter(): string =
  result = ""
  for c in viaClosure(): result.add c

echo plain()
echo fromLiteral()
echo lenInBound()
echo reassignedInLoop()
echo varArgInLoop()
echo addrInLoop()
echo nested()
echo zeroTrip()
echo readOnlyLiteral()
echo mixedReadWrite()
echo whileCondTouches()
echo closureIter()
