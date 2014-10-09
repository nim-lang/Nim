# Trim C compiler installation to a minimum

import strutils, os, pegs, strtabs, math, threadpool, times

proc fakeCppDep(x: ptr float) {.importcpp: "fakeCppDep", header: "<vector>".}

const
  Essential = """gcc.exe g++.exe gdb.exe ld.exe as.exe c++.exe cpp.exe cc1.exe
crtbegin.o crtend.o crt2.o dllcrt2.o
libexpat-1.dll libwinpthread-1.dll

aio.h
dlfcn.h
fcntl.h fenv.h fmtmsg.h fnmatch.h ftw.h
errno.h
glob.h gtmath.h
if.h in.h ipc.h
langinfo.h locale.h
math.h mman.h
netdb.h nl_types.h
poll.h pthread.h pwd.h
sched.h select.h semaphore.h signal.h
socket.h spawn.h stat.h statvfs.h stdio.h stdlib.h string.h strings.h
tcp.h time.h types.h
ucontext.h uio.h utsname.h unistd.h
wait.h
varargs.h
windows.h
zlib.h
""".split
  BucketSize = 40

proc includes(headerpath, headerfile: string, whitelist: StringTableRef) =
  whitelist[headerfile] = "processed"
  for line in lines(headerpath):
    if line =~ peg"""s <- ws '#include' ws ('"' / '<') {[^">]+} ('"' / '>') ws
                     comment <- '/*' @ '*/' / '//' .*
                     ws <- (comment / \s+)* """:
      let m = matches[0].extractFilename
      if whitelist[m] != "processed":
        whitelist[m] = "found"

proc processIncludes(dir: string, whitelist: StringTableRef) =
  for kind, path in walkDir(dir):
    case kind
    of pcFile:
      let name = extractFilename(path)
      if ('.' notin name and "include" in path) or ("c++" in path):
        let n = whitelist[name]
        if n != "processed": whitelist[name] = "found"
      if name.endswith(".h"):
        let n = whitelist[name]
        if n == "found": includes(path, name, whitelist)
    of pcDir: processIncludes(path, whitelist)
    else: discard

proc gatherFiles(dir: string, whitelist: StringTableRef, result: var seq[string]) =
  for kind, path in walkDir(dir):
    case kind
    of pcFile:
      let name = extractFilename(path)
      if not whitelist.hasKey(name):
        result.add(path)
    of pcDir: gatherFiles(path, whitelist, result)
    else: discard

proc newName(f: string): string =
  let (dir, name, ext) = splitFile(f)
  return dir / "trim_" & name & ext

proc ccStillWorks(): bool =
  const
    c1 = r"nim c --force_build koch"
    c2 = r"nim c --force_build --threads:on --out:temp.exe tools/trimcc"
  result = execShellCmd(c1) == 0 and execShellCmd(c2) == 0

proc trialDeletion(files: seq[string], a, b: int) =
  for i in a .. min(b, files.high):
    let path = files[i]
    moveFile(dest=newName(path), source=path)
  if ccStillWorks():
    for i in a .. min(b, files.high):
      let path = files[i]
      echo "Optional: ", path
      removeFile(newName(path))
  else:    for i in a .. min(b, files.high):
      let path = files[i]
      echo "Required: ", path
      # copy back:
      moveFile(dest=path, source=newName(path))

proc main(dir: string) =
  var whitelist = newStringTable(modeCaseInsensitive)
  for e in Essential:
    whitelist[e] = "found"
  while true:
    let oldLen = whitelist.len
    processIncludes(dir, whitelist)
    if oldLen == whitelist.len: break
  var allFiles: seq[string] = @[]
  gatherFiles(dir, whitelist, allFiles)
  when true:
    var i = 0
    while i < allFiles.len:
      trialDeletion(allFiles, i, i+BucketSize-1)
      inc i, BucketSize
  else:
    for x in allFiles: echo x

proc fakeTimeDep() = echo(times.getDateStr())

proc fakedeps() =
  var x = 0.4
  {.emit: "#if 0\n".}
  fakeCppDep(addr x)
  {.emit: "#endif\n".}

  # this is not true:
  if math.sin(x) > 0.6:
    spawn(fakeTimeDep())

if paramCount() == 1:
  doAssert ccStillWorks()
  fakedeps()
  main(paramStr(1))
else:
  quit "Usage: trimcc c_compiler_directory"
