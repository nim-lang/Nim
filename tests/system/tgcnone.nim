discard """
  matrix: "--mm:none -d:useMalloc"
"""
# bug #15617
# bug #22262
let x = 4
doAssert x == 4
