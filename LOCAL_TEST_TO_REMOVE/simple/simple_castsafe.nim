discard """
action: compile
"""
static: echo "########################"

proc xx() {.memUnsafe.} =
  echo "xx"

proc yy() {.memSafe.} =
  {.cast(memSafe).}:
    echo "yy"
    xx()

yy()
