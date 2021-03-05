discard """
  targets: "c cpp js"
"""

import std/[json, isolation]


proc main() =
  var x: seq[Isolated[JsonNode]]
  x.add isolate(newJString("1234"))

  doAssert $x == """@[(value: "1234")]"""


static: main()
main()
