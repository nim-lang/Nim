#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains code for reading from `stdin`:idx:. On UNIX the GNU
## readline library is wrapped and set up to provide default key bindings 
## (e.g. you can navigate with the arrow keys). On Windows ``system.readLine``
## is used. This suffices because Windows' console already provides the 
## wanted functionality.

when defined(Windows):
  proc readLineFromStdin*(prompt: string): TaintedString {.
                          tags: [FReadIO, FWriteIO].} = 
    ## Reads a line from stdin.
    stdout.write(prompt)
    result = readLine(stdin)

  proc readLineFromStdin*(prompt: string, line: var TaintedString): bool {.
                          tags: [FReadIO, FWriteIO].} =
    ## Reads a `line` from stdin. `line` must not be
    ## ``nil``! May throw an IO exception.
    ## A line of text may be delimited by ``CR``, ``LF`` or
    ## ``CRLF``. The newline character(s) are not part of the returned string.
    ## Returns ``false`` if the end of the file has been reached, ``true``
    ## otherwise. If ``false`` is returned `line` contains no new data.
    stdout.write(prompt)
    result = readLine(stdin, line)

else:
  import readline, history
    
  proc readLineFromStdin*(prompt: string): TaintedString {.
                          tags: [FReadIO, FWriteIO].} =
    var buffer = readline.readLine(prompt)
    if isNil(buffer): quit(0)
    result = TaintedString($buffer)
    if result.string.len > 0:
      add_history(buffer)
    readline.free(buffer)

  proc readLineFromStdin*(prompt: string, line: var TaintedString): bool {.
                          tags: [FReadIO, FWriteIO].} =
    var buffer = readline.readLine(prompt)
    if isNil(buffer): quit(0)
    line = TaintedString($buffer)
    if line.string.len > 0:
      add_history(buffer)
    readline.free(buffer)
    # XXX how to determine CTRL+D?
    result = true

  # initialization:
  # disable auto-complete: 
  proc doNothing(a, b: cint): cint {.cdecl, procvar.} = discard
  
  discard readline.bind_key('\t'.ord, doNothing)

