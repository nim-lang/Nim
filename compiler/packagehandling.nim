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

iterator walkFiles2(patterns: seq[string]): string =
  for p in patterns:
    for file in walkFiles(p):
      yield file

proc getNimbleBabelFile*(conf: ConfigRef; path: string): string =
  ## returns absolute path to nimble file, eg: /pathto/cligen.nimble
  ## Note: could also return a .babel file, see below
  var parents = 0
  block packageSearch:
    for d in myParentDirs(path):
      if conf.packageCache.hasKey(d):
        #echo "from cache ", d, " |", packageCache[d], "|", path.splitFile.name
        return conf.packageCache[d]
      inc parents
      for file in walkFiles2(@[d / "*.nimble", d / "*.babel"]):
        result = file
        break packageSearch
      #[
      see #14453
      cairo doesn't contain a cairo.nimble file, instead it has a cairo.babel file
      which is deprecated but we must honor it otherwise you get hit by #14453.
      Note: we can't rely on whether `nimblemeta.json` exists even if nimble
      always creates one for both `install` and `develop`, because for `nimble develop`,
      it's under ~/.nimble/pkgs/cairo-#head/nimblemeta.json yet `d` is wherever
      you've cloned the repo.
      It's not clear how to entirely purge old babel logic because old dependencies
      from pacakges (eg `import ggplotnim` caused that see #14453).
      Repro:
      git clone https://github.com/nim-lang/cairo && cd cairo
      git checkout aee593dd189a1e65b91ada4c098a49757a26fbe1
      nimble develop => no `nimblemeta.json`, no cairo.nimble, only cairo.babel
      ditto for ~/.nimble/pkgs/cairo--1.0/ instealled by `import ggplotnim`
      ]#
  # we also store if we didn't find anything:
  when not defined(nimNoNilSeqs):
    if result.isNil: result = ""
  for d in myParentDirs(path):
    #echo "set cache ", d, " |", result, "|", parents
    conf.packageCache[d] = result
    dec parents
    if parents <= 0: break

proc getPackageDir*(conf: ConfigRef, path: string): string =
  getNimbleBabelFile(conf, path).parentDir

proc getPackageName*(conf: ConfigRef; path: string): string =
  ## returns nimble package name, eg: `cligen`
  let path = getNimbleBabelFile(conf, path)
  result = path.splitFile.name

proc fakePackageName*(conf: ConfigRef; path: AbsoluteFile): string =
  # Convert `path` so that 2 modules with same name
  # in different directory get different name and they can be
  # placed in a directory.
  # foo-#head/../bar becomes @foo-@hhead@s..@sbar
  result = "@m" & relativeTo(path, conf.projectPath).string.multiReplace({$os.DirSep: "@s", $os.AltSep: "@s", "#": "@h", "@": "@@", ":": "@c"})

proc demanglePackageName*(path: string): string =
  result = path.multiReplace({"@@": "@", "@h": "#", "@s": "/", "@m": "", "@c": ":"})

proc withPackageName*(conf: ConfigRef; path: AbsoluteFile): AbsoluteFile =
  let x = getPackageName(conf, path.string)
  let (p, file, ext) = path.splitFile
  if x == "stdlib":
    # Hot code reloading now relies on 'stdlib_system' names etc.
    result = p / RelativeFile((x & '_' & file) & ext)
  else:
    result = p / RelativeFile(fakePackageName(conf, path))
