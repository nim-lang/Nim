discard """
  output: '''
Error: cannot open 'nonexistant_a.nim'\31
Error: cannot open 'nonexistant_b.nim'\31
'''
  targets: "c"
"""

import osproc
from std/os import getCurrentCompilerExe

var ps: seq[Process] # compile & run 2 progs in parallel
const nim = getCurrentCompilerExe()
for prog in ["nonexistant_a", "nonexistant_b"]:
  ps.add startProcess(nim, "",
                      ["r", "--hints:off", prog],
                      options = {poUsePath, poDaemon, poStdErrToStdOut})

for p in ps:
  let (lines, exCode) = p.readLines
  if exCode != 0:
    for line in lines: echo line
  p.close
