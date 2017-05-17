# This file is prefixed with an "a", because other tests
# depend on it and it must be compiled first.
stdout.writeLine("to stdout")
stdout.flushFile()
stdout.writeLine("to stdout")
stdout.flushFile()

stderr.writeLine("to stderr")
stderr.flushFile()
stderr.writeLine("to stderr")
stderr.flushFile()

stdout.writeLine("to stdout")
stdout.flushFile()
stdout.writeLine("to stdout")
stdout.flushFile()
