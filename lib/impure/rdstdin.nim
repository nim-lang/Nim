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

const useLinenoise = not (defined(windows) or defined(genode))

when useLinenoise:
  import linenoise

proc readLineFromStdin*(prompt: string, line: var string): bool {.
                        tags: [ReadIOEffect, WriteIOEffect].} =
  ## Reads a `line` from stdin. May raise `IOError`.
  ##
  ## A line of text may be delimited by ``\r``, ``\n`` or ``\r\n``, which are not
  ## part of the returned string.
  ##
  ## On platforms that support `linenoise`, it will be used.
  ##
  ## Returns `false` if the end of the file has been reached (or `^C` was entered),
  ## in which case `line.len == 0`. Entering an empty string would still return
  ## true.
  runnableExamples("-r:off"):
    echo readLineFromStdin("Is Nim awesome? (Y/n): ")
    var line: string
    while true:
      let ok = readLineFromStdin("How are you? ", line)
      if not ok: break # ctrl-C or ctrl-D will cause a break
      if line.len > 0: echo line
    echo "exiting"
  when useLinenoise:
    var buffer = linenoise.readLine(prompt)
    if isNil(buffer):
      line.setLen(0)
      return false
    line = $buffer
    if line.len > 0:
      historyAdd(buffer)
    linenoise.free(buffer)
    result = true
  else:
    stdout.write(prompt)
    result = readLine(stdin, line)

proc readLineFromStdin*(prompt: string): string {.inline.} =
  ## Outplace overload.
  runnableExamples("-r:off"):
    echo readLineFromStdin("Is Nim awesome? (Y/n): ")
  if not readLineFromStdin(prompt, result):
    raise newException(IOError, "no data returned by `readLineFromStdin`")
