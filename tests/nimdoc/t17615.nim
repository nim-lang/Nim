discard """
  cmd: "nim doc -r $file"
  errormsg: "runnableExamples must appear before the first non-comment statement"
  line: 10
"""
import std/assertions
func fn*() =
  ## foo
  discard
  runnableExamples:
    assert true
