discard """
  file: "tseqcon.nim"
  output: "Hithere, what\'s your name?Hathere, what\'s your name?"
"""
# Test the add proc for sequences and strings

const
  nestedFixed = true

type
  TRec {.final.} = object
    x, y: int
    s: string
    seq: seq[string]
  TRecSeq = seq[TRec]

proc test() =
  var s, b: seq[string]
  s = @[]
  add(s, "Hi")
  add(s, "there, ")
  add(s, "what's your name?")

  b = s # deep copying here!
  b[0][1] = 'a'

  for i in 0 .. len(s)-1:
    write(stdout, s[i])
  for i in 0 .. len(b)-1:
    write(stdout, b[i])


when nestedFixed:
  proc nested() =
    var
      s: seq[seq[string]]
    for i in 0..10_000: # test if the garbage collector
      # now works with sequences
      s = @[
        @["A", "B", "C", "D"],
        @["E", "F", "G", "H"],
        @["I", "J", "K", "L"],
        @["M", "N", "O", "P"]]

test()
when nestedFixed:
  nested()

#OUT Hithere, what's your name?Hathere, what's your name?


