discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/private/ntpath
import std/assertions

block: # From Python's `Lib/test/test_ntpath.py`
  doAssert splitDrive(r"c:\foo\bar") == (r"c:", r"\foo\bar")
  doAssert splitDrive(r"c:/foo/bar") == (r"c:", r"/foo/bar")
  doAssert splitDrive(r"\\conky\mountpoint\foo\bar") == (r"\\conky\mountpoint", r"\foo\bar")
  doAssert splitDrive(r"//conky/mountpoint/foo/bar") == (r"//conky/mountpoint", r"/foo/bar")
  doAssert splitDrive(r"\\\conky\mountpoint\foo\bar") == (r"", r"\\\conky\mountpoint\foo\bar")
  doAssert splitDrive(r"///conky/mountpoint/foo/bar") == (r"", r"///conky/mountpoint/foo/bar")
  doAssert splitDrive(r"\\conky\\mountpoint\foo\bar") == (r"", r"\\conky\\mountpoint\foo\bar")
  doAssert splitDrive(r"//conky//mountpoint/foo/bar") == (r"", r"//conky//mountpoint/foo/bar")
  # Issue #19911: UNC part containing U+0130
  doAssert splitDrive(r"//conky/MOUNTPOİNT/foo/bar") == (r"//conky/MOUNTPOİNT", r"/foo/bar")
  # gh-81790: support device namespace, including UNC drives.
  doAssert splitDrive(r"//?/c:") == (r"//?/c:", r"")
  doAssert splitDrive(r"//?/c:/") == (r"//?/c:", r"/")
  doAssert splitDrive(r"//?/c:/dir") == (r"//?/c:", r"/dir")
  doAssert splitDrive(r"//?/UNC") == (r"", r"//?/UNC")
  doAssert splitDrive(r"//?/UNC/") == (r"", r"//?/UNC/")
  doAssert splitDrive(r"//?/UNC/server/") == (r"//?/UNC/server/", r"")
  doAssert splitDrive(r"//?/UNC/server/share") == (r"//?/UNC/server/share", r"")
  doAssert splitDrive(r"//?/UNC/server/share/dir") == (r"//?/UNC/server/share", r"/dir")
  doAssert splitDrive(r"//?/VOLUME{00000000-0000-0000-0000-000000000000}/spam") == (r"//?/VOLUME{00000000-0000-0000-0000-000000000000}", r"/spam")
  doAssert splitDrive(r"//?/BootPartition/") == (r"//?/BootPartition", r"/")

  doAssert splitDrive(r"\\?\c:") == (r"\\?\c:", r"")
  doAssert splitDrive(r"\\?\c:\") == (r"\\?\c:", r"\")
  doAssert splitDrive(r"\\?\c:\dir") == (r"\\?\c:", r"\dir")
  doAssert splitDrive(r"\\?\UNC") == (r"", r"\\?\UNC")
  doAssert splitDrive(r"\\?\UNC\") == (r"", r"\\?\UNC\")
  doAssert splitDrive(r"\\?\UNC\server\") == (r"\\?\UNC\server\", r"")
  doAssert splitDrive(r"\\?\UNC\server\share") == (r"\\?\UNC\server\share", r"")
  doAssert splitDrive(r"\\?\UNC\server\share\dir") == (r"\\?\UNC\server\share", r"\dir")
  doAssert splitDrive(r"\\?\VOLUME{00000000-0000-0000-0000-000000000000}\spam") == (r"\\?\VOLUME{00000000-0000-0000-0000-000000000000}", r"\spam")
  doAssert splitDrive(r"\\?\BootPartition\") == (r"\\?\BootPartition", r"\")

block:
  doAssert splitDrive(r"C:") == (r"C:", r"")
  doAssert splitDrive(r"C:\") == (r"C:", r"\")
  doAssert splitDrive(r"non/absolute/path") == (r"", r"non/absolute/path")

  # Special for `\`-rooted paths on Windows. I don't know if this is correct,
  # rbut `\` is not recognized as a drive, in contrast to `C:` or `\?\c:`.
  # This behavior is the same for Python's `splitdrive` function.
  doAssert splitDrive(r"\\") == (r"", r"\\")
