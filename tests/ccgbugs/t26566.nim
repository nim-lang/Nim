discard """
  matrix: "--mm:refc"
  ccodecheck: "\\i @('nimZeroMem(((void*) ((&colontmpD_)))')"
  output: '''
ok
'''
"""

# bug #26566: the temporary of a value producing 'try' must be initialized
# with refc: the callee resets it before it writes to it

type A = object
  case k: uint8
  of 0xF0: s: string
  else: discard

proc g(): A = discard

proc f(x: bool): A =
  defer: discard
  if x: return A()
  g()

proc fill() =
  var b: array[256, byte]
  for i in 0 ..< b.len: b[i] = 0xF0
  doAssert b[17] == 0xF0

proc main() =
  fill()
  let a = f(false)
  doAssert a.k == 0
  echo "ok"

main()
