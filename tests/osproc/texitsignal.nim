discard """
  output: '''true
true'''
  targets: "c"
"""

import os, osproc
when not defined(windows):
  import posix

# Checks that the environment is passed correctly in startProcess
# To do that launches a copy of itself with a new environment.

if paramCount() == 0:
  # Parent process

  let p = startProcess(
    getAppFilename(),
    args = @["child"],
    options = {poStdErrToStdOut, poUsePath, poParentStreams}
  )

  echo p.running()

  p.kill()

  when defined(windows):
    # windows kill happens using TerminateProcess(h, 0), so we should get a
    # 0 here
    echo p.waitForExit() == 0
  elif defined(haiku):
    # on Haiku, the program main thread receive SIGKILLTHR
    echo p.waitForExit() == 128 + SIGKILLTHR
  else:
    # on posix (non-windows), kill sends SIGKILL
    echo p.waitForExit() == 128 + SIGKILL

else:
  sleep(5000)  # should get killed before this
