#[
Usage:
this will print out unique types, the number of calls to new, the types size, and the total bytes for that type

nim c -o:bin/nim_temp1 -d:release -d:nimWithStatsTypes compiler/nim.nim
bin/nim_temp1 c -o:bin/nim_temp1 -d:release -d:nimWithStatsTypes compiler/nim.nim
bin/nim_temp1 c -o:bin/nim_temp1 -d:release -d:nimWithStatsTypes compiler/nim.nim #(yes, we need to call it a 2nd time)
]#

import system/stats_types_new

import std/os
import std/strformat
import std/algorithm

import compiler/asciitables

proc numBytes(a: SysCounter): int = a.size * a.count
proc toStr(result: var string, bytesTot: var int,  a: SysCounter) =
  let bytes = a.numBytes
  bytesTot += bytes
  result.add &"{$a.name}\tc: {a.count}\ts: {a.size}\tb: {bytes}"

proc showStats*() {.noconv.} =
  var bytesTot = 0
  var ret = ""
  var s: seq[SysCounter]
  for i in 0..<sysCountersLen:
    s.add sysCounters[i]
  proc fun(a, b: SysCounter): int = b.numBytes - a.numBytes
  s = s.sorted(fun)
  for i in 0..<s.len:
    ret.add "  " & $i & " "
    ret.toStr(bytesTot, s[i])
    ret.add "\n"
  var pid = 0
  when not defined(nimscript):
    pid = getCurrentProcessId()
  # ret = ret.alignTableCustom
  ret = ret.alignTable
  ret = &"stats pid: {pid}: num: {sysCountersLen} tot: {bytesTot} \n{ret}"
  when not defined(nimscript) and not defined(js):
    write(stderr, ret) # already ends in "\n", no need to add
  else:
    echo ret

when nimvm:
  discard
  # TODO: Error: cannot 'importc' variable at compile time; addQuitProc
else:
  addQuitProc(showStats)
