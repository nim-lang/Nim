discard """
action: compile
"""

import os

# bug #3636

proc fooIt(foo: string): iterator(): (string) =
  iterator temp(): (string) =
    for f in walkDirRec(foo): # No problem with walkFiles
      yield f
  return temp

let it = fooIt(".")
for x in it():
  echo x
