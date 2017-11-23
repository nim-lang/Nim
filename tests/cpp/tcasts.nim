discard """
  cmd: "nim cpp $file"
  output: ""
"""

block: #5979
  var a = 'a'
  var p: pointer = cast[pointer](a)
  var c = cast[char](p)
  doAssert(c == 'a')
