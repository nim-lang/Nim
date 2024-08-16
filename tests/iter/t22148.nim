discard """
  action: compile
"""

import std/memfiles

# bug #22148
proc make*(input: string) =
  var inp = memfiles.open(input)
  for line in memSlices(inp):
    let lineF = MemFile(mem: line.data, size: line.size)
    for word in memSlices(lineF, ','):
      discard

make("") # Must call to trigger
