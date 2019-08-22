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

proc getPackageName*(conf: ConfigRef; path: string): string =
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
  # we also store if we didn't find anything:
  when not defined(nimNoNilSeqs):
    if result.isNil: result = ""
  for d in myParentDirs(path):
    #echo "set cache ", d, " |", result, "|", parents
    conf.packageCache[d] = result
    dec parents
    if parents <= 0: break

proc fakePackageName*(conf: ConfigRef; path: AbsoluteFile): string =
  # foo/../bar becomes foo7_7bar
  result = relativeTo(path, conf.projectPath, '/').string.multiReplace(
    {"/": "7", "..": "_", "7": "77", "_": "__", ":": "8", "8": "88"})

proc demanglePackageName*(path: string): string =
  result = path.multiReplace(
    {"88": "8", "8": ":", "77": "7", "__": "_", "_7": "../", "7": "/"})

proc withPackageName*(conf: ConfigRef; path: AbsoluteFile): AbsoluteFile =
  let x = getPackageName(conf, path.string)
  if x.len == 0:
    result = path
  else:
    let (p, file, ext) = path.splitFile
    if x == "stdlib":
      # Hot code reloading now relies on 'stdlib_system' names etc.
      result = p / RelativeFile((x & '_' & file) & ext)
    else:
      result = p / RelativeFile(fakePackageName(conf, path))
