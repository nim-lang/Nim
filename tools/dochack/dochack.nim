import dom
import fuzzysearch

proc textContent(e: Element): cstring {.
  importcpp: "#.textContent", nodecl.}

proc textContent(e: Node): cstring {.
  importcpp: "#.textContent", nodecl.}

proc tree(tag: string; kids: varargs[Element]): Element =
  result = document.createElement tag
  for k in kids:
    result.appendChild k

proc add(parent, kid: Element) =
  if parent.nodeName == cstring"TR" and (
      kid.nodeName == cstring"TD" or kid.nodeName == cstring"TH"):
    let k = document.createElement("TD")
    appendChild(k, kid)
    appendChild(parent, k)
  else:
    appendChild(parent, kid)

proc setClass(e: Element; value: string) =
  e.setAttribute("class", value)
proc text(s: string): Element = cast[Element](document.createTextNode(s))
proc text(s: cstring): Element = cast[Element](document.createTextNode(s))

proc getElementById(id: cstring): Element {.importc: "document.getElementById", nodecl.}

proc replaceById(id: cstring; newTree: Node) =
  let x = getElementById(id)
  x.parentNode.replaceChild(newTree, x)
  newTree.id = id

proc findNodeWith(x: Element; tag, content: cstring): Element =
  if x.nodeName == tag and x.textContent == content:
    return x
  for i in 0..<x.len:
    let it = x[i]
    let y = findNodeWith(it, tag, content)
    if y != nil: return y
  return nil

proc clone(e: Element): Element {.importcpp: "#.cloneNode(true)", nodecl.}
proc parent(e: Element): Element {.importcpp: "#.parentNode", nodecl.}
proc markElement(x: Element) {.importcpp: "#.__karaxMarker__ = true", nodecl.}
proc isMarked(x: Element): bool {.
  importcpp: "#.hasOwnProperty('__karaxMarker__')", nodecl.}
proc title(x: Element): cstring {.importcpp: "#.title", nodecl.}

proc sort[T](x: var openArray[T]; cmp: proc(a, b: T): int) {.importcpp:
  "#.sort(#)", nodecl.}

proc parentWith(x: Element; tag: cstring): Element =
  result = x.parent
  while result.nodeName != tag:
    result = result.parent
    if result == nil: return nil

proc extractItems(x: Element; items: var seq[Element]) =
  if x == nil: return
  if x.nodeName == cstring"A":
    items.add x
  else:
    for i in 0..<x.len:
      let it = x[i]
      extractItems(it, items)

# HTML trees are so shitty we transform the TOC into a decent
# data-structure instead and work on that.
type
  TocEntry = ref object
    heading: Element
    kids: seq[TocEntry]
    sortId: int
    doSort: bool

proc extractItems(x: TocEntry; heading: cstring;
                  items: var seq[Element]) =
  if x == nil: return
  if x.heading != nil and x.heading.textContent == heading:
    for i in 0..<x.kids.len:
      items.add x.kids[i].heading
  else:
    for i in 0..<x.kids.len:
      let it = x.kids[i]
      extractItems(it, heading, items)

proc toHtml(x: TocEntry; isRoot=false): Element =
  if x == nil: return nil
  if x.kids.len == 0:
    if x.heading == nil: return nil
    return x.heading.clone
  result = tree("DIV")
  if x.heading != nil and not isMarked(x.heading):
    result.add x.heading.clone
  let ul = tree("UL")
  if isRoot:
    ul.setClass("simple simple-toc")
  else:
    ul.setClass("simple")
  if x.dosort:
    x.kids.sort(proc(a, b: TocEntry): int =
      if a.heading != nil and b.heading != nil:
        let x = a.heading.textContent
        let y = b.heading.textContent
        if x < y: return -1
        if x > y: return 1
        return 0
      else:
        # ensure sorting is stable:
        return a.sortId - b.sortId
    )
  for k in x.kids:
    let y = toHtml(k)
    if y != nil:
      ul.add tree("LI", y)
  if ul.len != 0: result.add ul
  if result.len == 0: result = nil

#proc containsWord(a, b: cstring): bool {.asmNoStackFrame.} =
  #{.emit: """
     #var escaped = `b`.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
     #return new RegExp("\\b" + escaped + "\\b").test(`a`);
  #""".}

proc isWhitespace(text: cstring): bool {.asmNoStackFrame.} =
  {.emit: """
     return !/[^\s]/.test(`text`);
  """.}

proc isWhitespace(x: Element): bool =
  x.nodeName == cstring"#text" and x.textContent.isWhitespace or
    x.nodeName == cstring"#comment"

proc toToc(x: Element; father: TocEntry) =
  if x.nodeName == cstring"UL":
    let f = TocEntry(heading: nil, kids: @[], sortId: father.kids.len)
    var i = 0
    while i < x.len:
      var nxt = i+1
      while nxt < x.len and x[nxt].isWhitespace:
        inc nxt
      if nxt < x.len and x[i].nodeName == cstring"LI" and x[i].len == 1 and
          x[nxt].nodeName == cstring"UL":
        let e = TocEntry(heading: x[i][0], kids: @[], sortId: f.kids.len)
        let it = x[nxt]
        for j in 0..<it.len:
          toToc(it[j], e)
        f.kids.add e
        i = nxt+1
      else:
        toToc(x[i], f)
        inc i
    father.kids.add f
  elif isWhitespace(x):
    discard
  elif x.nodeName == cstring"LI":
    var idx: seq[int] = @[]
    for i in 0 ..< x.len:
      if not x[i].isWhitespace: idx.add i
    if idx.len == 2 and x[idx[1]].nodeName == cstring"UL":
      let e = TocEntry(heading: x[idx[0]], kids: @[],
                       sortId: father.kids.len)
      let it = x[idx[1]]
      for j in 0..<it.len:
        toToc(it[j], e)
      father.kids.add e
    else:
      for i in 0..<x.len:
        toToc(x[i], father)
  else:
    father.kids.add TocEntry(heading: x, kids: @[],
                             sortId: father.kids.len)

proc tocul(x: Element): Element =
  # x is a 'ul' element
  result = tree("UL")
  for i in 0..<x.len:
    let it = x[i]
    if it.nodeName == cstring"LI":
      result.add it.clone
    elif it.nodeName == cstring"UL":
      result.add tocul(it)

proc getSection(toc: Element; name: cstring): Element =
  let sec = findNodeWith(toc, "A", name)
  if sec != nil:
    result = sec.parentWith("LI")

proc uncovered(x: TocEntry): TocEntry =
  if x.kids.len == 0 and x.heading != nil:
    return if not isMarked(x.heading): x else: nil
  result = TocEntry(heading: x.heading, kids: @[], sortId: x.sortId,
                    doSort: x.doSort)
  for i in 0..<x.kids.len:
    let y = uncovered(x.kids[i])
    if y != nil: result.kids.add y
  if result.kids.len == 0: result = nil

proc mergeTocs(orig, news: TocEntry): TocEntry =
  result = uncovered(orig)
  if result == nil:
    result = news
  else:
    for i in 0..<news.kids.len:
      result.kids.add news.kids[i]

proc buildToc(orig: TocEntry; types, procs: seq[Element]): TocEntry =
  var newStuff = TocEntry(heading: nil, kids: @[], doSort: true)
  for t in types:
    let c = TocEntry(heading: t.clone, kids: @[], doSort: true)
    t.markElement()
    for p in procs:
      if not isMarked(p):
        let xx = getElementsByClass(p.parent, cstring"attachedType")
        if xx.len == 1 and xx[0].textContent == t.textContent:
          #kout(cstring"found ", p.nodeName)
          let q = tree("A", text(p.title))
          q.setAttr("href", p.getAttribute("href"))
          c.kids.add TocEntry(heading: q, kids: @[])
          p.markElement()
    newStuff.kids.add c
  result = mergeTocs(orig, newStuff)

var alternative: Element

proc togglevis(d: Element) =
  asm """
    if (`d`.style.display == 'none')
      `d`.style.display = 'inline';
    else
      `d`.style.display = 'none';
  """

proc groupBy*(value: cstring) {.exportc.} =
  let toc = getElementById("toc-list")
  if alternative.isNil:
    var tt = TocEntry(heading: nil, kids: @[])
    toToc(toc, tt)
    tt = tt.kids[0]

    var types: seq[Element] = @[]
    var procs: seq[Element] = @[]

    extractItems(tt, "Types", types)
    extractItems(tt, "Procs", procs)
    extractItems(tt, "Converters", procs)
    extractItems(tt, "Methods", procs)
    extractItems(tt, "Templates", procs)
    extractItems(tt, "Macros", procs)
    extractItems(tt, "Iterators", procs)

    let ntoc = buildToc(tt, types, procs)
    let x = toHtml(ntoc, isRoot=true)
    alternative = tree("DIV", x)
  if value == cstring"type":
    replaceById("tocRoot", alternative)
  else:
    replaceById("tocRoot", tree("DIV"))
  togglevis(getElementById"toc-list")

var
  db: seq[Node]
  contents: seq[cstring]

template normalize(x: cstring): cstring = x.toLower.replace("_", "")

proc escapeCString(x: var cstring) =
  # Original strings are already escaped except HTML tags, so
  # we only escape `<` and `>`.
  var s = ""
  for c in x:
    case c
    of '<': s.add("&lt;")
    of '>': s.add("&gt;")
    else: s.add(c)
  x = s.cstring

proc dosearch(value: cstring): Element =
  if db.len == 0:
    var stuff: Element
    {.emit: """
    var request = new XMLHttpRequest();
    request.open("GET", "theindex.html", false);
    request.send(null);

    var doc = document.implementation.createHTMLDocument("theindex");
    doc.documentElement.innerHTML = request.responseText;

    //parser=new DOMParser();
    //doc=parser.parseFromString("<html></html>", "text/html");

    `stuff` = doc.documentElement;
    """.}
    db = stuff.getElementsByClass"reference"
    contents = @[]
    for ahref in db:
      contents.add ahref.getAttribute("data-doc-search-tag")
  let ul = tree("UL")
  result = tree("DIV")
  result.setClass"search_results"
  var matches: seq[(Node, int)] = @[]
  for i in 0..<db.len:
    let c = contents[i]
    if c == cstring"Examples" or c == cstring"PEG construction":
    # Some manual exclusions.
    # Ideally these should be fixed in the index to be more
    # descriptive of what they are.
      continue
    let (score, matched) = fuzzymatch(value, c)
    if matched:
      matches.add((db[i], score))

  matches.sort(proc(a, b: auto): int = b[1] - a[1])
  for i in 0 ..< min(matches.len, 29):
    matches[i][0].innerHTML = matches[i][0].getAttribute("data-doc-search-tag")
    escapeCString(matches[i][0].innerHTML)
    ul.add(tree("LI", cast[Element](matches[i][0])))
  if ul.len == 0:
    result.add tree("B", text"no search results")
  else:
    result.add tree("B", text"search results")
    result.add ul

var oldtoc: Element
var timer: Timeout

proc search*() {.exportc.} =
  proc wrapper() =
    let elem = getElementById("searchInput")
    let value = elem.value
    if value.len != 0:
      if oldtoc.isNil:
        oldtoc = getElementById("tocRoot")
      let results = dosearch(value)
      replaceById("tocRoot", results)
    elif not oldtoc.isNil:
      replaceById("tocRoot", oldtoc)

  if timer != nil: clearTimeout(timer)
  timer = setTimeout(wrapper, 400)
