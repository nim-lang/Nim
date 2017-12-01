import jsffi
import macros

when not defined(js):
  {.error "asyncjs is only available for javascript"}


type
  Future*[T] = ref object
    future*: T

  PromiseJs* {.importcpp: "Promise".} = ref object

proc generateJsasync(arg: NimNode): NimNode

macro async*(arg: untyped): untyped =
  generateJsasync(arg)

proc newPromise*[T](handler: proc(resolve: proc(response: T))): Future[T] {.importcpp: "(new Promise(#))".}

## can convert cb to async
## proc a*: Future[bool] =
##   var promise = newPromise() do (resolve: proc(response: bool)):
##     call() do (r: cstring):
##       resolve(len($r) > 0)
##   return promise

proc jsResolve*[T](a: T): Future[T] {.importcpp: "#".}

proc `$`*[T](future: Future[T]): string =
  result = "Future"

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
  result.body.add(q)
  for child in code:
    result.body.add(child)
  result.pragma = quote:
    {.codegenDecl: "async function $2($3)".}
  # echo repr(result)
