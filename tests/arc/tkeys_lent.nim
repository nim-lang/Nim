discard """
  output: '''{"string": 2}'''
  cmd: "nim c --gc:orc $file"
"""

import tables

proc use(x: int) = echo x

proc main =
  var tab = {"string": 1}.toTable
  for keyAAA in tab.keys():
    template alias(): untyped = tab[keyAAA]
    alias() = 2
  echo tab

main()
