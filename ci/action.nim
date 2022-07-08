import std/[strutils, os, osproc, parseutils, strformat]


proc main() =
  var msg = ""
  const cmd = "koch boot --gc:orc -d:release"

  let (output, exitCode) = execCmdEx(cmd)

  doAssert exitCode == 0, output

  var start = rfind(output, "Hint: gc")
  if start < 0:
    start = rfind(output, "Hint: mm")
  doAssert parseUntil(output, msg, "; proj", start) > 0, output

  let welcomeMessage = fmt"""Thanks for your hard work on this PR!
The lines below are statistics for the compiler built from your commits:

{msg}
"""
  createDir "ci/nimcache"
  writeFile "ci/nimcache/results.txt", welcomeMessage

when isMainModule:
  main()