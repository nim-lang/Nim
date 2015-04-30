#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(nodejs):
  proc alert*(s: cstring) {.importc: "console.log", nodecl.}
else:
  proc alert*(s: cstring) {.importc, nodecl.}

proc log*(s: cstring) {.importc: "console.log", varargs, nodecl.}

type
  PSafePoint = ptr TSafePoint
  TSafePoint {.compilerproc, final.} = object
    prev: PSafePoint # points to next safe point
    exc: ref Exception

  PCallFrame = ptr TCallFrame
  TCallFrame {.importc, nodecl, final.} = object
    prev: PCallFrame
    procname: cstring
    line: int # current line number
    filename: cstring

  PJSError = ref object
    columnNumber {.importc.}: int
    fileName {.importc.}: cstring
    lineNumber {.importc.}: int
    message {.importc.}: cstring
    stack {.importc.}: cstring

var
  framePtr {.importc, nodecl, volatile.}: PCallFrame
  excHandler {.importc, nodecl, volatile.}: PSafePoint = nil
    # list of exception handlers
    # a global variable for the root of all try blocks
  lastJSError {.importc, nodecl, volatile.}: PJSError = nil

{.push stacktrace: off, profiler:off.}
proc nimBoolToStr(x: bool): string {.compilerproc.} =
  if x: result = "true"
  else: result = "false"

proc nimCharToStr(x: char): string {.compilerproc.} =
  result = newString(1)
  result[0] = x

proc getCurrentExceptionMsg*(): string =
  if excHandler != nil and excHandler.exc != nil:
    return $excHandler.exc.msg
  elif lastJSError != nil:
    return $lastJSError.message
  else:
    return ""

proc auxWriteStackTrace(f: PCallFrame): string =
  type
    TTempFrame = tuple[procname: cstring, line: int]
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
  if framePtr != nil:
    result = "Traceback (most recent call last)\n" & auxWriteStackTrace(framePtr)
    framePtr = nil
  elif lastJSError != nil:
    result = $lastJSError.stack
  else:
    result = "No stack traceback available\n"

proc raiseException(e: ref Exception, ename: cstring) {.
    compilerproc, asmNoStackFrame.} =
  e.name = ename
  if excHandler != nil:
    excHandler.exc = e
  else:
    when NimStackTrace:
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

proc reraiseException() {.compilerproc, asmNoStackFrame.} =
  if excHandler == nil:
    raise newException(ReraiseError, "no exception to reraise")
  else:
    asm """throw excHandler.exc;"""

proc raiseOverflow {.exportc: "raiseOverflow", noreturn.} =
  raise newException(OverflowError, "over- or underflow")

proc raiseDivByZero {.exportc: "raiseDivByZero", noreturn.} =
  raise newException(DivByZeroError, "division by zero")

proc raiseRangeError() {.compilerproc, noreturn.} =
  raise newException(RangeError, "value out of range")

proc raiseIndexError() {.compilerproc, noreturn.} =
  raise newException(IndexError, "index out of bounds")

proc raiseFieldError(f: string) {.compilerproc, noreturn.} =
  raise newException(FieldError, f & " is not accessible")

proc SetConstr() {.varargs, asmNoStackFrame, compilerproc.} =
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

proc cstrToNimstr(c: cstring): string {.asmNoStackFrame, compilerproc.} =
  asm """
    var result = [];
    for (var i = 0; i < `c`.length; ++i) {
      result[i] = `c`.charCodeAt(i);
    }
    result[result.length] = 0; // terminating zero
    return result;
  """

proc toJSStr(s: string): cstring {.asmNoStackFrame, compilerproc.} =
  asm """
    var len = `s`.length-1;
    var result = new Array(len);
    var fcc = String.fromCharCode;
    for (var i = 0; i < len; ++i) {
      result[i] = fcc(`s`[i]);
    }
    return result.join("");
  """

proc mnewString(len: int): string {.asmNoStackFrame, compilerproc.} =
  asm """
    var result = new Array(`len`+1);
    result[0] = 0;
    result[`len`] = 0;
    return result;
  """

proc SetCard(a: int): int {.compilerproc, asmNoStackFrame.} =
  # argument type is a fake
  asm """
    var result = 0;
    for (var elem in `a`) { ++result; }
    return result;
  """

proc SetEq(a, b: int): bool {.compilerproc, asmNoStackFrame.} =
  asm """
    for (var elem in `a`) { if (!`b`[elem]) return false; }
    for (var elem in `b`) { if (!`a`[elem]) return false; }
    return true;
  """

proc SetLe(a, b: int): bool {.compilerproc, asmNoStackFrame.} =
  asm """
    for (var elem in `a`) { if (!`b`[elem]) return false; }
    return true;
  """

proc SetLt(a, b: int): bool {.compilerproc.} =
  result = SetLe(a, b) and not SetEq(a, b)

proc SetMul(a, b: int): int {.compilerproc, asmNoStackFrame.} =
  asm """
    var result = {};
    for (var elem in `a`) {
      if (`b`[elem]) { result[elem] = true; }
    }
    return result;
  """

proc SetPlus(a, b: int): int {.compilerproc, asmNoStackFrame.} =
  asm """
    var result = {};
    for (var elem in `a`) { result[elem] = true; }
    for (var elem in `b`) { result[elem] = true; }
    return result;
  """

proc SetMinus(a, b: int): int {.compilerproc, asmNoStackFrame.} =
  asm """
    var result = {};
    for (var elem in `a`) {
      if (!`b`[elem]) { result[elem] = true; }
    }
    return result;
  """

proc cmpStrings(a, b: string): int {.asmNoStackFrame, compilerProc.} =
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

proc eqStrings(a, b: string): bool {.asmNoStackFrame, compilerProc.} =
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
  TDocument {.importc.} = object of RootObj
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
  TNode* {.importc.} = object of RootObj
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
  proc rawEcho {.compilerproc, asmNoStackFrame.} =
    asm """
      var buf = "";
      for (var i = 0; i < arguments.length; ++i) {
        buf += `toJSStr`(arguments[i]);
      }
      print(buf);
    """

elif defined(nodejs):
  proc ewriteln(x: cstring) = log(x)

  proc rawEcho {.compilerproc, asmNoStackFrame.} =
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
      raise newException(ValueError, "<body> element does not exist yet!")

  proc rawEcho {.compilerproc.} =
    var node = document.getElementsByTagName("body")[0]
    if node == nil:
      raise newException(IOError, "<body> element does not exist yet!")
    asm """
      for (var i = 0; i < arguments.length; ++i) {
        var x = `toJSStr`(arguments[i]);
        `node`.appendChild(document.createTextNode(x))
      }
    """
    node.appendChild(document.createElement("br"))

# Arithmetic:
proc addInt(a, b: int): int {.asmNoStackFrame, compilerproc.} =
  asm """
    var result = `a` + `b`;
    if (result > 2147483647 || result < -2147483648) `raiseOverflow`();
    return result;
  """

proc subInt(a, b: int): int {.asmNoStackFrame, compilerproc.} =
  asm """
    var result = `a` - `b`;
    if (result > 2147483647 || result < -2147483648) `raiseOverflow`();
    return result;
  """

proc mulInt(a, b: int): int {.asmNoStackFrame, compilerproc.} =
  asm """
    var result = `a` * `b`;
    if (result > 2147483647 || result < -2147483648) `raiseOverflow`();
    return result;
  """

proc divInt(a, b: int): int {.asmNoStackFrame, compilerproc.} =
  asm """
    if (`b` == 0) `raiseDivByZero`();
    if (`b` == -1 && `a` == 2147483647) `raiseOverflow`();
    return Math.floor(`a` / `b`);
  """

proc modInt(a, b: int): int {.asmNoStackFrame, compilerproc.} =
  asm """
    if (`b` == 0) `raiseDivByZero`();
    if (`b` == -1 && `a` == 2147483647) `raiseOverflow`();
    return Math.floor(`a` % `b`);
  """

proc addInt64(a, b: int): int {.asmNoStackFrame, compilerproc.} =
  asm """
    var result = `a` + `b`;
    if (result > 9223372036854775807
    || result < -9223372036854775808) `raiseOverflow`();
    return result;
  """

proc subInt64(a, b: int): int {.asmNoStackFrame, compilerproc.} =
  asm """
    var result = `a` - `b`;
    if (result > 9223372036854775807
    || result < -9223372036854775808) `raiseOverflow`();
    return result;
  """

proc mulInt64(a, b: int): int {.asmNoStackFrame, compilerproc.} =
  asm """
    var result = `a` * `b`;
    if (result > 9223372036854775807
    || result < -9223372036854775808) `raiseOverflow`();
    return result;
  """

proc divInt64(a, b: int): int {.asmNoStackFrame, compilerproc.} =
  asm """
    if (`b` == 0) `raiseDivByZero`();
    if (`b` == -1 && `a` == 9223372036854775807) `raiseOverflow`();
    return Math.floor(`a` / `b`);
  """

proc modInt64(a, b: int): int {.asmNoStackFrame, compilerproc.} =
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

proc toU8*(a: int): int8 {.asmNoStackFrame, compilerproc.} =
  asm """
    return `a`;
  """

proc toU16*(a: int): int16 {.asmNoStackFrame, compilerproc.} =
  asm """
    return `a`;
  """

proc toU32*(a: int64): int32 {.asmNoStackFrame, compilerproc.} =
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

proc nimCopyAux(dest, src: pointer, n: ptr TNimNode) {.compilerproc.} =
  case n.kind
  of nkNone: sysAssert(false, "nimCopyAux")
  of nkSlot:
    asm "`dest`[`n`.offset] = nimCopy(`src`[`n`.offset], `n`.typ);"
  of nkList:
    for i in 0..n.len-1:
      nimCopyAux(dest, src, n.sons[i])
  of nkCase:
    asm """
      `dest`[`n`.offset] = nimCopy(`src`[`n`.offset], `n`.typ);
      for (var i = 0; i < `n`.sons.length; ++i) {
        nimCopyAux(`dest`, `src`, `n`.sons[i][1]);
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
    if ti.base != nil: result = nimCopy(x, ti.base)
    elif ti.kind == tyObject:
      asm "`result` = {m_type: `ti`};"
    else:
      asm "`result` = {};"
    nimCopyAux(result, x, ti.node)
  of tySequence, tyArrayConstr, tyOpenArray, tyArray:
    asm """
      `result` = new Array(`x`.length);
      for (var i = 0; i < `x`.length; ++i) {
        `result`[i] = nimCopy(`x`[i], `ti`.base);
      }
    """
  of tyString:
    asm """
      if (`x` !== null) {
        `result` = `x`.slice(0);
      }
    """
  else:
    result = x

proc genericReset(x: pointer, ti: PNimType): pointer {.compilerproc.} =
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
                 asmNoStackFrame, compilerproc.} =
  # types are fake
  asm """
    var result = new Array(`len`);
    for (var i = 0; i < `len`; ++i) result[i] = nimCopy(`value`, `typ`);
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
      raise newException(ObjectConversionError, "invalid object conversion")
    x = x.base

proc isObj(obj, subclass: PNimType): bool {.compilerproc.} =
  # checks if obj is of type subclass:
  var x = obj
  if x == subclass: return true # optimized fast path
  while x != subclass:
    if x == nil: return false
    x = x.base
  return true

proc addChar(x: string, c: char) {.compilerproc, asmNoStackFrame.} =
  asm """
    `x`[`x`.length-1] = `c`; `x`.push(0);
  """

{.pop.}

proc tenToThePowerOf(b: int): BiggestFloat =
  var b = b
  var a = 10.0
  result = 1.0
  while true:
    if (b and 1) == 1:
      result = result * a
    b = b shr 1
    if b == 0: break
    a = a * a

const
  IdentChars = {'a'..'z', 'A'..'Z', '0'..'9', '_'}

# XXX use JS's native way here
proc nimParseBiggestFloat(s: string, number: var BiggestFloat, start = 0): int {.
                          compilerProc.} =
  var
    esign = 1.0
    sign = 1.0
    i = start
    exponent: int
    flags: int
  number = 0.0
  if s[i] == '+': inc(i)
  elif s[i] == '-':
    sign = -1.0
    inc(i)
  if s[i] == 'N' or s[i] == 'n':
    if s[i+1] == 'A' or s[i+1] == 'a':
      if s[i+2] == 'N' or s[i+2] == 'n':
        if s[i+3] notin IdentChars:
          number = NaN
          return i+3 - start
    return 0
  if s[i] == 'I' or s[i] == 'i':
    if s[i+1] == 'N' or s[i+1] == 'n':
      if s[i+2] == 'F' or s[i+2] == 'f':
        if s[i+3] notin IdentChars:
          number = Inf*sign
          return i+3 - start
    return 0
  while s[i] in {'0'..'9'}:
    # Read integer part
    flags = flags or 1
    number = number * 10.0 + toFloat(ord(s[i]) - ord('0'))
    inc(i)
    while s[i] == '_': inc(i)
  # Decimal?
  if s[i] == '.':
    var hd = 1.0
    inc(i)
    while s[i] in {'0'..'9'}:
      # Read fractional part
      flags = flags or 2
      number = number * 10.0 + toFloat(ord(s[i]) - ord('0'))
      hd = hd * 10.0
      inc(i)
      while s[i] == '_': inc(i)
    number = number / hd # this complicated way preserves precision
  # Again, read integer and fractional part
  if flags == 0: return 0
  # Exponent?
  if s[i] in {'e', 'E'}:
    inc(i)
    if s[i] == '+':
      inc(i)
    elif s[i] == '-':
      esign = -1.0
      inc(i)
    if s[i] notin {'0'..'9'}:
      return 0
    while s[i] in {'0'..'9'}:
      exponent = exponent * 10 + ord(s[i]) - ord('0')
      inc(i)
      while s[i] == '_': inc(i)
  # Calculate Exponent
  let hd = tenToThePowerOf(exponent)
  if esign > 0.0: number = number * hd
  else:           number = number / hd
  # evaluate sign
  number = number * sign
  result = i - start
