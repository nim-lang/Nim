import os, osproc, strutils

const characters = "abcdefghijklmnopqrstuvwxyz"
var s: string

# # chcks.nim:23
# # test formatErrorIndexBound returns correct bounds
block:
  s = characters
  try:
    discard s[0..999]
  except IndexError:
    let msg = getCurrentExceptionMsg()
    let expected = "index $# not in 0 .. $#" % [$len(s), $(len(s)-1)]
    doAssert msg.contains expected, $(msg, expected)

block:
  try:
    discard paramStr(999)
  except IndexError:
    let msg = getCurrentExceptionMsg()
    let expected = "index 999 not in 0 .. 0"
    doAssert msg.contains expected, $(msg, expected)

block:
  const nim = getCurrentCompilerExe()
  for i in 1..4:
    let (outp, errC) = execCmdEx("$# e tests/exception/testindexerroroutput.nims test$#" % [nim, $i])
    let expected = "index 3 not in 0 .. 2"
    doAssert errC != 0
    doAssert outp.contains expected, $(outp, errC, expected, i)
