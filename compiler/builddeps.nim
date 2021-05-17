#[
## TODO
* this will show `CC: dragonbox`:
`nim r -f --hint:cc --filenames:abs --processing:filenames --hint:conf nonexistant`
we could refine the logic to delay compilation until cgen phase instead.
(see also `tests/osproc/treadlines.nim`)
* allow some form of reporting so that caller can tell whether a dependency
  doesn't exist, or was already built, or builds with error, or builds successfully, etc.
]#

import std/[osproc, os, strutils]
import msgs, options, ast, lineinfos, extccomp, pathutils

const prefix = "__" # prevent clashing with user files

proc addDependency*(conf: ConfigRef, name: string, info: TLineInfo) =
  case name
  of "dragonbox":
    if name notin conf.dependencies:
      conf.dependencies.add name
      # xxx we could also build this under $nimb/build/
      let dir = conf.getNimcacheDir().string
      createDir dir
      let objFile = dir / ("$1nimdragonbox.o" % prefix)
      if optForceFullMake in conf.globalOptions or not objFile.fileExists:
        # consider using instead: `getCompilerExe(conf, ...)`
        when defined(osx):
          let cppExe = "clang++"
        else:
          let cppExe = "g++"
        when defined(linux):
          let options = "-fPIE" # avoids: `relocation R_X86_64_32S against `.rodata' can not be used when making a PIE object`
        else:
          let options = ""
        let inputFile = conf.libpath.string / "vendor/drachennest/dragonbox.cc"
        let cmd = "$# -c -std=c++11 $# -O3 -o $# $#" % [cppExe.quoteShell, options, objFile.quoteShell, inputFile.quoteShell]
        # xxx use md5 hash to recompile if needed
        writePrettyCmdsStderr displayProgressCC(conf, inputFile, cmd)
        let (outp, status) = execCmdEx(cmd)
        if status != 0:
          localError(conf, info, "building '$#' failed: cmd: $#\noutput:\n$#" % [name, cmd, outp])
      conf.addExternalFileToLink(objFile.AbsoluteFile)
  else:
    localError(conf, info, "expected: 'dragonbox', got: '$1'" % name)
