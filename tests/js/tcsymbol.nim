discard """
  matrix: "--cc:gcc; --cc:tcc"
"""

doAssert not defined(gcc)
doAssert not defined(tcc)