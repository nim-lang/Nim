discard """
  cmd: "nimrod cc --hints:on -d:embedUnidecodeTable $# $#"
  output: "Ausserst"
"""

import unidecode

assert unidecode("\\x53\\x17\\x4E\\xB0") == "Bei Jing"
echo unidecode("Äußerst")

