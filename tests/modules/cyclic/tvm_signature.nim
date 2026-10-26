discard """
  joinable: false
  output: '''
6
6
9
6 6
'''
"""

# The signatures need the VM to run routines of the group whose bodies are
# still deferred (by the declaration phase); the VM demands them.
import vmsig/mvm_signature {.cyclic.}

proc helper2*(): int = 3
proc helper*(): int =
  const c = 2 # a constant inside of the demanded body
  result = helper2() * c
proc user*(x: array[helper(), int]): int = x.len
proc withDefault*(x: static int = helper()): int = x
proc gen*[T](x: T; y: array[helper(), int]): int = y.len

var z: array[6, int]
echo user(z)
echo withDefault()
var w: array[9, int]
echo partnerUser(w)
echo gen(1, z), " ", useGen()
