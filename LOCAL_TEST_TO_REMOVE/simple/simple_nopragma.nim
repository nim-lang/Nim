discard """
action: compile
"""
static: echo "########################"

proc xx() =
  echo "xx"

proc yy() {.memSafe.} =
  echo "yy"
  xx()

yy()
