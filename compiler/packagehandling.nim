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
    # IMPROVE:parentDir is buggy, "foo.nim".parentDir should be ".", not ""
    if current.len == 0:
      current = "."
      yield current
      break
    yield current

const packageSep = "@"

proc getPackageName*(conf: ConfigRef; path: string): string =
  var dirs:seq[string] = @[]
  var pkg = ""
  var path_root = ""
  block packageSearch:
    for d in myParentDirs(path):
      path_root = d
      if conf.packageCache.hasKey(d):
        pkg = conf.packageCache[d]
        break packageSearch
      for file in walkFiles(d / "*.nimble"):
        pkg = file.splitFile.name
        break packageSearch
      for file in walkFiles(d / "*.babel"):
        pkg = file.splitFile.name
        break packageSearch
      dirs.add d.splitPath.tail

  # at this point, path_root maps to pkg
  for index in 0 .. dirs.len:
    if index > 0:
      let dir = dirs[^index]
      path_root = path_root & DirSep & dir
      pkg = pkg & packageSep & dir
    if conf.packageCache.hasKey(path_root):
      doAssert conf.packageCache[path_root] == pkg
    else:
      conf.packageCache[path_root] = pkg
  result = pkg

proc fullyQualifiedName*(conf: ConfigRef; path: string): string =
  let pkg = getPackageName(conf, path)
  doAssert pkg.len > 0
  let (p, file, ext) = path.splitFile
  result = pkg & packageSep & file

proc withPackageName*(conf: ConfigRef; path: string): string =
  let fqname = fullyQualifiedName(conf, path)
  let (p, file, ext) = path.splitFile
  # TODO: is `p/` part needed?
  result = p / (fqname & ext)
