discard """
  targets: "c cpp"
  matrix: "--mm:arc; --mm:orc"
"""

import std/assertions

when defined(musl):
  import std/syncio

  type Wrapper = object
    file: File

  doAssert repr(stdout) == $typeof(stdout) & "()"
  doAssert repr(Wrapper(file: stdout)) ==
    "Wrapper(file: " & $typeof(stdout) & "())"
  doAssert repr(File(nil)) == "nil"

when defined(posix):
  import std/posix

  block:
    let directory = opendir(".")
    doAssert directory != nil
    defer: discard closedir(directory)
    doAssert repr(directory) == $typeof(directory) & "()"
