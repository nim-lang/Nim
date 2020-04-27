import

  ".." / [ ast, cgendata, pathutils, sighashes, lineinfos, ropes,
  modulegraphs ]

import

  std / [ hashes, intsets, strutils ]

proc hash*(s: TTypeSeq): Hash =
  # good enough indeed
  var
    h: Hash = 0
  for t in s.items:
    h = h !& hash($hashType(t))
  result = !$h

proc hash*(r: Rope): Hash =
  # good enough indeed
  var
    h: Hash = 0
  if r == nil:
    h = h !& hash("")
  else:
    for leaf in r.leaves:
      h = h !& hash(leaf)
  result = !$h

proc hash*(s: IntSet): Hash =
  var
    h: Hash = 0
  for i in s.items:
    h = h !& hash(i)
  result = !$h

proc hash*(s: TCFileSections): Hash =
  var
    h: Hash = 0
  for section, roap in s.pairs:
    if roap != nil:
      h = h !& hash(ord(section))
    h = h !& hash(roap)
  result = !$h

proc hash*(b: BProc): Hash =
  # also lousy
  var
    h: Hash = 0
  h = h !& hash(b.flags)
  if b.prc == nil:
    h = h !& hash("")
  else:
    h = h !& hash($hashProc(b.prc))
  result = !$h

proc hash*(d: TNodeTable): Hash =
  # lousy, but probably good enough
  var
    h: Hash = 0
  for pair in d.data.items:
    h = h !& pair.h
    h = h !& hash(pair.val)
  result = !$h

proc hash*(m: BModule): Hash =
  var
    h: Hash = 0
  h = h !& hash(m.headerFiles)
  h = h !& hash($m.filename)
  h = h !& hash($m.cfilename)

  h = h !& hash(m.labels)
  h = h !& hash(m.typeNodes)
  h = h !& hash(m.nimTypes)
  h = h !& hash(m.injectStmt)

  h = h !& hash(m.flags)
  h = h !& hash(m.typeStack)
  h = h !& hash(m.declaredThings)
  h = h !& hash(m.declaredProtos)

  h = h !& hash(m.initProc)
  h = h !& hash(m.initProc.options)
  h = h !& hash(m.preInitProc)

  h = h !& hash(m.dataCache)

  #h = h !& hash(m.s)

  result = !$h

proc hash*(list: BModuleList): Hash =
  var
    h: Hash = 0
  h = h !& hash(list.mainModProcs)
  h = h !& hash(list.mainModInit)
  h = h !& hash(list.otherModsInit)
  h = h !& hash(list.mainDatInit)
  h = h !& hash(list.mapping)
  for module in list.modules.items:
    h = h !& h.hash
  result = !$h

proc dumpLine*(info: TLineInfo): string =
  result = "fileIndex[$#] line: $#, col: $#" % [ $info.fileIndex.int32,
                                                 $info.line, $(info.col+1) ]
