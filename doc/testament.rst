Testament is an advanced automatic unittests runner for Nim tests, is used for the development of Nim itself,
offers process isolation for your tests, it can generate statistics about test cases,
supports multiple targets (C, C++, ObjectiveC, JavaScript, etc),
simulated `Dry-Runs <https://en.wikipedia.org/wiki/Dry_run_(testing)>`_,
has logging, can generate HTML reports, skip tests from a file and more,
so can be useful to run your tests, even the most complex ones.


Test files location
===================

By default Testament looks for test files on ``"./tests/*.nim"``,
you can overwrite this pattern glob using ``pattern <glob>``,
the default working directory path can be changed using ``--directory:"folder/subfolder/"``.

Testament uses the nim compiler on ``PATH`` you can change that using ``--nim:"folder/subfolder/nim"``,
running JavaScript tests with ``--targets:"js"`` requires a working NodeJS on ``PATH``.


Options
=======

* ``--print``                   Also print results to the console
* ``--simulate``                See what tests would be run but don't run them (for debugging)
* ``--failing``                 Only show failing/ignored tests
* ``--targets:"c c++ js objc"`` Run tests for specified targets (default: all)
* ``--nim:path``                Use a particular nim executable (default: ``$PATH/nim``)
* ``--directory:dir``           Change to directory dir before reading the tests or doing anything else.
* ``--colors:on|off``           Turn messages coloring on|off.
* ``--backendLogging:on|off``   Disable or enable backend logging. By default turned on.
* ``--skipFrom:file``           Read tests to skip from ``file`` - one test per line, # comments ignored


Running a single test
=====================

This is a minimal example to understand the basics,
not very useful for production, but easy to understand:

.. code::

  $ mkdir tests
  $ echo "assert 42 == 42" > tests/test0.nim
  $ testament run test0.nim
    PASS: tests/test0.nim C                                       ( 0.2 sec)

  $ testament r test0
    PASS: tests/test0.nim C                                       ( 0.2 sec)

  $


Running all tests from a directory
==================================

.. code::

  $ testament pattern "tests/*.nim"


HTML Reports
============

Generate HTML Reports ``testresults.html`` from unittests,
you have to run at least 1 test *before* generating a report:

.. code::

  $ testament html


Writing Unitests
================

Example "template" **to edit** and write a Testament unittest:

.. code-block:: nim

  discard """

    action: "run"     # What to do, one of "compile" OR "run".

    exitcode: 0       # This is the Exit Code the test should return, zero typically.

    output: ""        # This is the Standard Output the test should print, if any.

    input:  ""        # This is the Standard Input the test should take, if any.

    errormsg: ""      # Error message the test should print, if any.

    batchable: true   # Can be run in batch mode, or not.

    joinable: true    # Can be run Joined with other tests to run all togheter, or not.

    valgrind: false   # Can use Valgrind to check for memory leaks, or not (Linux 64Bit only).

    cmd: "nim c -r $file" # Command the test should use to run.

    maxcodesize: 666  # Maximum generated temporary intermediate code file size for the test.

    timeout: 666      # Timeout microseconds to run the test.

    target: "c js"    # Targets to run the test into (C, C++, JavaScript, etc).

    disabled: "bsd"   # Disable the test by condition, here BSD is disabled just as an example.
    disabled: "win"   # Can disable multiple OSes at once
    disabled: "32bit" # ...or architectures
    disabled: "i386"
    disabled: "azure" # ...or pipeline runners
    disabled: true    # ...or can disable the test entirely

  """
  assert true
  assert 42 == 42, "Assert error message"


* As you can see the "Spec" is just a ``discard """ """``.
* Spec has sane defaults, so you dont need to provide them all, any simple assert will work Ok.
* `This is not the full spec of Testament, check the Testament Spec on GitHub, see parseSpec(). <https://github.com/nim-lang/Nim/blob/devel/testament/specs.nim#L238>`_
* `Nim itself uses Testament, so theres plenty of test examples. <https://github.com/nim-lang/Nim/tree/devel/tests>`_
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
    target: "js"
  """
  when defined(js):
    import jsconsole
    console.log("My Frontend Project")

Compile time tests:

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
