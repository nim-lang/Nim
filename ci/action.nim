import std/[strutils, os, osproc, parseutils, strformat]


proc main() =
  var msg = ""
  const cmd = "./koch boot --gc:orc -d:release"

  let (output, exitCode) = execCmdEx(cmd)

  doAssert exitCode == 0, output

  let start = rfind(output, "Hint: mm")
  doAssert parseUntil(output, msg, "; proj", start) > 0, output

  let (commitHash, _) = execCmdEx("""git log --format="%H" -n 1""")

  let welcomeMessage = fmt"""Thanks for your hard work on this PR!
The lines below are statistics of the Nim compiler built from {commitHash}

{msg}
"""
  createDir "ci/nimcache"
  writeFile "ci/nimcache/results.txt", welcomeMessage

when isMainModule:
  main()
