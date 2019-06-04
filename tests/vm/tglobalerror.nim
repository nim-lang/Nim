discard """
  errormsg: "'global' variables not allowed at compile time; id"
  line: 7
"""

proc unique: int =
  var id {.global.} = 0
  result = id
  id += 1

const x = unique()

echo x
