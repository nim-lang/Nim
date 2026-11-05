# Nim's standard nifmake uses the Nimony scheduler. BIF links carry an
# artifact-specific timestamp even when their targets are shared.
import std/[os, times, strutils]
import ../dist/nimony/src/lib/vfs

when defined(posix):
  import std/posix
  var atFdcwd {.importc: "AT_FDCWD", header: "<fcntl.h>".}: cint
  var atSymlinkNofollow {.importc: "AT_SYMLINK_NOFOLLOW", header: "<fcntl.h>".}: cint
  proc utimensat(dir: cint; path: cstring; times: ptr Timespec; flags: cint): cint
    {.importc, header: "<sys/stat.h>".}

proc isBifLink(path: string): bool =
  when defined(posix):
    (path.endsWith(".s.bif") or path.endsWith(".t.bif")) and symlinkExists(path)
  else:
    false

proc vfsMtime(path: string): int64 =
  if isBifLink(path):
    let t = getFileInfo(path, followSymlink = false).lastWriteTime
    t.toUnix * 1_000_000_000'i64 + int64(t.nanosecond)
  else:
    vfs.vfsMtime(path)

proc setLastModificationTime(path: string; t: times.Time) =
  when defined(posix):
    if isBifLink(path):
      var stamps = [Timespec(tv_sec: posix.Time(t.toUnix), tv_nsec: int(t.nanosecond)),
                    Timespec(tv_sec: posix.Time(t.toUnix), tv_nsec: int(t.nanosecond))]
      if utimensat(atFdcwd, path.cstring, addr stamps[0], atSymlinkNofollow) != 0:
        raiseOSError(osLastError())
      return
  os.setLastModificationTime(path, t)

# The IC driver uses this probe to avoid silently using an older scheduler.
when isMainModule:
  if paramCount() == 1 and paramStr(1) == "--nimBifLinksSupport":
    echo "nim-bif-links-v1"
    quit QuitSuccess

include ../dist/nimony/src/nifmake/nifmake
