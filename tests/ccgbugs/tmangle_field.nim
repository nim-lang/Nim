discard """
"""

# bug #5404

import parseopt2

{.emit: """typedef struct {
    int key;
} foo;""".}

type foo* {.importc: "foo", nodecl.} = object
  key* {.importc: "key".}: cint

for kind, key, value in parseopt2.getopt():
  discard
