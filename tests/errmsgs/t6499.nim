discard """
  errormsg: "'chr' is a built-in and cannot be used as a first-class procedure"
"""

# bug #6499
let x = (chr, 0)
