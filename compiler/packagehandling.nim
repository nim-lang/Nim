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

proc getPackageName_orig*(conf: ConfigRef; path: string): string =
  var dirs:seq[string] = @[]
  var pkg = ""
  var path_root = ""
  block packageSearch:
    for d in myParentDirs(path):
      # echo ("getPackageName_orig", path, d)
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

proc getPackageName*(conf: ConfigRef; path: string): string =
  result = getPackageName_orig(conf, path)
  #PRTEMP
  # let (p, file, ext) = path.splitFile
  # result = result & packageSep & file
  # echo ("getPackageName:overall",path, result)

when false:
 proc withPackageName*(conf: ConfigRef; path: string): string =
   let x = getPackageName(conf, path)
   if x.len == 0:
     result = path
   else:
     let (p, file, ext) = path.splitFile
     result = (p / (x & '_' & file)) & ext

elif false:
 proc getPackageName2*(conf: ConfigRef; path: string): string =
  let (p, file, ext) = path.splitFile
  let sep = '@'
  result = p.replace(DirSep, sep) & sep

 proc withPackageName*(conf: ConfigRef; path: string): string =
  let x0 = getPackageName(conf, path)
  let x = getPackageName2(conf, path)
  doAssert x.len > 0
  let (p, file, ext) = path.splitFile
  result = (p / (x & file)) & ext
  echo ("withPackageName",x0, x, result)
else:
 proc getPackageName2*(conf: ConfigRef; path: string): string =
  let (p, file, ext) = path.splitFile
  let sep = '@'
  result = p.replace(DirSep, sep) & sep

 proc fullyQualifiedName*(conf: ConfigRef; path: string): string =
  let pkg = getPackageName(conf, path)
  doAssert pkg.len > 0
  let (p, file, ext) = path.splitFile
  result = pkg & packageSep & file

 #TODO: is `p/` part needed?
 proc withPackageName*(conf: ConfigRef; path: string): string =
  let fqname = fullyQualifiedName(conf, path)
  let (p, file, ext) = path.splitFile
  result = p / (fqname & ext)
