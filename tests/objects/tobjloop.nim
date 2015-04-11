discard """
  output: "is Nil false"
"""
# bug #1658

type
  Loop* = ref object
    onBeforeSelect*: proc (L: Loop)

var L: Loop
new L
L.onBeforeSelect = proc (bar: Loop) =
  echo "is Nil ", bar.isNil

L.onBeforeSelect(L)
