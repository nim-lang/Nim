#!/usr/bin/env bash
set -e
# Compile the test project with fresh debug information.
nim c --debugger:native --mm:orc --out:gdbNew gdb_pretty_printer_test_program.nim
echo "Running new runtime tests..."
# 2>&1 redirects stderr to stdout (all output in stdout)
gdb -x gdb_pretty_printer_test.py --batch-silent --args gdbNew 2>&1


# Do it all again, but with old runtime
nim c --debugger:native --mm:refc --out:gdbOld gdb_pretty_printer_test_program.nim &> /dev/null
echo "Running old runtime tests"
gdb -x gdb_pretty_printer_test.py --batch-silent --args gdbOld 2>&1
