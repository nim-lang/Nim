discard """
  output: '''0
0'''
"""

# test another strange bug ... (I hate this compiler; it is much too buggy!)

proc putEnv(key, val: string) =
  # XXX: we have to leak memory here, as we cannot
  # free it before the program ends (says Borland's
  # documentation)
  var
    env: ptr array[0..500000, char]
  env = cast[ptr array[0..500000, char]](alloc(len(key) + len(val) + 2))
  for i in 0..len(key)-1: env[i] = key[i]
  env[len(key)] = '='
  for i in 0..len(val)-1:
    env[len(key)+1+i] = val[i]

# bug #7153
const
  UnsignedConst = 1024'u
type
  SomeObject* = object
    s1: array[UnsignedConst, uint32]

var
  obj: SomeObject

echo obj.s1[0]
echo obj.s1[0u]
