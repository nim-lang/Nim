discard """
  targets: "c cpp"
"""

import marshal
import std/assertions

template main() =
  let orig: set[char] = {'A'..'Z'}
  let m = $$orig
  let old = to[set[char]](m)
  doAssert orig - old == {}

static: main()
main()
