#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Module that implements ``gorge`` for the compiler.

import msgs, options, lineinfos, pathutils

import std/[os, osproc, streams]

when defined(nimPreviewSlimSystem):
  import std/syncio

import ../dist/checksums/src/checksums/sha1

proc readOutput(p: Process): (string, int) =
  var outp = p.outputStream
  # the following code is copied from osproc.execCmdEx
  #   @eea4ce0e2cf1dfdd2a90c2ab7f93888

  # consider `p.lines(keepNewLines=true)` to avoid exit code test
  result = ("", -1)
  var line = newStringOfCap(120)
  while true:
    if outp.readLine(line):
      result[0].add(line)
      result[0].add("\n")
    else:
      result[1] = peekExitCode(p)
      if result[1] != -1: break
  close(p)

proc opGorge*(cmd, input, cache: string, info: TLineInfo; conf: ConfigRef): (string, int) =
  let workingDir = parentDir(toFullPath(conf, info))
  result = ("", 0)
  if cache.len > 0:
    let h = secureHash(cmd & "\t" & input & "\t" & cache)
    let filename = toGeneratedFile(conf, AbsoluteFile("gorge_" & $h), "txt").string
    var f: File = default(File)
    if optForceFullMake notin conf.globalOptions and open(f, filename):
      result = (f.readAll, 0)
      f.close
      return
    var readSuccessful = false
    try:
      var p = startProcess(cmd, workingDir,
                           options={poEvalCommand, poStdErrToStdOut})
      if input.len != 0:
        p.inputStream.write(input)
        p.inputStream.close()
      result = p.readOutput
      p.close()
      readSuccessful = true
      # only cache successful runs:
      if result[1] == 0:
        writeFile(filename, result[0])
    except IOError, OSError:
      if not readSuccessful:
        when defined(nimLegacyGorgeErrors):
          result = ("", -1)
        else:
          result = ("Error running startProcess: " & getCurrentExceptionMsg(), -1)
  else:
    try:
      var p = startProcess(cmd, workingDir,
                           options={poEvalCommand, poStdErrToStdOut})
      if input.len != 0:
        p.inputStream.write(input)
        p.inputStream.close()
      result = p.readOutput
      p.close()
    except IOError, OSError:
      when defined(nimLegacyGorgeErrors):
        result = ("", -1)
      else:
        result = ("Error running startProcess: " & getCurrentExceptionMsg(), -1)
