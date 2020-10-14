discard """
  cmd: "nim c --experimental:strictFuncs --experimental:views $file"
"""

import tables, streams, nre, parsecsv, uri

type
  Contig2Reads = TableRef[string, seq[string]]

proc get_Contig2Reads(sin: Stream, fn: string, contig2len: TableRef[string, int]): Contig2Reads =
  result = newTable[string, seq[string]]()
  var parser: CsvParser
  open(parser, sin, filename = fn, separator = ' ', skipInitialSpace = true)
  while readRow(parser, 2):
    if contig2len.haskey(parser.row[1]):
      mgetOrPut(result, parser.row[1], @[]).add(parser.row[0])

