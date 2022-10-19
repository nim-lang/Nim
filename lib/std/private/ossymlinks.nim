include system/inclrtl
import std/oserrors

import oscommon
export symlinkExists

when defined(nimPreviewSlimSystem):
  import std/[syncio, assertions, widestrs]

when weirdTarget:
  discard
elif defined(windows):
  import winlean, times
elif defined(posix):
  import posix
else:
  {.error: "OS module not ported to your operating system!".}


when weirdTarget:
  {.pragma: noWeirdTarget, error: "this proc is not available on the NimScript/js target".}
else:
  {.pragma: noWeirdTarget.}


when defined(windows) and not weirdTarget:
  when useWinUnicode:
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
  else:
    template findFirstFile(a, b: untyped): untyped = findFirstFileA(a, b)
    template findNextFile(a, b: untyped): untyped = findNextFileA(a, b)
    template getCommandLine(): untyped = getCommandLineA()

    template getFilename(f: untyped): untyped = $cstring(addr f.cFileName)

  proc skipFindData(f: WIN32_FIND_DATA): bool {.inline.} =
    # Note - takes advantage of null delimiter in the cstring
    const dot = ord('.')
    result = f.cFileName[0].int == dot and (f.cFileName[1].int == 0 or
             f.cFileName[1].int == dot and f.cFileName[2].int == 0)


when defined(nimscript):
  # for procs already defined in scriptconfig.nim
  template noNimJs(body): untyped = discard
elif defined(js):
  {.pragma: noNimJs, error: "this proc is not available on the js target".}
else:
  {.pragma: noNimJs.}

{.pragma: paths.}
{.pragma: files.}
{.pragma: dirs.}
{.pragma: symlinks.}
{.pragma: appdirs.}



proc createSymlink*(src, dest: string) {.noWeirdTarget, symlinks.} =
  ## Create a symbolic link at `dest` which points to the item specified
  ## by `src`. On most operating systems, will fail if a link already exists.
  ##
  ## .. warning:: Some OS's (such as Microsoft Windows) restrict the creation
  ##   of symlinks to root users (administrators) or users with developer mode enabled.
  ##
  ## See also:
  ## * `createHardlink proc`_
  ## * `expandSymlink proc`_

  when defined(windows):
    const SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE = 2
    # allows anyone with developer mode on to create a link
    let flag = dirExists(src).int32 or SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
    when useWinUnicode:
      var wSrc = newWideCString(src)
      var wDst = newWideCString(dest)
      if createSymbolicLinkW(wDst, wSrc, flag) == 0 or getLastError() != 0:
        raiseOSError(osLastError(), $(src, dest))
    else:
      if createSymbolicLinkA(dest, src, flag) == 0 or getLastError() != 0:
        raiseOSError(osLastError(), $(src, dest))
  else:
    if symlink(src, dest) != 0:
      raiseOSError(osLastError(), $(src, dest))

proc expandSymlink*(symlinkPath: string): string {.noWeirdTarget, symlinks.} =
  ## Returns a string representing the path to which the symbolic link points.
  ##
  ## On Windows this is a noop, `symlinkPath` is simply returned.
  ##
  ## See also:
  ## * `createSymlink proc`_
  when defined(windows):
    result = symlinkPath
  else:
    result = newString(maxSymlinkLen)
    var len = readlink(symlinkPath, result.cstring, maxSymlinkLen)
    if len < 0:
      raiseOSError(osLastError(), symlinkPath)
    if len > maxSymlinkLen:
      result = newString(len+1)
      len = readlink(symlinkPath, result.cstring, len)
    setLen(result, len)
