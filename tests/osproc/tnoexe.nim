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

let process = startProcess(command, options = {poUsePath, poEvalCommand})
let exitCode = process.waitForExit()
echo exitCode != 0
