discard """
  output: '''Error: cannot open 'a.nim'
Error: cannot open 'b.nim'
'''
  targets: "c"
"""

import osproc

const opts = {poUsePath, poDaemon, poStdErrToStdOut}

var ps: seq[Process] # compile & run 2 progs in parallel
for prog in ["a", "b"]:
  ps.add startProcess("nim", "", ["r", prog], nil, opts)

for p in ps:
  let (lines, exCode) = p.readLines
  if exCode != 0:
    for line in lines: echo line
  p.close
