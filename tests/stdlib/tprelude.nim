discard """
  targets: "c js"
  matrix: "; -d:nimTestTpreludeCase1"
"""

when defined nimTestTpreludeCase1:
  include std/prelude
else:
  include prelude

template main() =
  doAssert toSeq(1..3) == @[1,2,3]
static: main()
main()
