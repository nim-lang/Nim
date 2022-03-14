discard """
  matrix: "--cc:gcc; --cc:tcc"
"""
import std/assertions
doAssert not defined(gcc)
doAssert not defined(tcc)