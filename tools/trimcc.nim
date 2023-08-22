# Trim C compiler installation to a minimum

import strutils, os, pegs, strtabs, math, times

const
  Essential = """gcc.exe g++.exe gdb.exe ld.exe as.exe c++.exe cpp.exe cc1.exe
crtbegin.o crtend.o crt2.o dllcrt2.o libgcc_s_dw2-1.dll libgcc_s_sjlj-1.dll
libgcc_s_seh-1.dll libexpat-1.dll libwinpthread-1.dll aio.h dlfcn.h fcntl.h
fenv.h fmtmsg.h fnmatch.h ftw.h errno.h glob.h gtmath.h if.h in.h ipc.h
langinfo.h locale.h math.h mman.h netdb.h nl_types.h poll.h pthread.h pwd.h
sched.h select.h semaphore.h signal.h socket.h spawn.h stat.h statvfs.h stdio.h
stdlib.h string.h strings.h tcp.h time.h types.h ucontext.h uio.h utsname.h
unistd.h wait.h varargs.h windows.h zlib.h
""".split

proc includes(headerpath, headerfile: string, whitelist: StringTableRef) =
  whitelist[headerfile] = "processed"
  for line in lines(headerpath):
    if line =~ peg"""s <- ws '#include' ws ('"' / '<') {[^">]+} ('"' / '>') ws
                     comment <- '/*' @ '*/' / '//' .*
                     ws <- (comment / \s+)* """:
      let m = matches[0].extractFilename
      if whitelist.getOrDefault(m) != "processed":
        whitelist[m] = "found"

proc processIncludes(dir: string, whitelist: StringTableRef) =
  for kind, path in walkDir(dir):
    case kind
    of pcFile:
      let name = extractFilename(path)
      if ('.' notin name and "include" in path) or ("c++" in path):
        let n = whitelist.getOrDefault(name)
        if n != "processed": whitelist[name] = "found"
      if name.endsWith(".h"):
        let n = whitelist.getOrDefault(name)
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
    of pcDir:
      gatherFiles(path, whitelist, result)
    else:
      discard

proc gatherEmptyFolders(dir: string, whitelist: StringTableRef, result: var seq[string]) =
  var empty = true
  for kind, path in walkDir(dir):
    case kind
    of pcFile:
      empty = false
    of pcDir:
      let (none, name) = splitPath(path)
      if not whitelist.hasKey(name):
        gatherEmptyFolders(path, whitelist, result)
      empty = false
    else:
      discard
  if empty:
    result.add(dir)

proc newName(f: string): string =
  let (dir, name, ext) = splitFile(f)
  return dir / "trim_" & name & ext

proc ccStillWorks(): bool =
  const
    c1 = r"nim c --verbosity:0 --force_build koch"
    c2 = r"nim c --verbosity:0 --force_build --threads:on --out:tempOne.exe tools/trimcc"
    c3 = r"nim c --verbosity:0 --force_build --threads:on --out:tempTwo.exe tools/fakeDeps"
    c4 = r".\koch.exe"
    c5 = r".\tempOne.exe"
    c6 = r".\tempTwo.exe"
  result = execShellCmd(c1) == 0 and execShellCmd(c2) == 0 and
           execShellCmd(c3) == 0 and execShellCmd(c4) == 0 and
           execShellCmd(c5) == 0 and execShellCmd(c6) == 0

proc trialDeletion(files: seq[string], a, b: int, whitelist: StringTableRef): bool =
  result = true
  var single = (a == min(b, files.high))
  for path in files[a .. min(b, files.high)]:
    try:
      moveFile(dest=newName(path), source=path)
    except OSError:
      return false

  # Test if compilation still works, even with the moved files.
  if ccStillWorks():
    for path in files[a .. min(b, files.high)]:
      try:
        removeFile(newName(path))
        echo "Optional: ", path
      except OSError:
        echo "Warning, couldn't move ", path
        moveFile(dest=path, source=newName(path))
        return false
  else:
    for path in files[a .. min(b, files.high)]:
      echo "Required: ", path
      moveFile(dest=path, source=newName(path))
      if single:
        whitelist[path] = "found"
      result = false

proc main(dir: string) =
  # Construct a whitelist of files to not remove
  var whitelist = newStringTable(modeCaseInsensitive)
  for e in Essential:
    whitelist[e] = "found"
  while true:
    let oldLen = whitelist.len
    processIncludes(dir, whitelist)
    if oldLen == whitelist.len:
      break

  # Remove batches of files
  var nearlyDone = false
  while true:
    # Gather files to test
    var allFiles = newSeq[string]()
    gatherFiles(dir, whitelist, allFiles)

    # Determine the initial size of groups to check
    var
      maxBucketSize = len(allFiles)
      bucketSize = 1

    # Loop through the list of files, deleting batches
    var i = 0
    while i < allFiles.len:
      var success = trialDeletion(allFiles, i, i+bucketSize-1, whitelist)
      inc i, bucketSize

      # If we aren't on the last pass, adjust the batch size based on success
      if not nearlyDone:
        if success:
          bucketSize = min(bucketSize * 2, maxBucketSize)
        else:
          bucketSize = max(bucketSize div 2, 1)
      echo "Bucket size is now ", bucketSize

    # After looping through all the files, check if we need to break.
    if nearlyDone:
      break
    if bucketSize == 1:
      nearlyDone = true

  while true:
    var
      emptyFolders = newSeq[string]()
      changed = false

    gatherEmptyFolders(dir, whitelist, emptyFolders)
    for path in emptyFolders:
      removeDir(path)
      if not ccStillWorks():
        createDir(path)
        whitelist[path] = "found"
      else:
        changed = true
    if not changed:
      break

if paramCount() == 1:
  doAssert ccStillWorks()
  main(paramStr(1))
else:
  quit "Usage: trimcc c_compiler_directory", QuitSuccess
