#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(nodejs):
  proc alert*(s: cstring) {.importc: "console.log", nodecl.}
else:
  proc alert*(s: cstring) {.importc, nodecl.}

proc log*(s: cstring) {.importc: "console.log", nodecl.}

type
  PSafePoint = ptr TSafePoint
  TSafePoint {.compilerproc, final.} = object
    prev: PSafePoint # points to next safe point
    exc: ref E_Base

  PCallFrame = ptr TCallFrame
  TCallFrame {.importc, nodecl, final.} = object
    prev: PCallFrame
    procname: CString
    line: int # current line number
    filename: CString

var
  framePtr {.importc, nodecl, volatile.}: PCallFrame
  excHandler {.importc, nodecl, volatile.}: PSafePoint = nil
    # list of exception handlers
    # a global variable for the root of all try blocks

{.push stacktrace: off, profiler:off.}
proc nimBoolToStr(x: bool): string {.compilerproc.} =
  if x: result = "true"
  else: result = "false"

proc nimCharToStr(x: char): string {.compilerproc.} =
  result = newString(1)
  result[0] = x

proc getCurrentExceptionMsg*(): string =
  if excHandler != nil: return $excHandler.exc.msg
  return ""

proc auxWriteStackTrace(f: PCallFrame): string =
  type
    TTempFrame = tuple[procname: CString, line: int]
  var
    it = f
    i = 0
    total = 0
    tempFrames: array [0..63, TTempFrame]
  while it != nil and i <= high(tempFrames):
    tempFrames[i].procname = it.procname
    tempFrames[i].line = it.line
    inc(i)
    inc(total)
    it = it.prev
  while it != nil:
    inc(total)
    it = it.prev
  result = ""
  # if the buffer overflowed print '...':
  if total != i:
    add(result, "(")
    add(result, $(total-i))
    add(result, " calls omitted) ...\n")
  for j in countdown(i-1, 0):
    add(result, tempFrames[j].procname)
    if tempFrames[j].line > 0:
      add(result, ", line: ")
      add(result, $tempFrames[j].line)
    add(result, "\n")

proc rawWriteStackTrace(): string =
  if framePtr == nil:
    result = "No stack traceback available\n"
  else:
    result = "Traceback (most recent call last)\n"& auxWriteStackTrace(framePtr)
    framePtr = nil

proc raiseException(e: ref E_Base, ename: cstring) {.
    compilerproc, noStackFrame.} =
  e.name = ename
  if excHandler != nil:
    excHandler.exc = e
  else:
    when nimrodStackTrace:
      var buf = rawWriteStackTrace()
    else:
      var buf = ""
    if e.msg != nil and e.msg[0] != '\0':
      add(buf, "Error: unhandled exception: ")
      add(buf, e.msg)
    else:
      add(buf, "Error: unhandled exception")
    add(buf, " [")
    add(buf, ename)
    add(buf, "]\n")
    alert(buf)
  asm """throw `e`;"""

proc reraiseException() {.compilerproc, noStackFrame.} =
  if excHandler == nil:
    raise newException(ENoExceptionToReraise, "no exception to reraise")
  else:
    asm """throw excHandler.exc;"""

proc raiseOverflow {.exportc: "raiseOverflow", noreturn.} =
  raise newException(EOverflow, "over- or underflow")

proc raiseDivByZero {.exportc: "raiseDivByZero", noreturn.} =
  raise newException(EDivByZero, "divison by zero")

proc raiseRangeError() {.compilerproc, noreturn.} =
  raise newException(EOutOfRange, "value out of range")

proc raiseIndexError() {.compilerproc, noreturn.} =
  raise newException(EInvalidIndex, "index out of bounds")

proc raiseFieldError(f: string) {.compilerproc, noreturn.} =
  raise newException(EInvalidField, f & " is not accessible")

proc SetConstr() {.varargs, noStackFrame, compilerproc.} =
  asm """
    var result = {};
    for (var i = 0; i < arguments.length; ++i) {
      var x = arguments[i];
      if (typeof(x) == "object") {
        for (var j = x[0]; j <= x[1]; ++j) {
          result[j] = true;
        }
      } else {
        result[x] = true;
      }
    }
    return result;
  """

proc cstrToNimstr(c: cstring): string {.noStackFrame, compilerproc.} =
  asm """
    var result = [];
    for (var i = 0; i < `c`.length; ++i) {
      result[i] = `c`.charCodeAt(i);
    }
    result[result.length] = 0; // terminating zero
    return result;
  """

proc toJSStr(s: string): cstring {.noStackFrame, compilerproc.} =
  asm """
    var len = `s`.length-1;
    var result = new Array(len);
    var fcc = String.fromCharCode;
    for (var i = 0; i < len; ++i) {
      result[i] = fcc(`s`[i]);
    }
    return result.join("");
  """

proc mnewString(len: int): string {.noStackFrame, compilerproc.} =
  asm """
    var result = new Array(`len`+1);
    result[0] = 0;
    result[`len`] = 0;
    return result;
  """

proc SetCard(a: int): int {.compilerproc, noStackFrame.} =
  # argument type is a fake
  asm """
    var result = 0;
    for (var elem in `a`) { ++result; }
    return result;
  """

proc SetEq(a, b: int): bool {.compilerproc, noStackFrame.} =
  asm """
    for (var elem in `a`) { if (!`b`[elem]) return false; }
    for (var elem in `b`) { if (!`a`[elem]) return false; }
    return true;
  """

proc SetLe(a, b: int): bool {.compilerproc, noStackFrame.} =
  asm """
    for (var elem in `a`) { if (!`b`[elem]) return false; }
    return true;
  """

proc SetLt(a, b: int): bool {.compilerproc.} =
  result = SetLe(a, b) and not SetEq(a, b)

proc SetMul(a, b: int): int {.compilerproc, noStackFrame.} =
  asm """
    var result = {};
    for (var elem in `a`) {
      if (`b`[elem]) { result[elem] = true; }
    }
    return result;
  """

proc SetPlus(a, b: int): int {.compilerproc, noStackFrame.} =
  asm """
    var result = {};
    for (var elem in `a`) { result[elem] = true; }
    for (var elem in `b`) { result[elem] = true; }
    return result;
  """

proc SetMinus(a, b: int): int {.compilerproc, noStackFrame.} =
  asm """
    var result = {};
    for (var elem in `a`) {
      if (!`b`[elem]) { result[elem] = true; }
    }
    return result;
  """

proc cmpStrings(a, b: string): int {.noStackFrame, compilerProc.} =
  asm """
    if (`a` == `b`) return 0;
    if (!`a`) return -1;
    if (!`b`) return 1;
    for (var i = 0; i < `a`.length-1; ++i) {
      var result = `a`[i] - `b`[i];
      if (result != 0) return result;
    }
    return 0;
  """

proc cmp(x, y: string): int = return cmpStrings(x, y)

proc eqStrings(a, b: string): bool {.noStackFrame, compilerProc.} =
  asm """
    if (`a` == `b`) return true;
    if ((!`a`) || (!`b`)) return false;
    var alen = `a`.length;
    if (alen != `b`.length) return false;
    for (var i = 0; i < alen; ++i)
      if (`a`[i] != `b`[i]) return false;
    return true;
  """

type
  TDocument {.importc.} = object of TObject
    write: proc (text: cstring) {.nimcall.}
    writeln: proc (text: cstring) {.nimcall.}
    createAttribute: proc (identifier: cstring): ref TNode {.nimcall.}
    createElement: proc (identifier: cstring): ref TNode {.nimcall.}
    createTextNode: proc (identifier: cstring): ref TNode {.nimcall.}
    getElementById: proc (id: cstring): ref TNode {.nimcall.}
    getElementsByName: proc (name: cstring): seq[ref TNode] {.nimcall.}
    getElementsByTagName: proc (name: cstring): seq[ref TNode] {.nimcall.}

  TNodeType* = enum
    ElementNode = 1,
    AttributeNode,
    TextNode,
    CDATANode,
    EntityRefNode,
    EntityNode,
    ProcessingInstructionNode,
    CommentNode,
    DocumentNode,
    DocumentTypeNode,
    DocumentFragmentNode,
    NotationNode
  TNode* {.importc.} = object of TObject
    attributes*: seq[ref TNode]
    childNodes*: seq[ref TNode]
    data*: cstring
    firstChild*: ref TNode
    lastChild*: ref TNode
    nextSibling*: ref TNode
    nodeName*: cstring
    nodeType*: TNodeType
    nodeValue*: cstring
    parentNode*: ref TNode
    previousSibling*: ref TNode
    appendChild*: proc (child: ref TNode) {.nimcall.}
    appendData*: proc (data: cstring) {.nimcall.}
    cloneNode*: proc (copyContent: bool) {.nimcall.}
    deleteData*: proc (start, len: int) {.nimcall.}
    getAttribute*: proc (attr: cstring): cstring {.nimcall.}
    getAttributeNode*: proc (attr: cstring): ref TNode {.nimcall.}
    getElementsByTagName*: proc (): seq[ref TNode] {.nimcall.}
    hasChildNodes*: proc (): bool {.nimcall.}
    insertBefore*: proc (newNode, before: ref TNode) {.nimcall.}
    insertData*: proc (position: int, data: cstring) {.nimcall.}
    removeAttribute*: proc (attr: cstring) {.nimcall.}
    removeAttributeNode*: proc (attr: ref TNode) {.nimcall.}
    removeChild*: proc (child: ref TNode) {.nimcall.}
    replaceChild*: proc (newNode, oldNode: ref TNode) {.nimcall.}
    replaceData*: proc (start, len: int, text: cstring) {.nimcall.}
    setAttribute*: proc (name, value: cstring) {.nimcall.}
    setAttributeNode*: proc (attr: ref TNode) {.nimcall.}

when defined(kwin):
  proc rawEcho {.compilerproc, nostackframe.} =
    asm """
      var buf = "";
      for (var i = 0; i < arguments.length; ++i) {
        buf += `toJSStr`(arguments[i]);
      }
      print(buf);
    """
    
elif defined(nodejs):
  proc ewriteln(x: cstring) = log(x)
  
  proc rawEcho {.compilerproc, nostackframe.} =
    asm """
      var buf = "";
      for (var i = 0; i < arguments.length; ++i) {
        buf += `toJSStr`(arguments[i]);
      }
      console.log(buf);
    """

else:
  var
    document {.importc, nodecl.}: ref TDocument

  proc ewriteln(x: cstring) = 
    var node = document.getElementsByTagName("body")[0]
    if node != nil: 
      node.appendChild(document.createTextNode(x))
      node.appendChild(document.createElement("br"))
    else: 
      raise newException(EInvalidValue, "<body> element does not exist yet!")

  proc rawEcho {.compilerproc.} =
    var node = document.getElementsByTagName("body")[0]
    if node == nil: raise newException(EIO, "<body> element does not exist yet!")
    asm """
      for (var i = 0; i < arguments.length; ++i) {
        var x = `toJSStr`(arguments[i]);
        `node`.appendChild(document.createTextNode(x))
      }
    """
    node.appendChild(document.createElement("br"))

# Arithmetic:
proc addInt(a, b: int): int {.noStackFrame, compilerproc.} =
  asm """
    var result = `a` + `b`;
    if (result > 2147483647 || result < -2147483648) `raiseOverflow`();
    return result;
  """

proc subInt(a, b: int): int {.noStackFrame, compilerproc.} =
  asm """
    var result = `a` - `b`;
    if (result > 2147483647 || result < -2147483648) `raiseOverflow`();
    return result;
  """

proc mulInt(a, b: int): int {.noStackFrame, compilerproc.} =
  asm """
    var result = `a` * `b`;
    if (result > 2147483647 || result < -2147483648) `raiseOverflow`();
    return result;
  """

proc divInt(a, b: int): int {.noStackFrame, compilerproc.} =
  asm """
    if (`b` == 0) `raiseDivByZero`();
    if (`b` == -1 && `a` == 2147483647) `raiseOverflow`();
    return Math.floor(`a` / `b`);
  """

proc modInt(a, b: int): int {.noStackFrame, compilerproc.} =
  asm """
    if (`b` == 0) `raiseDivByZero`();
    if (`b` == -1 && `a` == 2147483647) `raiseOverflow`();
    return Math.floor(`a` % `b`);
  """

proc addInt64(a, b: int): int {.noStackFrame, compilerproc.} =
  asm """
    var result = `a` + `b`;
    if (result > 9223372036854775807
    || result < -9223372036854775808) `raiseOverflow`();
    return result;
  """

proc subInt64(a, b: int): int {.noStackFrame, compilerproc.} =
  asm """
    var result = `a` - `b`;
    if (result > 9223372036854775807
    || result < -9223372036854775808) `raiseOverflow`();
    return result;
  """

proc mulInt64(a, b: int): int {.noStackFrame, compilerproc.} =
  asm """
    var result = `a` * `b`;
    if (result > 9223372036854775807
    || result < -9223372036854775808) `raiseOverflow`();
    return result;
  """

proc divInt64(a, b: int): int {.noStackFrame, compilerproc.} =
  asm """
    if (`b` == 0) `raiseDivByZero`();
    if (`b` == -1 && `a` == 9223372036854775807) `raiseOverflow`();
    return Math.floor(`a` / `b`);
  """

proc modInt64(a, b: int): int {.noStackFrame, compilerproc.} =
  asm """
    if (`b` == 0) `raiseDivByZero`();
    if (`b` == -1 && `a` == 9223372036854775807) `raiseOverflow`();
    return Math.floor(`a` % `b`);
  """

proc negInt(a: int): int {.compilerproc.} =
  result = a*(-1)

proc negInt64(a: int64): int64 {.compilerproc.} =
  result = a*(-1)

proc absInt(a: int): int {.compilerproc.} =
  result = if a < 0: a*(-1) else: a

proc absInt64(a: int64): int64 {.compilerproc.} =
  result = if a < 0: a*(-1) else: a

proc leU(a, b: int): bool {.compilerproc.} =
  result = abs(a) <= abs(b)

proc ltU(a, b: int): bool {.compilerproc.} =
  result = abs(a) < abs(b)

proc leU64(a, b: int64): bool {.compilerproc.} =
  result = abs(a) <= abs(b)
proc ltU64(a, b: int64): bool {.compilerproc.} =
  result = abs(a) < abs(b)

proc addU(a, b: int): int {.compilerproc.} =
  result = abs(a) + abs(b)
proc addU64(a, b: int64): int64 {.compilerproc.} =
  result = abs(a) + abs(b)

proc subU(a, b: int): int {.compilerproc.} =
  result = abs(a) - abs(b)
proc subU64(a, b: int64): int64 {.compilerproc.} =
  result = abs(a) - abs(b)

proc mulU(a, b: int): int {.compilerproc.} =
  result = abs(a) * abs(b)
proc mulU64(a, b: int64): int64 {.compilerproc.} =
  result = abs(a) * abs(b)

proc divU(a, b: int): int {.compilerproc.} =
  result = abs(a) div abs(b)
proc divU64(a, b: int64): int64 {.compilerproc.} =
  result = abs(a) div abs(b)

proc modU(a, b: int): int {.compilerproc.} =
  result = abs(a) mod abs(b)
proc modU64(a, b: int64): int64 {.compilerproc.} =
  result = abs(a) mod abs(b)

proc ze*(a: int): int {.compilerproc.} =
  result = a

proc ze64*(a: int64): int64 {.compilerproc.} =
  result = a

proc toU8*(a: int): int8 {.noStackFrame, compilerproc.} =
  asm """
    return `a`;
  """

proc toU16*(a: int): int16 {.noStackFrame, compilerproc.} =
  asm """
    return `a`;
  """

proc toU32*(a: int64): int32 {.noStackFrame, compilerproc.} =
  asm """
    return `a`;
  """

proc nimMin(a, b: int): int {.compilerproc.} = return if a <= b: a else: b
proc nimMax(a, b: int): int {.compilerproc.} = return if a >= b: a else: b

type NimString = string # hack for hti.nim
include "system/hti"

proc isFatPointer(ti: PNimType): bool =
  # This has to be consistent with the code generator!
  return ti.base.kind notin {tyObject,
    tyArray, tyArrayConstr, tyTuple,
    tyOpenArray, tySet, tyVar, tyRef, tyPtr}

proc nimCopy(x: pointer, ti: PNimType): pointer {.compilerproc.}

proc nimCopyAux(dest, src: Pointer, n: ptr TNimNode) {.compilerproc.} =
  case n.kind
  of nkNone: sysAssert(false, "NimCopyAux")
  of nkSlot:
    asm "`dest`[`n`.offset] = NimCopy(`src`[`n`.offset], `n`.typ);"
  of nkList:
    for i in 0..n.len-1:
      NimCopyAux(dest, src, n.sons[i])
  of nkCase:
    asm """
      `dest`[`n`.offset] = NimCopy(`src`[`n`.offset], `n`.typ);
      for (var i = 0; i < `n`.sons.length; ++i) {
        NimCopyAux(`dest`, `src`, `n`.sons[i][1]);
      }
    """

proc nimCopy(x: pointer, ti: PNimType): pointer =
  case ti.kind
  of tyPtr, tyRef, tyVar, tyNil:
    if not isFatPointer(ti):
      result = x
    else:
      asm """
        `result` = [null, 0];
        `result`[0] = `x`[0];
        `result`[1] = `x`[1];
      """
  of tySet:
    asm """
      `result` = {};
      for (var key in `x`) { `result`[key] = `x`[key]; }
    """
  of tyTuple, tyObject:
    if ti.base != nil: result = NimCopy(x, ti.base)
    elif ti.kind == tyObject:
      asm "`result` = {m_type: `ti`};"
    else:
      asm "`result` = {};"
    NimCopyAux(result, x, ti.node)
  of tySequence, tyArrayConstr, tyOpenArray, tyArray:
    asm """
      `result` = new Array(`x`.length);
      for (var i = 0; i < `x`.length; ++i) {
        `result`[i] = NimCopy(`x`[i], `ti`.base);
      }
    """
  of tyString:
    asm "`result` = `x`.slice(0);"
  else:
    result = x

proc genericReset(x: Pointer, ti: PNimType): pointer {.compilerproc.} =
  case ti.kind
  of tyPtr, tyRef, tyVar, tyNil:
    if not isFatPointer(ti):
      result = nil
    else:
      asm """
        `result` = [null, 0];
      """
  of tySet:
    asm """
      `result` = {};
    """
  of tyTuple, tyObject:
    if ti.kind == tyObject:
      asm "`result` = {m_type: `ti`};"
    else:
      asm "`result` = {};"
  of tySequence, tyOpenArray:
    asm """
      `result` = [];
    """
  of tyArrayConstr, tyArray:
    asm """
      `result` = new Array(`x`.length);
      for (var i = 0; i < `x`.length; ++i) {
        `result`[i] = genericReset(`x`[i], `ti`.base);
      }
    """
  else:
    result = nil

proc arrayConstr(len: int, value: pointer, typ: PNimType): pointer {.
                 noStackFrame, compilerproc.} =
  # types are fake
  asm """
    var result = new Array(`len`);
    for (var i = 0; i < `len`; ++i) result[i] = NimCopy(`value`, `typ`);
    return result;
  """

proc chckIndx(i, a, b: int): int {.compilerproc.} =
  if i >= a and i <= b: return i
  else: raiseIndexError()

proc chckRange(i, a, b: int): int {.compilerproc.} =
  if i >= a and i <= b: return i
  else: raiseRangeError()

proc chckObj(obj, subclass: PNimType) {.compilerproc.} =
  # checks if obj is of type subclass:
  var x = obj
  if x == subclass: return # optimized fast path
  while x != subclass:
    if x == nil:
      raise newException(EInvalidObjectConversion, "invalid object conversion")
    x = x.base

proc isObj(obj, subclass: PNimType): bool {.compilerproc.} =
  # checks if obj is of type subclass:
  var x = obj
  if x == subclass: return true # optimized fast path
  while x != subclass:
    if x == nil: return false
    x = x.base
  return true

proc addChar(x: string, c: char) {.compilerproc, noStackFrame.} =
  asm """
    `x`[`x`.length-1] = `c`; `x`.push(0);
  """

{.pop.}
