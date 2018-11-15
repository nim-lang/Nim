discard """
  output: '''[Suite] suite #1

[Suite] suite #2
'''
"""

# Unfortunately, it's not possible to decouple the thread execution order from
# the number of available cores, due to how threadpool dynamically (and lazily)
# adjusts the number of worker threads, so we can't have a PRINT_ALL output in
# the verification section above.

import unittest, os

test "independent test #1":
  sleep(1000)
  check 1 == 1
  # check 1 == 2
  # require 1 == 2
  # var g {.global.}: seq[int]
  # g.add(1)

test "independent test #2":
  sleep(800)
  check 1 == 1

test "independent test #3":
  ## nested tests
  # we might as well keep this futile attempt at finding a problem with
  # uninitialized `flowVars` in child threads
  test "independent test #4":
    test "independent test #5":
      test "independent test #8":
        test "independent test #9":
          test "independent test #10":
            test "independent test #11":
              test "independent test #12":
                test "independent test #13":
                  test "independent test #14":
                    test "independent test #15":
                      sleep(200)
                      check 1 == 1
                    test "independent test #16":
                      sleep(200)
                      check 1 == 1
                    test "independent test #17":
                      sleep(200)
                      check 1 == 1
                    test "independent test #18":
                      sleep(200)
                      check 1 == 1
                    test "independent test #19":
                      sleep(200)
                      check 1 == 1
                    test "independent test #20":
                      sleep(200)
                      check 1 == 1
                    test "independent test #21":
                      sleep(200)
                      check 1 == 1
                    test "independent test #22":
                      sleep(200)
                      check 1 == 1
                    test "independent test #23":
                      sleep(200)
                      check 1 == 1
                    test "independent test #24":
                      sleep(200)
                      check 1 == 1
                    test "independent test #25":
                      test "independent test #26":
                        sleep(200)
                        check 1 == 1
                      sleep(200)
                      check 1 == 1
                    sleep(200)
                    check 1 == 1
                  sleep(200)
                  check 1 == 1
                sleep(200)
                check 1 == 1
              sleep(200)
              check 1 == 1
            sleep(200)
            check 1 == 1
          sleep(200)
          check 1 == 1
        sleep(200)
        check 1 == 1
      sleep(200)
      check 1 == 1
    sleep(400)
    check 1 == 1
  sleep(600)
  check 1 == 1

suite "suite #1":
  test "suite #1, test #1":
    sleep(400)
    check 1 == 1

  test "suite #1, test #2":
    sleep(300)
    check 1 == 1

suite "suite #2":
  setup:
    # only here can we set formatters when running the tests in parallel
    # (this setup will be executed for each test, so it may run multiple times
    # in the same thread, hence the clearing of the threadvar before adding to it)
    clearOutputFormatters()
    addOutputFormatter(newConsoleOutputFormatter(PRINT_FAILURES, colorOutput=false))

  teardown:
    # we don't want the custom formatter to remain in worker threads after this
    # suite is done
    clearOutputFormatters()

  test "suite #2, test #1":
    sleep(200)
    check 1 == 1

  test "suite #2, test #2":
    sleep(100)
    check 1 == 1

test "independent test #6":
  sleep(200)
  check 1 == 1

test "independent test #7":
  sleep(100)
  check 1 == 1

