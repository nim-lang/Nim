ES modules (modern NodeJS/browser)
==================================

Sample binding functions to import ES6 modules (`esmodules` Nim module):

.. code-block:: nim
  import macros, jsffi

  # import { x } from 'xyz'
  proc esImport*(name: cstring, nameOrPath: cstring) {.
      importcpp: "import { # } from #".}

Using the ES module bindings in Nim

.. code-block:: nim
  import esmodules # custom binding module we created above

  # import { x } from 'xyz'
  esImport("x", "./xyz")  

  # referencing constants imported (implicitly available)
  var nimx {.importjs. "x"} # links to imported var levels via * import  
  echo nimx # links to imported default var with alias $

The Nim JS compiler by default spits out all the Nim JS code inside a scope, 
so that `import` and `export` statements are invalid (must be in global/outer scope of file).

Compile ``x_import.nim`` to nodejs compatible JavaScript using: 

  nim js -d:nodejs -r x_import.nim

```js
// ... loads of Nim generated code
import { "x" } from "./xyz";

// for assignment, the string argument is not auto-quoted by the JS compiler
var nimx = x; 

// console.log
rawEcho(xx);
```

The output is of the form ``import { "x" } from "./x";`` which is not what we desired.

We will want to ensure the imported identifier is "hidden in the shadows" and doesn't conflict with other identifiers.
The Nim program should use the correct identifier name, shadowing the underlying imported JS identifier

To circumvent the malformed import identifier, we need to use a more advanced technique, using ``template`` and ``emit``.

.. code-block:: nim
  proc esImportImpl(name: string, nameOrPath: string): string =
    result = "import { " & name & " as " & name & "$$ } from "
    result.addQuoted nameOrPath

  template esImport*(name: string, nameOrPath: string) =
    {.emit: esImportImpl(name, nameOrPath).}

We use string concatenation ``&`` to output the name without quotes and use ``addQuoted`` to
output the module name or path in a quoted string.

Now calling ``esImport("x", "./x")`` outputs ``import { x as x$$ } from "./x";``. 
We still need to bind a Nim ``var``

.. code-block:: nim
  esImport("x", "./x")
  var x {.importjs. "x$$"}

It would be very convenient if we could automatically generate the var binding as well. 

## Naive var binding approach

.. code-block:: nim
  # emits: import { x } from 'xyz'
  proc esImportImpl(name: string, nameOrPath: string, bindVar: bool): string =
    result = "import { " & name & " as " & name & "$$ } from "
    result.addQuoted nameOrPath & ";\n"
    if bindVar
      result = result & "var " & name & " = " & name & "$$;"

  # import { _i_x_ } from 'xyz'; var x = _i_x_;
  template esImport*(name: string, nameOrPath: string, bindVar: bool = true) =
    {.emit: esImportImpl(name, nameOrPath, bindVar).}

Unfortunately the `var` will only be output to the ``js`` file and not be present in the Nim program.
To do this correctly we would need to use a macro that operates on the AST to generate code.

The imported file ``x`` must be an ``mjs`` file as well (turtles all the way down).

You can run the ``mjs`` file via Node using the ``--experimental-modules`` option

`node --experimental-modules my-game.mjs`

Alternatively compile the ``mjs`` files to compatible ES 5 JavaScript using `Babel <https://babeljs.io/>`_.

See `ES module bindings for Nim <https://github.com/kristianmandrup/esmodule_nim>`_ repo.