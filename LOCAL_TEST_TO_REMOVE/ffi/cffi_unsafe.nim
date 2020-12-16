discard """
action: compile
"""
{.compile: "cffi.c"}

proc xx(): int {.importc.}

proc yy() =
  echo "yy"
  echo xx()

yy()
