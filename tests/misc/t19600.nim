discard """
  targets: "c cpp"
  disabled: "win"
  disabled: "osx"
  exitcode: 1
  outputsub: "No space left on device"
"""

writeFile("/dev/full", "hello\n")
