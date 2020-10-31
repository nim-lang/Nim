discard """
  nimout: '''t14407.nim(7, 3) Hint: 'v0.99' is declared but not used [XDeclaredButNotUsed]
t14407.nim(8, 3) Hint: 'v0.99.99' is declared but not used [XDeclaredButNotUsed]'''
"""

let
  `v0.99` = "0.99"
  `v0.99.99` = "0.99.99"
