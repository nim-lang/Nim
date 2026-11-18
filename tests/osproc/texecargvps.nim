discard """
joinable: false
"""

# `execArgvProcesses` runs argvs in parallel without a shell: each argument
# reaches the program exactly as given (a shell would have expanded `$HOME`
# and split `a b`), the highest exit code is returned, and an empty argv is
# refused. `execProcesses` shares its scheduler and is covered by texecps.

import std/[osproc, streams, strutils, os]

when defined(nimPreviewSlimSystem):
  import std/assertions

if paramCount() >= 1:
  # Child mode: print the arguments after the first, then exit with the
  # first.
  stdout.write commandLineParams()[1..^1].join("|")
  quit parseInt(paramStr(1))

var outputs = newSeq[string](3)
let me = getAppFilename()
let cmds = @[@[me, "0", "a b", "$HOME", ""], @[me, "2", "`x`"],
  @[me, "1", "it's"]]
for n in [1, 2, 3]:
  let worst = execArgvProcesses(cmds, options = {poStdErrToStdOut}, n = n,
    afterRunEvent = proc (idx: int, p: Process) =
      outputs[idx] = p.outputStream.readAll())
  doAssert worst == 2, $worst
  doAssert outputs == @["a b|$HOME|", "`x`", "it's"], $outputs

doAssertRaises(ValueError):
  discard execArgvProcesses([newSeq[string]()], n = 1)
