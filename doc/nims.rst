================================
          NimScript
================================

Strictly speaking, ``NimScript`` is the subset of Nim that can be evaluated
by Nim's builtin virtual machine (VM). This VM is used for Nim's compiletime
function evaluation features, but also replaces Nim's existing configuration
system.

So instead of a ``myproject.nim.cfg`` configuration file, you can use
a ``myproject.nims`` file that simply contains Nim code controlling the
compilation process. For a directory wide configuration, use ``config.nims``
instead of ``nim.cfg``.

The VM cannot deal with ``importc``, the FFI is not available, so there are not
many stdlib modules that you can use with Nim's VM. However, at least the
following modules are available:

* `strutils <strutils.html>`_
* `ospaths <ospaths.html>`_
* `math <math.html>`_

The `system <system.html>`_ module in NimScript mode additionally supports
these operations: `nimscript <nimscript.html>`_.


NimScript as a configuration file
=================================

What is ``x.y.key = "value"`` in the configuration file
becomes ``switch("x.y.key", "value")``. ``--option`` is ``switch("option")``.
The ``system`` module also exports 2 ``--`` templates for convenience:

.. code-block:: nim
  --forceBuild
  # is the same as:
  switch("forceBuild")


NimScript as a build tool
=========================

The ``task`` template that the ``system`` module defines allows a NimScript
file to be used as a build tool. The following example defines a
task ``build`` that is an alias for the ``c`` command:

.. code-block:: nim
  task build, "builds an example":
    setCommand "c"


In fact, as a convention the following tasks should be available:

=========     ===================================================
Task          Description
=========     ===================================================
``build``     Build the project with the required
              backend (``c``, ``cpp`` or ``js``).
``tests``     Runs the tests belonging to the project.
``bench``     Runs benchmarks belonging to the project.
=========     ===================================================


If the task runs an external command via ``exec`` it should afterwards call
``setCommand "nop"`` to tell the Nim compiler that nothing else needs to be
done:

.. code-block:: nim

  task tests, "test regular expressions":
    exec "nim c -r tests"
    setCommand "nop"


Nimble integration
==================

A ``project.nims`` file can also be used as an alternative to
a ``project.nimble`` file to specify the meta information (for example, author,
description) and dependencies of a Nimble package. This means you can easily
have platform specific dependencies:

.. code-block:: nim

  version = "1.0"
  author = "The green goo."
  description = "Lexer generation and regex implementation for Nim."
  license = "MIT"

  when defined(windows):
    requires "oldwinapi >= 1.0"
  else:
    requires "gtk2 >= 1.0"




Standalone NimScript
====================

NimScript can also be used directly as a portable replacement for Bash and
Batch files. Use ``nim e myscript.nims`` to run ``myscript.nims``. For example,
installation of Nimble is done with this simple script:

.. code-block:: nim

  mode = ScriptMode.Verbose

  var id = 0
  while dirExists("nimble" & $id):
    inc id

  exec "git clone https://github.com/nim-lang/nimble.git nimble" & $id

  withDir "nimble" & $id & "/src":
    exec "nim c nimble"

  mvFile "nimble" & $id & "/src/nimble".toExe, "bin/nimble".toExe

