discard """
  file: "passenv.nim"
  output: "123"
  targets: "c cpp objc"
"""

import osproc, os, strtabs

# Checks that the environment is passed correctly in startProcess
# To do that launches a copy of itself with a new environment.

if paramCount() == 0:
  # Parent process

  let env = newStringTable()
  env["A"] = "1"
  env["B"] = "2"
  env["C"] = "3"

  let p = startProcess(
    getAppFilename(),
    args = @["child"],
    env = env,
    options = {poStdErrToStdOut, poUsePath, poParentStreams}
  )

  discard p.waitForExit

else:
  # Child process
  # should output "123"
  echo getEnv("A") & getEnv("B") & getEnv("C")
