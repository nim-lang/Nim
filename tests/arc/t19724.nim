discard """
  matrix: "--mm:arc --sinkInference:on"
"""

import std/[os, sequtils]

proc main = 
  let saves = @["/path/to/file.txt"].map(extractFilename)
  doAssert saves == @["file.txt"]

  proc foo(x: sink string): string = x & "def"
  doAssert @["abc"].map(foo) == @["abcdef"]

main()
