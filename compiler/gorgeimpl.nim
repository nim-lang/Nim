#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Module that implements ``gorge`` for the compiler as well as
## the scriptable import mechanism.

import msgs, securehash, os, osproc, streams, strutils, options

proc readOutput(p: Process): (string, int) =
  result[0] = ""
  var output = p.outputStream
  while not output.atEnd:
    result[0].add(output.readLine)
    result[0].add("\n")
  if result[0].len > 0:
    result[0].setLen(result[0].len - "\n".len)
  result[1] = p.waitForExit

proc opGorge*(cmd, input, cache: string, info: TLineInfo): (string, int) =
  let workingDir = parentDir(info.toFullPath)
  if cache.len > 0:# and optForceFullMake notin gGlobalOptions:
    let h = secureHash(cmd & "\t" & input & "\t" & cache)
    let filename = options.toGeneratedFile("gorge_" & $h, "txt")
    var f: File
    if open(f, filename):
      result = (f.readAll, 0)
      f.close
      return
    var readSuccessful = false
    try:
      var p = startProcess(cmd, workingDir,
                           options={poEvalCommand, poStderrToStdout})
      if input.len != 0:
        p.inputStream.write(input)
        p.inputStream.close()
      result = p.readOutput
      readSuccessful = true
      # only cache successful runs:
      if result[1] == 0:
        writeFile(filename, result[0])
    except IOError, OSError:
      if not readSuccessful: result = ("", -1)
  else:
    try:
      var p = startProcess(cmd, workingDir,
                           options={poEvalCommand, poStderrToStdout})
      if input.len != 0:
        p.inputStream.write(input)
        p.inputStream.close()
      result = p.readOutput
    except IOError, OSError:
      result = ("", -1)

proc scriptableImport*(pkg, subdir: string; info: TLineInfo): string =
  var cmd = getConfigVar("resolver.exe")
  if cmd.len == 0: cmd = "nimresolve"
  else: cmd = quoteShell(cmd)
  cmd.add " --source:"
  cmd.add quoteShell(info.toFullPath())
  cmd.add " --stdlib:"
  cmd.add quoteShell(options.libpath)
  cmd.add "  --project:"
  cmd.add quoteShell(gProjectFull)
  if subdir.len != 0:
    cmd.add " --subdir:"
    cmd.add quoteShell(subdir)
  if options.gNoNimblePath:
    cmd.add " --nonimblepath"
  cmd.add ' '
  cmd.add quoteShell(pkg)
  let (res, exitCode) = opGorge(cmd, "", cmd, info)
  if exitCode == 0:
    result = res.strip()
  elif res.len > 0:
    localError(info, res)
  else:
    localError(info, "cannot resolve: " & (pkg / subdir))
