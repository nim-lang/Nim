discard """
  file: "txmltree.nim"
  output: "true"
"""

import xmltree, strtabs

var x = <>a(href="nimrod.de", newText("www.nimrod-test.de"))

echo($x == "<a href=\"nimrod.de\">www.nimrod-test.de</a>")



