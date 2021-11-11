discard """
  disabled: "win"
  targets: "c"
"""

proc main =
  setNonBlocking(stdin)
  doAssert(endOfFile(stdin))

main()
