# This module is inspired by Python's `ntpath.py` module.

import std/[
  strutils,
]

# Adapted `splitdrive` function from the following commits in Python source
# code:
# 5a607a3ee5e81bdcef3f886f9d20c1376a533df4 (2009): Initial UNC handling (by Mark Hammond)
# 2ba0fd5767577954f331ecbd53596cd8035d7186 (2022): Support for "UNC"-device paths (by Barney Gale)
#
# FAQ: Why use `strip` below? `\\?\UNC` is the start of a "UNC symbolic link",
# which is a special UNC form. Running `strip` differentiates `\\?\UNC\` (a UNC
# symbolic link) from e.g. `\\?\UNCD` (UNCD is the server in the UNC path).
func splitDrive*(p: string): tuple[drive, path: string] =
  ## Splits a Windows path into a drive and path part. The drive can be e.g.
  ## `C:`. It can also be a UNC path (`\\server\drive\path`).
  ##
  ## The equivalent `splitDrive` for POSIX systems always returns empty drive.
  ## Therefore this proc is only necessary on DOS-like file systems (together
  ## with Nim's `doslikeFileSystem` conditional variable).
  ##
  ## This proc's use case is to extract `path` such that it can be manipulated
  ## like a POSIX path.
  runnableExamples:
    doAssert splitDrive("C:") == ("C:", "")
    doAssert splitDrive(r"C:\") == (r"C:", r"\")
    doAssert splitDrive(r"\\server\drive\foo\bar") == (r"\\server\drive", r"\foo\bar")
    doAssert splitDrive(r"\\?\UNC\server\share\dir") == (r"\\?\UNC\server\share", r"\dir")

  result = ("", p)
  if p.len < 2:
    return
  const sep = '\\'
  let normp = p.replace('/', sep)
  if p.len > 2 and normp[0] == sep and normp[1] == sep and normp[2] != sep:

    # is a UNC path:
    # vvvvvvvvvvvvvvvvvvvv drive letter or UNC path
    # \\machine\mountpoint\directory\etc\...
    #           directory ^^^^^^^^^^^^^^^
    let start = block:
      const unc = "\\\\?\\UNC" # Length is 7
      let idx = min(8, normp.len)
      if unc == normp[0..<idx].strip(chars = {sep}, leading = false).toUpperAscii:
        8
      else:
        2
    let index = normp.find(sep, start)
    if index == -1:
      return
    var index2 = normp.find(sep, index + 1)

    # a UNC path can't have two slashes in a row (after the initial two)
    if index2 == index + 1:
      return
    if index2 == -1:
      index2 = p.len
    return (p[0..<index2], p[index2..^1])
  if p[1] == ':':
    return (p[0..1], p[2..^1])
