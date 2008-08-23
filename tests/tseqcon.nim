# Test the &= operator for sequences and strings

type
  TRec {.final.} = object
    x, y: int
    s: string
    seq: seq[string]
  TRecSeq = seq[TRec]

proc test() =
  var seq, b: seq[string]
  seq = []
  add(seq, "Hi")
  add(seq, "there, ")
  add(seq, "what's your name?")

  b = seq # deep copying here!
  b[0][1] = 'a'

  for i in 0 .. length(seq)-1:
    write(stdout, seq[i])
  for i in 0 .. length(b)-1:
    write(stdout, b[i])


when defined(nestedFixed):
  proc nested() =
    var
      seq: seq[seq[string]]
    for i in 0..10_000: # test if the garbage collector
      # now works with sequences
      seq = [
        ["A", "B", "C", "D"],
        ["E", "F", "G", "H"],
        ["I", "J", "K", "L"],
        ["M", "N", "O", "P"]
      ]

test()
when defined(nestedFixed):
  nested()

#OUT Hithere, what's your name?Hathere, what's your name?
