#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Standard tool that resolves import paths.

import
  os, strutils, parseopt

import "../compiler/nimblecmd"

# You can change these constants to build you own adapted resolver.
const
  considerParentDirs = not defined(noParentProjects)
  considerNimbleDirs = not defined(noNimbleDirs)

const
  Version = "1.0"
  Usage = "nimresolve - Nim Resolve Package Path Version " & Version & """

  (c) 2017 Andreas Rumpf
Usage:
  nimresolve [options] package
Options:
  --source:FILE       the file that requests to resolve 'package'
  --stdlib:PATH       the path to use for the standard library
  --project:FILE      the main '.nim' file that was passed to the Nim compiler
  --subdir:EXPR       the subdir part in: 'import $pkg / subdir'
  --noNimblePath      do not search the Nimble path to resolve the package
"""

proc writeHelp() =
  stdout.write(Usage)
  stdout.flushFile()
  quit(0)

proc writeVersion() =
  stdout.write(Version & "\n")
  stdout.flushFile()
  quit(0)

type
  Task = object
    source, stdlib, subdir, project, pkg: string
    noNimblePath: bool

proc findInNimbleDir(t: Task; dir: string): bool =
  var best = ""
  var bestv = ""
  for k, p in os.walkDir(dir, relative=true):
    if k == pcDir and p.len > t.pkg.len+1 and
        p[t.pkg.len] == '-' and p.startsWith(t.pkg):
      let (_, a) = getPathVersion(p)
      if bestv.len == 0 or bestv < a:
        bestv = a
        best = dir / p

  if best.len > 0:
    var f: File
    if open(f, best / changeFileExt(t.pkg, ".nimble-link")):
      # the second line contains what we're interested in, see:
      # https://github.com/nim-lang/nimble#nimble-link
      var override = ""
      discard readLine(f, override)
      discard readLine(f, override)
      close(f)
      if not override.isAbsolute():
        best = best / override
      else:
        best = override
  let f = if t.subdir.len == 0: t.pkg else: t.subdir
  let res = addFileExt(best / f, "nim")
  if best.len > 0 and fileExists(res):
    echo res
    result = true

const stdlibDirs = [
  "pure", "core", "arch",
  "pure/collections",
  "pure/concurrency", "impure",
  "wrappers", "wrappers/linenoise",
  "windows", "posix", "js"]

proc resolve(t: Task) =
  template attempt(a) =
    let x = addFileExt(a, "nim")
    if fileExists(x):
      echo x
      return

  case t.pkg
  of "stdlib":
    if t.subdir.len == 0:
      echo t.stdlib
      return
    else:
      for candidate in stdlibDirs:
        attempt(t.stdlib / candidate / t.subdir)
  of "root":
    let root = t.project.splitFile.dir
    if t.subdir.len == 0:
      echo root
      return
    else:
      attempt(root / t.subdir)
  else:
    when considerParentDirs:
      var p = parentDir(t.source.splitFile.dir)
      # support 'import $karax':
      let f = if t.subdir.len == 0: t.pkg else: t.subdir

      while p.len > 0:
        let dir = p / t.pkg
        if dirExists(dir):
          attempt(dir / f)
          # 2nd attempt: try to use 'karax/karax'
          attempt(dir / t.pkg / f)
          # 3rd attempt: try to use 'karax/src/karax'
          attempt(dir / "src" / f)
          attempt(dir / "src" / t.pkg / f)
        p = parentDir(p)

    when considerNimbleDirs:
      if not t.noNimblePath:
        if findInNimbleDir(t, getHomeDir() / ".nimble" / "pkgs"): return
        when not defined(windows):
          if findInNimbleDir(t, "/opt/nimble/pkgs"): return

  quit "cannot resolve: " & (t.pkg / t.subdir)

proc main =
  var t: Task
  t.subdir = ""
  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      t.pkg = key
    of cmdLongoption, cmdShortOption:
      case normalize(key)
      of "source": t.source = val
      of "stdlib": t.stdlib = val
      of "project": t.project = val
      of "subdir": t.subdir = val
      of "nonimblepath": t.noNimblePath = true
      of "help", "h": writeHelp()
      of "version", "v": writeVersion()
      else: writeHelp()
    of cmdEnd: assert(false) # cannot happen
  if t.pkg.len == 0:
    quit "[Error] no package to resolve."
  resolve(t)

main()
