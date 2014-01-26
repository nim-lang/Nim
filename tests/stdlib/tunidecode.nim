discard """
  cmd: "nimrod cc --hints:on -d:embedUnidecodeTable $# $#"
  output: "Ausserst"
"""

import unidecode

loadUnidecodeTable("lib/pure/unidecode/unidecode.dat")

#assert unidecode("\x53\x17\x4E\xB0") == "Bei Jing"
echo unidecode("Äußerst")

