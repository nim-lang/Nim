## Minimal repro for closure callback regression (extccomp.nim pattern).
##
## Pattern from extccomp.execCmdsInParallel (lines 877-895):
## - Proc takes callback param (prettyCb)
## - Inner closure (runCb) captures outer var (conf)
## - Closure passed to execProcesses which stores and invokes it asynchronously
##
## Run: nim c -r closure_callback_repro.nim
## With fix: should pass. Without fix: if regression, may crash when runCb uses conf.

import osproc

type
  Config = ref object
    projectName: string

proc rawMessage(conf: Config, msg: string) =
  echo "[", conf.projectName, "] ", msg

proc runWithCallback(conf: Config; cmds: seq[string];
    prettyCb: proc(idx: int) = nil): int =
  ## Same structure as execCmdsInParallel.
  let runCb = proc (idx: int, p: Process) =
    let exitCode = p.peekExitCode
    if exitCode != 0:
      rawMessage(conf, "command failed: " & cmds[idx])
  let n = min(2, cmds.len)
  if n <= 1:
    for i in 0..high(cmds):
      discard execProcess(cmds[i], options = {poStdErrToStdOut})
  else:
    return execProcesses(cmds, {poStdErrToStdOut, poUsePath, poParentStreams},
                         n, prettyCb, afterRunEvent = runCb)
  0

when isMainModule:
  var conf = Config(projectName: "test")
  let cmds = @["echo ok", "echo ok2"]
  let res = runWithCallback(conf, cmds, proc(idx: int) = discard)
  echo "result: ", res
