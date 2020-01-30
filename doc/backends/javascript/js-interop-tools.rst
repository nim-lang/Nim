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