==========================================
Nim-flavored Markdown and reStructuredText
==========================================

Both `Markdown`:idx: and `reStructuredText`:idx: (RST) are markup
languages whose goal is to
typeset texts with complex structure, formatting and references
using simple plaintext representation.
A large subset is implemented with some limitations_ and
`Nim-specific features`_.

This module is also embedded into Nim compiler; the compiler can output
the result to HTML \[#html] or Latex \[#latex].

\[#html] commands `nim doc`:cmd: for ``*.nim`` files and
   `nim rst2html`:cmd: for ``*.rst`` files

\[#latex] commands `nim doc2tex`:cmd: for ``*.nim`` and
   `nim rst2tex`:cmd: for ``*.rst``.

If you are new to Markdown/RST please consider reading the following:

1) `Markdown Basic Syntax`_
2) a long specification of Markdown: `CommonMark Spec`_
3) a short `quick introduction`_ to RST
4) an `RST reference`_: a comprehensive cheatsheet for RST
5) a more formal 50-page `RST specification`_.

Features
--------

Supported standard RST features:

* body elements
  + sections
  + transitions
  + paragraphs
  + bullet lists using \+, \*, \-
  + enumerated lists using arabic numerals or alphabet
    characters:  1. ... 2. ... *or* a. ... b. ... *or* A. ... B. ...
  + footnotes (including manually numbered, auto-numbered, auto-numbered
    with label, and auto-symbol footnotes) and citations
  + definition lists
  + field lists
  + option lists
  + indented literal blocks
  + quoted literal blocks
  + line blocks
  + simple tables
  + directives (see official documentation in `RST directives list`_):
    - ``image``, ``figure`` for including images and videos
    - ``code``
    - ``contents`` (table of contents), ``container``, ``raw``
    - ``include``
    - admonitions: "attention", "caution", "danger", "error", "hint",
      "important", "note", "tip", "warning", "admonition"
    - substitution definitions: `replace` and `image`
  + comments
* inline markup
  + *emphasis*, **strong emphasis**,
    ``inline literals``, hyperlink references (including embedded URI),
    substitution references, standalone hyperlinks,
    internal links (inline and outline)
  + \`interpreted text\` with roles ``:literal:``, ``:strong:``,
    ``emphasis``, ``:sub:``/``:subscript:``, ``:sup:``/``:superscript:``
    (see `RST roles list`_ for description).
  + inline internal targets

.. _`Nim-specific features`:

Additional Nim-specific features:

* directives: ``code-block`` \[cmp:Sphinx], ``title``,
  ``index`` \[cmp:Sphinx]
* predefined roles
  - ``:nim:`` (default), ``:c:`` (C programming language),
    ``:python:``, ``:yaml:``, ``:java:``, ``:cpp:`` (C++), ``:csharp`` (C#).
    That is every language that `highlite <highlite.html>`_ supports.
    They turn on appropriate syntax highlighting in inline code.

    .. Note:: default role for Nim files is ``:nim:``,
              for ``*.rst`` it's currently ``:literal:``.

  - generic command line highlighting roles:
    - ``:cmd:`` for commands and common shells syntax
    - ``:console:`` the same  for interactive sessions
      (commands should be prepended by ``$``)
    - ``:program:`` for executable names \[cmp:Sphinx]
      (one can just use ``:cmd:`` on single word)
    - ``:option:`` for command line options \[cmp:Sphinx]
  - ``:tok:``, a role for highlighting of programming language tokens
* ***triple emphasis*** (bold and italic) using \*\*\*
* ``:idx:`` role for \`interpreted text\` to include the link to this
  text into an index (example: `Nim index`_).
* double slash `//` in option lists serves as a prefix for any option that
  starts from a word (without any leading symbols like `-`, `--`, `/`)::

    //compile   compile the project
    //doc       generate documentation

  Here the dummy `//` will disappear, while options `compile`:option:
  and `doc`:option: will be left in the final document.

\[cmp:Sphinx] similar but different from the directives of
   Python `Sphinx directives`_ and `Sphinx roles`_ extensions

.. _`extra features`:

Optional additional features, turned on by ``options: RstParseOption`` in
`proc rstParse`_:

* emoji / smiley symbols
* Markdown tables
* Markdown code blocks. For them the same additional arguments as for RST
  code blocks can be provided (e.g. `test` or `number-lines`) but with
  a one-line syntax like this::

    ```nim test number-lines=10
    echo "ok"
    ```
* Markdown links
* Markdown headlines
* Markdown block quotes
* using ``1`` as auto-enumerator in enumerated lists like RST ``#``
  (auto-enumerator ``1`` can not be used with ``#`` in the same list)

.. Note:: By default Nim has ``roSupportMarkdown`` and
   ``roSupportRawDirective`` turned **on**.

.. warning:: Using Nim-specific features can cause other RST implementations
  to fail on your document.

Idiosyncrasies
--------------

Currently we do **not** aim at 100% Markdown or RST compatibility in inline
markup recognition rules because that would provide very little user value.
This parser has 2 modes for inline markup:

1) Markdown-like mode which is enabled by `roPreferMarkdown` option
   (turned **on** by default).

   .. Note:: RST features like directives are still turned **on**

2) Compatibility mode which is RST rules.

.. Note:: in both modes the parser interpretes text between single
     backticks (code) identically:
     backslash does not escape; the only exception: ``\`` folowed by `
     does escape so that we can always input a single backtick ` in
     inline code. However that makes impossible to input code with
     ``\`` at the end in *single* backticks, one must use *double*
     backticks::

       `\`   -- WRONG
       ``\`` -- GOOD
       So single backticks can always be input: `\`` will turn to ` code

.. Attention::
   We don't support some obviously poor design choices of Markdown (or RST).

   - no support for the rule of 2 spaces causing a line break in Markdown
     (use RST "line blocks" syntax for making line breaks)

   - interpretation of Markdown block quotes is also slightly different,
     e.g. case

     ::

       >>> foo
       > bar
       >>baz

     is a single 3rd-level quote `foo bar baz` in original Markdown, while
     in Nim we naturally see it as 3rd-level quote `foo` + 1st level `bar` +
     2nd level `baz`:

     >>> foo
     > bar
     >>baz

Limitations
-----------

* no Unicode support in character width calculations
* body elements
  - no roman numerals in enumerated lists
  - no doctest blocks
  - no grid tables
  - some directives are missing (check official `RST directives list`_):
    ``parsed-literal``, ``sidebar``, ``topic``, ``math``, ``rubric``,
    ``epigraph``, ``highlights``, ``pull-quote``, ``compound``,
    ``table``, ``csv-table``, ``list-table``, ``section-numbering``,
    ``header``, ``footer``, ``meta``, ``class``
    - no ``role`` directives and no custom interpreted text roles
    - some standard roles are not supported (check `RST roles list`_)
    - no generic admonition support
* inline markup
  - no simple-inline-markup
  - no embedded aliases

Usage
-----

See `Nim DocGen Tools Guide <docgen.html>`_ for the details about
`nim doc`:cmd:, `nim rst2html`:cmd: and `nim rst2tex`:cmd: commands.

.. _Markdown Basic Syntax: https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax
.. _CommonMark Spec: https://spec.commonmark.org/0.30
.. _quick introduction: https://docutils.sourceforge.io/docs/user/rst/quickstart.html
.. _RST reference: https://docutils.sourceforge.io/docs/user/rst/quickref.html
.. _RST specification: https://docutils.sourceforge.io/docs/ref/rst/restructuredtext.html
.. _RST directives list: https://docutils.sourceforge.io/docs/ref/rst/directives.html
.. _RST roles list: https://docutils.sourceforge.io/docs/ref/rst/roles.html
.. _Nim index: https://nim-lang.org/docs/theindex.html
.. _Sphinx directives: https://www.sphinx-doc.org/en/master/usage/restructuredtext/directives.html
.. _Sphinx roles: https://www.sphinx-doc.org/en/master/usage/restructuredtext/roles.html
