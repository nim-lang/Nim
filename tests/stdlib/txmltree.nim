discard """
  file: "txmltree.nim"
  output: "true"
"""

import xmltree, strtabs

var x = <>a(href="nim.de", newText("www.nim-test.de"))

echo($x == "<a href=\"nim.de\">www.nim-test.de</a>")



