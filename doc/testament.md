===========
 Testament
===========

.. default-role:: code
.. include:: rstcommon.rst
.. contents::

Testament is an advanced automatic unittests runner for Nim tests, is used for the development of Nim itself,
offers process isolation for your tests, it can generate statistics about test cases,
supports multiple targets (C, C++, ObjectiveC, JavaScript, etc),
simulated `Dry-Runs <https://en.wikipedia.org/wiki/Dry_run_(testing)>`_,
has logging, can generate HTML reports, skip tests from a file, and more,
so can be useful to run your tests, even the most complex ones.


Test files location
===================

By default Testament looks for test files on ``"./tests/*.nim"``.
You can overwrite this pattern glob using `pattern <glob>`:option:.
The default working directory path can be changed using
`--directory:"folder/subfolder/"`:option:.

Testament uses the `nim`:cmd: compiler on `PATH`.
You can change that using `--nim:"folder/subfolder/nim"`:option:.
Running JavaScript tests with `--targets:"js"`:option: requires
a working NodeJS on `PATH`.


Options
=======

--print                   Also print results to the console
--simulate                See what tests would be run but don't run them
                          (for debugging)
--failing                 Only show failing/ignored tests
--targets:"c cpp js objc"
                          Run tests for specified targets (default: c)
--nim:path                Use a particular nim executable (default: $PATH/nim)
--directory:dir           Change to directory dir before reading the tests
                          or doing anything else.
--colors:on|off           Turn messages coloring on|off.
--backendLogging:on|off   Disable or enable backend logging.
                          By default turned on.
--skipFrom:file           Read tests to skip from ``file`` - one test per
                          line, # comments ignored


Running a single test
=====================

This is a minimal example to understand the basics,
not very useful for production, but easy to understand:

.. code:: console

  $ mkdir tests
  $ echo "assert 42 == 42" > tests/test0.nim
  $ testament run test0.nim
  PASS: tests/test0.nim C                                    ( 0.2 sec)
  $ testament r test0
  PASS: tests/test0.nim C                                    ( 0.2 sec)


Running all tests from a directory
==================================

.. code:: console

  $ testament pattern "tests/*.nim"

To search for tests deeper in a directory, use

.. code:: console

  $ testament pattern "tests/**/*.nim"    # one level deeper
  $ testament pattern "tests/**/**/*.nim" # two levels deeper

HTML Reports
============

Generate HTML Reports ``testresults.html`` from unittests,
you have to run at least 1 test *before* generating a report:

.. code:: console

  $ testament html


Writing Unitests
================

Example "template" **to edit** and write a Testament unittest:

.. code-block:: nim

  discard """

    # What actions to expect completion on.
    # Options:
    #   "compile": expect successful compilation
    #   "run": expect successful compilation and execution
    #   "reject": expect failed compilation. The "reject" action can catch
    #             {.error.} pragmas but not {.fatal.} pragmas because
    #             {.fatal.} pragmas guarantee that compilation will be aborted.
    action: "run"

    # The exit code that the test is expected to return. Typically, the default
    # value of 0 is fine. Note that if the test will be run by valgrind, then
    # the test will exit with either a code of 0 on success or 1 on failure.
    exitcode: 0

    # Provide an `output` string to assert that the test prints to standard out
    # exatly the expected string. Provide an `outputsub` string to assert that
    # the string given here is a substring of the standard out output of the
    # test.
    output: ""
    outputsub: ""

    # Whether to sort the output lines before comparing them to the desired
    # output.
    sortoutput: true

    # Each line in the string given here appears in the same order in the
    # compiler output, but there may be more lines that appear before, after, or
    # in between them.
    nimout: '''
  a very long,
  multi-line
  string'''

    # This is the Standard Input the test should take, if any.
    input: ""

    # Error message the test should print, if any.
    errormsg: ""

    # Can be run in batch mode, or not.
    batchable: true

    # Can be run Joined with other tests to run all togheter, or not.
    joinable: true

    # On Linux 64-bit machines, whether to use Valgrind to check for bad memory
    # accesses or memory leaks. On other architectures, the test will be run
    # as-is, without Valgrind.
    # Options:
    #   true: run the test with Valgrind
    #   false: run the without Valgrind
    #   "leaks": run the test with Valgrind, but do not check for memory leaks
    valgrind: false   # Can use Valgrind to check for memory leaks, or not (Linux 64Bit only).

    # Command the test should use to run. If left out or an empty string is
    # provided, the command is taken to be:
    # "nim $target --hints:on -d:testing --nimblePath:build/deps/pkgs $options $file"
    # You can use the $target, $options, and $file placeholders in your own
    # command, too.
    cmd: "nim c -r $file"

    # Maximum generated temporary intermediate code file size for the test.
    maxcodesize: 666

    # Timeout seconds to run the test. Fractional values are supported.
    timeout: 1.5

    # Targets to run the test into (c, cpp, objc, js). Defaults to c.
    targets: "c js"

    # flags with which to run the test, delimited by `;`
    matrix: "; -d:release; -d:caseFoo -d:release"

    # Conditions that will skip this test. Use of multiple "disabled" clauses
    # is permitted.
    disabled: "bsd"   # Can disable OSes...
    disabled: "win"
    disabled: "32bit" # ...or architectures
    disabled: "i386"
    disabled: "azure" # ...or pipeline runners
    disabled: true    # ...or can disable the test entirely

  """
  assert true
  assert 42 == 42, "Assert error message"


* As you can see the "Spec" is just a `discard """ """`.
* Spec has sane defaults, so you don't need to provide them all, any simple assert will work just fine.
* `This is not the full spec of Testament, check the Testament Spec on GitHub, see parseSpec(). <https://github.com/nim-lang/Nim/blob/devel/testament/specs.nim#L238>`_
* `Nim itself uses Testament, so there are plenty of test examples. <https://github.com/nim-lang/Nim/tree/devel/tests>`_
* Has some built-in CI compatibility, like Azure Pipelines, etc.
* `Testament supports inlined error messages on Unittests, basically comments with the expected error directly on the code. <https://github.com/nim-lang/Nim/blob/9a110047cbe2826b1d4afe63e3a1f5a08422b73f/tests/effects/teffects1.nim>`_


Unitests Examples
=================

Expected to fail:

.. code-block:: nim

  discard """
    errormsg: "undeclared identifier: 'not_defined'"
  """
  assert not_defined == "not_defined", "not_defined is not defined"

Non-Zero exit code:

.. code-block:: nim

  discard """
    exitcode: 1
  """
  quit "Non-Zero exit code", 1

Standard output checking:

.. code-block:: nim

  discard """

    output: '''
  0
  1
  2
  3
  4
  5
  '''

  """
  for i in 0..5: echo i

JavaScript tests:

.. code-block:: nim

  discard """
    targets: "js"
  """
  when defined(js):
    import std/jsconsole
    console.log("My Frontend Project")

Compile-time tests:

.. code-block:: nim

  discard """
    action: "compile"
  """
  static: assert 9 == 9, "Compile time assert"

Tests without Spec:

.. code-block:: nim

  assert 1 == 1


See also:
* `Unittest <unittest.html>`_
