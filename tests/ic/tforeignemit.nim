discard """
  output: "5 6 2"
"""

# See mforeignemit.nim.
import mforeignemit

echo foreignEmitValue(), " ", foreignEmitGeneric(1), " ", foreignEmitHelped(1)
