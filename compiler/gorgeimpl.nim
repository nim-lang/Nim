#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Module that implements ``gorge`` for the compiler.
##
## On POSIX a command that needs no shell runs without one (see
## `shellfreeexec`): the shell made the host's `/bin/sh`, its C library and
## its libraries part of every compile that calls `staticExec`, as it did of
## every C compile, for a build tool that records what a compile reads.

import msgs, options, lineinfos, pathutils, shellfreeexec

import std/[os, osproc, streams, strtabs]

when defined(posix):
  from std/posix import ENOEXEC

when defined(nimPreviewSlimSystem):
  import std/syncio

import ../dist/checksums/src/checksums/sha1

proc readOutput(p: Process): (string, int) =
  result[0] = ""
  var output = p.outputStream
  while not output.atEnd:
    result[0].add(output.readLine)
    result[0].add("\n")
  if result[0].len > 0:
    result[0].setLen(result[0].len - "\n".len)
  result[1] = p.waitForExit

proc startGorgeProcess(cmd, workingDir: string): Process =
  ## Start `cmd` as `staticExec` runs it: in `workingDir`, with stderr merged
  ## into stdout. A command that needs the shell is handed to `/bin/sh -c`
  ## (`poEvalCommand`) unchanged; one that does not (`directCommand`) runs
  ## directly, in the directory its `cd` names when it has one. The shell
  ## sets `PWD` to the directory it runs the command in, so the direct route
  ## does too. A program that cannot be started, or a directory that cannot
  ## be entered, raises `OSError`; the shell would have said so on its
  ## output and exited with a failure code, which `runGorge` reports.
  when defined(windows):
    result = startProcess(cmd, workingDir,
                          options={poEvalCommand, poStdErrToStdOut})
  else:
    let direct = directCommand(cmd)
    if direct.argv.len == 0:
      result = startProcess(cmd, workingDir,
                            options={poEvalCommand, poStdErrToStdOut})
    else:
      let dir = if direct.dir.len > 0: normalizedPath(direct.dir)
                else: workingDir
      var env = newStringTable(modeCaseSensitive)
      for key, value in envPairs():
        env[key] = value
      # After `cd DIR` the shell exports DIR as `cd` made it (`dir`); a
      # shell started in a directory exports what `shellStartPwd` says.
      env["PWD"] = if direct.dir.len > 0: dir else: shellStartPwd(dir)
      try:
        result = startProcess(direct.argv[0], dir,
          args = direct.argv.toOpenArray(1, direct.argv.high), env = env,
          options = {poUsePath, poStdErrToStdOut})
      except OSError as e:
        # A file without a `#!` line is not an executable the kernel knows,
        # and the shell runs it as a script of its own: hand it the command.
        if e.errorCode != ENOEXEC: raise
        result = startProcess(cmd, workingDir,
                              options={poEvalCommand, poStdErrToStdOut})

proc runGorge(cmd, input, workingDir: string): (string, int) =
  ## Run `cmd` (`startGorgeProcess`) with `input` on its stdin and return its
  ## merged output and exit code. A command run without the shell that cannot
  ## be started reports the reason and the exit code the shell would give
  ## (`notStartedExitCode`: 127 for no such program, 126 otherwise).
  var p: Process = nil
  try:
    p = startGorgeProcess(cmd, workingDir)
  except OSError as e:
    when defined(windows):
      raise
    else:
      if directCommand(cmd).argv.len == 0:
        raise
      when defined(nimLegacyGorgeErrors):
        return ("", -1)
      else:
        return (directCommand(cmd).argv[0] & ": " & e.msg,
                notStartedExitCode(e.errorCode))
  if input.len != 0:
    p.inputStream.write(input)
    p.inputStream.close()
  result = p.readOutput
  p.close()

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
      result = runGorge(cmd, input, workingDir)
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
      result = runGorge(cmd, input, workingDir)
    except IOError, OSError:
      when defined(nimLegacyGorgeErrors):
        result = ("", -1)
      else:
        result = ("Error running startProcess: " & getCurrentExceptionMsg(), -1)
