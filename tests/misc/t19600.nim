discard """
  targets: "c cpp"
  disabled: "win"
  disabled: "osx"
  disabled: "linux"
  exitcode: 1
  outputsub: "No space left on device"
"""

writeFile("/dev/full", "hello\n")
