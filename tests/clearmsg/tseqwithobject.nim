discard """
  file: "tseqwithobject.nim"
  line: 8
  errormsg: "'object' cannot be used as 'seq' parameter."
"""
# issue #3069

var x: seq[object] = @[]
