#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
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
  proc ReadLineFromStdin*(prompt: string): string = 
    ## Reads a line from stdin.
    stdout.write(prompt)
    result = readLine(stdin)

else:
  import readline, history
    
  proc ReadLineFromStdin*(prompt: string): string = 
    var buffer = readline.readLine(prompt)
    if isNil(buffer): quit(0)
    result = $buffer
    if result.len > 0:
      add_history(buffer)
    readline.free(buffer)

  # initialization:
  # disable auto-complete: 
  discard readline.bind_key('\t'.ord, readline.abort) 

