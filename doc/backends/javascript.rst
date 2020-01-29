The JavaScript target
---------------------

Nim can also generate `JavaScript`:idx: code through the ``js`` command.

Nim targets JavaScript 1.5 which is supported by any widely used browser.
Since JavaScript does not have a portable means to include another module,
Nim just generates a long ``.js`` file.

Features or modules that the JavaScript platform does not support are not
available. This includes:

* manual memory management (``alloc``, etc.)
* casting and other unsafe operations (``cast`` operator, ``zeroMem``, etc.)
* file management
* most modules of the standard library
* proper 64 bit integer arithmetic
* unsigned integer arithmetic

However, the modules `strutils <strutils.html>`_, `math <math.html>`_, and
`times <times.html>`_ are available! To access the DOM, use the `dom
<dom.html>`_ module that is only available for the JavaScript platform.

For JavaScript, an ``importjs`` pragma is available which is an alias for ``importcpp``.

Nim code calling the backend 
----------------------------

JavaScript in the Browser 
-------------------------

To compile a Nim module into a ``.js`` file use the ``js`` command; the
default is a ``.js`` file that is supposed to be referenced in an ``.html``
file. 

  nim js examples/hallo.nim

The same html file which hosts the generated JavaScript will likely provide other
JavaScript functions which you are importing with ``importjs``.

JavaScript outside the Browser (Node or Deno)
---------------------------------------------

You can also run the code with `nodejs`:idx:
(`<http://nodejs.org>`_)::

  nim js -d:nodejs -r examples/hallo.nim

For CommonJS interop (using `require` to import modules), use the `exportJs` module

JavaScript invocation example
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Create a ``host.html`` file with the following content:

.. code-block::

  <html><body>
  <script type="text/javascript">
  function addTwoIntegers(a, b)
  {
    return a + b;
  }
  </script>
  <script type="text/javascript" src="calculator.js"></script>
  </body></html>

Create a ``calculator.nim`` file with the following content (or reuse the one
from the previous section):

.. code-block:: nim

  proc addTwoIntegers(a, b: int): int {.importjs.}

  when isMainModule:
    echo addTwoIntegers(3, 7)

Compile the Nim code to JavaScript with ``nim js -o:calculator.js
calculator.nim`` and open ``host.html`` in a browser. If the browser supports
javascript, you should see the value ``10`` in the browser's console. 

Many JavaScript libraries provide a global object that contains all the functions available.
Sometimes these functions are structured and categorised in a hierarchy of objects within this global object.

.. code-block:: nim

  # basic rxjs functions are all made available in the rxjs global object
  proc from*(input: auto): Observable {.importjs "rxjs.from".}

  # operator functions are all made available in the rxjs.operators object
  proc merge(a, b: int): int {.importjs. "rxjs.operators.merge" }

Use the
`dom module <dom.html>`_ for specific DOM querying and modification procs.

Take a look at `karax <https://github.com/pragmagic/karax>`_ for how to
develop browser based applications.

FFI bindings for javascript libraries
-------------------------------------

A number of Nim modules are available that provide FFI bindings for popular JavaScript libraries.

- Html5Canvas
- p5
- Vue
- React

Some of these binding libs are a bit dated and could be improved, using 
the latest Nim features, modules and best FFI practices.


jsffi module
------------

The ``jsffi`` module provides convenient types, wrappers and macros to make it easier to interop with JavaScript

- ``JsObject`` (``Object`` type)
- ``jsNull`` (``null`` literal)    
- ``jsUndefined`` (``undefined`` literal)

For NodeJS:

- ``jsDirname`` (``__dirname`` pseudo-variable)
- ``jsFilename``(``__filename`` pseudo-variable)

The ``jsffi`` module is key for proper JavaScript interop, so take some time to see what 
is available that could be useful for your use case.

emit pragma
-----------

In rare cases, you might need to use the ``{.emit.}`` pragma to fine tune the JavaScript code being generated.

.. code-block:: nim

  proc promise*(resolve, reject): PromiseJs =
    ``{.emit: ["new Promise(", resolve, ",", reject, ");"]}``

Backend code calling Nim
------------------------

The JavaScript target doesn't have any further interfacing considerations
since it also has garbage collection.

Nim invocation example from JavaScript
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Create a ``mhost.html`` file with the following content:

.. code-block::

  <html><body>
  <script type="text/javascript" src="fib.js"></script>
  <script type="text/javascript">
  alert("Fib for 9 is " + fib(9));
  </script>
  </body></html>

Create a ``fib.nim`` file with the following content (or reuse the one
from the previous section):

.. code-block:: nim

  proc fib(a: cint): cint {.exportjs.} =
    if a <= 2:
      result = 1
    else:
      result = fib(a - 1) + fib(a - 2)

Compile the Nim code to JavaScript with ``nim js -o:fib.js fib.nim`` and
open ``mhost.html`` in a browser. If the browser supports javascript, you
should see an alert box displaying the text ``Fib for 9 is 34``. As mentioned
earlier, JavaScript doesn't require an initialisation call to ``NimMain`` or
similar function and you can call the exported Nim proc directly.

Async Javascript
~~~~~~~~~~~~~~~~

To interop with asynchronous JavaScript such as `async/await` and `Promises`, 
please use the ``asyncjs`` module.

Memory management
=================

Since JavaScript already provides automatic memory management, you can freely pass
objects between the two language without problems. 