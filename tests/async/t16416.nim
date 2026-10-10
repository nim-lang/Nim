discard """
  output: '''done'''
"""
# Issue #16416: Can't call closure iterator from inside an async function
# https://github.com/nim-lang/Nim/issues/16416

import asyncdispatch

iterator x(): int {.closure.} =
  yield 1

proc y() {.async.} =
  for z in x():
    discard

waitFor y()
echo "done"
