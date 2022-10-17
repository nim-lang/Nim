import paths, files

import std/oserrors

const weirdTarget = defined(nimscript) or defined(js)

when weirdTarget:
  {.pragma: noWeirdTarget, error: "this proc is not available on the NimScript/js target".}
else:
  {.pragma: noWeirdTarget.}


when defined(nimscript):
  # for procs already defined in scriptconfig.nim
  template noNimJs(body): untyped = discard
elif defined(js):
  {.pragma: noNimJs, error: "this proc is not available on the js target".}
else:
  {.pragma: noNimJs.}

when weirdTarget:
  discard
elif defined(windows):
  import winlean, times
elif defined(posix):
  import posix, times

  proc toTime(ts: Timespec): times.Time {.inline.} =
    result = initTime(ts.tv_sec.int64, ts.tv_nsec.int)
else:
  {.error: "OS module not ported to your operating system!".}


when defined(windows) and not weirdTarget:
  template wrapUnary(varname, winApiProc, arg: untyped) =
    var varname = winApiProc(newWideCString(arg))

  template wrapBinary(varname, winApiProc, arg, arg2: untyped) =
    var varname = winApiProc(newWideCString(arg), arg2)
  proc findFirstFile(a: string, b: var WIN32_FIND_DATA): Handle =
    result = findFirstFileW(newWideCString(a), b)
  template findNextFile(a, b: untyped): untyped = findNextFileW(a, b)
  template getCommandLine(): untyped = getCommandLineW()

  template getFilename(f: untyped): untyped =
    $cast[WideCString](addr(f.cFileName[0]))

  proc skipFindData(f: WIN32_FIND_DATA): bool {.inline.} =
    # Note - takes advantage of null delimiter in the cstring
    const dot = ord('.')
    result = f.cFileName[0].int == dot and (f.cFileName[1].int == 0 or
             f.cFileName[1].int == dot and f.cFileName[2].int == 0)



type
  PathComponent* = enum   ## Enumeration specifying a path component.
    ##
    ## See also:
    ## * `walkDirRec iterator`_
    ## * `FileInfo object`_
    pcFile,               ## path refers to a file
    pcLinkToFile,         ## path refers to a symbolic link to a file
    pcDir,                ## path refers to a directory
    pcLinkToDir           ## path refers to a symbolic link to a directory

proc staticWalkDir(dir: string; relative: bool): seq[
                  tuple[kind: PathComponent, path: string]] =
  discard

iterator walkDir*(dir: Path; relative = false, checkDir = false):
  tuple[kind: PathComponent, path: Path] {.tags: [ReadDirEffect].} =
  ## Walks over the directory `dir` and yields for each directory or file in
  ## `dir`. The component type and full path for each item are returned.
  ##
  ## Walking is not recursive. If ``relative`` is true (default: false)
  ## the resulting path is shortened to be relative to ``dir``.
  ##
  ## If `checkDir` is true, `OSError` is raised when `dir`
  ## doesn't exist.
  ##
  ## **Example:**
  ##
  ## This directory structure:
  ##
  ##     dirA / dirB / fileB1.txt
  ##          / dirC
  ##          / fileA1.txt
  ##          / fileA2.txt
  ##
  ## and this code:
  runnableExamples("-r:off"):
    import std/[strutils, sugar]
    # note: order is not guaranteed
    # this also works at compile time
    assert collect(for k in walkDir("dirA"): k.path).join(" ") ==
                          "dirA/dirB dirA/dirC dirA/fileA2.txt dirA/fileA1.txt"
  ## See also:
  ## * `walkPattern iterator`_
  ## * `walkFiles iterator`_
  ## * `walkDirs iterator`_
  ## * `walkDirRec iterator`_

  when nimvm:
    for k, v in items(staticWalkDir(dir.string, relative)):
      yield (k, Path(v))
  else:
    when weirdTarget:
      for k, v in items(staticWalkDir(dir, relative)):
        yield (k, v)
    elif defined(windows):
      var f: WIN32_FIND_DATA
      var h = findFirstFile(string(dir / Path("*")), f)
      if h == -1:
        if checkDir:
          raiseOSError(osLastError(), dir.string)
      else:
        defer: findClose(h)
        while true:
          var k = pcFile
          if not skipFindData(f):
            if (f.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0'i32:
              k = pcDir
            if (f.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32:
              k = succ(k)
            let xx = if relative: extractFilename(Path(getFilename(f)))
                     else: dir / extractFilename(Path(getFilename(f)))
            yield (k, xx)
          if findNextFile(h, f) == 0'i32:
            let errCode = getLastError()
            if errCode == ERROR_NO_MORE_FILES: break
            else: raiseOSError(errCode.OSErrorCode)
    else:
      var d = opendir(dir)
      if d == nil:
        if checkDir:
          raiseOSError(osLastError(), dir)
      else:
        defer: discard closedir(d)
        while true:
          var x = readdir(d)
          if x == nil: break
          var y = $cstring(addr x.d_name)
          if y != "." and y != "..":
            var s: Stat
            let path = dir / y
            if not relative:
              y = path
            var k = pcFile

            template kSetGeneric() =  # pure Posix component `k` resolution
              if lstat(path.cstring, s) < 0'i32: continue  # don't yield
              elif S_ISDIR(s.st_mode):
                k = pcDir
              elif S_ISLNK(s.st_mode):
                k = getSymlinkFileKind(path)

            when defined(linux) or defined(macosx) or
                 defined(bsd) or defined(genode) or defined(nintendoswitch):
              case x.d_type
              of DT_DIR: k = pcDir
              of DT_LNK:
                if dirExists(path): k = pcLinkToDir
                else: k = pcLinkToFile
              of DT_UNKNOWN:
                kSetGeneric()
              else: # e.g. DT_REG etc
                discard # leave it as pcFile
            else:  # assuming that field `d_type` is not present
              kSetGeneric()

            yield (k, y)

iterator walkDirRec*(dir: Path,
                     yieldFilter = {pcFile}, followFilter = {pcDir},
                     relative = false, checkDir = false): Path {.tags: [ReadDirEffect].} =
  ## Recursively walks over the directory `dir` and yields for each file
  ## or directory in `dir`.
  ##
  ## If ``relative`` is true (default: false) the resulting path is
  ## shortened to be relative to ``dir``, otherwise the full path is returned.
  ##
  ## If `checkDir` is true, `OSError` is raised when `dir`
  ## doesn't exist.
  ##
  ## .. warning:: Modifying the directory structure while the iterator
  ##   is traversing may result in undefined behavior!
  ##
  ## Walking is recursive. `followFilter` controls the behaviour of the iterator:
  ##
  ## =====================   =============================================
  ## yieldFilter             meaning
  ## =====================   =============================================
  ## ``pcFile``              yield real files (default)
  ## ``pcLinkToFile``        yield symbolic links to files
  ## ``pcDir``               yield real directories
  ## ``pcLinkToDir``         yield symbolic links to directories
  ## =====================   =============================================
  ##
  ## =====================   =============================================
  ## followFilter            meaning
  ## =====================   =============================================
  ## ``pcDir``               follow real directories (default)
  ## ``pcLinkToDir``         follow symbolic links to directories
  ## =====================   =============================================
  ##
  ##
  ## See also:
  ## * `walkPattern iterator`_
  ## * `walkFiles iterator`_
  ## * `walkDirs iterator`_
  ## * `walkDir iterator`_

  var stack = newseq[Path]()
  var checkDir = checkDir
  while stack.len > 0:
    let d = stack.pop()
    for k, p in walkDir(dir / d, relative = true, checkDir = checkDir):
      let rel = d / p
      if k in {pcDir, pcLinkToDir} and k in followFilter:
        stack.add rel
      if k in yieldFilter:
        yield if relative: rel else: dir / rel
    checkDir = false
      # We only check top-level dir, otherwise if a subdir is invalid (eg. wrong
      # permissions), it'll abort iteration and there would be no way to
      # continue iteration.
      # Future work can provide a way to customize this and do error reporting.

proc rawRemoveDir(dir: string) {.noWeirdTarget.} =
  when defined(windows):
    wrapUnary(res, removeDirectoryW, dir)
    let lastError = osLastError()
    if res == 0'i32 and lastError.int32 != 3'i32 and
        lastError.int32 != 18'i32 and lastError.int32 != 2'i32:
      raiseOSError(lastError, dir)
  else:
    if rmdir(dir) != 0'i32 and errno != ENOENT: raiseOSError(osLastError(), dir)

proc removeDir*(dir: Path, checkDir = false) {.tags: [
  WriteDirEffect, ReadDirEffect], gcsafe.} =
  ## Removes the directory `dir` including all subdirectories and files
  ## in `dir` (recursively).
  ##
  ## If this fails, `OSError` is raised. This does not fail if the directory never
  ## existed in the first place, unless `checkDir` = true.
  ##
  ## See also:
  ## * `tryRemoveFile proc`_
  ## * `removeFile proc`_
  ## * `existsOrCreateDir proc`_
  ## * `createDir proc`_
  ## * `copyDir proc`_
  ## * `copyDirWithPermissions proc`_
  ## * `moveDir proc`_
  for kind, path in walkDir(dir, checkDir = checkDir):
    case kind
    of pcFile, pcLinkToFile, pcLinkToDir: removeFile(path)
    of pcDir: removeDir(path, true)
      # for subdirectories there is no benefit in `checkDir = false`
      # (unless perhaps for edge case of concurrent processes also deleting
      # the same files)
  rawRemoveDir(dir.string)

proc dirExists*(dir: Path): bool {.tags: [ReadDirEffect],
                                     noNimJs.} =
  ## Returns true if the directory `dir` exists. If `dir` is a file, false
  ## is returned. Follows symlinks.
  ##
  ## See also:
  ## * `fileExists proc`_
  ## * `symlinkExists proc`_
  when defined(windows):
    wrapUnary(a, getFileAttributesW, dir.string)
    if a != -1'i32:
      result = (a and FILE_ATTRIBUTE_DIRECTORY) != 0'i32
  else:
    var res: Stat
    result = stat(dir.string, res) >= 0'i32 and S_ISDIR(res.st_mode)

proc rawCreateDir(dir: string): bool {.noWeirdTarget.} =
  # Try to create one directory (not the whole path).
  # returns `true` for success, `false` if the path has previously existed
  #
  # This is a thin wrapper over mkDir (or alternatives on other systems),
  # so in case of a pre-existing path we don't check that it is a directory.
  when defined(solaris):
    let res = mkdir(dir, 0o777)
    if res == 0'i32:
      result = true
    elif errno in {EEXIST, ENOSYS}:
      result = false
    else:
      raiseOSError(osLastError(), dir)
  elif defined(haiku):
    let res = mkdir(dir, 0o777)
    if res == 0'i32:
      result = true
    elif errno == EEXIST or errno == EROFS:
      result = false
    else:
      raiseOSError(osLastError(), dir)
  elif defined(posix):
    let res = mkdir(dir, 0o777)
    if res == 0'i32:
      result = true
    elif errno == EEXIST:
      result = false
    else:
      #echo res
      raiseOSError(osLastError(), dir)
  else:
    wrapUnary(res, createDirectoryW, dir)

    if res != 0'i32:
      result = true
    elif getLastError() == 183'i32:
      result = false
    else:
      raiseOSError(osLastError(), dir)

proc existsOrCreateDir*(dir: Path): bool {.
  tags: [WriteDirEffect, ReadDirEffect], noWeirdTarget.} =
  ## Checks if a `directory`:idx: `dir` exists, and creates it otherwise.
  ##
  ## Does not create parent directories (raises `OSError` if parent directories do not exist).
  ## Returns `true` if the directory already exists, and `false` otherwise.
  ##
  ## See also:
  ## * `removeDir proc`_
  ## * `createDir proc`_
  ## * `copyDir proc`_
  ## * `copyDirWithPermissions proc`_
  ## * `moveDir proc`_
  result = not rawCreateDir(dir.string)
  if result:
    # path already exists - need to check that it is indeed a directory
    if not dirExists(dir):
      raise newException(IOError, "Failed to create '" & dir.string & "'")

# proc createDir*(dir: Path) {.
#   tags: [WriteDirEffect, ReadDirEffect], noWeirdTarget.} =
#   ## Creates the `directory`:idx: `dir`.
#   ##
#   ## The directory may contain several subdirectories that do not exist yet.
#   ## The full path is created. If this fails, `OSError` is raised.
#   ##
#   ## It does **not** fail if the directory already exists because for
#   ## most usages this does not indicate an error.
#   ##
#   ## See also:
#   ## * `removeDir proc`_
#   ## * `existsOrCreateDir proc`_
#   ## * `copyDir proc`_
#   ## * `copyDirWithPermissions proc`_
#   ## * `moveDir proc`_
#   if dir.len == 0:
#     return
#   var omitNext = isAbsolute(dir)
#   for p in parentDirs(dir, fromRoot=true):
#     if omitNext:
#       omitNext = false
#     else:
#       discard existsOrCreateDir(p)

# proc copyDir*(source, dest: string) {.tags: [ReadDirEffect, WriteIOEffect, ReadIOEffect], gcsafe, noWeirdTarget.} =
#   ## Copies a directory from `source` to `dest`.
#   ##
#   ## On non-Windows OSes, symlinks are copied as symlinks. On Windows, symlinks
#   ## are skipped.
#   ##
#   ## If this fails, `OSError` is raised.
#   ##
#   ## On the Windows platform this proc will copy the attributes from
#   ## `source` into `dest`.
#   ##
#   ## On other platforms created files and directories will inherit the
#   ## default permissions of a newly created file/directory for the user.
#   ## Use `copyDirWithPermissions proc`_
#   ## to preserve attributes recursively on these platforms.
#   ##
#   ## See also:
#   ## * `copyDirWithPermissions proc`_
#   ## * `copyFile proc`_
#   ## * `copyFileWithPermissions proc`_
#   ## * `removeDir proc`_
#   ## * `existsOrCreateDir proc`_
#   ## * `createDir proc`_
#   ## * `moveDir proc`_
#   createDir(dest)
#   for kind, path in walkDir(source):
#     var noSource = splitPath(path).tail
#     if kind == pcDir:
#       copyDir(path, dest / noSource)
#     else:
#       copyFile(path, dest / noSource, {cfSymlinkAsIs})

# proc moveDir*(source, dest: string) {.tags: [ReadIOEffect, WriteIOEffect], noWeirdTarget.} =
#   ## Moves a directory from `source` to `dest`.
#   ##
#   ## Symlinks are not followed: if `source` contains symlinks, they themself are
#   ## moved, not their target.
#   ##
#   ## If this fails, `OSError` is raised.
#   ##
#   ## See also:
#   ## * `moveFile proc`_
#   ## * `copyDir proc`_
#   ## * `copyDirWithPermissions proc`_
#   ## * `removeDir proc`_
#   ## * `existsOrCreateDir proc`_
#   ## * `createDir proc`_
#   if not tryMoveFSObject(source, dest, isDir = true):
#     # Fallback to copy & del
#     copyDir(source, dest)
#     removeDir(source)