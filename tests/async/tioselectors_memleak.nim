discard """
  cmd: "nim c -r --threads:on -d:threadsafe --mm:orc $file"
  output: "0"
"""

import selectors

let before = getOccupiedSharedMem()

block:
  let selector = newSelector[int]()
  selector.close()

echo getOccupiedSharedMem() - before
