#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim Authors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This Module implements types and macros to facilitate the wrapping of, and
## interaction with JavaScript libraries. Using the provided types ``JsObject``
## and ``JsAssoc`` together with the provided macros allows for smoother
## interfacing with JavaScript, allowing for example quick and easy imports of
## JavaScript variables:
##
## .. code-block:: nim
##
##  # Here, we are using jQuery for just a few calls and do not want to wrap the
##  # whole library:
##
##  # import the document object and the console
##  magicVar(document, JsObject)
##  magicVar(console, JsObject)
##  # import the "$" function
##  proc jq(selector: JsObject): JsObject {. importcpp: "$(#)" .}
##
##  # Use jQuery to make the following code run, after the document is ready.
##  # This uses an experimental ``.()`` operator for ``JsObject``, to emit
##  # JavaScript calls, when no corresponding proc exists for ``JsObject``.
##  proc main =
##    jq(document).ready(proc() =
##      console.log("Hello JavaScript!")
##    )
##

when not defined(js) and not defined(nimdoc) and not defined(nimsuggest):
  {.fatal: "Module jsFFI is designed to be used with the JavaScript backend.".}

import macros

const
  setImpl = "#[#] = #"
  setImplJsString = "#[toJSStr(#)] = #"
  getImpl = "#[#]"
  getImplJsString = "#[toJSStr(#)]"
  callImpl = "#[#].apply(#, #)"

type
  JsRoot* = ref object of RootObj
    ## Root type of both JsObject and JsAssoc
  JsObject* = ref object of JsRoot
    ## Dynamically typed wrapper around a JavaScript object.
  JsAssoc*[K, V] = ref object of JsRoot
    ## Statically typed wrapper around a JavaScript object.

# Import variables:
template magicVar*(name, typ: untyped): untyped =
  ## Imports a variable declared in JavaScript code. This is useful for
  ## importing globals or things like `self` or `this` from JavaScript.
  ## It takes the name of the variable and its type.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##  # We want to import the console object as an JsObject
  ##  magicVar(console, JsObject)
  ##  console.log("Hello JavaScript!")
  ##
  var `name` {. importc, nodecl, inject .}: `typ`

# New
proc newJsObject*: JsObject {. importcpp: "{@}" .}
  ## Creates a new empty JsObject
proc newJsAssoc*[K, V]: JsAssoc[K, V] = {. importcpp: "{@}" .}
  ## Creates a new empty JsAssoc with key type `K` and value type `V`.

# Checks
proc hasOwnProperty*(x: JsObject, prop: string): bool
  {. importcpp: "#.hasOwnProperty(#)" .}
  ## Checks, whether `x` has a property of name `prop`.

proc jsTypeOf*(x: JsObject): cstring {. importcpp: "typeof(#)" .}
  ## Returns the name of the JsObject's JavaScript type as a cstring.

# Conversion to and from JsObject
proc to*(x: JsObject, T: typedesc): T {. importcpp: "(#)" .}
  ## Converts a JsObject `x` to type `T`.
proc toJs*[T](val: T): JsObject {. importcpp: "(#)" .}
  ## Converts a value of any type to type JsObject

proc callFieldImpl(obj, field, obj1: JsObject,
  args: varargs[JsObject]): JsObject {. importcpp: callImpl, discardable .}

proc `[]`*(obj: JsObject, field: cstring): JsObject {. importcpp: getImpl .}
  ## Return the value of a property of name `field` from a JsObject `obj`.

proc `[]=`*[T](obj: JsObject, field: cstring, val: T) {. importcpp: setImpl .}
  ## Set the value of a property of name `field` in a JsObject `obj` to `v`.

proc `[]`*[K, V](obj: JsAssoc[K, V], field: K): V {. importcpp: getImpl .}
  ## Return the value of a property of name `field` from a JsAssoc `obj`.

proc `[]`*[V](obj: JsAssoc[string, V], field: string): V
  {. importcpp: getImplJsString .}
  ## Return the value of a property of name `field` from a JsAssoc `obj`.

proc `[]=`*[K, V](obj: JsAssoc[K, V], field: K, val: V) {. importcpp: setImpl .}
  ## Set the value of a property of name `field` in a JsAssoc `obj` to `v`.

proc `[]=`*[V](obj: JsAssoc[string, V], field: string, val: V)
  {. importcpp: setImplJsString .}
  ## Set the value of a property of name `field` in a JsAssoc `obj` to `v`.

proc `==`*(x, y: JsRoot): bool {. importcpp: "(# === #)" .}
  ## Compare two JsObjects or JsAssocs. Be careful though, as this is comparison
  ## like in JavaScript, so if your JsObjects are in fact JavaScript Objects,
  ## and not strings or numbers, this is a *comparison of references*.

{. experimental .}
proc `.`*(obj: JsObject, field: cstring): JsObject {. importcpp: getImpl .}
  ## Experimental dot accessor (get) for type JsObject.
  ## Returns the value of a property of name `field` from a JsObject `x`.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##  let obj = newJsObject()
  ##  obj.a = 20
  ##  console.log(obj.a) # puts 20 onto the console.

proc `.=`*[T](obj: JsObject, field: cstring, value: T) {. importcpp: setImpl .}
  ## Experimental dot accessor (set) for type JsObject.
  ## Sets the value of a property of name `field` in a JsObject `x` to `value`.

template `.()`*(obj: JsObject, field: cstring,
    args: varargs[JsObject, toJs]): JsObject =
  ## Experimental "method call" operator for type JsObject.
  ## Takes the name of a method of the JavaScript object (`field`) and calls
  ## it with `args` as arguments, returning a JsObject (which may be discarded,
  ## and may be `undefined`, if the method does not return anything,
  ## so be careful when using this.)
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##  # Let's get back to the console example:
  ##  magicVar(console, JsObject)
  ##  let res = console.log("I return undefined!")
  ##  console.log(res) # This prints undefined, as console.log always returns
  ##                   # undefined. Thus one has to be careful, when using
  ##                   # JsObject calls.
  callFieldImpl(obj, field.cstring.toJs, obj, args)

proc `.`*[V](obj: JsAssoc[string, V], field: cstring): V
  {. importcpp: getImpl .}
  ## Experimental dot accessor (get) for type JsAssoc.
  ## Returns the value of a property of name `field` from a JsObject `x`.

proc `.=`*[V](obj: JsAssoc[string, V], field: cstring, value: V)
  {. importcpp: setImpl .}
  ## Experimental dot accessor (set) for type JsAssoc.
  ## Sets the value of a property of name `field` in a JsObject `x` to `value`.

macro `.()`*[K: string | cstring, V: proc](obj: JsAssoc[K, V], field: cstring,
  args: varargs[untyped]): auto =
  ## Experimental "method call" operator for type JsAssoc.
  ## Takes the name of a method of the JavaScript object (`field`) and calls
  ## it with `args` as arguments. Here, everything is typechecked, so you do not
  ## have to worry about `undefined` return values.
  result = quote do:
    let temp = `obj`[`field`]
    temp()
  for elem in args:
    result[1].add elem

# Iterators:

iterator pairs*(obj: JsObject): (cstring, JsObject) =
  ## Yields tuples of type ``(cstring, JsObject)``, with the first entry
  ## being the `name` of a fields in the JsObject and the second being its
  ## value wrapped into a JsObject.
  var k: cstring
  var v: JsObject
  {.emit: "for (var `k` in `obj`) {".}
  {.emit: "  if (!`obj`.hasOwnProperty(`k`)) continue;".}
  {.emit: "  `v`=`obj`[`k`];".}
  yield (k, v)
  {.emit: "}".}

iterator items*(obj: JsObject): JsObject =
  ## Yields the `values` of each field in a JsObject, wrapped into a JsObject.
  var v: JsObject
  {.emit: "for (var k in `obj`) {".}
  {.emit: "  if (!`obj`.hasOwnProperty(k)) continue;".}
  {.emit: "  `v`=`obj`[k];".}
  yield v
  {.emit: "}".}

iterator keys*(obj: JsObject): cstring =
  ## Yields the `names` of each field in a JsObject.
  var k: cstring
  {.emit: "for (var `k` in `obj`) {".}
  {.emit: "  if (!`obj`.hasOwnProperty(`k`)) continue;".}
  yield k
  {.emit: "}".}

iterator pairs*[K, V](assoc: JsAssoc[K, V]): (K,V) =
  ## Yields tuples of type ``(K, V)``, with the first entry
  ## being a `key` in the JsAssoc and the second being its corresponding value.
  when K is string:
    var k: cstring
  else:
    var k: K
  var v: V
  {.emit: "for (var `k` in `assoc`) {".}
  {.emit: "  if (!`assoc`.hasOwnProperty(`k`)) continue;".}
  {.emit: "  `v`=`assoc`[`k`];".}
  when K is string:
    yield ($k, v)
  else:
    yield (k, v)
  {.emit: "}".}

iterator items*[K,V](assoc: JSAssoc[K,V]): V =
  ## Yields the `values` in a JsAssoc.
  var v: V
  {.emit: "for (var k in `assoc`) {".}
  {.emit: "  if (!`assoc`.hasOwnProperty(k)) continue;".}
  {.emit: "  `v`=`assoc`[k];".}
  yield v
  {.emit: "}".}

iterator keys*[K,V](assoc: JSAssoc[K,V]): K =
  ## Yields the `keys` in a JsAssoc.
  when K is string:
    var k: cstring
  else:
    var k: K
  {.emit: "for (var `k` in `assoc`) {".}
  {.emit: "  if (!`assoc`.hasOwnProperty(`k`)) continue;".}
  when K is string:
    yield $k
  else:
    yield k
  {.emit: "}".}

# Literal generation

macro lit*(typ: typedesc, xs: untyped = []): auto =
  ## Takes a ``typedesc`` as its first argument, and a series of expressions of
  ## type ``key = value`` in brackets `[]` or in a `do`-statement as its second
  ## argument, and returns a value of the specified type with each field ``key``
  ## set to ``value``, as specified in the arguments of ``lit``.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##  # Let's say we have a type with a ton of fields, where some fields do not
  ##  # need to be set, and we do not want those fields to be set to ``nil``:
  ##  type
  ##    ExtremelyHugeType = ref object
  ##      a, b, c, d, e, f, g: int
  ##      h, i, j, k, l: cstring
  ##      # And even more fields ...
  ##
  ##  let obj = ExtremelyHugeType.lit([a = 1, k = "foo".cstring, d = 42])
  ##
  ##  # alternatively:
  ##  let obj = ExtremelyHugeType.lit do:
  ##    a = 1
  ##    k = "foo".cstring
  ##    d = 42
  ##
  ##  # This generates roughly the same JavaScript as:
  ##  {. emit: "var obj = {a: 1, k: "foo", d: 42};" .}
  ##
  var
    newXs: NimNode
    expectedKind: NimNodeKind
  case xs.kind
  of nnkBracket:
    newXs = xs
    expectedKind = nnkExprEqExpr
  of nnkDo:
    newXs = xs[6]
    expectedKind = nnkAsgn
  else:
    error("Invalid argument `" & $xs.toStrLit & "`.")
  let a = !"a"
  var body = quote do:
    var `a` {.noinit.}: `typ`
    {.emit: "`a` = {};".}
  for x in newXs.children:
    if x.kind == expectedKind:
      let
        k = x[0]
        kString = quote do:
          when compiles($`k`): $`k` else: "invalid"
        v = x[1]
      body.add(quote do:
        when compiles(`a`.`k`):
          `a`.`k` = `v`
        elif compiles(`a`[`k`]):
          `a`[`k`] = `v`
        else:
          `a`[`kString`] = `v`
      )
    else:
      error("Expression `" & $x.toStrLit & "` not allowed in `lit` macro")

  body.add(quote do:
    return `a`
  )

  result = quote do:
    proc inner(): `typ` {.gensym.} =
      `body`
    inner()

# Macro to build a lambda using JavaScript's `this`
# from a proc, `this` being the first argument.

macro bindMethod*(procedure: typed): auto =
  ## Takes the name of a procedure and wraps it into a lambda missing the first
  ## argument, which passes the JavaScript builtin ``this`` as the first
  ## argument to the procedure. Returns the resulting lambda.
  ##
  ## Example:
  ##
  ## We want to generate roughly this JavaScript:
  ##
  ## .. code-block:: js
  ##  var obj = {a: 10};
  ##  obj.someMethod = function() {
  ##    return this.a + 42;
  ##  };
  ##
  ## We can achieve this using the ``bindMethod`` macro:
  ##
  ## .. code-block:: nim
  ##  let obj = JsObject.lit(a = 10)
  ##  proc someMethodImpl(that: JsObject): int =
  ##    that.a.to(int) + 42
  ##  obj.someMethod = bindMethod someMethodImpl
  ##
  ##  # Alternatively:
  ##  obj.someMethod = bindMethod
  ##    proc(that; JsObject): int = that.a.to(int) + 42
  if not (procedure.kind == nnkSym or procedure.kind == nnkLambda):
    error("Argument has to be a proc or a symbol corresponding to a proc.")
  var
    rawProc = if procedure.kind == nnkSym:
        getImpl(procedure.symbol)
      else:
        procedure
    args = rawProc[3]
    thisType = args[1][1]
    params = newNimNode(nnkFormalParams).add(args[0])
    body = newNimNode(nnkLambda)
    this = newIdentNode("this")
    # construct the `this` parameter:
    thisQuote = quote do:
      var `this` {. nodecl, importc .} : `thisType`
    call = newNimNode(nnkCall).add(rawProc[0], thisQuote[0][0][0][0])
  # construct the procedure call inside the method
  if args.len > 2:
    for idx in 2..args.len-1:
      params.add(args[idx])
      call.add(args[idx][0])
  body.add(newNimNode(nnkEmpty),
      rawProc[1],
      rawProc[2],
      params,
      rawProc[4],
      rawProc[5],
      newTree(nnkStmtList, thisQuote[0], call)
  )
  result = body
