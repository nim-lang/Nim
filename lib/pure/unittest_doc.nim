## :Author: Zahary Karadjov
##
## This module implements boilerplate to make unit testing easy.
##
## The test status and name is printed after any output or traceback.
##
## Tests can be nested, however failure of a nested test will not mark the
## parent test as failed. Setup and teardown are inherited. Setup can be
## overridden locally.
##
## Compiled test files return the number of failed test as exit code, while
## ``nim c -r <testfile.nim>`` exits with 0 or 1
##
## # Basic usage
##
## ## Running a single test
##
## Specify the test name as a command line argument.
##
## .. code::
##
##   nim c -r test "my test name" "another test"
##
## Multiple arguments can be used.
##
## ## Running a single test suite
##
## Specify the suite name delimited by ``"::"``.
##
## .. code::
##
##   nim c -r test "my test name::"
##
## ## Selecting tests by pattern
##
## A single ``"*"`` can be used for globbing.
##
## Delimit the end of a suite name with ``"::"``.
##
## Tests matching **any** of the arguments are executed.
##
## .. code::
##
##   nim c -r test fast_suite::mytest1 fast_suite::mytest2
##   nim c -r test "fast_suite::mytest*"
##   nim c -r test "auth*::" "crypto::hashing*"
##   # Run suites starting with 'bug #' and standalone tests starting with '#'
##   nim c -r test 'bug #*::' '::#*'
##
## # Example
##
## .. code:: nim
##
##   suite "description for this stuff":
##     echo "suite setup: run once before the tests"
##
##     setup:
##       echo "run before each test"
##
##     teardown:
##       echo "run after each test"
##
##     test "essential truths":
##       # give up and stop if this fails
##       require(true)
##
##     test "slightly less obvious stuff":
##       # print a nasty message and move on, skipping
##       # the remainder of this block
##       check(1 != 1)
##       check("asd"[2] == 'd')
##
##     test "out of bounds error is thrown on bad access":
##       let v = @[1, 2, 3]  # you can do initialization here
##       expect(IndexError):
##         discard v[4]
##
##     echo "suite teardown: run once after the tests"

