discard """
  nimout: '''tannot.nim(9, 1) Warning: efgh; foo1 is deprecated [Deprecated]
tannot.nim(9, 8) Warning: abcd; foo is deprecated [Deprecated]
'''
"""

let foo* {.deprecated: "abcd".} = 42
var foo1* {.deprecated: "efgh".} = 42
foo1 = foo
