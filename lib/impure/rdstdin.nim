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

runnableExamples("-r:off"):
  echo readLineFromStdin("Is Nim awesome? (Y/n): ")
  var line: string
  while true:
    let ok = readLineFromStdin("How are you? ", line)
    if not ok: break # ctrl-C or ctrl-D will cause a break
    if line.len > 0: echo line
  echo "exiting"

when defined(windows):
  proc readLineFromStdin*(prompt: string): string {.
                          tags: [ReadIOEffect, WriteIOEffect].} =
    ## Reads a line from stdin.
    stdout.write(prompt)
    result = readLine(stdin)

  proc readLineFromStdin*(prompt: string, line: var string): bool {.
                          tags: [ReadIOEffect, WriteIOEffect].} =
    ## Reads a `line` from stdin. `line` must not be
    ## `nil`! May throw an IO exception.
    ## A line of text may be delimited by `CR`, `LF` or
    ## `CRLF`. The newline character(s) are not part of the returned string.
    ## Returns `false` if the end of the file has been reached, `true`
    ## otherwise. If `false` is returned `line` contains no new data.
    stdout.write(prompt)
    result = readLine(stdin, line)

elif defined(genode):
  proc readLineFromStdin*(prompt: string): string {.
                          tags: [ReadIOEffect, WriteIOEffect].} =
    stdin.readLine()

  proc readLineFromStdin*(prompt: string, line: var string): bool {.
                          tags: [ReadIOEffect, WriteIOEffect].} =
    stdin.readLine(line)

else:
  import linenoise

  proc readLineFromStdin*(prompt: string, line: var string): bool {.
                          tags: [ReadIOEffect, WriteIOEffect].} =
    var buffer = linenoise.readLine(prompt)
    if isNil(buffer):
      line.setLen(0)
      return false
    line = $buffer
    if line.len > 0:
      historyAdd(buffer)
    linenoise.free(buffer)
    result = true

  proc readLineFromStdin*(prompt: string): string {.inline.} =
    if not readLineFromStdin(prompt, result):
      raise newException(IOError, "Linenoise returned nil")
