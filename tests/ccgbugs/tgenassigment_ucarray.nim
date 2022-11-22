discard """
  matrix: "--mm:arc; --mm:orc"
"""

type
  OObj {.byref.} = object
    case bbool: bool
    of false: discard
    of true:
      sstr: string
      aarr: UncheckedArray[char]

var o: ref OObj
new o
o[] = OObj(bbool: true, sstr: "1234")
