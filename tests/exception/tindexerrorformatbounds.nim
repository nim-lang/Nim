import os
import strutils


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
    let expected = "(i:$#) <= (n:$#)" % [$len(s), $(len(s)-1)]
    doAssert msg.contains expected

block:
  try:
    discard paramStr(999)
  except IndexError:
    let msg = getCurrentExceptionMsg()
    let expected = "(i:999) <= (n:1)"
    doAssert msg.contains expected

static:
  const nim = getCurrentCompilerExe()

  block:
    let ret = gorgeEx(nim & " e testindexerroroutput.nims test1")
    let expected = "(i:3) <= (n:2)"
    doAssert ret.exitCode != 0
    doAssert ret.output.contains expected

  block:
    let ret = gorgeEx(nim & " e testindexerroroutput.nims test2")
    let expected = "(i:3) <= (n:2)"
    doAssert ret.exitCode != 0
    doAssert ret.output.contains expected

  block:
    let ret = gorgeEx(nim & " e testindexerroroutput.nims test3")
    let expected = "(i:3) <= (n:2)"
    doAssert ret.exitCode != 0
    doAssert ret.output.contains expected

  block:
    let ret = gorgeEx(nim & " e testindexerroroutput.nims test4")
    let expected = "(i:3) <= (n:2)"
    doAssert ret.exitCode != 0
    doAssert ret.output.contains expected
