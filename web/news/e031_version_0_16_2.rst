Version 0.16.2 released
=======================

Changelog
~~~~~~~~~

Changes affecting backwards compatibility
-----------------------------------------

- ``httpclient.request`` now respects ``maxRedirects`` option. Previously
  redirects were handled only by ``get`` and ``post`` procs.

Library Additions
-----------------


Tool Additions
--------------


Compiler Additions
------------------


Language Additions
------------------

- The ``try`` statement's ``except`` branches now support the binding of a
caught exception to a variable:

.. code-block:: nim
  try:
    raise newException(Exception, "Hello World")
  except Exception as exc:
    echo(exc.msg)

This replaces the ``getCurrentException`` and ``getCurrentExceptionMsg()``
procedures, although these procedures will remain in the stdlib for the
foreseeable future. This new language feature is actually implemented using
these procedures.

In the near future we will be converting all exception types to refs to
remove the need for the ``newException`` template.
