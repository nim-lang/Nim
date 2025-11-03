discard """
  matrix: "-d:nimPreviewStrictVarRange"
"""

# issue #24032

proc `++`(n: var int) =
  n += 1

type
  r = range[ 0..15 ]

var a: r = 15

++a #[tt.Error
^ type mismatch: got <r>]#

echo a
