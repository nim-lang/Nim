
# bug #5237

import tables
import sets
import sequtils


const EXTENSIONMAP = {
  "c": @["*.c", "*.h"],
}.toTable()

const EXTENSIONS = toHashSet(concat(toSeq(EXTENSIONMAP.values())))
