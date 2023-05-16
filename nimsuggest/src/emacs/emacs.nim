## Everything required for the nimsuggest emacs intergration.
import compiler/renderer
import strutils, os, net
import sequtils
import times

import ../setup
import ../execution
import ../communication
import ../utils
import ../types
import sexp
import compiler/[options, msgs, sigmatch, ast, modulegraphs, prefixmatches, pathutils]

proc sexp(s: IdeCmd|TSymKind|PrefixMatch): SexpNode = sexp($s)

proc sexp(s: Suggest): SexpNode =
  # If you change the order here, make sure to change it over in
  # nim-mode.el too.
  let qp = if s.qualifiedPath.len == 0: @[] else: s.qualifiedPath
  result = convertSexp([
    s.section,
    TSymKind s.symkind,
    qp.map(newSString),
    s.filePath,
    s.forth,
    s.line,
    s.column,
    s.doc,
    s.quality
  ])
  if s.section == ideSug:
    result.add convertSexp(s.prefix)
  if s.section in {ideOutline, ideExpand} and s.version == 3:
    result.add convertSexp(s.endLine.int)
    result.add convertSexp(s.endCol)

proc sexp(s: seq[Suggest]): SexpNode =
  result = newSList()
  for sug in s:
    result.add(sexp(sug))

proc listEpc*(): SexpNode =
  # This function is called from Emacs to show available options.
  let
    argspecs = sexp("file line column dirtyfile".split(" ").map(newSSymbol))
    docstring = sexp("line starts at 1, column at 0, dirtyfile is optional")
  result = newSList()
  for command in ["sug", "con", "def", "use", "dus", "chk", "mod", "globalSymbols", "recompile", "saved", "chkFile", "declaration"]:
    let
      cmd = sexp(command)
      methodDesc = newSList()
    methodDesc.add(cmd)
    methodDesc.add(argspecs)
    methodDesc.add(docstring)
    result.add(methodDesc)

proc argsToStr(x: SexpNode): string =
  if x.kind != SList: return x.getStr
  doAssert x.kind == SList
  doAssert x.len >= 4
  let file = x[0].getStr
  let line = x[1].getNum
  let col = x[2].getNum
  let dirty = x[3].getStr
  result = x[0].getStr.escape
  if dirty.len > 0:
    result.add ';'
    result.add dirty.escape
  result.add ':'
  result.addInt line
  result.add ':'
  result.addInt col

proc returnEpc(socket: Socket, uid: BiggestInt, s: SexpNode|string,
               returnSymbol = "return") =
  let response = $convertSexp([newSSymbol(returnSymbol), uid, s])
  socket.send(toHex(len(response), 6))
  socket.send(response)

proc toEpc(client: Socket; uid: BiggestInt) {.gcsafe.} =
  var list = newSList()
  while true:
    let res = results.recv()
    case res.section
    of ideNone: break
    of ideMsg:
      list.add sexp(res.doc)
    of ideKnown:
      list.add sexp(res.quality == 1)
    of ideProject:
      list.add sexp(res.filePath)
    else:
      list.add sexp(res)
  returnEpc(client, uid, list)

proc replEpc*(x: ThreadParams) {.thread.} =
  var server = newSocket()
  let port = connectToNextFreePort(server, "localhost")
  server.listen()
  echo port
  stdout.flushFile()

  var client: Socket
  # Wait for connection
  accept(server, client)
  while true:
    var
      sizeHex = ""
      size = 0
      messageBuffer = ""
    checkSanity(client, sizeHex, size, messageBuffer)
    let
      message = parseSexp($messageBuffer)
      epcApi = message[0].getSymbol
    case epcApi
    of "call":
      let
        uid = message[1].getNum
        cmd = message[2].getSymbol
        args = message[3]

      when false:
        x.ideCmd[] = parseIdeCmd(message[2].getSymbol)
        case x.ideCmd[]
        of ideSug, ideCon, ideDef, ideUse, ideDus, ideOutline, ideHighlight:
          setVerbosity(0)
        else: discard
      let fullCmd = cmd & " " & args.argsToStr
      myLog "MSG CMD: " & fullCmd
      requests.send(fullCmd)
      toEpc(client, uid)
    of "methods":
      returnEpc(client, message[1].getNum, listEpc())
    of "epc-error":
      # an unhandled exception forces down the whole process anyway, so we
      # use 'quit' here instead of 'raise'
      quit("received epc error: " & $messageBuffer)
    else:
      let errMessage = case epcApi
                       of "return", "return-error":
                         "no return expected"
                       else:
                         "unexpected call: " & epcApi
      quit errMessage


proc executeEpc(ideCmd: IdeCmd, args: SexpNode, graph: ModuleGraph) =
  var dirtyfile = AbsoluteFile""
  if len(args) > 3:
    dirtyfile = AbsoluteFile args[3].getStr("")

  let cmd= CommandData( 
      ideCmd:ideCmd,
      file:AbsoluteFile args[0].getStr,
      dirtyFile:dirtyfile,
      line: int(args[1].getNum),
      col:  int(args[2].getNum),
      tag: args[3].getStr
      )
  execute(cmd, graph)
