discard """
  file: "tseqtuple.nim"
  output: "fA13msg1falsefB14msg2truefC15msg3false"
"""

type
  TMsg = tuple[
    file: string,
    line: int,
    msg: string,
    err: bool]

var s: seq[TMsg] = @[]

s.add(("fA", 13, "msg1", false))
s.add(("fB", 14, "msg2", true))
s.add(("fC", 15, "msg3", false))

for file, line, msg, err in items(s):
  stdout.write(file)
  stdout.write($line)
  stdout.write(msg)
  stdout.write($err)

#OUT fA13msg1falsefB14msg2truefC15msg3false



