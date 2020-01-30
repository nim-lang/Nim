JavaScript interop pragmas
=========================

importjs pragma
---------------

The ``importjs`` pragma can be used to output JavaScript code to bridge Nim program code to the underlying JavaScript.

.. code-block:: nim
  # simple identifier bindings 

  type
    DOM {.importjs.} = JsObject

  var
    dom {.importjs.}

  # implicit mirrored call
  proc addTwoIntegers(a, b: int): int {.importjs.}

  # placeholder string substitution
  proc systemImport*(path: cstring): auto {.importjs "System.import(#)".}

emit pragma
-----------

In rare cases, you might need to use the ``{.emit.}`` pragma to have complete control over the JavaScript code being generated.
A good example for this can be found in the walkthrough for interop with `ES modules <js-es-modules.html>`_

