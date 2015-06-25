Writing tests
=============

Not all the tests follow this scheme, feel free to change the ones
that don't. Always leave the code cleaner than you found it.

Stdlib
------

If you change the stdlib (anything under ``lib/``), put a test in the
file you changed. Add the tests under an ``when isMainModule:``
condition so they only get executed when the tester is building the
file. Each test should be in a separate ``block:`` statement, such that
each has its own scope. Use boolean conditions and ``doAssert`` for the
testing by itself, don't rely on echo statements or similar.

Sample test:

.. code-block:: nim

  when isMainModule:
    block: # newSeqWith tests
      var seq2D = newSeqWith(4, newSeq[bool](2))
      seq2D[0][0] = true
      seq2D[1][0] = true
      seq2D[0][1] = true
      doAssert seq2D == @[@[true, true], @[true, false],
                          @[false, false], @[false, false]]

Compiler
--------

The tests for the compiler work differently, they are all located in
``tests/``. Each test has its own file, which is different from the
stdlib tests. At the beginning of every test is the expected side of
the test. Possible keys are:

- output: The expected output, most likely via ``echo``
- exitcode: Exit code of the test (via ``exit(number)``)
- errormsg: The expected error message
- file: The file the errormsg
- line: The line the errormsg was produced at

An example for a test:

.. code-block:: nim

  discard """
    errormsg: "type mismatch: got (PTest)"
  """

  type
    PTest = ref object

  proc test(x: PTest, y: int) = nil

  var buf: PTest
  buf.test()

Running tests
=============

You can run the tests with

::
  ./koch tests

which will run a good subset of tests. Some tests may fail. If you
only want to see the output of failing tests, go for

::
  ./koch tests --failing all

You can also run only a single category of tests. A category is a subdirectory
in the ``tests`` directory. There are a couple of special categories; for a
list of these, see ``tests/testament/categories.nim``, at the bottom.

::
  ./koch tests c lib

Comparing tests
===============

Because some tests fail in the current ``devel`` branch, not every fail
after your change is necessarily caused by your changes.

The tester can compare two test runs. First, you need to create the
reference test. You'll also need to the commit id, because that's what
the tester needs to know in order to compare the two.

::
  git checkout devel
  DEVEL_COMMIT=$(git rev-parse HEAD)
  ./koch tests

Then switch over to your changes and run the tester again.

::
  git checkout your-changes
  ./koch tests

Then you can ask the tester to create a ``testresults.html`` which will
tell you if any new tests passed/failed.

::
  ./koch --print html $DEVEL_COMMIT


Deprecation
===========

Backward compatibility is important, so if you are renaming a proc or
a type, you can use


.. code-block:: nim

  {.deprecated: [oldName: new_name].}

Or you can simply use

.. code-block:: nim

  proc oldProc() {.deprecated.}

to mark a symbol as deprecated. Works for procs/types/vars/consts,
etc. Note that currently the ``deprecated`` statement does not work well with
overloading so for routines the latter variant is better.


`Deprecated <http://nim-lang.org/docs/manual.html#pragmas-deprecated-pragma>`_
pragma in the manual.



The Git stuff
=============

General commit rules
--------------------

1. All changes introduced by the commit (diff lines) must be related to the
   subject of the commit.

   If you change some other unrelated to the subject parts of the file, because
   your editor reformatted automatically the code or whatever different reason,
   this should be excluded from the commit.

   *Tip:* Never commit everything as is using ``git commit -a``, but review
   carefully your changes with ``git add -p``.

2. Changes should not introduce any trailing whitespace.

   Always check your changes for whitespace errors using ``git diff --check``
   or add following ``pre-commit`` hook:

   .. code-block:: sh

      #!/bin/sh
      git diff --check --cached || exit $?

   No sane programming or markup language cares about trailing whitespace, so
   tailing whitespace is just a noise you should not introduce to the
   repository.

3. Describe your commit and use your common sense.
