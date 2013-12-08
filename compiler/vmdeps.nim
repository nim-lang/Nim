#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ast, types, msgs, osproc, streams, options

proc readOutput(p: PProcess): string =
  result = ""
  var output = p.outputStream
  discard p.waitForExit
  while not output.atEnd:
    result.add(output.readLine)

proc opGorge*(cmd, input: string): string =
  var p = startCmd(cmd)
  if input.len != 0:
    p.inputStream.write(input)
    p.inputStream.close()
  result = p.readOutput

proc opSlurp*(file: string, info: TLineInfo, module: PSym): string = 
  try:
    let filename = file.FindFile
    result = readFile(filename)
    # we produce a fake include statement for every slurped filename, so that
    # the module dependencies are accurate:
    appendToModule(module, newNode(nkIncludeStmt, info, @[
      newStrNode(nkStrLit, filename)]))
  except EIO:
    LocalError(info, errCannotOpenFile, file)
    result = ""
