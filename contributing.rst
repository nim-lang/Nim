The git stuff
=============

`Guide by github, scroll down a bit<https://guides.github.com/activities/contributing-to-open-source/>`_

# Deprecation

Backward compatibility is important, so if you are renaming a proc or
a type, you can use


.. code-block:: nim
  {.deprecated [oldName: new_name].}

Or you can simply use

.. code-block:: nim
  proc oldProc() {.deprecated.}

to mark a symbol as deprecated. Works for procs/types/vars/consts,
etc.

`Deprecated pragma in the manual.<http://nim-lang.org/docs/manual.html#pragmas-deprecated-pragma>`_

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
      doAssert seq2D == @[@[true, true], @[true, false], @[false, false], @[false, false]]

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

  type
    PTest = ref object

  proc test(x: PTest, y: int) = nil

  var buf: PTest
  buf.test()

Running tests
=============

You can run the tests with

.. code-block:: bash
  ./koch tests

which will run a good subset of tests. Some tests may fail.

Comparing tests
===============

Because some tests fail in the current ``devel`` branch, not every fail
after your change is necessarily caused by your changes.

The tester can compare two test runs. First, you need to create the
reference test. You'll also need to the commit id, because that's what
the tester needs to know in order to compare the two.

.. code-block:: bash
  git checkout devel
  DEVEL_COMMIT=$(git rev-parse HEAD)
  ./koch tests

Then switch over to your changes and run the tester again.

.. code-block:: bash
  git checkout your-changes
  ./koch tests

Then you can ask the tester to create a ``testresults.html`` which will
tell you if any new tests passed/failed.

.. code-block:: bash
  ./koch --print html $DEVEL_COMMIT
