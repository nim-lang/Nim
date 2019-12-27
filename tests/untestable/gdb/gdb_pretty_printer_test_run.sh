#!/usr/bin/env bash
# Exit if anything fails
set -e
#!/usr/bin/env bash
# Compile the test project with fresh debug information.
nim c --debugger:native gdb_pretty_printer_test_program.nim &> /dev/null
# 2>&1 redirects stderr to stdout (all output in stdout)
# <(...) is a bash feature that makes the output of a command into a
# file handle.
# diff compares the two files, the expected output, and the file
# handle that is created by the execution of gdb.
diff ./gdb_pretty_printer_test_output.txt <(gdb -x gdb_pretty_printer_test.py --batch-silent --args gdb_pretty_printer_test_program 2>&1)
# The exit code of diff is forwarded as the exit code of this
# script. So when the comparison fails, the exit code of this script
# won't be 0. So this script should be embeddable in a test suite.
