# Simple lib to write JS UIs

import dom

export dom.Element, dom.Event, dom.cloneNode, dom

proc kout*[T](x: T) {.importc: "console.log", varargs.}
  ## the preferred way of debugging karax applications.

proc id*(e: Node): cstring {.importcpp: "#.id", nodecl.}
proc `id=`*(e: Node; x: cstring) {.importcpp: "#.id = #", nodecl.}
proc className*(e: Node): cstring {.importcpp: "#.className", nodecl.}
proc `className=`*(e: Node; v: cstring) {.importcpp: "#.className = #", nodecl.}

proc value*(e: Element): cstring {.importcpp: "#.value", nodecl.}
proc `value=`*(e: Element; v: cstring) {.importcpp: "#.value = #", nodecl.}

proc getElementsByClass*(e: Element; name: cstring): seq[Element] {.importcpp: "#.getElementsByClassName(#)", nodecl.}

proc toLower*(x: cstring): cstring {.
  importcpp: "#.toLowerCase()", nodecl.}
proc replace*(x: cstring; search, by: cstring): cstring {.
  importcpp: "#.replace(#, #)", nodecl.}

type
  EventHandler* = proc(ev: Event)
  EventHandlerId* = proc(ev: Event; id: int)

  Timeout* = ref object

var document* {.importc.}: Document

var
  dorender: proc (): Element {.closure.}
  drawTimeout: Timeout
  currentTree: Element

proc setRenderer*(renderer: proc (): Element) =
  dorender = renderer

proc setTimeout*(action: proc(); ms: int): Timeout {.importc, nodecl.}
proc clearTimeout*(t: Timeout) {.importc, nodecl.}
proc targetElem*(e: Event): Element = cast[Element](e.target)

proc getElementById*(id: cstring): Element {.importc: "document.getElementById", nodecl.}

proc getElementsByClassName*(cls: cstring): seq[Element] {.importc:
  "document.getElementsByClassName", nodecl.}

proc textContent*(e: Element): cstring {.
  importcpp: "#.textContent", nodecl.}

proc replaceById*(id: cstring; newTree: Node) =
  let x = getElementById(id)
  x.parentNode.replaceChild(newTree, x)
  newTree.id = id

proc equals(a, b: Node): bool =
  if a.nodeType != b.nodeType: return false
  if a.id != b.id: return false
  if a.nodeName != b.nodeName: return false
  if a.nodeType == TextNode:
    if a.data != b.data: return false
  elif a.childNodes.len != b.childNodes.len:
    return false
  if a.className != b.className:
    # style differences are updated in place and we pretend
    # it's still the same node
    a.className = b.className
    #return false
  return true

proc diffTree(parent, a, b: Node) =
  if equals(a, b):
    if a.nodeType != TextNode:
      # we need to do this correctly in the presence of asyncronous
      # DOM updates:
      var i = 0
      while i < a.childNodes.len and a.childNodes.len == b.childNodes.len:
        diffTree(a, a.childNodes[i], b.childNodes[i])
        inc i
  elif parent == nil:
    replaceById("ROOT", b)
  else:
    parent.replaceChild(b, a)

proc dodraw() =
  let newtree = dorender()
  newtree.id = "ROOT"
  if currentTree == nil:
    currentTree = newtree
    replaceById("ROOT", currentTree)
  else:
    diffTree(nil, currentTree, newtree)

proc redraw*() =
  # we buffer redraw requests:
  if drawTimeout != nil:
    clearTimeout(drawTimeout)
  drawTimeout = setTimeout(dodraw, 30)

proc tree*(tag: string; kids: varargs[Element]): Element =
  result = document.createElement tag
  for k in kids:
    result.appendChild k

proc tree*(tag: string; attrs: openarray[(string, string)];
           kids: varargs[Element]): Element =
  result = tree(tag, kids)
  for a in attrs: result.setAttribute(a[0], a[1])

proc text*(s: string): Element = cast[Element](document.createTextNode(s))
proc text*(s: cstring): Element = cast[Element](document.createTextNode(s))
proc add*(parent, kid: Element) =
  if parent.nodeName == "TR" and (kid.nodeName == "TD" or kid.nodeName == "TH"):
    let k = document.createElement("TD")
    appendChild(k, kid)
    appendChild(parent, k)
  else:
    appendChild(parent, kid)

proc len*(x: Element): int {.importcpp: "#.childNodes.length".}
proc `[]`*(x: Element; idx: int): Element {.importcpp: "#.childNodes[#]".}

proc isInt*(s: cstring): bool {.asmNoStackFrame.} =
  asm """
    return s.match(/^[0-9]+$/);
  """

var
  linkCounter: int

proc link*(id: int): Element =
  result = document.createElement("a")
  result.setAttribute("href", "#")
  inc linkCounter
  result.setAttribute("id", $linkCounter & ":" & $id)

proc link*(action: EventHandler): Element =
  result = document.createElement("a")
  result.setAttribute("href", "#")
  addEventListener(result, "click", action)

proc parseInt*(s: cstring): int {.importc, nodecl.}
proc parseFloat*(s: cstring): float {.importc, nodecl.}
proc split*(s, sep: cstring): seq[cstring] {.importcpp, nodecl.}

proc startsWith*(a, b: cstring): bool {.importcpp: "startsWith", nodecl.}
proc contains*(a, b: cstring): bool {.importcpp: "(#.indexOf(#)>=0)", nodecl.}
proc substr*(s: cstring; start: int): cstring {.importcpp: "substr", nodecl.}
proc substr*(s: cstring; start, length: int): cstring {.importcpp: "substr", nodecl.}

#proc len*(s: cstring): int {.importcpp: "#.length", nodecl.}
proc `&`*(a, b: cstring): cstring {.importcpp: "(# + #)", nodecl.}
proc toCstr*(s: int): cstring {.importcpp: "((#)+'')", nodecl.}

proc suffix*(s, prefix: cstring): cstring =
  if s.startsWith(prefix):
    result = s.substr(prefix.len)
  else:
    kout(cstring"bug! " & s & cstring" does not start with " & prefix)

proc valueAsInt*(e: Element): int = parseInt(e.value)
proc suffixAsInt*(s, prefix: cstring): int = parseInt(suffix(s, prefix))

proc scrollTop*(e: Element): int {.importcpp: "#.scrollTop", nodecl.}
proc offsetHeight*(e: Element): int {.importcpp: "#.offsetHeight", nodecl.}
proc offsetTop*(e: Element): int {.importcpp: "#.offsetTop", nodecl.}

template onImpl(s) {.dirty} =
  proc wrapper(ev: Event) =
    action(ev)
    redraw()
  addEventListener(e, s, wrapper)

proc setOnclick*(e: Element; action: proc(ev: Event)) =
  onImpl "click"

proc setOnclick*(e: Element; action: proc(ev: Event; id: int)) =
  proc wrapper(ev: Event) =
    let id = ev.target.id
    let a = id.split(":")
    if a.len == 2:
      action(ev, parseInt(a[1]))
      redraw()
    else:
      kout(cstring("cannot deal with id "), id)
  addEventListener(e, "click", wrapper)

proc setOnfocuslost*(e: Element; action: EventHandler) =
  onImpl "blur"

proc setOnchanged*(e: Element; action: EventHandler) =
  onImpl "change"

proc setOnscroll*(e: Element; action: EventHandler) =
  onImpl "scroll"

proc select*(choices: openarray[string]): Element =
  result = document.createElement("select")
  var i = 0
  for c in choices:
    result.add tree("option", [("value", $i)], text(c))
    inc i

proc select*(choices: openarray[(int, string)]): Element =
  result = document.createElement("select")
  for c in choices:
    result.add tree("option", [("value", $c[0])], text(c[1]))

var radioCounter: int

proc radio*(choices: openarray[(int, string)]): Element =
  result = document.createElement("fieldset")
  var i = 0
  inc radioCounter
  for c in choices:
    let id = "radio_" & c[1] & $i
    var kid = tree("input", [("type", "radio"),
      ("id", id), ("name", "radio" & $radioCounter),
      ("value", $c[0])])
    if i == 0:
      kid.setAttribute("checked", "checked")
    var lab = tree("label", [("for", id)], text(c[1]))
    kid.add lab
    result.add kid
    inc i

proc tag*(name: string; id="", class=""): Element =
  result = document.createElement(name)
  if id.len > 0:
    result.setAttribute("id", id)
  if class.len > 0:
    result.setAttribute("class", class)

proc tdiv*(id="", class=""): Element = tag("div", id, class)
proc span*(id="", class=""): Element = tag("span", id, class)

proc th*(s: string): Element =
  result = tag("th")
  result.add text(s)

proc td*(s: string): Element =
  result = tag("td")
  result.add text(s)

proc td*(s: Element): Element =
  result = tag("td")
  result.add s

proc td*(class: string; s: Element): Element =
  result = tag("td")
  result.add s
  result.setAttribute("class", class)

proc table*(class="", kids: varargs[Element]): Element =
  result = tag("table", "", class)
  for k in kids: result.add k

proc tr*(kids: varargs[Element]): Element =
  result = tag("tr")
  for k in kids:
    if k.nodeName == "TD" or k.nodeName == "TH":
      result.add k
    else:
      result.add td(k)

proc setClass*(e: Element; value: string) =
  e.setAttribute("class", value)

proc setAttr*(e: Element; key, value: cstring) =
  e.setAttribute(key, value)

proc getAttr*(e: Element; key: cstring): cstring {.
  importcpp: "#.getAttribute(#)", nodecl.}

proc realtimeInput*(id, val: string; changed: proc(value: cstring)): Element =
  let oldElem = getElementById(id)
  #if oldElem != nil: return oldElem
  let newVal = if oldElem.isNil: val else: $oldElem.value
  var timer: Timeout
  proc wrapper() =
    changed(getElementById(id).value)
    redraw()
  proc onkeyup(ev: Event) =
    if timer != nil: clearTimeout(timer)
    timer = setTimeout(wrapper, 400)
  result = tree("input", [("type", "text"),
    ("value", newVal),
    ("id", id)])
  result.addEventListener("keyup", onkeyup)

proc ajax(meth, url: cstring; headers: openarray[(string, string)];
          data: cstring;
          cont: proc (httpStatus: int; response: cstring)) =
  proc setRequestHeader(a, b: cstring) {.importc: "ajax.setRequestHeader".}
  {.emit: """
  var ajax = new XMLHttpRequest();
  ajax.open(`meth`,`url`,true);""".}
  for a, b in items(headers):
    setRequestHeader(a, b)
  {.emit: """
  ajax.onreadystatechange = function(){
    if(this.readyState == 4){
      if(this.status == 200){
        `cont`(this.status, this.responseText);
      } else {
        `cont`(this.status, this.statusText);
      }
    }
  }
  ajax.send(`data`);
  """.}

proc ajaxPut*(url: string; headers: openarray[(string, string)];
          data: cstring;
          cont: proc (httpStatus: int, response: cstring)) =
  ajax("PUT", url, headers, data, cont)

proc ajaxGet*(url: string; headers: openarray[(string, string)];
          cont: proc (httpStatus: int, response: cstring)) =
  ajax("GET", url, headers, nil, cont)

{.push stackTrace:off.}

proc setupErrorHandler*(useAlert=false) =
  ## Installs an error handler that transforms native JS unhandled
  ## exceptions into Nim based stack traces. If `useAlert` is false,
  ## the error message it put into the console, otherwise `alert`
  ## is called.
  proc stackTraceAsCstring(): cstring = cstring(getStackTrace())
  {.emit: """
  window.onerror = function(msg, url, line, col, error) {
    var x = "Error: " + msg + "\n" + `stackTraceAsCstring`()
    if (`useAlert`)
      alert(x);
    else
      console.log(x);
    var suppressErrorAlert = true;
    return suppressErrorAlert;
  };""".}

{.pop.}
