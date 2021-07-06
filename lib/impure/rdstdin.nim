#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains code for reading from `stdin`:idx:. On UNIX the
## linenoise library is wrapped and set up to provide default key bindings
## (e.g. you can navigate with the arrow keys). On Windows `system.readLine`
## is used. This suffices because Windows' console already provides the
## wanted functionality.

import std/private/rdstdin_impl

type ReadLine* = object
  prompt*: string
  line*: string
  status*: ReadlineStatus

proc initReadLine*(prompt: string): ReadLine = ReadLine(prompt: prompt)

# These APIs are recommended to allow growing `ReadlineStatus`.
proc isError*(a: ReadlineStatus): bool {.inline.} =
  a == lnCtrlUnkown

proc isEndOfFile*(a: ReadlineStatus): bool {.inline.} =
  a == lnCtrlD

proc isInterrupt*(a: ReadlineStatus): bool {.inline.} =
  a == lnCtrlC

proc isNormal*(a: ReadlineStatus): bool {.inline.} =
  a == lnNormal

import std/os

const hasLinenoise = not (defined(windows) or defined(genode)) and fileExists(currentSourcePath.parentDir.parentDir / "wrappers/linenoise/linenoise.c")

when hasLinenoise:
  import linenoise

proc readLineFromStdin*(data: var ReadLine) {.tags: [ReadIOEffect, WriteIOEffect].} =
  ## Reads a line from stdin into `data.line`. May raise `IOError`.
  ##
  ## A line of text may be delimited by ``\r``, ``\n`` or ``\r\n``, which are not
  ## part of the returned string. `data.status` indicates the return status and
  ## can be queried via `isError`, `isEndOfFile`, `isInterrupt`, `isNormal`.
  ##
  ## On platforms that support `linenoise`, it will be used.
  runnableExamples("-r:off"):
    var data = initReadLine(prompt = "(prompt) ")
    while true:
      readLineFromStdin(data) # ctrl-D will exit, ctrl-C will go to next prompt
      if data.status.isError: echo "error"; break
      elif data.status.isEndOfFile: echo "^D called"; break
      elif data.status.isInterrupt: echo "^C called"; continue
      else: echo data.line
  when hasLinenoise:
    var data2: LinenoiseData
    let buf = linenoiseExtra(data.prompt, data2.addr)
    data.line = $buf
    free(buf)
    data.status = if buf != nil: lnNormal else: data2.status.ord.ReadlineStatus
    if data.line.len > 0:
      historyAdd data.line.cstring
  else:
    stdout.write(data.prompt)
    let ok = stdin.readLine(data.line)
    data.status = if ok: lnNormal else: lnCtrlUnkown

proc readLineFromStdin*(prompt: string, line: var string): bool =
  ## Inline overload that returns false on failure or when ^C or ^D was entered.
  runnableExamples("-r:off"):
    echo readLineFromStdin("Is Nim awesome? (Y/n): ")
    var line: string
    while true:
      let ok = readLineFromStdin("How are you? ", line)
      if not ok: break # ctrl-C or ctrl-D will cause a break
      if line.len > 0: echo line
    echo "exiting"
  var data = ReadLine(prompt: prompt)
  readLineFromStdin(data)
  line = data.line
  result = data.status.isNormal()

proc readLineFromStdin*(prompt: string): string {.inline.} =
  ## Outline overload, raises `IOError` on failure.
  if not readLineFromStdin(prompt, result):
    raise newException(IOError, "Linenoise returned nil")
