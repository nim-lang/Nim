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
    let expected = "(i: $#) <= (n: $#)" % [$len(s), $(len(s)-1)]
    doAssert msg.contains expected, $(msg, expected)

block:
  try:
    discard paramStr(999)
  except IndexError:
    let msg = getCurrentExceptionMsg()
    let expected = "(i: 999) <= (n: 0)"
    doAssert msg.contains expected

block:
  const nim = getCurrentCompilerExe()
  for i in 1..4:
    let (outp, errC) = execCmdEx("$# e tests/exception/testindexerroroutput.nims test$#" % [nim, $i])
    let expected = "(i: 3) <= (n: 2)"
    doAssert errC != 0
    doAssert outp.contains expected, $(outp, errC, expected, i)
