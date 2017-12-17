#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim Authors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.

## This Module implements types and macros for writing asynchronous code
## for the JS backend. It provides tools for interaction with JavaScript async API-s 
## and libraries, writing async procedures in Nim and converting callback-based code
## to promises.
##
## The pragma `{.async.}` means a procedure is asynchronous. Such a procedure
## should always have a `Future[T]` return type or not have a return type at all.
## A `Future[void]` return type is assumed by default.
## 
## This is roughly equivalent to the `async` keyword in the generated JavaScript code.
## 
## ..code-block:: nim
##  proc loadGame(name: string): Future[Game] {.async.} =
##    ..
## 
## should be equivalent to
## 
## ..code-block:: javascript
##   async function loadGame(name) {
##     ..
##   }
## 
## A call to an asynchronous procedure usually needs `await` to wait for
## the completion of the `Future`.
## 
## ..code-block:: nim
##   var game = await loadGame(name)
## 
## Often, you might work with callback-based API-s. You can wrap them with
## asynchronous procedures using promises and `newPromise`:
## 
## ..code-block:: nim
##   proc loadGame(name: string): Future[Game] =
##     var promise = newPromise() do (resolve: proc(response: Game)):
##       cbBasedLoadGame(name) do (game: Game):
##         resolve(game)
##   return promise
##
## Forward definitions work properly, you just don't need to add the `{.async.}` pragma:
## 
## ..code-block:: nim
##   proc loadGame(name: string): Future[Game]
## 

import jsffi
import macros

when not defined(js):
  {.error "asyncjs is only available for javascript"}

type
  Future*[T] = ref object
    future*: T

  PromiseJs* {.importcpp: "Promise".} = ref object

proc replaceReturn(node: var NimNode) =
  var z = 0
  for s in node:
    var son = node[z]
    if son.kind == nnkReturnStmt:
      node[z] = nnkReturnStmt.newTree(nnkCall.newTree(ident("jsResolve"), son[0]))
    elif son.kind == nnkAsgn and son[0].kind == nnkIdent and $son[0] == "result":
      node[z] = nnkAsgn.newTree(son[0], nnkCall.newTree(ident("jsResolve"), son[1]))
    else:
      replaceReturn(son)
    inc z

proc generateJsasync(arg: NimNode): NimNode =
  assert arg.kind == nnkProcDef
  result = arg
  if arg.params[0].kind == nnkEmpty:
    result.params[0] = nnkBracketExpr.newTree(ident("Future"), ident("void"))
  var code = result.body
  replaceReturn(code)
  result.body = nnkStmtList.newTree()
  var q = quote:
    proc await[T](f: Future[T]): T {.importcpp: "(await #)".}
    proc jsResolve[T](a: T): Future[T] {.importcpp: "#".}
  result.body.add(q)
  for child in code:
    result.body.add(child)
  result.pragma = quote:
    {.codegenDecl: "async function $2($3)".}

macro async*(arg: untyped): untyped =
  ## Macro which converts normal procedures into
  ## javascript-compatible async procedures
  generateJsasync(arg)

proc newPromise*[T](handler: proc(resolve: proc(response: T))): Future[T] {.importcpp: "(new Promise(#))".}
  ## A helper for wrapping callback-based functions
  ## into promises and async procedures
