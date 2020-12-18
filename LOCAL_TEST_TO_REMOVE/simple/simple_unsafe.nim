discard """
action: compile
"""
static: echo "########################"

proc xx() {.memUnsafe.} =
  echo "xx"
proc yy() =
  echo "yy"
  xx()

yy()
