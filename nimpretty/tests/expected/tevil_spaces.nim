if true:
  echo 7

type
  TCallingConvention* = enum # \
    # asdfkljsdlf
    #
    ccDefault,               # proc has no explicit calling convention
    ccStdCall,               # procedure is stdcall
    ccCDecl,                 # cdecl
    ccSafeCall,              # safecall
    ccSysCall,               # system call
    ccInline,                # proc should be inlined
    ccNoInline,              # proc should not be inlined
                             #
                             # continuing here
    ccFastCall,              # fastcall (pass parameters in registers)
    ccClosure,               # proc has a closure
    ccNoConvention           # needed for generating proper C procs sometimes

# asyncmacro.nim:260
# asfkjaflk jkldas
proc asyncSingleProc(prc: NimNode): NimNode {.compileTime.} =
  ## Doc comment here.
  # Now an ordinary comment.
  outerProcBody.add(
    newVarStmt(retFutureSym,
      newCall(
        newNimNode(nnkBracketExpr, prc.body).add(
          newIdentNode("newFuture"),
          subRetType),
      newLit(prcName)))) # Get type from return type of this proc

  # -> iterator nameIter(): FutureBase {.closure.} =
  # ->   {.push warning[resultshadowed]: off.}
  # ->   var result: T
  # ->   {.pop.}
  # ->   <proc_body>
  # ->   complete(retFuture, result)
  var iteratorNameSym = genSym(nskIterator, $prcName & "Iter")
  var procBody = prc.body.processBody(retFutureSym, subtypeIsVoid,
                                    futureVarIdents)
  if tue:
    foo() # comment here
  # end if

proc distribute*[T](s: seq[T], num: Positive, spread = true): seq[seq[T]] =
  ## Splits and distributes a sequence `s` into `num` sub-sequences.
  let num = int(num) # XXX probably only needed because of .. bug
                     # This is part of the above.
  result = newSeq[seq[T]](num)

proc distribute*[T](s: seq[T], num: Positive, spread = true): seq[seq[T]] =
  ## Splits and distributes a sequence `s` into `num` sub-sequences.
  let num = int(num) # XXX probably only needed because of .. bug

  # This belongs below.
  result = newSeq[seq[T]](num)
