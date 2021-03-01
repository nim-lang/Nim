#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module is deprecated, `import os` instead.
{.deprecated: "import os.nim instead".}

import os
export ReadEnvEffect, WriteEnvEffect, ReadDirEffect, WriteDirEffect, OSErrorCode,
  doslikeFileSystem, CurDir, ParDir, DirSep, AltSep, PathSep, FileSystemCaseSensitive,
  ExeExt, ScriptExt, DynlibFormat, ExtSep, joinPath, `/`, splitPath, parentDir,
  tailDir, isRootDir, parentDirs, `/../`, searchExtPos, splitFile, extractFilename,
  lastPathPart, changeFileExt, addFileExt, cmpPaths, isAbsolute, unixToNativePath,
  `==`, `$`, osErrorMsg, raiseOSError, osLastError, getEnv, existsEnv, putEnv,
  getHomeDir, getConfigDir, getTempDir, expandTilde, quoteShellWindows,
  quoteShellPosix, quoteShell, quoteShellCommand
