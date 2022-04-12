===============================
   Nim maintenance script
===============================

:Version: |nimversion|

.. default-role:: code
.. include:: rstcommon.rst
.. contents::

.. raw:: html
  <blockquote><p>
  "A great chef is an artist that I truly respect" -- Robert Stack.
  </p></blockquote>


Introduction
============

The `koch`:idx: program is Nim's maintenance script. It is a replacement
for make and shell scripting with the advantage that it is much more portable.
The word *koch* means *cook* in German. `koch`:cmd: is used mainly to build the
Nim compiler, but it can also be used for other tasks. This document
describes the supported commands and their options.


Commands
========

boot command
------------

The `boot`:idx: command bootstraps the compiler, and it accepts different
options:

-d:release    By default a debug version is created, passing this option will
  force a release build, which is much faster and should be preferred
  unless you are debugging the compiler.
-d:nimUseLinenoise     Use the linenoise library for interactive mode
                       (not needed on Windows).

After compilation is finished you will hopefully end up with the nim
compiler in the `bin` directory. You can add Nim's `bin` directory to
your `$PATH` or use the install command to place it where it will be
found.

csource command
---------------

The `csource`:idx: command builds the C sources for installation. It accepts
the same options as you would pass to the `boot command
<#commands-boot-command>`_.

temp command
------------

The temp command builds the Nim compiler but with a different final name
(`nim_temp`:cmd:), so it doesn't overwrite your normal compiler. You can use
this command to test different options, the same you would issue for the `boot
command <#commands-boot-command>`_.

test command
------------

The `test`:idx: command can also be invoked with the alias `tests`:option:. This
command will compile and run ``testament/tester.nim``, which is the main
driver of Nim's test suite. You can pass options to the `test`:option: command,
they will be forwarded to the tester. See its source code for available
options.

web command
-----------

The `web`:idx: command converts the documentation in the `doc` directory
from rst to HTML. It also repeats the same operation but places the result in
the ``web/upload`` which can be used to update the website at
https://nim-lang.org.

By default, the documentation will be built in parallel using the number of
available CPU cores. If any documentation build sub-commands fail, they will
be rerun in serial fashion so that meaningful error output can be gathered for
inspection. The `--parallelBuild:n`:option: switch or configuration option can be
used to force a specific number of parallel jobs or run everything serially
from the start (`n == 1`).

pdf command
-----------

The `pdf`:idx: command builds PDF versions of Nim documentation: Manual,
Tutorial and a few other documents. To run it one needs to
`install Latex/xelatex <https://www.latex-project.org/get>`_ first.
