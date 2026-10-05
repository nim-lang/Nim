# Helper for tmethitanium: an override in a DIFFERENT module than the base, plus
# a `procCall` super-reference to the base from this non-owner module. That
# cross-module reference to the base impl is what diverged from the base's
# definition name under the per-module Itanium mangling.

import mmethanimal

type Dog* = ref object of Animal

method speak*(a: Dog): string =
  "woof"

proc speakBoth*(a: Dog): string =
  procCall(speak(Animal(a))) & "/" & speak(a)
