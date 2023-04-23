==========================================
Nim-flavored Markdown and reStructuredText
==========================================

:Author: Andrey Makarov
:Version: |nimversion|

.. default-role:: code
.. include:: rstcommon.rst
.. contents::

.. importdoc:: docgen.md

Both `Markdown`:idx: (md) and `reStructuredText`:idx: (RST) are markup
languages whose goal is to typeset texts with complex structure,
formatting and references using simple plaintext representation.

Command line usage
==================

Usage (to convert Markdown into HTML):

  ```cmd
  nim md2html markdown_rst.md
  ```

Output:

    You're reading it!

The `md2tex`:option: command is invoked identically to `md2html`:option:,
but outputs a ``.tex`` file instead of ``.html``.

These tools embedded into Nim compiler; the compiler can output
the result to HTML \[#html] or Latex \[#latex].

\[#html] commands `nim doc`:cmd: for ``*.nim`` files and
   `nim rst2html`:cmd: for ``*.rst`` files

\[#latex] commands `nim doc2tex`:cmd: for ``*.nim`` and
   `nim rst2tex`:cmd: for ``*.rst``.

Full list of supported commands:

===================   ======================   ============   ==============
command               runs on...               input format   output format
===================   ======================   ============   ==============
`nim md2html`:cmd:    standalone md files      ``.md``        ``.html`` HTML
`nim md2tex`:cmd:     same                     same           ``.tex`` LaTeX
`nim rst2html`:cmd:   standalone rst files     ``.rst``       ``.html`` HTML
`nim rst2tex`:cmd:    same                     same           ``.tex`` LaTeX
`nim doc`:cmd:        documentation comments   ``.nim``       ``.html`` HTML
`nim doc2tex`:cmd:    same                     same           ``.tex`` LaTeX
`nim jsondoc`:cmd:    same                     same           ``.json`` JSON
===================   ======================   ============   ==============


Basic markup
============

If you are new to Markdown/RST please consider reading the following:

1) [Markdown Basic Syntax]
2) a long specification of Markdown: [CommonMark Spec]
3) a short [quick introduction] to RST
4) an [RST reference]: a comprehensive cheatsheet for RST
5) a more formal 50-page [RST specification].

Features
--------

A large subset is implemented with some [limitations] and
[additional Nim-specific features].

Supported common RST/Markdown features:

* body elements
  + sections
  + transitions
  + paragraphs
  + bullet lists using \+, \*, \-
  + enumerated lists using arabic numerals or alphabet
    characters:  1. ... 2. ... *or* a. ... b. ... *or* A. ... B. ...
  + footnotes (including manually numbered, auto-numbered, auto-numbered
    with label, and auto-symbol footnotes) and citations
  + field lists
  + option lists
  + quoted literal blocks
  + line blocks
  + simple tables
  + directives (see official documentation in [RST directives list]):
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
    (see [RST roles list] for description).
  + inline internal targets

RST mode only features
----------------------

+ RST syntax for definition lists (that is additional indentation after
  a definition line)
+ indented literal blocks starting from ``::``

Markdown-specific features
--------------------------

* Markdown tables
* Markdown code blocks. For them the same additional arguments as for RST
  code blocks can be provided (e.g. `test` or `number-lines`) but with
  a one-line syntax like this:

      ```nim test number-lines=10
      echo "ok"
      ```
* Markdown links ``[...](...)``
* Pandoc syntax for automatic links ``[...]``, see [Referencing] for description
+ Markdown literal blocks indented by 4 or more spaces
* Markdown headlines
* Markdown block quotes
* Markdown syntax for definition lists
* using ``1`` as auto-enumerator in enumerated lists like RST ``#``
  (auto-enumerator ``1`` can not be used with ``#`` in the same list)

Additional Nim-specific features
--------------------------------

* referencing to definitions in external files, see
  [Markup external referencing] section
* directives: ``code-block`` \[cmp:Sphinx], ``title``,
  ``index`` \[cmp:Sphinx]
* predefined roles
  - ``:nim:`` (default), ``:c:`` (C programming language),
    ``:python:``, ``:yaml:``, ``:java:``, ``:cpp:`` (C++), ``:csharp`` (C#).
    That is every language that [highlite](highlite.html) supports.
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
  text into an index (example: [Nim index]).
* double slash `//` in option lists serves as a prefix for any option that
  starts from a word (without any leading symbols like `-`, `--`, `/`):

      //compile   compile the project
      //doc       generate documentation

  Here the dummy `//` will disappear, while options `compile`:option:
  and `doc`:option: will be left in the final document.
* emoji / smiley symbols

\[cmp:Sphinx] similar but different from the directives of
   Python [Sphinx directives] and [Sphinx roles] extensions

.. Note:: By default Nim has ``roSupportMarkdown`` and
   ``roSupportRawDirective`` turned **on**.

.. warning:: Using Nim-specific features can cause other Markdown and
  RST implementations to fail on your document.

Referencing
===========

To be able to copy and share links Nim generates anchors for all
main document elements:

* headlines (including document title)
* footnotes
* explicitly set anchors: RST internal cross-references and
  inline internal targets
* Nim symbols (external referencing), see [Nim DocGen Tools Guide] for details.

But direct use of those anchors have 2 problems:

1. the anchors are usually mangled (e.g. spaces substituted to minus
   signs, etc).
2. manual usage of anchors is not checked, so it's easy to get broken
   links inside your project if e.g. spelling has changed for a heading
   or you use a wrong relative path to your document.

That's why Nim implementation has syntax for using
*original* labels for referencing.
Such referencing can be either local/internal or external:

* Local referencing (inside any given file) is defined by
  RST standard or Pandoc Markdown User guide.
* External (cross-document) referencing is a Nim-specific feature,
  though it's not really different from local referencing by its syntax.

Markup local referencing
------------------------

There are 2 syntax option available for referencing to objects
inside any given file, e.g. for headlines:

    Markdown                  RST

    Some headline             Some headline
    =============             =============

    Ref. [Some headline]      Ref. `Some headline`_


Markup external referencing
---------------------------

The syntax is the same as for local referencing, but the anchors are
saved in ``.idx`` files, so one needs to generate them beforehand,
and they should be loaded by an `.. importdoc::` directive.
E.g. if we want to reference section "Some headline" in ``file1.md``
from ``file2.md``, then ``file2.md`` may look like:

```
.. importdoc:: file1.md

Ref. [Some headline]
```

```cmd
nim md2html --index:only file1.md  # creates ``htmldocs/file1.idx``
nim md2html file2.md               # creates ``htmldocs/file2.html``
```

To allow cross-references between any files in any order (especially, if
circular references are present), it's strongly reccommended
to make a run for creating all the indexes first:

```cmd
nim md2html --index:only file1.md  # creates ``htmldocs/file1.idx``
nim md2html --index:only file2.md  # creates ``htmldocs/file2.idx``
nim md2html file1.md               # creates ``htmldocs/file1.html``
nim md2html file2.md               # creates ``htmldocs/file2.html``
```

and then one can freely reference any objects as if these 2 documents
are actually 1 file.

Other
=====

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
     backticks:

         `\`   -- WRONG
         ``\`` -- GOOD
         So single backticks can always be input: `\`` will turn to ` code

.. Attention::
   We don't support some obviously poor design choices of Markdown (or RST).

   - no support for the rule of 2 spaces causing a line break in Markdown
     (use RST "line blocks" syntax for making line breaks)

   - interpretation of Markdown block quotes is also slightly different,
     e.g. case

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
  - some directives are missing (check official [RST directives list]):
    ``parsed-literal``, ``sidebar``, ``topic``, ``math``, ``rubric``,
    ``epigraph``, ``highlights``, ``pull-quote``, ``compound``,
    ``table``, ``csv-table``, ``list-table``, ``section-numbering``,
    ``header``, ``footer``, ``meta``, ``class``
    - no ``role`` directives and no custom interpreted text roles
    - some standard roles are not supported (check [RST roles list])
    - no generic admonition support
* inline markup
  - no simple-inline-markup
  - no embedded aliases

Additional resources
--------------------

* See [Nim DocGen Tools Guide](docgen.html) for the details about
  `nim doc`:cmd: command and idiosyncrasies of documentation markup in
  ``.nim`` files and Nim programming language projects.
* See also documentation for [rst module](rst.html) -- Nim RST/Markdown parser.

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
