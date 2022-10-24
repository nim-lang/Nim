#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple high performance `JSON`:idx:
## parser. JSON (JavaScript Object Notation) is a lightweight
## data-interchange format that is easy for humans to read and write
## (unlike XML). It is easy for machines to parse and generate.
## JSON is based on a subset of the JavaScript Programming Language,
## Standard ECMA-262 3rd Edition - December 1999.
##
## See also
## ========
## * `std/parsejson <parsejson.html>`_
## * `std/jsonutils <jsonutils.html>`_
## * `std/marshal <marshal.html>`_
## * `std/jscore <jscore.html>`_
##
##
## Overview
## ========
##
## Parsing JSON
## ------------
##
## JSON often arrives into your program (via an API or a file) as a `string`.
## The first step is to change it from its serialized form into a nested object
## structure called a `JsonNode`.
##
## The `parseJson` procedure takes a string containing JSON and returns a
## `JsonNode` object. This is an object variant and it is either a
## `JObject`, `JArray`, `JString`, `JInt`, `JFloat`, `JBool` or
## `JNull`. You check the kind of this object variant by using the `kind`
## accessor.
##
## For a `JsonNode` who's kind is `JObject`, you can access its fields using
## the `[]` operator. The following example shows how to do this:
##
## .. code-block:: Nim
##   import std/json
##
##   let jsonNode = parseJson("""{"key": 3.14}""")
##
##   doAssert jsonNode.kind == JObject
##   doAssert jsonNode["key"].kind == JFloat
##
## Reading values
## --------------
##
## Once you have a `JsonNode`, retrieving the values can then be achieved
## by using one of the helper procedures, which include:
##
## * `getInt`
## * `getFloat`
## * `getStr`
## * `getBool`
##
## To retrieve the value of `"key"` you can do the following:
##
## .. code-block:: Nim
##   import std/json
##
##   let jsonNode = parseJson("""{"key": 3.14}""")
##
##   doAssert jsonNode["key"].getFloat() == 3.14
##
## **Important:** The `[]` operator will raise an exception when the
## specified field does not exist.
##
## Handling optional keys
## ----------------------
##
## By using the `{}` operator instead of `[]`, it will return `nil`
## when the field is not found. The `get`-family of procedures will return a
## type's default value when called on `nil`.
##
## .. code-block:: Nim
##   import std/json
##
##   let jsonNode = parseJson("{}")
##
##   doAssert jsonNode{"nope"}.getInt() == 0
##   doAssert jsonNode{"nope"}.getFloat() == 0
##   doAssert jsonNode{"nope"}.getStr() == ""
##   doAssert jsonNode{"nope"}.getBool() == false
##
## Using default values
## --------------------
##
## The `get`-family helpers also accept an additional parameter which allow
## you to fallback to a default value should the key's values be `null`:
##
## .. code-block:: Nim
##   import std/json
##
##   let jsonNode = parseJson("""{"key": 3.14, "key2": null}""")
##
##   doAssert jsonNode["key"].getFloat(6.28) == 3.14
##   doAssert jsonNode["key2"].getFloat(3.14) == 3.14
##   doAssert jsonNode{"nope"}.getFloat(3.14) == 3.14 # note the {}
##
## Unmarshalling
## -------------
##
## In addition to reading dynamic data, Nim can also unmarshal JSON directly
## into a type with the `to` macro.
##
## Note: Use `Option <options.html#Option>`_ for keys sometimes missing in json
## responses, and backticks around keys with a reserved keyword as name.
##
## .. code-block:: Nim
##   import std/json
##   import std/options
##
##   type
##     User = object
##       name: string
##       age: int
##       `type`: Option[string]
##
##   let userJson = parseJson("""{ "name": "Nim", "age": 12 }""")
##   let user = to(userJson, User)
##   if user.`type`.isSome():
##     assert user.`type`.get() != "robot"
##
## Creating JSON
## =============
##
## This module can also be used to comfortably create JSON using the `%*`
## operator:
##
## .. code-block:: nim
##   import std/json
##
##   var hisName = "John"
##   let herAge = 31
##   var j = %*
##     [
##       { "name": hisName, "age": 30 },
##       { "name": "Susan", "age": herAge }
##     ]
##
##   var j2 = %* {"name": "Isaac", "books": ["Robot Dreams"]}
##   j2["details"] = %* {"age":35, "pi":3.1415}
##   echo j2
##
## See also: std/jsonutils for hookable json serialization/deserialization
## of arbitrary types.

runnableExamples:
  ## Note: for JObject, key ordering is preserved, unlike in some languages,
  ## this is convenient for some use cases. Example:
  type Foo = object
    a1, a2, a0, a3, a4: int
  doAssert $(%* Foo()) == """{"a1":0,"a2":0,"a0":0,"a3":0,"a4":0}"""




import std/private/jsontree
export jsontree

import std/private/jsonparser
export jsonparser

import std/private/jsonmapper
export jsonmapper

import std/private/jsonbuilder
export jsonbuilder

import std/private/jsondeserialiser
export jsondeserialiser

import std/private/jsontypes


