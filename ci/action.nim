import std/[strutils, os, osproc, strformat]


proc main() =
  var msg = ""
  const cmd = "./koch boot --mm:orc -d:release"

  let (output, exitCode) = execCmdEx(cmd)

  doAssert exitCode == 0, output

  let start = rfind(output, "Hint: codegen mm")
  doAssert start >= 0, "Could not find compiler success summary in koch output:\n" & output
  let finish = find(output, "; proj:", start)
  doAssert finish > start, "Could not find end of compiler success summary in koch output:\n" & output
  msg = output[start ..< finish]

  let (commitHash, _) = execCmdEx("""git log --format="%H" -n 1""")

  let welcomeMessage = fmt"""Thanks for your hard work on this PR!
The lines below are statistics of the Nim compiler built from {commitHash}

{msg}
"""
  createDir "ci/nimcache"
  writeFile "ci/nimcache/results.txt", welcomeMessage

when isMainModule:
  main()
