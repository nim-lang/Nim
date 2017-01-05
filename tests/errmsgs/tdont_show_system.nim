discard """
  errormsg: "value of type 'bool' has to be discarded"
  line: 13
  file: "tdont_show_system.nim"
"""

# bug #4308

#proc getGameTile: int =
#  1 > 0

# bug #4905  subsumes the problem of #4308:
true notin {false}
