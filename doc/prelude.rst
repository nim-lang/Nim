Prelude
=======

This is an include file that simply imports common modules for your convenience:

.. code-block:: nim
  include prelude

Same as:

.. code-block:: nim
  import os, strutils, times, parseutils, parseopt, hashes, tables, sets


Examples
========

Get the basic most common imports ready to start coding using ``prelude``:

.. code-block:: nim
  include prelude

  echo now()
  echo getCurrentDir()
  echo "Hello $1".format("World")


See also:
- `Sugar <sugar.html>`_
