================================
  Nim IDE Integration Guide
================================

:Author: Unknown
:Version: |nimversion|

.. default-role:: code
.. include:: rstcommon.rst
.. contents::


Nim differs from many other compilers in that it is really fast,
and being so fast makes it suited to provide external queries for
text editors about the source code being written. Through the
`nimsuggest`:cmd: tool, any IDE
can query a ``.nim`` source file and obtain useful information like
definition of symbols or suggestions for completion.

This document will guide you through the available options. If you
want to look at practical examples of nimsuggest support you can look
at the
`various editor integrations <https://github.com/Araq/Nim/wiki/Editor-Support>`_
already available.


Installation
============

Nimsuggest is part of Nim's core. Build it via:

.. code:: cmd
  koch nimsuggest


Nimsuggest invocation
=====================

Run it via `nimsuggest --stdin --debug myproject.nim`:cmd:. Nimsuggest is a
server that takes queries that are related to `myproject`. There is some
support so that you can throw random ``.nim`` files which are not part
of `myproject` at Nimsuggest too, but usually the query refer to modules/files
that are part of `myproject`.

`--stdin`:option: means that Nimsuggest reads the query from `stdin`. This is great
for testing things out and playing with it but for an editor communication
via sockets is more reasonable so that is the default. It listens to port 6000
by default.

Nimsuggest is basically a frontend for the nim compiler so `--path`:option: flags and
`config files <https://nim-lang.org/docs/nimc.html#compiler-usage-configuration-files>`_
can be used to specify additional dependencies like 
`nimsuggest --stdin --debug --path:"dependencies" myproject.nim`:cmd:.


Specifying the location of the query
------------------------------------

Nimsuggest then waits for queries to process. A query consists of a
cryptic 3 letter "command" `def` or `con` or `sug` or `use` followed by
a location. A query location consists of:


``file.nim``
    This is the name of the module or include file the query refers to.

``dirtyfile.nim``
    This is optional.

    The `file` parameter is enough for static analysis, but IDEs
    tend to have *unsaved buffers* where the user may still be in
    the middle of typing a line. In such situations the IDE can
    save the current contents to a temporary file and then use the
    ``dirtyfile.nim`` option to tell Nimsuggest that ``foobar.nim`` should
    be taken from ``temporary/foobar.nim``.


``line``
    An integer with the line you are going to query. For the compiler
    lines start at **1**.

``col``
    An integer with the column you are going to query. For the
    compiler columns start at **0**.


Definitions
-----------

The `def` Nimsuggest command performs a query about the definition
of a specific symbol. If available, Nimsuggest will answer with the
type, source file, line/column information and other accessory data
if available like a docstring. With this information an IDE can
provide the typical *Jump to definition* where a user puts the
cursor on a symbol or uses the mouse to select it and is redirected
to the place where the symbol is located.

Since Nim is implemented in Nim, one of the nice things of
this feature is that any user with an IDE supporting it can quickly
jump around the standard library implementation and see exactly
what a proc does, learning about the language and seeing real life
examples of how to write/implement specific features.

Nimsuggest will always answer with a single definition or none if it
can't find any valid symbol matching the position of the query.


Suggestions
-----------

The `sug` Nimsuggest command performs a query about possible
completion symbols at some point in the file.

The typical usage scenario for this option is to call it after the
user has typed the dot character for `the object oriented call
syntax <tut2.html#object-oriented-programming-method-call-syntax>`_.
Nimsuggest will try to return the suggestions sorted first by scope
(from innermost to outermost) and then by item name.


Invocation context
------------------

The `con` Nimsuggest command is very similar to the suggestions
command, but instead of being used after the user has typed a dot
character, this one is meant to be used after the user has typed
an opening brace to start typing parameters.


Symbol usages
-------------

The `use` Nimsuggest command lists all usages of the symbol at
a position. IDEs can use this to find all the places in the file
where the symbol is used and offer the user to rename it in all
places at the same time.

For this kind of query the IDE will most likely ignore all the
type/signature info provided by Nimsuggest and concentrate on the
filename, line and column position of the multiple returned answers.



Parsing nimsuggest output
=========================

Nimsuggest output is always returned on single lines separated by
tab characters (``\t``). The values of each column are:

1. Three characters indicating the type of returned answer (e.g.
   `def` for definition, `sug` for suggestion, etc).
2. Type of the symbol. This can be `skProc`, `skLet`, and just
   about any of the enums defined in the module ``compiler/ast.nim``.
3. Fully qualified path of the symbol. If you are querying a symbol
   defined in the ``proj.nim`` file, this would have the form
   `proj.symbolName`.
4. Type/signature. For variables and enums this will contain the
   type of the symbol, for procs, methods and templates this will
   contain the full unique signature (e.g. `proc (File)`).
5. Full path to the file containing the symbol.
6. Line where the symbol is located in the file. Lines start to
   count at **1**.
7. Column where the symbol is located in the file. Columns start
   to count at **0**.
8. Docstring for the symbol if available or the empty string. To
   differentiate the docstring from end of answer,
   the docstring is always provided enclosed in double quotes, and
   if the docstring spans multiple lines, all following lines of the
   docstring will start with a blank space to align visually with
   the starting quote.

   Also, you won't find raw ``\n`` characters breaking the one
   answer per line format. Instead you will need to parse sequences
   in the form ``\xHH``, where *HH* is a hexadecimal value (e.g.
   newlines generate the sequence ``\x0A``).
