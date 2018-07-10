# Exit if anything fails
set -e
#!/usr/bin/env bash
# Compile the test project with fresh debug information.
nim c --debugger:native prettyPrinterTestProgram.nim &> /dev/null
# 2>&1 redirects stderr to stdout (all output in stdout)
# <(...) is a bash feature that makes the output of a command into a
# file handle.
# diff compares the two files, the expected output, and the file
# handle that is created by the execution of gdb.
diff -q ./prettyPrinterTestOutput <(gdb -x prettyPrinterTest.py --batch-silent --args prettyPrinterTestProgram 2>&1)
# The exit code of diff is forwarded as the exit code of this
# script. So when the comparison fails, the exit code of this script
# won't be 0. So this script should be embeddable in a test suite.
