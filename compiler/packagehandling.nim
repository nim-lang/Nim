#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

iterator myParentDirs(p: string): string =
  # XXX os's parentDirs is stupid (multiple yields) and triggers an old bug...
  var current = p
  while true:
    current = current.parentDir
    if current.len == 0: break
    yield current

proc resetPackageCache*(conf: ConfigRef) =
  conf.packageCache = newPackageCache()

when false:
 proc getPackageName*(conf: ConfigRef; path: string): string =
  echo ("getPackageName",path)
  var parents = 0
  block packageSearch:
    for d in myParentDirs(path):
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
  if result.isNil: result = ""
  for d in myParentDirs(path):
    #echo "set cache ", d, " |", result, "|", parents
    conf.packageCache[d] = result
    dec parents
    if parents <= 0: break

proc getPackageName*(conf: ConfigRef; path: string): string =
  let (p, file, ext) = path.splitFile
  let sep = '@'
  result = p.replace(DirSep, sep) & sep

proc withPackageName*(conf: ConfigRef; path: string): string =
  let x = getPackageName(conf, path)
  doAssert x.len > 0
  let (p, file, ext) = path.splitFile
  result = (p / (x & file)) & ext
