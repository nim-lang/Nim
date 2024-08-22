discard """
  output: '''true
true'''
"""

import std/osproc

const command = "lsaaa -lah"

try:
  let process = startProcess(command, options = {poUsePath})
  discard process.waitForExit()
except OSError as e:
  echo e.errorCode != 0

# `poEvalCommand`, invokes the system shell to run the specified command
try:
  let process = startProcess(command, options = {poUsePath, poEvalCommand})
  let exitCode = process.waitForExit()
  echo exitCode != 0
except OSError as e:
  doAssert false, "after #24000 is merged, this will no longer throw an exception"
