===================================
   Nim DocGen Tools Guide
===================================

:Author: Erik O'Leary
:Version: |nimversion|

.. contents::


Introduction
============

This document describes the `documentation generation tools`:idx: built into
the `Nim compiler <nimc.html>`_, which can generate HTML and JSON output
from input .nim files and projects, as well as HTML and LaTeX from input RST
(reStructuredText) files. The output documentation will include the module
dependencies (``import``), any top-level documentation comments (##), and
exported symbols (*), including procedures, types, and variables.

Quick start
-----------

Generate HTML documentation for a file:

::
  nim doc <filename>.nim

Generate HTML documentation for a whole project:

::
  # delete any htmldocs/*.idx file before starting
  nim doc --project --index:on --git.url:<url> --git.commit:<tag> --outdir:htmldocs <main_filename>.nim
  # this will generate html files, a theindex.html index, css and js under `htmldocs`
  # See also `--docroot` to specify a relative root.
  # to get search (dochacks.js) to work locally, you need a server otherwise
  # CORS will prevent opening file:// urls; this works:
  python3 -m http.server 7029 --directory htmldocs
  # When --outdir is omitted it defaults to $projectPath/htmldocs,
  or `$nimcache/htmldocs` with `--usenimcache` which avoids clobbering your sources;
  and likewise without `--project`.
  Adding `-r` will open in a browser directly.


Documentation Comments
----------------------

Any comments which are preceded by a double-hash (##), are interpreted as
documentation.  Comments are parsed as RST (see `reference
<http://docutils.sourceforge.net/docs/user/rst/quickref.html>`_), providing
Nim module authors the ability to easily generate richly formatted
documentation with only their well-documented code.

Example:

.. code-block:: nim
  type Person* = object
    ## This type contains a description of a person
    name: string
    age: int

Outputs::
  Person* = object
    name: string
    age: int

This type contains a description of a person

Field documentation comments can be added to fields like so:

.. code-block:: nim
  var numValues: int ## \
    ## `numValues` stores the number of values

Note that without the `*` following the name of the type, the documentation for
this type would not be generated. Documentation will only be generated for
*exported* types/procedures/etc.

It's recommended to always add exactly **one** space after `##` for readability
of comments — this extra space will be cropped from the parsed comments and
won't influence RST formatting.

.. note:: Generally, this baseline indentation level inside a documentation
   comment may not be 1: it can be any since it is determined by the offset
   of the first non-whitespace character in the comment.
   After that indentation **must** be consistent on the following lines of
   the same comment.
   If you still need to add an additional indentation at the very beginning
   (for RST block quote syntax) use backslash \\ before it:

   .. code-block:: nim
      ## \
      ##
      ##    Block quote at the first line.
      ##
      ## Paragraph.

Nim file input
-----------------

The following examples will generate documentation for the below contrived
*Nim* module, aptly named 'sample.nim'

sample.nim:

.. code-block:: nim
  ## This module is a sample.

  import std/strutils

  proc helloWorld*(times: int) =
    ## Takes an integer and outputs
    ## as many "hello world!"s

    for i in 0 .. times-1:
      echo "hello world!"

  helloWorld(5)


Document Types
==============


HTML
----

The generation of HTML documents is done via the ``doc`` command. This command
takes either a single .nim file, outputting a single .html file with the same
base filename, or multiple .nim files, outputting multiple .html files and,
optionally, an index file.

The ``doc`` command::
  nim doc sample

Partial Output::
  ...
  proc helloWorld(times: int) {.raises: [], tags: [].}
  ...

The full output can be seen here: `docgen_sample.html <docgen_sample.html>`_.
It runs after semantic checking and includes pragmas attached implicitly by the
compiler.


JSON
----

The generation of JSON documents is done via the ``jsondoc`` command. This command
takes in a .nim file and outputs a .json file with the same base filename. Note
that this tool is built off of the ``doc`` command (previously ``doc2``), and
contains the same information.

The ``jsondoc`` command::
  nim jsondoc sample

Output::
  {
    "orig": "docgen_sample.nim",
    "nimble": "",
    "moduleDescription": "This module is a sample",
    "entries": [
      {
        "name": "helloWorld",
        "type": "skProc",
        "line": 5,
        "col": 0,
        "description": "Takes an integer and outputs as many &quot;hello world!&quot;s",
        "code": "proc helloWorld(times: int) {.raises: [], tags: [].}"
      }
    ]
  }

Similarly to the old ``doc`` command, the old ``jsondoc`` command has been
renamed to ``jsondoc0``.

The ``jsondoc0`` command::
  nim jsondoc0 sample

Output::
  [
    {
      "comment": "This module is a sample."
    },
    {
      "name": "helloWorld",
      "type": "skProc",
      "description": "Takes an integer and outputs as many &quot;hello world!&quot;s",
      "code": "proc helloWorld*(times: int)"
    }
  ]

Note that the ``jsondoc`` command outputs it's JSON without pretty-printing it,
while ``jsondoc0`` outputs pretty-printed JSON.

Related Options
===============

Project switch
--------------

::
  nim doc --project filename.nim

This will recursively generate documentation of all nim modules imported
into the input module that belong to the Nimble package that ``filename.nim``
belongs to.


Index switch
------------

::
  nim doc --index:on filename.nim

This will generate an index of all the exported symbols in the input Nim
module, and put it into a neighboring file with the extension of ``.idx``. The
index file is line-oriented (newlines have to be escaped). Each line
represents a tab-separated record of several columns, the first two mandatory,
the rest optional. See the `Index (idx) file format`_ section for details.

Once index files have been generated for one or more modules, the Nim
compiler command ``buildIndex directory`` can be run to go over all the index
files in the specified directory to generate a `theindex.html <theindex.html>`_
file.

See source switch
-----------------

::
  nim doc --git.url:<url> filename.nim

With the ``git.url`` switch the *See source* hyperlink will appear below each
documented item in your source code pointing to the implementation of that
item on a GitHub repository.
You can click the link to see the implementation of the item.

The ``git.commit`` switch overrides the hardcoded `devel` branch in config/nimdoc.cfg.
This is useful to link to a different branch e.g. `--git.commit:master`,
or to a tag e.g. `--git.commit:1.2.3` or a commit.

Source URLs are generated as `href="${url}/tree/${commit}/${path}#L${line}"` by default and this compatible with GitHub but not with GitLab.

Similarly, ``git.devel`` switch overrides the hardcoded `devel` branch for the `Edit` link which is also useful if you have a different working branch than `devel` e.g. `--git.devel:master`.

Edit URLs are generated as `href="${url}/tree/${devel}/${path}#L${line}"` by default.

You can edit ``config/nimdoc.cfg`` and modify the ``doc.item.seesrc`` value with a hyperlink to your own code repository.

In the case of Nim's own documentation, the ``commit`` value is just a commit
hash to append to a formatted URL to https://github.com/nim-lang/Nim. The
``tools/nimweb.nim`` helper queries the current git commit hash during the doc
generation, but since you might be working on an unpublished repository, it
also allows specifying a ``githash`` value in ``web/website.ini`` to force a
specific commit in the output.


Other Input Formats
===================

The *Nim compiler* also has support for RST (reStructuredText) files with
the ``rst2html`` and ``rst2tex`` commands. Documents like this one are
initially written in a dialect of RST which adds support for nim source code
highlighting with the ``.. code-block:: nim`` prefix. ``code-block`` also
supports highlighting of C++ and some other c-like languages.

Usage::
  nim rst2html docgen.txt

Output::
  You're reading it!

The ``rst2tex`` command is invoked identically to ``rst2html``, but outputs
a .tex file instead of .html.


HTML anchor generation
======================

When you run the ``rst2html`` command, all sections in the RST document will
get an anchor you can hyperlink to. Usually, you can guess the anchor lower
casing the section title and replacing spaces with dashes, and in any case, you
can get it from the table of contents. But when you run the ``doc``
command to generate API documentation, some symbol get one or two anchors at
the same time: a numerical identifier, or a plain name plus a complex name.

The numerical identifier is just a random number. The number gets assigned
according to the section and position of the symbol in the file being processed
and you should not rely on it being constant: if you add or remove a symbol the
numbers may shuffle around.

The plain name of a symbol is a simplified version of its fully exported
signature. Variables or constants have the same plain name symbol as their
complex name. The plain name for procs, templates, and other callable types
will be their unquoted value after removing parameters, return types, and
pragmas. The plain name allows short and nice linking of symbols that works
unless you have a module with collisions due to overloading.

If you hyperlink a plain name symbol and there are other matches on the same
HTML file, most browsers will go to the first one. To differentiate the rest,
you will need to use the complex name. A complex name for a callable type is
made up of several parts:

    (**plain symbol**)(**.type**),(**first param**)?(**,param type**)\*

The first thing to note is that all callable types have at least a comma, even
if they don't have any parameters. If there are parameters, they are
represented by their types and will be comma-separated. To the plain symbol a
suffix may be added depending on the type of the callable:

-------------   --------------
Callable type   Suffix
-------------   --------------
proc            *empty string*
macro           ``.m``
method          ``.e``
iterator        ``.i``
template        ``.t``
converter       ``.c``
-------------   --------------

The relationship of type to suffix is made by the proc ``complexName`` in the
``compiler/docgen.nim`` file. Here are some examples of complex names for
symbols in the `system module <system.html>`_.

* ``type SomeSignedInt = int | int8 | int16 | int32 | int64`` **=>**
  `#SomeSignedInt <system.html#SomeSignedInt>`_
* ``var globalRaiseHook: proc (e: ref E_Base): bool {.nimcall.}`` **=>**
  `#globalRaiseHook <system.html#globalRaiseHook>`_
* ``const NimVersion = "0.0.0"`` **=>**
  `#NimVersion <system.html#NimVersion>`_
* ``proc getTotalMem(): int {.rtl, raises: [], tags: [].}`` **=>**
  `#getTotalMem, <system.html#getTotalMem>`_
* ``proc len[T](x: seq[T]): int {.magic: "LengthSeq", noSideEffect.}`` **=>**
  `#len,seq[T] <system.html#len,seq[T]>`_
* ``iterator pairs[T](a: seq[T]): tuple[key: int, val: T] {.inline.}`` **=>**
  `#pairs.i,seq[T] <iterators.html#pairs.i,seq[T]>`_
* ``template newException[](exceptn: typedesc; message: string;
    parentException: ref Exception = nil): untyped`` **=>**
  `#newException.t,typedesc,string,ref.Exception
  <system.html#newException.t,typedesc,string,ref.Exception>`_


Index (idx) file format
=======================

Files with the ``.idx`` extension are generated when you use the `Index
switch <#related-options-index-switch>`_ along with commands to generate
documentation from source or text files. You can programmatically generate
indices with the `setIndexTerm()
<rstgen.html#setIndexTerm,RstGenerator,string,string,string,string,string>`_
and `writeIndexFile() <rstgen.html#writeIndexFile,RstGenerator,string>`_ procs.
The purpose of ``idx`` files is to hold the interesting symbols and their HTML
references so they can be later concatenated into a big index file with
`mergeIndexes() <rstgen.html#mergeIndexes,string>`_.  This section documents
the file format in detail.

Index files are line-oriented and tab-separated (newline and tab characters
have to be escaped). Each line represents a record with at least two fields
but can have up to four (additional columns are ignored). The content of these
columns is:

1. Mandatory term being indexed. Terms can include quoting according to
   Nim's rules (e.g. \`^\`).
2. Base filename plus anchor hyperlink (e.g. ``algorithm.html#*,int,SortOrder``).
3. Optional human-readable string to display as a hyperlink. If the value is not
   present or is the empty string, the hyperlink will be rendered
   using the term. Prefix whitespace indicates that this entry is
   not for an API symbol but for a TOC entry.
4. Optional title or description of the hyperlink. Browsers usually display
   this as a tooltip after hovering a moment over the hyperlink.

The index generation tools try to differentiate between documentation
generated from ``.nim`` files and documentation generated from ``.txt`` or
``.rst`` files. The former are always closely related to source code and
consist mainly of API entries. The latter are generic documents meant for
human reading.

To differentiate both types (documents and APIs), the index generator will add
to the index of documents an entry with the title of the document. Since the
title is the topmost element, it will be added with a second field containing
just the filename without any HTML anchor.  By convention, this entry without
anchor is the *title entry*, and since entries in the index file are added as
they are scanned, the title entry will be the first line. The title for APIs
is not present because it can be generated concatenating the name of the file
to the word **Module**.

Normal symbols are added to the index with surrounding whitespaces removed. An
exception to this are the table of content (TOC) entries. TOC entries are added to
the index file with their third column having as much prefix spaces as their
level is in the TOC (at least 1 character). The prefix whitespace helps to
filter TOC entries from API or text symbols. This is important because the
amount of spaces is used to replicate the hierarchy for document TOCs in the
final index, and TOC entries found in ``.nim`` files are discarded.


Additional resources
====================

`Nim Compiler User Guide <nimc.html#compiler-usage-commandminusline-switches>`_

`RST Quick Reference
<http://docutils.sourceforge.net/docs/user/rst/quickref.html>`_

The output for HTML and LaTeX comes from the ``config/nimdoc.cfg`` and
``config/nimdoc.tex.cfg`` configuration files. You can add and modify these
files to your project to change the look of the docgen output.

You can import the `packages/docutils/rstgen module <rstgen.html>`_ in your
programs if you want to reuse the compiler's documentation generation procs.
