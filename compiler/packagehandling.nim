#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

proc resetPackageCache*(conf: ConfigRef) =
  conf.packageCache = newPackageCache()

proc getPackageName*(conf: ConfigRef; path: string): string =
  var parents = 0
  block packageSearch:
    for d in parentDirs(path, inclusive=false):
      if conf.packageCache.hasKey(d):
        #echo "from cache ", d, " |", packageCache[d], "|", path.splitFile.name
        return conf.packageCache[d]
      inc parents
      for file in walkFiles(d / "*.nimble"):
        result = file.splitFile.name
        break packageSearch
      for file in walkFiles(d / "*.babel"):
        result = file.splitFile.name
        break packageSearch
  # we also store if we didn't find anything:
  when not defined(nimNoNilSeqs):
    if result.isNil: result = ""
  for d in parentDirs(path, inclusive=false):
    #echo "set cache ", d, " |", result, "|", parents
    conf.packageCache[d] = result
    dec parents
    if parents <= 0: break

proc withPackageName*(conf: ConfigRef; path: AbsoluteFile): AbsoluteFile =
  let x = getPackageName(conf, path.string)
  if x.len == 0:
    result = path
  else:
    let (p, file, ext) = path.splitFile
    result = p / RelativeFile((x & '_' & file) & ext)
