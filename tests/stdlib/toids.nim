discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/oids


block: # genOid
  let x = genOid()
  doAssert ($x).len == 32

block:
  let x = genOid()
  let y = parseOid(cstring($x))
  doAssert x == y
