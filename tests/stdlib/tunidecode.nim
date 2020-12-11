discard """
  cmd: "nim $target --hints:on -d:embedUnidecodeTable $options $file"
"""

import unidecode

import std/unidecode # #14112

loadUnidecodeTable("lib/pure/unidecode/unidecode.dat")

doAssert unidecode("北京") == "Bei Jing "
doAssert unidecode("Äußerst") == "Ausserst"
