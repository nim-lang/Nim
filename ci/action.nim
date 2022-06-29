import std/[strformat, os, times, strutils]

proc bench(body: proc()): float =
  let t = epochTime()
  body()
  result = epochTime() - t

proc main() =
  let dir = getTempDir()
  echo dir
  var msg = ""
  let cmd = "nim c -d:release compiler/nim.nim"
  let dt = bench(proc() = doAssert execShellCmd(cmd) == 0)
  msg.add &"build compiler => t: {dt}\n"
  writeFile "ci/results.txt", msg

when isMainModule:
  main()