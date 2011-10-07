discard """
  cmd: "nimrod cc --hints:on -d:embedUnidecodeTable $# $#"
  output: "Ausserst"
"""

import unidecode

unidecode("Äußerst")

