JavaScript modules interop
==========================

- CommonJS
- ES modules
- SystemJS

CommonJS (require)
------------------

``jsffi`` contains a require binding for CommonJS

- ``require(module: cstring)`` to import a CommonJS module by name or path

You can use the ``exportjs`` pragma to export a Nim procedure as a CommonJS module (``module.exports``)

.. code-block:: nim
  proc fib(a: cint): cint {.exportjs.} =


Alternatively, use the `jsExport <https://github.com/nepeckman/jsExport.nim>_ module. 
The macro ``jsExport`` can be used to create CommonJS exports for a set of Nim identifiers.

.. code-block:: nim
  jsExport:
    "nimGreet" = greet # export with a different name
    greetPerson # export with the same name
    (name, person) # comma seperated list of exports

ES modules
----------

See `ES modules <js-es-imports.rst.html>`_ for a detailed use case scenario on JavaScript FFI interop

SystemJS
--------

Binding functions for `SystemJs <https://github.com/systemjs/systemjs#example-usage>`_
should generate this code:

.. code-block:: js
  System.import('/js/main.js');

Nim bindings (in a ``systemjs`` module)

.. code-block:: nim
  # System.import('/js/main.js');
  proc systemImport*(path: cstring): auto {.importjs "System.import(#)".}

Using the ``systemJS`` Nim binding

.. code-block:: nim
  import systemjs # custom binding module we created above

  systemImport("/js/main.js")

To use `systemJS` in a scalable way, use `importMaps <https://github.com/systemjs/systemjs/blob/master/docs/import-maps.md>`_.
See `single-spa <https://single-spa.js.org>`_ for a concrete modern example for how to use this approach with Micro Frontends.

Watch `local development with microfrontends and import maps <https://www.youtube.com/watch?v=vjjcuIxqIzY>`_ for a brief introduction.
