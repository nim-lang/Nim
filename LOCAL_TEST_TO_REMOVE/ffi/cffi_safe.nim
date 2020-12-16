discard """
action: reject
"""
{.compile: "cffi.c"}

proc xx(): int {.importc.}

proc yy() {.memSafe.}=
  echo "yy"
  echo xx()

yy()
