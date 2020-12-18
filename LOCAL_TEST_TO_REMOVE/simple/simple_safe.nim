discard """
action: compile
"""
static: echo "#####################"


proc xx() {.memUnsafe.} =
  echo "xx"

proc yy() =
  echo "yy"
  xx()

proc zz() {.memSafe.} =
  echo "zz"
  yy()

zz()
