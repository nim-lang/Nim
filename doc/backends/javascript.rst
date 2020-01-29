=====================
The JavaScript target
=====================

Nim can generate `JavaScript`:idx: code through the ``js`` command.

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
`times <times.html>`_ are available! 

To access the DOM, use the `dom
<dom.html>`_ module that is only available for the JavaScript platform.

For JavaScript, an ``importjs`` pragma is available which is an alias for ``importcpp``.

Nim code calling the backend 
============================

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

`jscore <jscore.html>`_ is the core JavaScript interop library for Nim.

Nim also includes:

- `asyncjs <asyncjs.html>`_ Async JavaScript bindings (``async/await`` and ``Promise``)
- `dom <dom.html>`_ Browser DOM bindings (Document Object Model) 
- `jsconsole <jsconsole.html>`_ console bindings (such as ``console.log``)
- `jsffi <jsffi.html>`_ FFI helpers for JavaScript interop

FFI bindings for javascript libraries
-------------------------------------

Nim FFI bindings for some popular JavaScript libraries.

- `HTML5-Canvas <https://gitlab.com/define-private-public/HTML5-Canvas-Nim>`_
- `Vue <https://github.com/oskca/nimjs-vue>`_
- `React <https://github.com/andreaferretti/react.nim>`_

Some of these binding libs are a bit dated and could be improved, using 
the latest Nim features, modules and best FFI practices.

jsffi module
------------

The `jsffi <jsffi.html>`_ module provides convenient types, wrappers and macros to make it easier to interop with JavaScript.

Here are some of the special types available

- ``JsObject`` (``Object`` type)
- ``JsError`` (``Error`` type)

Here are some of the special variables available

- ``jsNull`` (``null`` literal)    
- ``jsUndefined`` (``undefined`` literal)

Some basic JavaScript helper functions:

- ``jsTypeOf(type)`` calls `typeOf` to return type of Object
- ``jsNew(clazz)`` invocation of the JavaScript `new` operator
- ``jsDelete(key)`` invocation of `delete` operator (delete key from object)

A few helpers specific to NodeJS:

- ``jsDirname`` (``__dirname`` pseudo-variable)
- ``jsFilename``(``__filename`` pseudo-variable)

The ``jsffi`` module is key for proper JavaScript interop, so take some time to see what 
is available that could be useful for your use case.

Sample usage:

.. code-block:: nim

  # define document and console
  var document {.importc, nodecl.}: JsObject
  var console {.importc, nodecl.}: JsObject

  # import the "$" function
  proc jq(selector: JsObject): JsObject {.importcpp: "$(#)".}

Sample ``jsffi`` Nim code:

.. code-block:: nim
  proc jsTypeOf*(x: JsObject): cstring {.importcpp: "typeof(#)".}
    ## Returns the name of the JsObject's JavaScript type as a cstring.

  proc jsNew*(x: auto): JsObject {.importcpp: "(new #)".}
    ## Turns a regular function call into an invocation of the
    ## JavaScript's `new` operator

  proc jsDelete*(x: auto): JsObject {.importcpp: "(delete #)".}

Notice the syntax ``{.importcpp: "typeof(#)".}`` where the ``#`` is an argument substituion similar 
to that used in Nim Regexp ``re`` module.

JavaScript modules interop
==========================

CommonJS (require)
------------------


``jsffi`` contains a require binding for CommonJS

- ``require(module: cstring)`` to import a CommonJS module by name or path

`jsExport <https://github.com/nepeckman/jsExport.nim>_ contains a macro ``jsExport`` 
that can be used to create CommonJS exports (ie. ``module.exports`` statements) for Nim. 

.. code-block:: nim
  jsExport:
    "nimGreet" = greet # export with a different name
    greetPerson # export with the same name
    (name, person) # comma seperated list of exports

ES6 imports (modern NodeJS/browser)
-----------------------------------

Sample binding functions to import ES6 modules (`esmodules` Nim module):

.. code-block:: nim
  # import * from 'xyz'
  proc esImportAll*(from: cstring)): auto {.importcpp: "import * from '#'".}

  # import xyz from 'xyz'
  proc esImportDefault*(name: cstring, nameOrPath: cstring)) =
    {.emit: ["import ", name, " from ", nameOrPath, "};] .}

  # import { default as abc } from 'xyz'
  proc esImportDefaultAs*(name: cstring, nameOrPath: cstring)) =
    {.emit: ["import { default as ", name, " }" from '", nameOrPath, "';"] .}

  # import { x } from 'xyz'
  proc esImport*(name: cstring, nameOrPath: cstring)) =
    {.emit: ["import { ", name, " }" from '", nameOrPath, "';"] .}

Using the ES module bindings in Nim

.. code-block:: nim
  import esmodules # custom binding module we created above

  # import { default as $ } from 'xyz'
  esImportDefaultAs("$")
  # import * from 'xyz'
  esImportAll("game")  

  # referencing constants imported (implicitly available)
  const levels {.importjs.} # links to imported var levels via * import
  const characters {.importjs "_characters".} 
  
  const game {.importjs "$".} # links to imported default var with alias $

SystemJS
--------

Binding functions for `SystemJs <https://github.com/systemjs/systemjs#example-usage>`_
should generate this code:

.. code-block:: js
  System.import('/js/main.js');

Nim bindings (in a ``systemjs`` module)

.. code-block:: nim
  # System.import('/js/main.js');
  proc systemImport*(path: cstring): auto {.importcpp: "System.import(#)".}

Using the ``systemJS`` Nim binding

.. code-block:: nim
  import systemjs # custom binding module we created above

  systemImport("/js/main.js")

To use `systemJS` in a scalable way, use `importMaps <https://github.com/systemjs/systemjs/blob/master/docs/import-maps.md>`_.
See `single-spa <https://single-spa.js.org>`_ for a concrete modern example for how to use this approach with Micro Frontends.

Watch `local development with microfrontends and import maps <https://www.youtube.com/watch?v=vjjcuIxqIzY>`_ for a brief introduction.

Writing JavaScript FFI binding modules
======================================

It is good practice to start by detecting if the runtime environment is js (ie. if ``js`` is defined).
If the module is used in the wrong type of runtime environment, abort with an error using the ``error`` 
pragma as shown in this example

.. code-block:: nim
  import macros, dom, jsconsole, jsffi, asyncjs

  when not defined(js) and not defined(Nimdoc):
    {.error: "This module only works on the JavaScript platform".}

TypeScript and dts2nim
======================

Nim is a statically typed language like `TypeScript <https://www.typescriptlang.org>`_, 
hence TypeScript should provide a gateway to make it easier for Nim 
to "pick up" the correct types for variables and function arguments etc.

`dts2nim <https://github.com/mcclure/dts2nim>`_ is a tool that can parse a TypeScript program and generate
Nim bindings that can be used as a good starting point.

See `nim-webgl-example <https://github.com/mcclure/nim-webgl-example>`_ for an example using the ``dts2nim`` 
tool to bind to the webGL library using its TypeScript definitions (type definitions, ie. ``d.ts`` files).

For a given library ``name-of-library`` see if you can find TypeScript types for it using `npm find @types/name-of-library`
If up to date typescript type definitions exist, use them to provide more information on the types to be used in your Nim bindings.

Don't overuse the generic type ``auto`` (similar to ``any`` in TypeScript).

Backend code calling Nim
------------------------

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
open ``mhost.html`` in a browser. 

If the browser supports javascript, you
should see an alert box displaying the text ``Fib for 9 is 34``. 

JavaScript doesn't require an initialisation call to ``NimMain`` or
similar function and you can call the exported Nim proc directly.

Async Javascript
~~~~~~~~~~~~~~~~

To interop with asynchronous JavaScript such as `async/await` and `Promises`, 
please use the `asyncjs <asyncjs.html>`_ module.

.. code-block:: nim

  proc loadGame(name: string): Future[Game] {.async.} =
    # code

should be equivalent to

.. code-block:: nim
  async function loadGame(name) {
    // code
  }

A call to an asynchronous procedure usually needs ``await`` to wait for the completion of the ``Future``.

.. code-block:: nim

  var game = await loadGame(name)

Callbacks
---------

You can wrap callbacks with asynchronous procedures using a promise via ``newPromise``:

.. code-block:: nim

  proc loadGame(name: string): Future[Game] =
    var promise = newPromise() do (resolve: proc(response: Game)):
      cbBasedLoadGame(name) do (game: Game):
        resolve(game)
    return promise

Promises
--------

Use the ``PromiseJs`` type and ``newPromise`` (as demonstrated above)

.. code-block:: nim
type
  PromiseJs {...} = ref object

Usage

.. code-block:: nim
  proc loadGame(init: PromiseJs): Future[Game]

emit pragma
===========

In rare cases, you might need to use the ``{.emit.}`` pragma to have complete control over the JavaScript code being generated.

.. code-block:: nim

  proc createGame*(name: cstring, type: cint, config: JsObject): PromiseJs =
    ``{.emit: ["await new Game(", name, ",", type, ",", config ").init();"]}``

The `emit` above is equivalent to the string interpolation: `await new Game(${name}, ${type}, ${config}).init();`

Note: The `Html5Canvas` bindings library uses the ``emit`` pragma extensively (not a good practice).

Memory management
=================

Since JavaScript already provides automatic memory management, you can freely pass
objects between the two language without problems. 