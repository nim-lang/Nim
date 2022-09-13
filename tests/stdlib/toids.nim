import std/oids
import std/assertions

block: # genOid
  let x = genOid()
  doAssert ($x).len == 24
