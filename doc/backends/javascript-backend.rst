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

We can reduce the extensive dot syntax, by first linking the variables we need, then 
calling functions on these variables in the function bindings.

.. code-block:: nim
  var
    rxjs {.importjs.} = JsObject
    operators {.importjs "rxjs.operators" .} = JsObject

  # operator functions are all made available in the rxjs.operators object
  proc merge(a, b: int): int {.importjs. "operators" }


React Nim bindings sample (from ``react`` module)

.. code-block:: nim
  import macros, dom, jsffi

  {.experimental: "callOperator".}

  when not defined(js):
    {.error: "React.nim is only available for the JS target" .}

  ReactGlobal* {.importc.} = ref object of RootObj
    version*: cstring
  ReactDOMGlobal* {.importc.} = ref object of RootObj

  var
    React* {.importc, nodecl.}: ReactGlobal
    ReactDOM* {.importc, nodecl.}: ReactDOMGlobal

  {.push importcpp .}

  # React.createElement(c)
  proc createElement*(react: ReactGlobal, c: ReactComponent): ReactNode
  
  # React.createClass(c)
  proc createClass*(react: ReactGlobal, c: ReactDescriptor): ReactComponent
  
  # ReactDOM.render(node, el)
  proc render*(reactDom: ReactDOMGlobal, node: ReactNode, el: Element)

  {.pop.}

Note here that we first bind to the global vars in the ``var`` block. 
We use type name conventions like `ReactGlobal` to clearly indicate that this is a type for a global variable.
Then we add the methods on the ``React`` object such as ``createElement`` by setting the first argument to ``react: ReactGlobal`` 
which makes invocation of the form ``React.createElement(component)`` possible, due to Nim's UFCX (Unified Function Call Syntax)

To add a ``useState`` binding (from `React Hooks <https://reactjs.org/docs/hooks-intro.html>`_) we would simply need to verify it is available as ``React.useState``, then

.. code-block:: nim
  # const [x, setX] = React.useState(0)
  proc useState*(react: ReactGlobal, initialValue: auto): seq[auto]

Javascript interop standard libraries
-------------------------------------

`jscore <jscore.html>`_ is the core JavaScript interop library for Nim.

Nim also includes:

- `asyncjs <asyncjs.html>`_ Async JavaScript bindings (``async/await`` and ``Promise``)
- `dom <dom.html>`_ Browser DOM bindings (Document Object Model) 
- `jsconsole <jsconsole.html>`_ console bindings (such as ``console.log``)
- `jsffi <jsffi.html>`_ FFI helpers for JavaScript interop

Javascript web apps with Nim
----------------------------

Take a look at `karax <https://github.com/pragmagic/karax>`_ for how to
develop browser based applications.

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

Note that the ``importc`` pragmas are used (works, but deprecated when in a JavaScript context).
We recommend always using ``importjs`` for JavaScript going forward.

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

Writing JavaScript FFI binding modules
======================================

It is good practice to start by detecting if the runtime environment is js (ie. if ``js`` is defined).
If the module is used in the wrong type of runtime environment, abort with an error using the ``error`` 
pragma as shown in this example

.. code-block:: nim
  import macros, dom, jsconsole, jsffi, asyncjs

  when not defined(js) and not defined(Nimdoc):
    {.error: "This module only works on the JavaScript platform".}

JavaScript interop tools
------------------------

See `JavaScript interop tools <js-interop-tools.html>`_ on tools available to make FFI interop easier.

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

Memory management
=================

Since JavaScript already provides automatic memory management, you can freely pass
objects between the two language without problems. 