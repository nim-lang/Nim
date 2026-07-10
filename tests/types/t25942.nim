discard """
  output: ""
"""

# see #25942
proc p(h: static set[bool]) = discard len(h)
p({})
p({false})
p({true, false})

discard card({})

proc q(h: static set[char]) = discard len(h)
q({})