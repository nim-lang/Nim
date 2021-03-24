import std/[macros, isolation]
import system/ansi_c

export isolation

#
# proc hello(a: int, b: string) =
#   echo $a & b
#
# let literal = "Nim"
# let t = toTask(hello(521, literal))
#
#
# is roughly converted to
#
# type
#   ScratchObj_369098780 = object
#     a: int
#     b: string
#
# let scratch_369098762 = cast[ptr ScratchObj_369098780](c_calloc(csize_t 1,
#     csize_t sizeof(ScratchObj_369098780)))
# if scratch_369098762.isNil:
#   raise newException(OutOfMemDefect, "Could not allocate memory")
# block:
#   var isolate_369098776 = isolate(521)
#   scratch_369098762.a = extract(isolate_369098776)
#   var isolate_369098778 = isolate(literal)
#   scratch_369098762.b = extract(isolate_369098778)
# proc hello_369098781(args`gensym3: pointer) {.nimcall.} =
#   let obj_369098775 = cast[ptr ScratchObj_369098780](args`gensym3)
#   let :tmp_369098777 = obj_369098775.a
#   let :tmp_369098779 = obj_369098775.b
#   hello(a = :tmp_369098777, b = :tmp_369098779)
#
# proc destroyScratch_369098782(args`gensym3: pointer) {.nimcall.} =
#   let obj_369098783 = cast[ptr ScratchObj_369098780](args`gensym3)
#   =destroy(obj_369098783[])
# let t = Task(callback: hello_369098781, args: scratch_369098762, destroy: destroyScratch_369098782)
#


type
  Task* = object ## `Task` contains the callback and its arguments.
    callback: proc (args: pointer) {.nimcall.}
    args: pointer
    destroy: proc (args: pointer) {.nimcall.}

proc `=destroy`*(t: var Task) =
  if t.args != nil:
    if t.destroy != nil:
      t.destroy(t.args)
    c_free(t.args)

proc invoke*(task: Task) {.inline.} =
  ## Invokes the `task`.
  task.callback(task.args)

macro toTask*(e: typed{nkCall | nkCommand}): Task =
  ## Converts the call and its arguments to `Task`.
  runnableExamples("--gc:orc"):
    proc hello(a: int) = echo a

    let b = toTask hello(13)
    assert b is Task

  template addAllNode =
    let scratchDotExpr = newDotExpr(scratchIdent, formalParams[i][0])

    
    let isolatedTemp = genSym(nskTemp, "isolate")
    scratchAssignList.add newVarStmt(isolatedTemp, newCall(newidentNode("isolate"), e[i]))
    scratchAssignList.add newAssignment(scratchDotExpr,
        newcall(newIdentNode("extract"), isolatedTemp))

    let tempNode = genSym(kind = nskTemp, ident = "")
    callNode.add nnkExprEqExpr.newTree(formalParams[i][0], tempNode)
    tempAssignList.add newLetStmt(tempNode, newDotExpr(objTemp, formalParams[i][0]))

  doAssert getTypeInst(e).typeKind == ntyVoid

  if e.len > 1:
    let scratchIdent = genSym(kind = nskTemp, ident = "scratch")
    let impl = e[0].getTypeInst

    when defined(nimTasksDebug):
      echo impl.treeRepr
      echo e.treeRepr
    let formalParams = impl[0]

    var
      scratchRecList = newNimNode(nnkRecList)
      scratchAssignList: seq[NimNode]
      tempAssignList: seq[NimNode]
      callNode: seq[NimNode]

    let
      objTemp = genSym(ident = "obj")

    for i in 1 ..< formalParams.len:
      let param = formalParams[i][1]

      case param.kind
      of nnkVarTy:
        error("'toTask'ed function cannot have a 'var' parameter")
      of nnkBracketExpr:
        if param[0].eqIdent("sink"):
          scratchRecList.add newIdentDefs(newIdentNode(formalParams[i][0].strVal), param[1])
          addAllNode()
        elif param[0].eqIdent("typeDesc"):
          callNode.add nnkExprEqExpr.newTree(formalParams[i][0], e[i])
        elif param[0].eqIdent("varargs") or param[0].eqIdent("openArray"):
          let
            seqType = nnkBracketExpr.newTree(newIdentNode("seq"), param[1])
            scratchDotExpr = newDotExpr(scratchIdent, formalParams[i][0])
            seqCallNode = newcall("@", e[i])

          # scratchAssignList.add newAssignment(scratchDotExpr, seqCallNode)

          let isolatedTemp = genSym(nskTemp, "isolate")
          scratchAssignList.add newVarStmt(isolatedTemp, newCall(newidentNode("isolate"), seqCallNode))
          scratchAssignList.add newAssignment(scratchDotExpr,
              newcall(newIdentNode("extract"), isolatedTemp))

          let tempNode = genSym(kind = nskTemp)
          callNode.add nnkExprEqExpr.newTree(formalParams[i][0], tempNode)
          tempAssignList.add newLetStmt(tempNode, newDotExpr(objTemp, formalParams[i][0]))
          scratchRecList.add newIdentDefs(newIdentNode(formalParams[i][0].strVal), seqType)
        else:
          scratchRecList.add newIdentDefs(newIdentNode(formalParams[i][0].strVal), param)
          addAllNode()
      of nnkBracket, nnkObjConstr:
        # passing by static parameters
        # so we pass them directly instead of passing by scratchObj
        callNode.add nnkExprEqExpr.newTree(formalParams[i][0], e[i])
      of nnkSym, nnkPtrTy:
        scratchRecList.add newIdentDefs(newIdentNode(formalParams[i][0].strVal), param)
        addAllNode()
      of nnkCharLit..nnkNilLit:
        callNode.add nnkExprEqExpr.newTree(formalParams[i][0], e[i])
      else:
        error("not supported type kinds")

    let stmtList = newStmtList()
    let scratchObjType = genSym(kind = nskType, ident = "ScratchObj")
    let scratchObj = nnkTypeSection.newTree(
                      nnkTypeDef.newTree(
                        scratchObjType,
                        newEmptyNode(),
                        nnkObjectTy.newTree(
                          newEmptyNode(),
                          newEmptyNode(),
                          scratchRecList
                        )
                      )
                    )


    let scratchObjPtrType = quote do:
      cast[ptr `scratchObjType`](c_calloc(csize_t 1, csize_t sizeof(`scratchObjType`)))

    let scratchLetSection = newLetStmt(
      scratchIdent,
      scratchObjPtrType
    )

    let scratchCheck = quote do:
      if `scratchIdent`.isNil:
        raise newException(OutOfMemDefect, "Could not allocate memory")

    stmtList.add(scratchObj)
    stmtList.add(scratchLetSection)
    stmtList.add(scratchCheck)
    stmtList.add(nnkBlockStmt.newTree(newEmptyNode(), newStmtList(scratchAssignList)))

    var functionStmtList = newStmtList()
    let funcCall = newCall(e[0], callNode)
    functionStmtList.add tempAssignList
    functionStmtList.add funcCall

    let funcName = genSym(nskProc, e[0].strVal)

    let destroyName = genSym(nskProc, "destroyScratch")

    let objTemp2 = genSym(ident = "obj")
    let tempNode = quote("@") do:
        `=destroy`(@objTemp2[])

    result = quote do:
      `stmtList`

      proc `funcName`(args: pointer) {.nimcall.} =
        let `objTemp` = cast[ptr `scratchObjType`](args)
        `functionStmtList`

      proc `destroyName`(args: pointer) {.nimcall.} =
        let `objTemp2` = cast[ptr `scratchObjType`](args)
        `tempNode`

      Task(callback: `funcName`, args: `scratchIdent`, destroy: `destroyName`)
  else:
    let funcCall = newCall(e[0])
    let funcName = genSym(nskProc, e[0].strVal)

    result = quote do:
      proc `funcName`(args: pointer) {.nimcall.} =
        `funcCall`

      Task(callback: `funcName`, args: nil)

  when defined(nimTasksDebug):
    echo result.repr

runnableExamples("--gc:orc"):
  var num = 0
  proc hello(a: int) = inc num, a

  let b = toTask hello(13)
  b.invoke()

  assert num == 13
