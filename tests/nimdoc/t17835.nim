discard """
  cmd: "nim doc $file"
  action: "compile"
  nimout: "t17835.nim(10, 3) Warning: runnableExamples must appear before the first non-comment statement [User]"
  joinable: false
"""

template anyIt(): bool =
  ## 123
  runnableExamples:
    echo 123
  true

proc foo*(n: seq[int]): bool =
  result = anyIt()
