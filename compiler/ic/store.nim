import

  ".." / [ modulegraphs, incremental ]

import

  std / [ db_sqlite, intsets, strutils, tables ]

import

  spec

type
  BlobReader* = object
    s*: string
    pos*: int

using
  b: var BlobReader
  g: ModuleGraph

template db(): DbConn = g.incr.db

proc newBlobReader*(blob: string): BlobReader =
  result = BlobReader(pos: 0)
  shallowCopy(result.s, blob)
  # ensure we can read without index checks:
  result.s.add '\0'
  result = BlobReader(pos: 0)
  shallowCopy(result.s, blob)
  # ensure we can read without index checks:
  result.s.add '\0'

proc loadBlob*(g; query: SqlQuery; id: int): BlobReader =
  let blob = db.getValue(query, id)
  if blob.len == 0:
    writeStackTrace()
    raise newException(Defect, "cannot find id " & $id)
    #internalError(g.config, "symbolfiles: cannot find ID " & $ id)
  result = newBlobReader(blob)
