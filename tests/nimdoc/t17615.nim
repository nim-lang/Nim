discard """
  cmd: "nim doc $file"
  action: "compile"
  nimout: "t17615.nim(11, 3) Warning: runnableExamples must appear before the first non-comment statement [User]"
  joinable: false
"""

func fn*() =
  ## foo
  discard
  runnableExamples:
    assert true
