discard """
  matrix: "--embedsrc=on"
"""

proc trim() =
  let s = 10
  let x = s + 5 # user entered literal \
trim()