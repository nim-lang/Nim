============
Contributing
============

.. default-role:: code
.. include:: rstcommon.rst

.. contents::


Contributing happens via "Pull requests" (PR) on github. Every PR needs to be
reviewed before it can be merged and the Continuous Integration should be green.

The PR has to be approved by two core developers or by Araq.



Writing tests
=============

There are 4 types of tests:

1. `runnableExamples` documentation comment tests, ran by `nim doc mymod.nim`:cmd:
   These end up in documentation and ensure documentation stays in sync with code.

2. separate test files, e.g.: ``tests/stdlib/tos.nim``.
   In nim repo, `testament`:cmd: (see below) runs all
   ``$nim/tests/*/t*.nim`` test files;
   for nimble packages, see https://github.com/nim-lang/nimble#tests.

3. (deprecated) tests in `when isMainModule:` block, ran by `nim r mymod.nim`:cmd:.
   `nimble test`:cmd: can run those in nimble packages when specified in a
   `task "test"`.

4. (not preferred) ``.. code-block:: nim`` RST snippets;
   these should only be used in rst sources,
   in nim sources `runnableExamples` should now always be preferred to those for
   several reasons (cleaner syntax, syntax highlights, batched testing, and
   parameter `rdoccmd` allows customization).

Not all the tests follow the convention here, feel free to change the ones
that don't. Always leave the code cleaner than you found it.

Stdlib
------

Each stdlib module (anything under ``lib/``, e.g. ``lib/pure/os.nim``) should
preferably have a corresponding separate test file, e.g. ``tests/stdlib/tos.nim``.
The old convention was to add a `when isMainModule:` block in the source file,
which only gets executed when the tester is building the file.

Each test should be in a separate `block:` statement, such that
each has its own scope. Use boolean conditions and `doAssert` for the
testing by itself, don't rely on echo statements or similar; in particular, avoid
things like `echo "done"`. Don't use `unittest.suite` and `unittest.test`.

Sample test:

.. code-block:: nim

  block: # foo
    doAssert foo(1) == 10

  block: # bug #1234
    static: doAssert 1+1 == 2

  block: # bug #1235
    var seq2D = newSeqWith(4, newSeq[bool](2))
    seq2D[0][0] = true
    seq2D[1][0] = true
    seq2D[0][1] = true
    doAssert seq2D == @[@[true, true], @[true, false],
                        @[false, false], @[false, false]]
    # doAssert with `not` can now be done as follows:
    doAssert not (1 == 2)

Always refer to a GitHub issue using the following exact syntax: ``bug #1234`` as shown
above, so that it's consistent and easier to search or for tooling. Some browser
extensions (e.g. https://github.com/sindresorhus/refined-github) will even turn those
in clickable links when it works.

Rationale for using a separate test file instead of `when isMainModule:` block:
* allows custom compiler flags or testing options (see details below)
* faster CI since they can be joined in ``megatest`` (combined into a single test)
* avoids making the parser do un-necessary work when a source file is merely imported
* avoids mixing source and test code when reporting line of code statistics or code coverage

Compiler
--------

The tests for the compiler use a testing tool called `testament`:cmd:. They are all
located in ``tests/`` (e.g.: ``tests/destructor/tdestructor3.nim``).
Each test has its own file. All test files are prefixed with `t`. If you want
to create a file for import into another test only, use the prefix `m`.

At the beginning of every test is the expected behavior of the test.
Possible keys are:

- `cmd`: A compilation command template e.g. `nim $target --threads:on $options $file`:cmd:
- `output`: The expected output (stdout + stderr), most likely via `echo`
- `exitcode`: Exit code of the test (via `exit(number)`)
- `errormsg`: The expected compiler error message
- `file`: The file the errormsg was produced at
- `line`: The line the errormsg was produced at

For a full spec, see here: ``testament/specs.nim``

An example of a test:

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

.. code-block:: cmd

  ./koch tests

which will run a good subset of tests. Some tests may fail. If you
only want to see the output of failing tests, go for

```cmd
  ./koch tests --failing all
```

You can also run only a single category of tests. A category is a subdirectory
in the ``tests/`` directory. There are a couple of special categories; for a
list of these, see ``testament/categories.nim``, at the bottom.

.. code:: cmd

  ./koch tests c lib # compiles / runs stdlib modules, including `isMainModule` tests
  ./koch tests c megatest # runs a set of tests that can be combined into 1

To run a single test:

.. code:: cmd

  ./koch test run <category>/<name>    # e.g.: tuples/ttuples_issues
  ./koch test run tests/stdlib/tos.nim # can also provide relative path

For reproducible tests (to reproduce an environment more similar to the one
run by Continuous Integration on github actions/azure pipelines), you may want to disable your
local configuration (e.g. in ``~/.config/nim/nim.cfg``) which may affect some
tests; this can also be achieved by using
`export XDG_CONFIG_HOME=pathtoAlternateConfig`:cmd: before running `./koch`:cmd:
commands.


Comparing tests
===============

Test failures can be grepped using ``Failure:``.

The tester can compare two test runs. First, you need to create a
reference test. You'll also need to the commit id, because that's what
the tester needs to know in order to compare the two.

.. code:: cmd

  git checkout devel
  DEVEL_COMMIT=$(git rev-parse HEAD)
  ./koch tests

Then switch over to your changes and run the tester again.

.. code:: cmd

  git checkout your-changes
  ./koch tests

Then you can ask the tester to create a ``testresults.html`` which will
tell you if any new tests passed/failed.

.. code:: cmd

  ./koch tests --print html $DEVEL_COMMIT


Deprecation
===========

Backward compatibility is important, so instead of a rename you need to deprecate
the old name and introduce a new name:

.. code-block:: nim

  # for routines (proc/template/macro/iterator) and types:
  proc oldProc(a: int, b: float): bool {.deprecated:
      "deprecated since v1.2.3; use `newImpl: string -> int` instead".} = discard

  # for (const/var/let/fields) the msg is not yet supported:
  const Foo {.deprecated.}  = 1

  # for enum types, you can deprecate the type or some elements
  # (likewise with object types and their fields):
  type Bar {.deprecated.} = enum bar0, bar1
  type Barz  = enum baz0, baz1 {.deprecated.}, baz2


See also `Deprecated <manual.html#pragmas-deprecated-pragma>`_
pragma in the manual.


Documentation
=============

When contributing new procs, be sure to add documentation, especially if
the proc is public. Even private procs benefit from documentation and can be
viewed using `nim doc --docInternal foo.nim`:cmd:.
Documentation begins on the line
following the `proc` definition, and is prefixed by `##` on each line.

Runnable code examples are also encouraged, to show typical behavior with a few
test cases (typically 1 to 3 `assert` statements, depending on complexity).
These `runnableExamples` are automatically run by `nim doc mymodule.nim`:cmd:
as well as `testament`:cmd: and guarantee they stay in sync.

.. code-block:: nim
  proc addBar*(a: string): string =
    ## Adds "Bar" to `a`.
    runnableExamples:
      assert "baz".addBar == "bazBar"
    result = a & "Bar"

See `parentDir <os.html#parentDir,string>`_ example.

The RestructuredText Nim uses has a special syntax for including code snippets
embedded in documentation; these are not run by `nim doc`:cmd: and therefore are
not guaranteed to stay in sync, so `runnableExamples` is almost always preferred:

.. code-block:: nim

  proc someProc*(): string =
    ## Returns "something"
    ##
    ## .. code-block::
    ##  echo someProc() # "something"
    result = "something" # single-hash comments do not produce documentation

The ``.. code-block:: nim`` followed by a newline and an indentation instructs the
`nim doc`:cmd: command to produce syntax-highlighted example code with the
documentation (``.. code-block::`` is sufficient from inside a nim module).

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
the third-person singular. That is, between:

.. code-block:: nim

  proc hello*(): string =
    ## Returns "hello"
    result = "hello"

or

.. code-block:: nim

  proc hello*(): string =
    ## say hello
    result = "hello"

the first is preferred.

When you specify an *RST role* (highlighting/interpretation marker) do it
in the postfix form for uniformity, that is after \`text in backticks\`.
For example an ``:idx:`` role for referencing a topic ("SQLite" in the
example below) from `Nim Index`_ can be used in doc comment this way:

.. code-block:: nim
  ## A higher level `SQLite`:idx: database wrapper.

.. _`Nim Index`: https://nim-lang.org/docs/theindex.html

Inline monospaced text can be input using \`single backticks\` or
\`\`double backticks\`\`. The former are syntactically highlighted,
the latter are not.
To avoid accidental highlighting follow this rule in ``*.nim`` files:

* use single backticks for fragments of code in Nim and other
  programming languages, including identifiers, in ``*.nim`` files.

  For languages other than Nim add a role after final backtick,
  e.g. for C++ inline highlighting::

    `#include <stdio.h>`:cpp:

  For a currently unsupported language add the `:code:` role,
  like for SQL in this example::

    `SELECT * FROM <table_name>;`:code:

  Highlight shell commands by ``:cmd:`` role; for command line options use
  ``:option:`` role, e.g.: \`--docInternal\`:option:.

* prefer double backticks otherwise:

  * for file names: \`\`os.nim\`\`
  * for fragments of strings **not** enclosed by `"` and `"` and not
    related to code, e.g. text of compiler messages
  * also when code ends with a standalone ``\`` (otherwise a combination of
    ``\`` and a final \` would get escaped)

.. Note:: ``*.rst`` files have ``:literal:`` as their default role.
          So for them the rule above is only applicable if the ``:nim:`` role
          is set up manually as the default [*]_::

            .. role:: nim(code)
               :language: nim
            .. default-role:: nim

          The first 2 lines are for other RST implementations,
          including Github one.

          .. [*] this is fulfilled when ``doc/rstcommon.rst`` is included.

Best practices
==============

Note: these are general guidelines, not hard rules; there are always exceptions.
Code reviews can just point to a specific section here to save time and
propagate best practices.

.. _define_needs_prefix:
New `defined(foo)` symbols need to be prefixed by the nimble package name, or
by `nim` for symbols in nim sources (e.g. compiler, standard library). This is
to avoid name conflicts across packages.

.. code-block:: nim

  # if in nim sources
  when defined(allocStats): discard # bad, can cause conflicts
  when defined(nimAllocStats): discard # preferred
  # if in a package `cligen`:
  when defined(debug): discard # bad, can cause conflicts
  when defined(cligenDebug): discard # preferred

.. _noimplicitbool:
Take advantage of no implicit bool conversion

.. code-block:: nim

  doAssert isValid() == true
  doAssert isValid() # preferred

.. _design_for_mcs:
Design with method call syntax chaining in mind

.. code-block:: nim

  proc foo(cond: bool, lines: seq[string]) # bad
  proc foo(lines: seq[string], cond: bool) # preferred
  # can be called as: `getLines().foo(false)`

.. _avoid_quit:
Use exceptions (including `assert` / `doAssert`) instead of `quit`
rationale: https://forum.nim-lang.org/t/4089

.. code-block:: nim

  quit() # bad in almost all cases
  doAssert() # preferred

.. _tests_use_doAssert:
Use `doAssert` (or `unittest.check`, `unittest.require`), not `assert` in all
tests so they'll be enabled even with `--assertions:off`:option:.

.. code-block:: nim

  block: # foo
    assert foo() # bad
    doAssert foo() # preferred

.. _runnableExamples_use_assert:
An exception to the above rule is `runnableExamples` and ``code-block`` rst blocks
intended to be used as `runnableExamples`, which for brevity use `assert`
instead of `doAssert`. Note that `nim doc -d:danger main`:cmd: won't pass `-d:danger`:option: to the
`runnableExamples`, but `nim doc --doccmd:-d:danger main`:cmd: would, and so would the
second example below:

.. code-block:: nim

  runnableExamples:
    doAssert foo() # bad
    assert foo() # preferred

  runnableExamples("-d:danger"):
    doAssert foo() # `assert` would be disabled here, so `doAssert` makes more sense

.. _delegate_printing:
Delegate printing to caller: return `string` instead of calling `echo`
rationale: it's more flexible (e.g. allows the caller to call custom printing,
including prepending location info, writing to log files, etc).

.. code-block:: nim

  proc foo() = echo "bar" # bad
  proc foo(): string = "bar" # preferred (usually)

.. _use_Option:
[Ongoing debate] Consider using Option instead of return bool + var argument,
unless stack allocation is needed (e.g. for efficiency).

.. code-block:: nim

  proc foo(a: var Bar): bool
  proc foo(): Option[Bar]

.. _use_doAssert_not_echo:
Tests (including in testament) should always prefer assertions over `echo`,
except when that's not possible. It's more precise, easier for readers and
maintainers to where expected values refer to. See for example
https://github.com/nim-lang/Nim/pull/9335 and https://forum.nim-lang.org/t/4089

.. code-block:: nim

  echo foo() # adds a line for testament in `output:` block inside `discard`.
  doAssert foo() == [1, 2] # preferred, except when not possible to do so.


The `git`:cmd: stuff
====================

General commit rules
--------------------

1. Important, critical bugfixes that have a tiny chance of breaking
   somebody's code should be backported to the latest stable release
   branch (currently 1.4.x) and maybe also all the way back to the 1.0.x branch.
   The commit message should contain the tag ``[backport]`` for "backport to the latest
   stable release" and the tag ``[backport:$VERSION]`` for backporting back to the
   given $VERSION (and all newer releases).

2. If you introduce changes which affect backward compatibility,
   make breaking changes, or have PR which is tagged as ``[feature]``,
   the changes should be mentioned in `the changelog
   <https://github.com/nim-lang/Nim/blob/devel/changelog.md>`_.

3. All changes introduced by the commit (diff lines) must be related to the
   subject of the commit.

   If you change something unrelated to the subject parts of the file, because
   your editor reformatted automatically the code or whatever different reason,
   this should be excluded from the commit.

   *Tip:* Never commit everything as is using `git commit -a`:cmd:, but review
   carefully your changes with `git add -p`:cmd:.

4. Changes should not introduce any trailing whitespace.

   Always check your changes for whitespace errors using `git diff --check`:cmd:
   or add the following ``pre-commit`` hook:

   .. code:: cmd

      #!/bin/sh
      git diff --check --cached || exit $?
5. Describe your commit and use your common sense.
   Example commit message::

     Fixes #123; refs #124

   indicates that issue ``#123`` is completely fixed (GitHub may automatically
   close it when the PR is committed), wheres issue ``#124`` is referenced
   (e.g.: partially fixed) and won't close the issue when committed.

6. PR body (not just PR title) should contain references to fixed/referenced github
   issues, e.g.: ``fix #123`` or ``refs #123``. This is so that you get proper cross
   referencing from linked issue to the PR (github won't make those links with just
   PR title, and commit messages aren't always sufficient to ensure that, e.g.
   can't be changed after a PR is merged).

7. Commits should be always be rebased against devel (so a fast forward
   merge can happen)

   e.g.: use `git pull --rebase origin devel`:cmd:. This is to avoid messing up
   git history.
   Exceptions should be very rare: when rebase gives too many conflicts, simply
   squash all commits using the script shown in
   https://github.com/nim-lang/Nim/pull/9356

8. Do not mix pure formatting changes (e.g. whitespace changes, nimpretty) or
   automated changes (e.g. nimfix) with other code changes: these should be in
   separate commits (and the merge on GitHub should not squash these into 1).


Continuous Integration (CI)
---------------------------

1. Continuous Integration is by default run on every push in a PR; this clogs
   the CI pipeline and affects other PR's; if you don't need it (e.g. for WIP or
   documentation only changes), add ``[skip ci]`` to your commit message title.
   This convention is supported by our github actions pipelines and our azure pipeline
   (using custom logic, which should complete in < 1mn) as well as our former other pipelines:
   `Appveyor <https://www.appveyor.com/docs/how-to/filtering-commits/#skip-directive-in-commit-message>`_
   and `Travis <https://docs.travis-ci.com/user/customizing-the-build/#skipping-a-build>`_.

2. Consider enabling CI (azure, GitHub actions and builds.sr.ht) in your own Nim fork, and
   waiting for CI to be green in that fork (fixing bugs as needed) before
   opening your PR in the original Nim repo, so as to reduce CI congestion. Same
   applies for updates on a PR: you can test commits on a separate private
   branch before updating the main PR.

Debugging CI failures, flaky tests, etc
---------------------------------------

1. First check the CI logs and search for `FAIL` to find why CI failed; if the
   failure seems related to your PR, try to fix the code instead of restarting CI.

2. If CI failure seems unrelated to your PR, it could be caused by a flaky test.
   File a bug for it if it isn't already reported. A PR push (or opening/closing PR)
   will re-trigger all CI jobs (even successful ones, which can be wasteful). Instead,
   follow these instructions to only restart the jobs that failed:

   * Azure: if on your own fork, it's possible from inside azure console
     (e.g. ``dev.azure.com/username/username/_build/results?buildId=1430&view=results``) via ``rerun failed jobs`` on top.
     If either on you own fork or in Nim repo, it's possible from inside GitHub UI
     under checks tab, see https://github.com/timotheecour/Nim/issues/211#issuecomment-629751569
   * GitHub actions: under "Checks" tab, click "Re-run jobs" in the right.
   * builds.sr.ht: create a sourcehut account so you can restart a PR job as illustrated.
     builds.sr.ht also allows you to ssh to a CI machine which can help a lot for debugging
     issues, see docs in https://man.sr.ht/builds.sr.ht/build-ssh.md and
     https://drewdevault.com/2019/08/19/Introducing-shell-access-for-builds.html; see
     https://man.sr.ht/tutorials/set-up-account-and-git.md to generate and upload ssh keys.


Code reviews
------------

1. Whenever possible, use GitHub's new 'Suggested change' in code reviews, which
   saves time explaining the change or applying it; see also
   https://forum.nim-lang.org/t/4317

2. When reviewing large diffs that may involve code moving around, GitHub's interface
   doesn't help much as it doesn't highlight moves. Instead, you can use something
   like this, see visual results `here <https://github.com/nim-lang/Nim/pull/10431#issuecomment-456968196>`_:

   .. code:: cmd

      git fetch origin pull/10431/head && git checkout FETCH_HEAD
      git diff --color-moved-ws=allow-indentation-change --color-moved=blocks HEAD^

3. In addition, you can view GitHub-like diffs locally to identify what was changed
   within a code block using `diff-highlight`:cmd: or `diff-so-fancy`:cmd:, e.g.:

   ::

      # put this in ~/.gitconfig:
      [core]
        pager = "diff-so-fancy | less -R" # or: use: `diff-highlight`



.. include:: docstyle.rst


Evolving the stdlib
===================

As outlined in https://github.com/nim-lang/RFCs/issues/173 there are a couple
of guidelines about what should go into the stdlib, what should be added and
what eventually should be removed.


What the compiler itself needs must be part of the stdlib
---------------------------------------------------------

Maybe in the future the compiler itself can depend on Nimble packages but for
the time being, we strive to have zero dependencies in the compiler as the
compiler is the root of the bootstrapping process and is also used to build
Nimble.


Vocabulary types must be part of the stdlib
-------------------------------------------

These are types most packages need to agree on for better interoperability,
for example `Option[T]`. This rule also covers the existing collections like
`Table`, `CountTable` etc. "Sorted" containers based on a tree-like data
structure are still missing and should be added.

Time handling, especially the `Time` type are also covered by this rule.


Existing, battle-tested modules stay
------------------------------------

Reason: There is no benefit in moving them around just to fullfill some design
fashion as in "Nim's core MUST BE SMALL". If you don't like an existing module,
don't import it. If a compilation target (e.g. JS) cannot support a module,
document this limitation.

This covers modules like `os`, `osproc`, `strscans`, `strutils`,
`strformat`, etc.


Syntactic helpers can start as experimental stdlib modules
----------------------------------------------------------

Reason: Generally speaking as external dependencies they are not exposed
to enough users so that we can see if the shortcuts provide enough benefit
or not. Many programmers avoid external dependencies, even moreso for
"tiny syntactic improvements". However, this is only true for really good
syntactic improvements that have the potential to clean up other parts of
the Nim library substantially. If in doubt, new stdlib modules should start
as external, successful Nimble packages.



Other new stdlib modules do not start as stdlib modules
-------------------------------------------------------

As we strive for higher quality everywhere, it's easier to adopt existing,
battle-tested modules eventually rather than creating modules from scratch.


Little additions are acceptable
-------------------------------

As long as they are documented and tested well, adding little helpers
to existing modules is acceptable. For two reasons:

1. It makes Nim easier to learn and use in the long run.
   ("Why does sequtils lack a `countIt`?
   Because version 1.0 happens to have lacked it? Silly...")
2. To encourage contributions. Contributors often start with PRs that
   add simple things and then they stay and also fix bugs. Nim is an
   open source project and lives from people's contributions and involvement.
   Newly introduced issues have to be balanced against motivating new people. We know where
   to find perfectly designed pieces of software that have no bugs -- these are the systems
   that nobody uses.

Conventions
-----------
1. New stdlib modules should go under ``Nim/lib/std/``. The rationale is to
   require users to import via `import std/foo` instead of `import foo`,
   which would cause potential conflicts with nimble packages.
   Note that this still applies for new modules in existing logical
   directories, e.g.: use ``lib/std/collections/foo.nim``,
   not ``lib/pure/collections/foo.nim``.

2. New module names should prefer plural form whenever possible, e.g.:
   ``std/sums.nim`` instead of ``std/sum.nim``. In particular, this reduces
   chances of conflicts between module name and the symbols it defines.
   Furthermore, module names should use `snake_case` and not use capital
   letters, which cause issues when going from an OS without case
   sensitivity to an OS with it.


Breaking Changes
================

Introducing breaking changes, no matter how well intentioned,
creates long-term problems for the community, in particular those looking to promote
reusable Nim code in libraries: In the Nim distribution, critical security and bugfixes,
language changes and community improvements are bundled in a single distribution - it is
difficult to make partial upgrades with only benign changes. When one library depends on
a legacy behavior, it can no longer be used together with another library that does not,
breaking all downstream applications - the standard library is unique in that it sits at
the root of **all** dependency trees.

There is a big difference between compile-time breaking changes and run-time breaking
changes.


Run-time breaking changes
-------------------------

Run-time breaking changes are to be avoided at almost all costs: Nim is used for
mission critical applications which depend on behaviours that
are not covered by the test suite. As such, it's important that changes to the
*stable* parts of the standard library are made avoiding changing the existing
behaviors, even when the test suite continues to pass.

Examples of run-time breaking changes:

- Raising exceptions of a new type, compared to what's currently being raised.

- Adding unconstrained or poorly constrained generic procs or macros
  ("hash now works for all `ref T`"): This may cause code to behave differently
  depending only on which modules are imported - common examples include `==` and `hash`.

- Changing behavior of existing functions like:

  * "Nim's path handling procs like `getXDir` now consistently lack the trailing slash"
  * "Nim's strformat implementation is now more consistent with Python"

Instead write new code that explicitly announces the feature you think we announced but
didn't. For example, `strformat` does not say "it's compatible with Python", it
says "inspired by Python's f-strings". This new code can be submitted to the stdlib
and the old code can be deprecated or it can be published as a Nimble package.

Sometimes, a run-time breaking change is most desirable: For example, a string
representation of a floating point number that "roundtrips" is much better than
a string represenation that doesn't. These run-time breaking changes must start in the
state "opt-in" via a new `-d:nimPreviewX` or command line flag and then should become
the new default later, in follow-up versions. This way users can track
regressions more easily. ("git bisect" is not an acceptable alternative, that's for
Nim compiler developers, not for Nim users.)

Above all else, additive approaches that don't change existing behaviors
should be preferred.


Compile-time breaking changes
-----------------------------

Compile-time breaking changes are usually easier to handle, but for large code bases
it can also be much work and it can hinder the adoption of a new Nim release.
Additive approaches are to be preferred here as well.

Examples of compile-time breaking changes include (but are not limited to):

* Renaming functions and modules, or moving things. Instead of a direct rename,
  deprecate the old name and introduce a new one.
* Renaming the parameter names: Thanks to Nim's "named parameter" calling syntax
  like `f(x = 0, y = 1)` this is a breaking change. Instead live with the existing
  parameter names.
* Adding an enum value to an existing enum. Nim's exhaustive case statements stop
  compiling after such a change. Instead consider to introduce new `bool`
  fields/parameters. This can be impractical though, so we use good judgement
  and our list of "important packages" to see if it doesn't break too much code
  out there in practice.
* Adding a new proc to an existing stdlib module. However, for aesthetic reasons
  this is often preferred over introducing a new module with just a single proc
  inside. We use good judgement and our list of "important packages" to see if
  it doesn't break too much code out there in practice. The new procs need to
  be annotated with a `.since` annotation.


Compiler/language spec bugfixes
-------------------------------

This can even be applied to compiler "bugfixes": If the compiler should have been
"pickier" in its handling of `typedesc`, instead of "fixing typedesc handling bugs",
consider the following solution:

- Spec out how `typedesc` should really work and also spec out the cases where it
  should not be allowed!
- Deprecate `typedesc` and name the new metatype something new like `typeArg`.
- Implement the spec.


Non-breaking changes
--------------------

Examples of changes that are considered non-breaking (or acceptable breaking changes) include:

* Creating a new module.
* Adding an overload to an already overloaded proc.
* Adding new default parameters to an existing proc. It is assumed that you do not
  use Nim's stdlib procs's addresses (that you don't use them as first class entities).
* Changing the calling convention from `nimcall` to `inline`
  (but first RFC https://github.com/nim-lang/RFCs/issues/396 needs to be implemented).
* Changing the behavior from "crashing" into some other, well documented result (including
  raising a Defect, but not raising an exception that does not inherit from Defect).
* Adding new fields to an existing object.

Nim's introspection facilities imply that strictly speaking almost every addition can
break somebody's code. It is impractical to care about these cases, a change that only
affects introspection is not considered to be a breaking change.
