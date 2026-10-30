# Experimental nifmake variant: BIF symlinks carry per-artifact freshness.
import std/[os, times, strutils]
import ../dist/nimony/src/lib/vfs

proc vfsMtime(path: string): int64 =
  if (path.endsWith(".s.bif") or path.endsWith(".t.bif")) and symlinkExists(path):
    let t = getFileInfo(path, followSymlink = false).lastWriteTime
    t.toUnix * 1_000_000_000'i64 + int64(t.nanosecond)
  else:
    vfs.vfsMtime(path)

include ../dist/nimony/src/nifmake/nifmake
