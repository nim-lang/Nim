===============================
   Nim maintenance script
===============================

:Version: |nimversion|

.. contents::

.. raw:: html
  <blockquote><p>
  "A great chef is an artist that I truly respect" -- Robert Stack.
  </p></blockquote>


Introduction
============

The `koch`:idx: program is Nim's maintenance script. It is a replacement
for make and shell scripting with the advantage that it is much more portable.
The word *koch* means *cook* in German. ``koch`` is used mainly to build the
Nim compiler, but it can also be used for other tasks. This document
describes the supported commands and their options.


Commands
========

boot command
------------

The `boot`:idx: command bootstraps the compiler, and it accepts different
options:

-d:release
  By default a debug version is created, passing this option will
  force a release build, which is much faster and should be preferred
  unless you are debugging the compiler.
-d:useGnuReadline
  Includes the `rdstdin module <rdstdin.html>`_ for `interactive
  mode <nimc.html#nim-interactive-mode>`_ (aka ``nim i``).
  This is not needed on Windows. On other platforms this may
  incorporate the GNU readline library.
-d:nativeStacktrace
  Use native stack traces (only for Mac OS X or Linux).
-d:avoidTimeMachine
  Only for Mac OS X, activating this switch will force excluding
  the generated ``nimcache`` directories from Time Machine backups.
  By default ``nimcache`` directories will be included in backups,
  and just for the Nim compiler itself it means backing up 20MB
  of generated files each time you update the compiler. Using this
  option will make the compiler invoke the `tmutil
  <https://developer.apple.com/library/mac/documentation/Darwin/Reference/Manpages/man8/tmutil.8.html>`_
  command on all ``nimcache`` directories, setting their backup
  exclusion bit.

  You can use the following command to locate all ``nimcache``
  directories and check their backup exclusion bit::

    $ find . -type d -name nimcache -exec tmutil isexcluded \{\} \;
--gc:refc|v2|markAndSweep|boehm|go|none
  Selects which garbage collection strategy to use for the compiler
  and generated code. See the `Nim's Garbage Collector <gc.html>`_
  documentation for more information.

After compilation is finished you will hopefully end up with the nim
compiler in the ``bin`` directory. You can add Nim's ``bin`` directory to
your ``$PATH`` or use the `install command`_ to place it where it will be
found.

csource command
---------------

The `csource`:idx: command builds the C sources for installation. It accepts
the same options as you would pass to the `boot command`_.

temp command
------------

The temp command builds the Nim compiler but with a different final name
(``nim_temp``), so it doesn't overwrite your normal compiler. You can use
this command to test different options, the same you would issue for the `boot
command`_.

test command
------------

The `test`:idx: command can also be invoked with the alias ``tests``. This
command will compile and run ``tests/testament/tester.nim``, which is the main
driver of Nim's test suite. You can pass options to the ``test`` command,
they will be forwarded to the tester. See its source code for available
options.

web command
-----------

The `web`:idx: command converts the documentation in the ``doc`` directory
from rst to HTML. It also repeats the same operation but places the result in
the ``web/upload`` which can be used to update the website at
https://nim-lang.org.

By default the documentation will be built in parallel using the number of
available CPU cores. If any documentation build sub commands fail, they will
be rerun in serial fashion so that meaninful error output can be gathered for
inspection. The ``--parallelBuild:n`` switch or configuration option can be
used to force a specific number of parallel jobs or run everything serially
from the start (``n == 1``).

zip command
-----------

The `zip`:idx: command builds the installation ZIP package.
