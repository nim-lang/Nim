discard """
  output: "pcDir\npcFile\npcLinkToDir\npcLinkToFile\n"
  joinable: false
"""

import os, strutils
# Cases
#  1 - String : Existing File : Symlink true
#  2 - String : Existing File : Symlink false
#  3 - String : Non-existing File : Symlink true
#  4 - String : Non-existing File : Symlink false
#  5 - Handle : Valid File
#  6 - Handle : Invalid File
#  7 - Handle : Valid Handle
#  8 - Handle : Invalid Handle

proc genBadFileName(limit = 100): string =
    ## Generates a filename of a nonexistent file.
    ## Returns "" if generation fails.
    result = "a"
    var hitLimit = true

    for i in 0..100:
      if fileExists(result):
        result.add("a")
      else:
        hitLimit = false
        break
    if hitLimit:
      result = ""

proc caseOneAndTwo(followLink: bool) =
  try:
    discard getFileInfo(getAppFilename(), followLink)
    #echo("String : Existing File : Symlink $# : Success" % $followLink)
  except OSError:
    echo("String : Existing File : Symlink $# : Failure" % $followLink)

proc caseThreeAndFour(followLink: bool) =
  var invalidName = genBadFileName()
  try:
    discard getFileInfo(invalidName, true)
    echo("String : Non-existing File : Symlink $# : Failure" % $followLink)
  except OSError:
    discard
    #echo("String : Non-existing File : Symlink $# : Success" % $followLink)

proc testGetFileInfo =
  # Case 1
  caseOneAndTwo(true)

  # Case 2
  caseOneAndTwo(false)

  # Case 3
  caseThreeAndFour(true)

  # Case 4
  caseThreeAndFour(false)

  # Case 5 and 7
  block:
    let
      testFile = open(getAppFilename())
      testHandle = getFileHandle(testFile)
    try:
      discard getFileInfo(testFile)
      #echo("Handle : Valid File : Success")
    except IOError:
      echo("Handle : Valid File : Failure")

    try:
      discard getFileInfo(testHandle)
      #echo("Handle : Valid File : Success")
    except IOError:
      echo("Handle : Valid File : Failure")

  # Case 6 and 8
  block:
    let
      testFile: File = nil
      testHandle = FileHandle(-1)
    try:
      discard getFileInfo(testFile)
      echo("Handle : Invalid File : Failure")
    except IOError, OSError:
      discard
      #echo("Handle : Invalid File : Success")

    try:
      discard getFileInfo(testHandle)
      echo("Handle : Invalid File : Failure")
    except IOError, OSError:
      discard
      #echo("Handle : Invalid File : Success")

  # Test kind for files, directories and symlinks.
  block:
    let
      tmp = getTempDir()
      dirPath      = tmp / "test-dir"
      filePath     = tmp / "test-file"
      linkDirPath  = tmp / "test-link-dir"
      linkFilePath = tmp / "test-link-file"

    createDir(dirPath)
    writeFile(filePath, "")
    when defined(posix):
      createSymlink(dirPath, linkDirPath)
      createSymlink(filePath, linkFilePath)

    let
      dirInfo = getFileInfo(dirPath)
      fileInfo = getFileInfo(filePath)
    when defined(posix):
      let
        linkDirInfo = getFileInfo(linkDirPath, followSymlink = false)
        linkFileInfo = getFileInfo(linkFilePath, followSymlink = false)

    echo dirInfo.kind
    echo fileInfo.kind
    when defined(posix):
      echo linkDirInfo.kind
      echo linkFileInfo.kind
    else:
      echo pcLinkToDir
      echo pcLinkToFile

    removeDir(dirPath)
    removeFile(filePath)
    when defined(posix):
      removeFile(linkDirPath)
      removeFile(linkFilePath)

testGetFileInfo()
