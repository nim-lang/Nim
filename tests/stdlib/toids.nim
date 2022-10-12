discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/oids
import std/assertions

block: # genOid
  let x = genOid()
  doAssert ($x).len == 24

block:
  let x = genOid()
  let y = parseOid(cstring($x))
  doAssert x == y
