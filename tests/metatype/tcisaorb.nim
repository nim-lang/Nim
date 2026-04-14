discard """
  action: "compile"
"""
import deps/cisaorb

when true:
  # These work fine.
  discard default(cisaorb.A)
  proc f1(x: cisaorb.A) = discard
  discard default(cisaorb.B)
  proc f2(x: cisaorb.B) = discard
  discard default(A)
  proc f3(x: A) = discard
  discard default(B)
  proc f4(x: B) = discard
  proc f5(x: C) = discard
  proc f6(x: cisaorb.C | C) = discard

proc doesWork(x: A | B) = discard

# Doesn't compile.
proc f(x: cisaorb.C) = discard
