discard """
  targets: "c cpp"
"""

import marshal

let orig: set[char] = {'A'..'Z'}
let m = $$orig
let old = to[set[char]](m)
doAssert orig - old == {}
