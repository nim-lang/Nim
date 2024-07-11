discard """
  matrix: "--mm:arc; --mm:orc"
"""

import std/macros
import std/streams

# bug #22237

proc iterlines_closure2(f: File | Stream): iterator (): string =
  result = iterator(): string =
    for line in f.lines:
      if line.len == 0:
        break
      yield line

proc test() =
  let f = newStringStream("""
    1
    2

    3
    4

    5
    6
    7

    8
""")
  while not f.atEnd():
    let iterator_inst = iterlines_closure2(f)
    for item in iterator_inst(): # Fails with "SIGSEGV: Illegal storage access. (Attempt to read from nil?)"
      discard

test()

# bug #21160
import sequtils

iterator allMoves(fls: seq[int]): seq[int] =
  yield fls

proc neighbors(flrs: seq[int]): iterator: seq[int] =
  return iterator(): seq[int] =
    for flrs2 in allMoves(flrs):
      yield flrs2
      for flrs3 in allMoves(flrs2):
        yield flrs3

let f = @[1]
for _ in neighbors(f):
  discard
for _ in neighbors(f):
  discard
