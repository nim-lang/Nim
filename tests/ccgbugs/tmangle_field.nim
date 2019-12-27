discard """
"""

# bug #5404

import parseopt

{.emit: """typedef struct {
    int key;
} foo;""".}

type foo* {.importc: "foo", nodecl.} = object
  key* {.importc: "key".}: cint

for kind, key, value in parseopt.getopt():
  discard
