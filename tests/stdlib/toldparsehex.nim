discard """
  matrix: "--d:nimLegacyParseInts"
"""

import std/strutils

doAssert parseHexInt("0xFFFFFFFFFFFFFFFF") == -1
doAssert parseHexInt("0xFF00FFFFFFFFFFFFFFFFFF") == -1
