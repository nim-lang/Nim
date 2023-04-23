
const DummyEof* = "!EOF!"
const Usage* = """
Nimsuggest - Tool to give every editor IDE like capabilities for Nim
Usage:
  nimsuggest [options] projectfile.nim

Options:
  --autobind              automatically binds into a free port
  --port:PORT             port, by default 6000
  --address:HOST          binds to that address, by default ""
  --stdin                 read commands from stdin and write results to
                          stdout instead of using sockets
  --epc                   use emacs epc mode
  --debug                 enable debug output
  --log                   enable verbose logging to nimsuggest.log file
  --v1                    use version 1 of the protocol; for backwards compatibility
  --v2                    use version 2(default) of the protocol
  --v3                    use version 3 of the protocol
  --refresh               perform automatic refreshes to keep the analysis precise
  --maxresults:N          limit the number of suggestions to N
  --tester                implies --stdin and outputs a line
                          '""" & DummyEof & """' for the tester
  --find                  attempts to find the project file of the current project

The server then listens to the connection and takes line-based commands.

If --autobind is used, the binded port number will be printed to stdout.

In addition, all command line options of Nim that do not affect code generation
are supported.
"""



const
  seps* = {':', ';', ' ', '\t'}
  Help* = "usage: sug|con|def|use|dus|chk|mod|highlight|outline|known|project file.nim[;dirtyfile.nim]:line:col\n" &
         "type 'quit' to quit\n" &
         "type 'debug' to toggle debug mode on/off\n" &
         "type 'terse' to toggle terse mode on/off"
