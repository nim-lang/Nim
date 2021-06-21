========================
Tools available with Nim
========================

.. default-role:: code
.. include:: rstcommon.rst

The standard distribution ships with the following tools:

- | `Hot code reloading <hcr.html>`_
  | The "Hot code reloading" feature is built into the compiler but has its own
    document explaining how it works.

- | `Documentation generator <docgen.html>`_
  | The builtin document generator `nim doc`:cmd: generates HTML documentation
    from ``.nim`` source files.

- | `Nimsuggest for IDE support <nimsuggest.html>`_
  | Through the `nimsuggest`:cmd: tool, any IDE can query a ``.nim`` source file
    and obtain useful information like the definition of symbols or suggestions for
    completion.

- | `C2nim <https://github.com/nim-lang/c2nim/blob/master/doc/c2nim.rst>`_
  | C to Nim source converter. Translates C header files to Nim.

- | `niminst <niminst.html>`_
  | niminst is a tool to generate an installer for a Nim program.

- | `nimgrep <nimgrep.html>`_
  | Nim search and replace utility.

- | nimpretty
  | `nimpretty`:cmd: is a Nim source code beautifier,
    to format code according to the official style guide.

- | `testament <https://nim-lang.github.io/Nim/testament.html>`_
  | `testament`:cmd: is an advanced automatic *unittests runner* for Nim tests,
    is used for the development of Nim itself, offers process isolation for your tests,
    it can generate statistics about test cases, supports multiple targets (C, JS, etc),
    `simulated Dry-Runs <https://en.wikipedia.org/wiki/Dry_run_(testing)>`_,
    has logging, can generate HTML reports, skip tests from a file, and more,
    so can be useful to run your tests, even the most complex ones.
