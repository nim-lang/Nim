import std/[osproc, os, strutils]

import msgs, options, ast, lineinfos, extccomp, pathutils

proc quoted(a: string): string =
  result.addQuoted(a)

proc addDependency*(conf: ConfigRef, name: string, info: TLineInfo) =
  case name
  of "dragonbox":
    # xxx we could also build this under $nimb/build/
    # let cppExe = getCompilerExe(c.config; compiler: TSystemCC; cfile: AbsoluteFile): string =
        # compilePattern = getCompilerExe(conf, c, cfile.cname)
    let dir = conf.getNimcacheDir().string
    createDir dir
    let objFile = dir / "nimdragonbox.o"
    if optForceFullMake in conf.globalOptions or not objFile.fileExists:
      let cppExe = "clang++"
      let inputFile = conf.libpath.string / "std/private/dragonbox_impl.cc"
      let cmd = "$# -c -std=c++11 -O3 -o $# $#" % [cppExe.quoted, objFile.quoted, inputFile.quoted]
      # xxx use md5 hash to recompile if needed
      writePrettyCmdsStderr displayProgressCC(conf, inputFile, cmd)
      let (outp, status) = execCmdEx(cmd)
      if status != 0:
        # stackTrace2("building '$#' failed: cmd: $#\noutput:\n$#" % [name, cmd, outp], a)
        localError(conf, info, "building '$#' failed: cmd: $#\noutput:\n$#" % [name, cmd, outp])
    conf.addExternalFileToLink objFile.AbsoluteFile
  else:
    # stackTrace2("expected: 'dragonbox', got: '$1'" % name, a)
    localError(conf, info, "expected: 'dragonbox', got: '$1'" % name)
