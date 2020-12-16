discard """
action: compile
"""

proc xx() {.memUnsafe.} =
  echo "xx"
proc yy() =
  echo "yy"
  xx()

yy()
