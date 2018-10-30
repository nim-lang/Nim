Contributing
============

Contributing happens via "Pull requests" (PR) on github. Every PR needs to be
reviewed before it can be merged and the Continuous Integration should be green.

The PR has to be approved (and is often merged too) by one "code owner", either
by the code owner who is responsible for the subsystem the PR belongs to or by
two core developers or by Araq.

See `codeowners <codeowners.html>`_ for more details.


Writing tests
=============

There are 3 types of tests:

1. ``runnableExamples`` documentation comment tests, ran by ``nim doc mymod.nim``
   These end up in documentation and ensure documentation stays in sync with code.

2. tests in ``when isMainModule:`` block, ran by ``nim c mymod.nim``
   ``nimble test`` also typially runs these in external nimble packages.

3. testament tests, eg: tests/stdlib/tospaths.nim (only used for Nim repo).

Not all the tests follow the convention here, feel free to change the ones
that don't. Always leave the code cleaner than you found it.

Stdlib
------

If you change the stdlib (anything under ``lib/``, eg ``lib/pure/ospaths.nim``),
put a test in the file you changed. Add the tests under a ``when isMainModule:``
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
      # doAssert with `not` can be done as follows:
      doAssert: not 1 == 2

Newer tests tend to be run via ``testament`` rather than via ``when isMainModule:``,
eg ``tests/stdlib/tospaths.nim``; this allows additional features such as custom
compiler flags; for more details see below.

Compiler
--------

The tests for the compiler use a testing tool called ``testament``. They are all
located in ``tests/`` (eg: ``tests/destructor/tdestructor3.nim``).
Each test has its own file. All test files are prefixed with ``t``. If you want
to create a file for import into another test only, use the prefix ``m``.

At the beginning of every test is the expected behavior of the test.
Possible keys are:

- output: The expected output, most likely via ``echo``
- exitcode: Exit code of the test (via ``exit(number)``)
- errormsg: The expected error message
- file: The file the errormsg was produced at
- line: The line the errormsg was produced at

For a full spec, see here: ``testament/specs.nim``

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
list of these, see ``testament/categories.nim``, at the bottom.

::

  ./koch tests c lib


For reproducible tests (to reproduce an environment more similar to the one
run by Continuous Integration on travis/appveyor), you may want to disable your
local configuration (eg in ``~/.config/nim/nim.cfg``) which may affect some
tests; this can also be achieved by using
``export XDG_CONFIG_HOME=pathtoAlternateConfig`` before running ``./koch``
commands.

Comparing tests
===============

Because some tests fail in the current ``devel`` branch, not every failure
after your change is necessarily caused by your changes. Some tests are
flaky and will fail on occasion; these are typically bugs that should be fixed.
Test failures can be grepped using ``Failure:``.

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

  ./koch tests --print html $DEVEL_COMMIT


Deprecation
===========

Backward compatibility is important, so instead of a rename you need to deprecate
the old name and introduce a new name:

.. code-block:: nim

  # for routines (proc/template/macro/iterator) and types:
  proc oldProc() {.deprecated: "use `newImpl: string -> int` instead".} = ...

  # for (const/var/let) the msg is not yet supported:
  const Foo {.deprecated.}  = 1

  # for enum types ``deprecated`` is not yet supported.


See also `Deprecated <https://nim-lang.org/docs/manual.html#pragmas-deprecated-pragma>`_
pragma in the manual.


Documentation
=============

When contributing new procs, be sure to add documentation, especially if
the proc is public. Documentation begins on the line
following the ``proc`` definition, and is prefixed by ``##`` on each line.

Runnable code examples are also encouraged, to show typical behavior with a few
test cases (typically 1 to 3 ``doAssert`` statements, depending on complexity).
These ``runnableExamples`` are automatically run by ``nim doc mymodule.nim``
as well as ``testament`` and guarantee they stay in sync.

.. code-block:: nim
  proc addBar*(a: string): string =
    ## Adds "Bar" to ``a``.
    runnableExamples:
      doAssert "baz".addBar == "bazBar"

     result = a & "Bar"

See `parentDir <https://nim-lang.github.io/Nim/ospaths.html#parentDir%2Cstring>`_
example.

The RestructuredText Nim uses has a special syntax for including code snippets
embedded in documentation; these are not run by ``nim doc`` and therefore are
not guaranteed to stay in sync, so ``runnableExamples`` is usually preferred:

.. code-block:: nim

  proc someproc*(): string =
    ## Return "something"
    ##
    ## .. code-block:: nim
    ##
    ##  echo someproc() # "something"
    result = "something" # single-hash comments do not produce documentation

The ``.. code-block:: nim`` followed by a newline and an indentation instructs the
``nim doc`` command to produce syntax-highlighted example code with the
documentation.

When forward declaration is used, the documentation should be included with the
first appearance of the proc.

.. code-block:: nim

  proc hello*(): string
    ## Put documentation here
  proc nothing() = discard
  proc hello*(): string =
    ## ignore this
    echo "hello"

The preferred documentation style is to begin with a capital letter and use
the imperative (command) form. That is, between:

.. code-block:: nim

  proc hello*(): string =
    # Return "hello"
    result = "hello"
or

.. code-block:: nim

  proc hello*(): string =
    # says hello
    result = "hello"

the first is preferred.

Best practices
=============

Note: these are general guidelines, not hard rules; there are always exceptions.
Code reviews can just point to a specific section here to save time and
propagate best practices.

.. _noimplicitbool:
Take advantage of no implicit bool conversion

.. code-block:: nim

  doAssert isValid() == true
  doAssert isValid() # preferred

.. _immediately_invoked_lambdas:
Immediately invoked lambdas (https://en.wikipedia.org/wiki/Immediately-invoked_function_expression)

.. code-block:: nim

  let a = (proc (): auto = getFoo())()
  let a = block:  # preferred
    getFoo()

.. _design_for_mcs:
Design with method call syntax (UFCS in other languages) chaining in mind

.. code-block:: nim

  proc foo(cond: bool, lines: seq[string]) # bad
  proc foo(lines: seq[string], cond: bool) # preferred
  # can be called as: `getLines().foo(false)`

.. _avoid_quit:
Use exceptions (including assert / doAssert) instead of ``quit``
rationale: https://forum.nim-lang.org/t/4089

.. code-block:: nim

  quit() # bad in almost all cases
  doAssert() # preferred

.. _tests_use_doAssert:
Use ``doAssert`` (or ``require``, etc), not ``assert`` in all tests.

.. code-block:: nim

  runnableExamples: assert foo() # bad
  runnableExamples: doAssert foo() # preferred

.. _delegate_printing:
Delegate printing to caller: return ``string`` instead of calling ``echo``
rationale: it's more flexible (eg allows caller to call custom printing,
including prepending location info, writing to log files, etc).

.. code-block:: nim

  proc foo() = echo "bar" # bad
  proc foo(): string = "bar" # preferred (usually)

.. _use_Option:
[Ongoing debate] Consider using Option instead of return bool + var argument,
unless stack allocation is needed (eg for efficiency).

.. code-block:: nim

  proc foo(a: var Bar): bool
  proc foo(): Option[Bar]

.. _use_doAssert_not_echo:
Tests (including in testament) should always prefer assertions over ``echo``,
except when that's not possible. It's more precise, easier for readers and
maintaners to where expected values refer to. See for example
https://github.com/nim-lang/Nim/pull/9335 and https://forum.nim-lang.org/t/4089

.. code-block:: nim

  echo foo() # adds a line in testament `discard` block.
  doAssert foo() == [1, 2] # preferred, except when not possible to do so.

The Git stuff
=============

General commit rules
--------------------

1. Bugfixes that should be backported to the latest stable release should
   contain the string ``[backport]`` in the commit message! There will be an
   outmated process relying on these. However, bugfixes also have the inherent
   risk of causing regressions which are worse for a "stable, bugfixes-only"
   branch, so in doubt, leave out the ``[backport]``. Standard library bugfixes
   are less critical than compiler bugfixes.

2. All changes introduced by the commit (diff lines) must be related to the
   subject of the commit.

   If you change something unrelated to the subject parts of the file, because
   your editor reformatted automatically the code or whatever different reason,
   this should be excluded from the commit.

   *Tip:* Never commit everything as is using ``git commit -a``, but review
   carefully your changes with ``git add -p``.

3. Changes should not introduce any trailing whitespace.

   Always check your changes for whitespace errors using ``git diff --check``
   or add following ``pre-commit`` hook:

   .. code-block:: sh

      #!/bin/sh
      git diff --check --cached || exit $?

4. Describe your commit and use your common sense.

   Example Commit messages: ``Fixes #123; refs #124``

   indicates that issue ``#123`` is completely fixed (github may automatically
   close it when the PR is committed), wheres issue ``#124`` is referenced
   (eg: partially fixed) and won't close the issue when committed.

5. Commits should be always be rebased against devel (so a fast forward
   merge can happen)

   eg: use ``git pull --rebase origin devel``. This is to avoid messing up
   git history, see `#8664 <https://github.com/nim-lang/Nim/issues/8664>`_ .
   Exceptions should be very rare: when rebase gives too many conflicts, simply
   squash all commits using the script shown in
   https://github.com/nim-lang/Nim/pull/9356


6. Do not mix pure formatting changes (eg whitespace changes, nimpretty) or
   automated changes (eg nimfix) with other code changes: these should be in
   separate commits (and the merge on github should not squash these into 1).


Continuous Integration (CI)
---------------------------

1. Continuous Integration is by default run on every push in a PR; this clogs
   the CI pipeline and affects other PR's; if you don't need it (eg for WIP or
   documentation only changes), add ``[ci skip]`` to your commit message title.
   This convention is supported by `Appveyor <https://www.appveyor.com/docs/how-to/filtering-commits/#skip-directive-in-commit-message>`_
   and `Travis <https://docs.travis-ci.com/user/customizing-the-build/#skipping-a-build>`_


2. Consider enabling CI (travis and appveyor) in your own Nim fork, and
   waiting for CI to be green in that fork (fixing bugs as needed) before
   opening your PR in original Nim repo, so as to reduce CI congestion. Same
   applies for updates on a PR: you can test commits on a separate private
   branch before updating the main PR.

Code reviews
------------

1. Whenever possible, use github's new 'Suggested change' in code reviews, which
   saves time explaining the change or applying it; see also
   https://forum.nim-lang.org/t/4317

.. include:: docstyle.rst


