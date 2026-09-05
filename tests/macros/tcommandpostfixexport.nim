discard """
  output: ""
"""

import mcommandpostfixexport

let x = Thing(value: 3)
doAssert x.value == 3

let y = Other(value: 4)
doAssert y.value == 4

let z = Spaced(value: 5)
doAssert z.value == 5

let userIdSet = UserIdSet(value: 6)
doAssert userIdSet.value == 6
