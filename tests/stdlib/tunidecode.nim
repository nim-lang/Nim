discard """
  cmd: "nim $target --hints:on -d:embedUnidecodeTable $options $file"
  output: "Ausserst"
"""

import unidecode

import std/unidecode # #14112

loadUnidecodeTable("lib/pure/unidecode/unidecode.dat")

#assert unidecode("\x53\x17\x4E\xB0") == "Bei Jing"
echo unidecode("Äußerst")

