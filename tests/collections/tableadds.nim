discard """
  output: '''done'''
"""

import tables

proc main =
  var tab = newTable[string, string]()
  for i in 0..1000:
    tab.add "key", "value " & $i

main()
echo "done"
