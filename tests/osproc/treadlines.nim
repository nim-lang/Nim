discard """
  output: '''
Error: cannot open 'a.nim'
Error: cannot open 'b.nim'
'''
  targets: "c"
"""

import osproc
from std/os import getCurrentCompilerExe

var ps: seq[Process] # compile & run 2 progs in parallel
const nim = getCurrentCompilerExe()
for prog in ["a", "b"]:
  ps.add startProcess(nim, "",
                      ["r", "--hint:Conf:off", "--hint:Processing:off", prog],
                      options = {poUsePath, poDaemon, poStdErrToStdOut})

for p in ps:
  let (lines, exCode) = p.readLines
  if exCode != 0:
    for line in lines: echo line
  p.close
