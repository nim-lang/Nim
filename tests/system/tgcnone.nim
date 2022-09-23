discard """
  matrix: "--gc:none -d:useMalloc --threads:off"
"""
# bug #15617
let x = 4
doAssert x == 4
