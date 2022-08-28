discard """
"""

# This module contains derivative work of Python's `Lib/test/test_ntpath.py`
# module. This is attributed to the PSF-2.0 license with the given notice:
#
# Copyright (c) 2001-2022 Python Software Foundation; All Rights Reserved

import std/private/ntpath

block: # From Python's `Lib/test/test_ntpath.py`
  doAssert splitDrive("c:\\foo\\bar") == ("c:", "\\foo\\bar")
  doAssert splitDrive("c:/foo/bar") == ("c:", "/foo/bar")
  doAssert splitDrive("\\\\conky\\mountpoint\\foo\\bar") == ("\\\\conky\\mountpoint", "\\foo\\bar")
  doAssert splitDrive("//conky/mountpoint/foo/bar") == ("//conky/mountpoint", "/foo/bar")
  doAssert splitDrive("\\\\\\conky\\mountpoint\\foo\\bar") == ("", "\\\\\\conky\\mountpoint\\foo\\bar")
  doAssert splitDrive("///conky/mountpoint/foo/bar") == ("", "///conky/mountpoint/foo/bar")
  doAssert splitDrive("\\\\conky\\\\mountpoint\\foo\\bar") == ("", "\\\\conky\\\\mountpoint\\foo\\bar")
  doAssert splitDrive("//conky//mountpoint/foo/bar") == ("", "//conky//mountpoint/foo/bar")
  # Issue #19911: UNC part containing U+0130
  doAssert splitDrive("//conky/MOUNTPOİNT/foo/bar") == ("//conky/MOUNTPOİNT", "/foo/bar")
  # gh-81790: support device namespace, including UNC drives.
  doAssert splitDrive("//?/c:") == ("//?/c:", "")
  doAssert splitDrive("//?/c:/") == ("//?/c:", "/")
  doAssert splitDrive("//?/c:/dir") == ("//?/c:", "/dir")
  doAssert splitDrive("//?/UNC") == ("", "//?/UNC")
  doAssert splitDrive("//?/UNC/") == ("", "//?/UNC/")
  doAssert splitDrive("//?/UNC/server/") == ("//?/UNC/server/", "")
  doAssert splitDrive("//?/UNC/server/share") == ("//?/UNC/server/share", "")
  doAssert splitDrive("//?/UNC/server/share/dir") == ("//?/UNC/server/share", "/dir")
  doAssert splitDrive("//?/VOLUME{00000000-0000-0000-0000-000000000000}/spam") == ("//?/VOLUME{00000000-0000-0000-0000-000000000000}", "/spam")
  doAssert splitDrive("//?/BootPartition/") == ("//?/BootPartition", "/")

  doAssert splitDrive("\\\\?\\c:") == ("\\\\?\\c:", "")
  doAssert splitDrive("\\\\?\\c:\\") == ("\\\\?\\c:", "\\")
  doAssert splitDrive("\\\\?\\c:\\dir") == ("\\\\?\\c:", "\\dir")
  doAssert splitDrive("\\\\?\\UNC") == ("", "\\\\?\\UNC")
  doAssert splitDrive("\\\\?\\UNC\\") == ("", "\\\\?\\UNC\\")
  doAssert splitDrive("\\\\?\\UNC\\server\\") == ("\\\\?\\UNC\\server\\", "")
  doAssert splitDrive("\\\\?\\UNC\\server\\share") == ("\\\\?\\UNC\\server\\share", "")
  doAssert splitDrive("\\\\?\\UNC\\server\\share\\dir") == ("\\\\?\\UNC\\server\\share", "\\dir")
  doAssert splitDrive("\\\\?\\VOLUME{00000000-0000-0000-0000-000000000000}\\spam") == ("\\\\?\\VOLUME{00000000-0000-0000-0000-000000000000}", "\\spam")
  doAssert splitDrive("\\\\?\\BootPartition\\") == ("\\\\?\\BootPartition", "\\")

block:
  doAssert splitDrive("C:") == ("C:", "")
  doAssert splitDrive("C:\\") == ("C:", "\\")
  doAssert splitDrive("non/absolute/path") == ("", "non/absolute/path")

  # Special for `\`-rooted paths on Windows. I don't know if this is correct,
  # but `\` is not recognized as a drive, in contrast to `C:` or `\\?\c:`.
  # This behavior is the same for Python's `splitdrive` function.
  doAssert splitDrive("\\\\") == ("", "\\\\")
