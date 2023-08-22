discard """
cmd: "nim check $file"
"""
type
  ABCD = enum A, B, C, D
  AliasABCD = ABCD
  RangeABC = range[A .. C]
  AliasRangeABC = RangeABC
  PrintableChars = range[' ' .. '~']

case PrintableChars 'x': #[tt.Error
^ not all cases are covered; missing: {' ', '!', '\"', '#', '$$', '%', '&', '\'', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', '\\', ']', '^', '_', '`', '{', '|', '}', '~'}]#
of '0'..'9', 'A'..'Z', 'a'..'z': discard
of '(', ')': discard

case AliasABCD A: #[tt.Error
^ not all cases are covered; missing: {B, C, D}]#
of A: discard

case RangeABC A: #[tt.Error
^ not all cases are covered; missing: {A, C}]#
of B: discard

case AliasRangeABC A: #[tt.Error
^ not all cases are covered; missing: {A, B}]#
of C: discard
