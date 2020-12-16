discard """
action: compile
"""
proc xx() {.memUnsafe.} =
  echo "xx"
proc yy() {.memSafe.} =
  echo "yy"
  xx()

yy()
