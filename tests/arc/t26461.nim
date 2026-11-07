discard """
  matrix: "--mm:arc; --mm:orc"
  output: '''
block OKAY: v=[1234567890] body=[ok:1234567890]
try   OKAY: v=[1234567890] body=[ok:1234567890]
if    OKAY: v=[1234567890] body=[ok:1234567890]
case  OKAY: v=[1234567890] body=[ok:1234567890]
while OKAY: v=[1234567890] body=[ok:1234567890]
'''
"""

# bug #26461: a variable must not become a cursor into a temporary
# that is destroyed at the end of a nested scope

import std/options

const expect = "ok:1234567890"
proc check(label, v, body: string) =
  var status = "OKAY"
  if v != "1234567890" or body != expect:
    status = "CORRUPTED"
  echo label, " ", status, ": v=[", v, "] body=[", body, "]"

proc getValue(a = 8, b = 90): Option[string] =
  result = some("1234567" & $a & $b)

proc blockTest(label: string) =
  var v: string
  block:
    v = getValue().get()
  let body = "ok:" & v
  check(label, v, body)

proc tryTest(label: string) =
  var v: string
  try:
    v = getValue().get()
  finally:
    discard
  let body = "ok:" & v
  check(label, v, body)

proc ifTest(label: string) =
  var v: string
  var flag = true
  if flag:
    v = getValue().get()
  let body = "ok:" & v
  check(label, v, body)

proc caseTest(label: string) =
  var v: string
  var x = 1
  case x
  of 1:
    v = getValue().get()
  else: discard
  let body = "ok:" & v
  check(label, v, body)

proc whileTest(label: string) =
  var v: string
  var i = 0
  while i < 1:
    v = getValue().get()
    inc i
  let body = "ok:" & v
  check(label, v, body)

blockTest("block")
tryTest("try  ")
ifTest("if   ")
caseTest("case ")
whileTest("while")
