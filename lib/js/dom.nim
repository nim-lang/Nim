#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Declaration of the Document Object Model for the `JavaScript backend
## <backends.html#the-javascript-target>`_.

when not defined(js) and not defined(Nimdoc):
  {.error: "This module only works on the JavaScript platform".}

type
  TEventHandlers* {.importc.} = object of RootObj
    onabort*: proc (event: ref TEvent) {.nimcall.}
    onblur*: proc (event: ref TEvent) {.nimcall.}
    onchange*: proc (event: ref TEvent) {.nimcall.}
    onclick*: proc (event: ref TEvent) {.nimcall.}
    ondblclick*: proc (event: ref TEvent) {.nimcall.}
    onerror*: proc (event: ref TEvent) {.nimcall.}
    onfocus*: proc (event: ref TEvent) {.nimcall.}
    onkeydown*: proc (event: ref TEvent) {.nimcall.}
    onkeypress*: proc (event: ref TEvent) {.nimcall.}
    onkeyup*: proc (event: ref TEvent) {.nimcall.}
    onload*: proc (event: ref TEvent) {.nimcall.}
    onmousedown*: proc (event: ref TEvent) {.nimcall.}
    onmousemove*: proc (event: ref TEvent) {.nimcall.}
    onmouseout*: proc (event: ref TEvent) {.nimcall.}
    onmouseover*: proc (event: ref TEvent) {.nimcall.}
    onmouseup*: proc (event: ref TEvent) {.nimcall.}
    onreset*: proc (event: ref TEvent) {.nimcall.}
    onselect*: proc (event: ref TEvent) {.nimcall.}
    onsubmit*: proc (event: ref TEvent) {.nimcall.}
    onunload*: proc (event: ref TEvent) {.nimcall.}

  TWindow* {.importc.} = object of TEventHandlers
    document*: ref TDocument
    event*: ref TEvent
    history*: ref THistory
    location*: ref TLocation
    closed*: bool
    defaultStatus*: cstring
    innerHeight*, innerWidth*: int
    locationbar*: ref TLocationBar
    menubar*: ref TMenuBar
    name*: cstring
    outerHeight*, outerWidth*: int
    pageXOffset*, pageYOffset*: int
    personalbar*: ref TPersonalBar
    scrollbars*: ref TScrollBars
    statusbar*: ref TStatusBar
    status*: cstring
    toolbar*: ref TToolBar

    addEventListener*: proc(ev: cstring, cb: proc(ev: ref TEvent) ) {.nimcall.}
    alert*: proc (msg: cstring) {.nimcall.}
    back*: proc () {.nimcall.}
    blur*: proc () {.nimcall.}
    captureEvents*: proc (eventMask: int) {.nimcall.}
    clearInterval*: proc (interval: ref TInterval) {.nimcall.}
    clearTimeout*: proc (timeout: ref TTimeOut) {.nimcall.}
    close*: proc () {.nimcall.}
    confirm*: proc (msg: cstring): bool {.nimcall.}
    disableExternalCapture*: proc () {.nimcall.}
    enableExternalCapture*: proc () {.nimcall.}
    find*: proc (text: cstring, caseSensitive = false, 
                 backwards = false) {.nimcall.}
    focus*: proc () {.nimcall.}
    forward*: proc () {.nimcall.}
    handleEvent*: proc (e: ref TEvent) {.nimcall.}
    home*: proc () {.nimcall.}
    moveBy*: proc (x, y: int) {.nimcall.}
    moveTo*: proc (x, y: int) {.nimcall.}
    open*: proc (uri, windowname: cstring,
                 properties: cstring = nil): ref TWindow {.nimcall.}
    print*: proc () {.nimcall.}
    prompt*: proc (text, default: cstring): cstring {.nimcall.}
    releaseEvents*: proc (eventMask: int) {.nimcall.}
    resizeBy*: proc (x, y: int) {.nimcall.}
    resizeTo*: proc (x, y: int) {.nimcall.}
    routeEvent*: proc (event: ref TEvent) {.nimcall.}
    scrollBy*: proc (x, y: int) {.nimcall.}
    scrollTo*: proc (x, y: int) {.nimcall.}
    setInterval*: proc (code: cstring, pause: int): ref TInterval {.nimcall.}
    setTimeout*: proc (code: cstring, pause: int): ref TTimeOut {.nimcall.}
    stop*: proc () {.nimcall.}
    frames*: seq[TFrame]

  TFrame* {.importc.} = object of TWindow

  TDocument* {.importc.} = object of TEventHandlers
    addEventListener*: proc(ev: cstring, cb: proc(ev: ref TEvent) ) {.nimcall.}
    alinkColor*: cstring
    bgColor*: cstring
    charset*: cstring
    cookie*: cstring
    defaultCharset*: cstring
    fgColor*: cstring
    lastModified*: cstring
    linkColor*: cstring
    referrer*: cstring
    title*: cstring
    URL*: cstring
    vlinkColor*: cstring
    captureEvents*: proc (eventMask: int) {.nimcall.}
    createAttribute*: proc (identifier: cstring): ref TNode {.nimcall.}
    createElement*: proc (identifier: cstring): ref TNode {.nimcall.}
    createTextNode*: proc (identifier: cstring): ref TNode {.nimcall.}
    getElementById*: proc (id: cstring): ref TNode {.nimcall.}
    getElementsByName*: proc (name: cstring): seq[ref TNode] {.nimcall.}
    getElementsByTagName*: proc (name: cstring): seq[ref TNode] {.nimcall.}
    getElementsByClassName*: proc (name: cstring): seq[ref TNode] {.nimcall.}
    getSelection*: proc (): cstring {.nimcall.}
    handleEvent*: proc (event: ref TEvent) {.nimcall.}
    open*: proc () {.nimcall.}
    releaseEvents*: proc (eventMask: int) {.nimcall.}
    routeEvent*: proc (event: ref TEvent) {.nimcall.}
    write*: proc (text: cstring) {.nimcall.}
    writeln*: proc (text: cstring) {.nimcall.}
    anchors*: seq[ref TAnchor]
    forms*: seq[ref TForm]
    images*: seq[ref TImage]
    applets*: seq[ref TApplet]
    embeds*: seq[ref TEmbed]
    links*: seq[ref TLink]

  TLink* {.importc.} = object of RootObj
    name*: cstring
    target*: cstring
    text*: cstring
    x*: int
    y*: int

  TEmbed* {.importc.} = object of RootObj
    height*: int
    hspace*: int
    name*: cstring
    src*: cstring
    width*: int
    `type`*: cstring
    vspace*: int
    play*: proc () {.nimcall.}
    stop*: proc () {.nimcall.}

  TAnchor* {.importc.} = object of RootObj
    name*: cstring
    text*: cstring
    x*, y*: int

  TApplet* {.importc.} = object of RootObj

  TElement* {.importc.} = object of TEventHandlers
    checked*: bool
    defaultChecked*: bool
    defaultValue*: cstring
    disabled*: bool
    form*: ref TForm
    name*: cstring
    readOnly*: bool
    `type`*: cstring
    value*: cstring
    blur*: proc () {.nimcall.}
    click*: proc () {.nimcall.}
    focus*: proc () {.nimcall.}
    handleEvent*: proc (event: ref TEvent) {.nimcall.}
    select*: proc () {.nimcall.}
    options*: seq[ref TOption]

  TOption* {.importc.} = object of RootObj
    defaultSelected*: bool
    selected*: bool
    selectedIndex*: int
    text*: cstring
    value*: cstring

  TForm* {.importc.} = object of TEventHandlers
    action*: cstring
    encoding*: cstring
    `method`*: cstring
    name*: cstring
    target*: cstring
    handleEvent*: proc (event: ref TEvent) {.nimcall.}
    reset*: proc () {.nimcall.}
    submit*: proc () {.nimcall.}
    elements*: seq[ref TElement]

  TImage* {.importc.} = object of TEventHandlers
    border*: int
    complete*: bool
    height*: int
    hspace*: int
    lowsrc*: cstring
    name*: cstring
    src*: cstring
    vspace*: int
    width*: int
    handleEvent*: proc (event: ref TEvent) {.nimcall.}

  ClassList* {.importc.} = object of RootObj
    add*: proc (class: cstring) {.nimcall.}
    remove*: proc (class: cstring) {.nimcall.}
    contains*: proc (class: cstring):bool {.nimcall.}
    toggle*: proc (class: cstring) {.nimcall.}

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
    children*: seq[ref TNode]
    classList*: ref Classlist
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
    cloneNode*: proc (copyContent: bool): ref TNode {.nimcall.}
    deleteData*: proc (start, len: int) {.nimcall.}
    getAttribute*: proc (attr: cstring): cstring {.nimcall.}
    getAttributeNode*: proc (attr: cstring): ref TNode {.nimcall.}
    getElementsByTagName*: proc (name: cstring): seq[ref TNode] {.nimcall.}
    getElementsByClassName*: proc (name: cstring): seq[ref TNode] {.nimcall.}
    hasChildNodes*: proc (): bool {.nimcall.}
    innerHTML*: cstring
    insertBefore*: proc (newNode, before: ref TNode) {.nimcall.}
    insertData*: proc (position: int, data: cstring) {.nimcall.}
    addEventListener*: proc(ev: cstring, cb: proc(ev: ref TEvent)) {.nimcall.}
    removeAttribute*: proc (attr: cstring) {.nimcall.}
    removeAttributeNode*: proc (attr: ref TNode) {.nimcall.}
    removeChild*: proc (child: ref TNode) {.nimcall.}
    replaceChild*: proc (newNode, oldNode: ref TNode) {.nimcall.}
    replaceData*: proc (start, len: int, text: cstring) {.nimcall.}
    scrollIntoView*: proc () {.nimcall.}
    setAttribute*: proc (name, value: cstring) {.nimcall.}
    setAttributeNode*: proc (attr: ref TNode) {.nimcall.}
    style*: ref TStyle

  TStyle* {.importc.} = object of RootObj
    background*: cstring
    backgroundAttachment*: cstring
    backgroundColor*: cstring
    backgroundImage*: cstring
    backgroundPosition*: cstring
    backgroundRepeat*: cstring
    border*: cstring
    borderBottom*: cstring
    borderBottomColor*: cstring
    borderBottomStyle*: cstring
    borderBottomWidth*: cstring
    borderColor*: cstring
    borderLeft*: cstring
    borderLeftColor*: cstring
    borderLeftStyle*: cstring
    borderLeftWidth*: cstring
    borderRight*: cstring
    borderRightColor*: cstring
    borderRightStyle*: cstring
    borderRightWidth*: cstring
    borderStyle*: cstring
    borderTop*: cstring
    borderTopColor*: cstring
    borderTopStyle*: cstring
    borderTopWidth*: cstring
    borderWidth*: cstring
    bottom*: cstring
    captionSide*: cstring
    clear*: cstring
    clip*: cstring
    color*: cstring
    cursor*: cstring
    direction*: cstring
    display*: cstring
    emptyCells*: cstring
    cssFloat*: cstring
    font*: cstring
    fontFamily*: cstring
    fontSize*: cstring
    fontStretch*: cstring
    fontStyle*: cstring
    fontVariant*: cstring
    fontWeight*: cstring
    height*: cstring
    left*: cstring
    letterSpacing*: cstring
    lineHeight*: cstring
    listStyle*: cstring
    listStyleImage*: cstring
    listStylePosition*: cstring
    listStyleType*: cstring
    margin*: cstring
    marginBottom*: cstring
    marginLeft*: cstring
    marginRight*: cstring
    marginTop*: cstring
    maxHeight*: cstring
    maxWidth*: cstring
    minHeight*: cstring
    minWidth*: cstring
    overflow*: cstring
    padding*: cstring
    paddingBottom*: cstring
    paddingLeft*: cstring
    paddingRight*: cstring
    paddingTop*: cstring
    pageBreakAfter*: cstring
    pageBreakBefore*: cstring
    position*: cstring
    right*: cstring
    scrollbar3dLightColor*: cstring
    scrollbarArrowColor*: cstring
    scrollbarBaseColor*: cstring
    scrollbarDarkshadowColor*: cstring
    scrollbarFaceColor*: cstring
    scrollbarHighlightColor*: cstring
    scrollbarShadowColor*: cstring
    scrollbarTrackColor*: cstring
    tableLayout*: cstring
    textAlign*: cstring
    textDecoration*: cstring
    textIndent*: cstring
    textTransform*: cstring
    top*: cstring
    verticalAlign*: cstring
    visibility*: cstring
    width*: cstring
    wordSpacing*: cstring
    zIndex*: int
    getAttribute*: proc (attr: cstring, caseSensitive=false): cstring {.nimcall.}
    removeAttribute*: proc (attr: cstring, caseSensitive=false) {.nimcall.}
    setAttribute*: proc (attr, value: cstring, caseSensitive=false) {.nimcall.}

  TEvent* {.importc.} = object of RootObj
    target*: ref TNode
    altKey*, ctrlKey*, shiftKey*: bool
    button*: int
    clientX*, clientY*: int
    keyCode*: int
    layerX*, layerY*: int
    modifiers*: int
    ALT_MASK*, CONTROL_MASK*, SHIFT_MASK*, META_MASK*: int
    offsetX*, offsetY*: int
    pageX*, pageY*: int
    screenX*, screenY*: int
    which*: int
    `type`*: cstring
    x*, y*: int
    ABORT*: int
    BLUR*: int
    CHANGE*: int
    CLICK*: int
    DBLCLICK*: int
    DRAGDROP*: int
    ERROR*: int
    FOCUS*: int
    KEYDOWN*: int
    KEYPRESS*: int
    KEYUP*: int
    LOAD*: int
    MOUSEDOWN*: int
    MOUSEMOVE*: int
    MOUSEOUT*: int
    MOUSEOVER*: int
    MOUSEUP*: int
    MOVE*: int
    RESET*: int
    RESIZE*: int
    SELECT*: int
    SUBMIT*: int
    UNLOAD*: int

  TLocation* {.importc.} = object of RootObj
    hash*: cstring
    host*: cstring
    hostname*: cstring
    href*: cstring
    pathname*: cstring
    port*: cstring
    protocol*: cstring
    search*: cstring
    reload*: proc () {.nimcall.}
    replace*: proc (s: cstring) {.nimcall.}

  THistory* {.importc.} = object of RootObj
    length*: int
    back*: proc () {.nimcall.}
    forward*: proc () {.nimcall.}
    go*: proc (pagesToJump: int) {.nimcall.}

  TNavigator* {.importc.} = object of RootObj
    appCodeName*: cstring
    appName*: cstring
    appVersion*: cstring
    cookieEnabled*: bool
    language*: cstring
    platform*: cstring
    userAgent*: cstring
    javaEnabled*: proc (): bool {.nimcall.}
    mimeTypes*: seq[ref TMimeType]

  TPlugin* {.importc.} = object of RootObj
    description*: cstring
    filename*: cstring
    name*: cstring

  TMimeType* {.importc.} = object of RootObj
    description*: cstring
    enabledPlugin*: ref TPlugin
    suffixes*: seq[cstring]
    `type`*: cstring

  TLocationBar* {.importc.} = object of RootObj
    visible*: bool
  TMenuBar* = TLocationBar
  TPersonalBar* = TLocationBar
  TScrollBars* = TLocationBar
  TToolBar* = TLocationBar
  TStatusBar* = TLocationBar

  TScreen* {.importc.} = object of RootObj
    availHeight*: int
    availWidth*: int
    colorDepth*: int
    height*: int
    pixelDepth*: int
    width*: int

  TTimeOut* {.importc.} = object of RootObj
  TInterval* {.importc.} = object of RootObj

var
  window* {.importc, nodecl.}: ref TWindow
  document* {.importc, nodecl.}: ref TDocument
  navigator* {.importc, nodecl.}: ref TNavigator
  screen* {.importc, nodecl.}: ref TScreen

proc decodeURI*(uri: cstring): cstring {.importc, nodecl.}
proc encodeURI*(uri: cstring): cstring {.importc, nodecl.}

proc escape*(uri: cstring): cstring {.importc, nodecl.}
proc unescape*(uri: cstring): cstring {.importc, nodecl.}

proc decodeURIComponent*(uri: cstring): cstring {.importc, nodecl.}
proc encodeURIComponent*(uri: cstring): cstring {.importc, nodecl.}
proc isFinite*(x: BiggestFloat): bool {.importc, nodecl.}
proc isNaN*(x: BiggestFloat): bool {.importc, nodecl.}
proc parseFloat*(s: cstring): BiggestFloat {.importc, nodecl.}
proc parseInt*(s: cstring): int {.importc, nodecl.}
proc parseInt*(s: cstring, radix: int):int {.importc, nodecl.}
