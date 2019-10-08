#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Module that implements ``gorge`` for the compiler.

import msgs, std / sha1, os, osproc, streams, options,
  lineinfos, pathutils

proc readOutput(p: Process): (string, int) =
  result[0] = ""
  var output = p.outputStream
  while not output.atEnd:
    result[0].add(output.readLine)
    result[0].add("\n")
  if result[0].len > 0:
    result[0].setLen(result[0].len - "\n".len)
  result[1] = p.waitForExit

proc opGorge*(cmd, input, cache: string, info: TLineInfo; conf: ConfigRef): (string, int) =
  let workingDir = parentDir(toFullPath(conf, info))
  if cache.len > 0:
    let h = secureHash(cmd & "\t" & input & "\t" & cache)
    let filename = toGeneratedFile(conf, AbsoluteFile("gorge_" & $h), "txt").string
    var f: File
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
      if not readSuccessful: result = ("", -1)
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
      result = ("", -1)
