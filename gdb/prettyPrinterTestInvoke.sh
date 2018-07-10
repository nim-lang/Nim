#!/usr/bin/env bash
# compile the test project with fresh debug information
nim c --debugger:native prettyPrinterTestFile.nim &> /dev/null
# 2>&1 redirects stderr to stdout (all output in stdout)
# <(...) is a bash feature that makes the output of a command into a
# file handle.
# diff compares the two files, the expected output, and the file
# handle that is created by the execution of gdb.
diff -q ./prettyPrinterTestOutput <(gdb -x prettyPrinterTestFile.py --batch-silent --args prettyPrinterTestFile 2>&1)
# The exit code of diff is forwarded as the exit code of this
# script. So when the comparison fails, the exit code of this script
# won't be 0. So this script should be embeddable in a test suite.
