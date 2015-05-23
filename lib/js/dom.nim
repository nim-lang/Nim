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
  EventHandlers* {.importc.} = object of RootObj
    onabort*: proc (event: ref Event) {.nimcall.}
    onblur*: proc (event: ref Event) {.nimcall.}
    onchange*: proc (event: ref Event) {.nimcall.}
    onclick*: proc (event: ref Event) {.nimcall.}
    ondblclick*: proc (event: ref Event) {.nimcall.}
    onerror*: proc (event: ref Event) {.nimcall.}
    onfocus*: proc (event: ref Event) {.nimcall.}
    onkeydown*: proc (event: ref Event) {.nimcall.}
    onkeypress*: proc (event: ref Event) {.nimcall.}
    onkeyup*: proc (event: ref Event) {.nimcall.}
    onload*: proc (event: ref Event) {.nimcall.}
    onmousedown*: proc (event: ref Event) {.nimcall.}
    onmousemove*: proc (event: ref Event) {.nimcall.}
    onmouseout*: proc (event: ref Event) {.nimcall.}
    onmouseover*: proc (event: ref Event) {.nimcall.}
    onmouseup*: proc (event: ref Event) {.nimcall.}
    onreset*: proc (event: ref Event) {.nimcall.}
    onselect*: proc (event: ref Event) {.nimcall.}
    onsubmit*: proc (event: ref Event) {.nimcall.}
    onunload*: proc (event: ref Event) {.nimcall.}

    addEventListener*: proc(ev: cstring, cb: proc(ev: ref Event), useCapture: bool = false) {.nimcall.}

  Window* = ref WindowObj
  WindowObj {.importc.} = object of EventHandlers
    document*: Document
    event*: ref Event
    history*: ref History
    location*: ref Location
    closed*: bool
    defaultStatus*: cstring
    innerHeight*, innerWidth*: int
    locationbar*: ref LocationBar
    menubar*: ref MenuBar
    name*: cstring
    outerHeight*, outerWidth*: int
    pageXOffset*, pageYOffset*: int
    personalbar*: ref PersonalBar
    scrollbars*: ref ScrollBars
    statusbar*: ref StatusBar
    status*: cstring
    toolbar*: ref ToolBar

    alert*: proc (msg: cstring) {.nimcall.}
    back*: proc () {.nimcall.}
    blur*: proc () {.nimcall.}
    captureEvents*: proc (eventMask: int) {.nimcall.}
    clearInterval*: proc (interval: ref Interval) {.nimcall.}
    clearTimeout*: proc (timeout: ref TimeOut) {.nimcall.}
    close*: proc () {.nimcall.}
    confirm*: proc (msg: cstring): bool {.nimcall.}
    disableExternalCapture*: proc () {.nimcall.}
    enableExternalCapture*: proc () {.nimcall.}
    find*: proc (text: cstring, caseSensitive = false,
                 backwards = false) {.nimcall.}
    focus*: proc () {.nimcall.}
    forward*: proc () {.nimcall.}
    handleEvent*: proc (e: ref Event) {.nimcall.}
    home*: proc () {.nimcall.}
    moveBy*: proc (x, y: int) {.nimcall.}
    moveTo*: proc (x, y: int) {.nimcall.}
    open*: proc (uri, windowname: cstring,
                 properties: cstring = nil): Window {.nimcall.}
    print*: proc () {.nimcall.}
    prompt*: proc (text, default: cstring): cstring {.nimcall.}
    releaseEvents*: proc (eventMask: int) {.nimcall.}
    resizeBy*: proc (x, y: int) {.nimcall.}
    resizeTo*: proc (x, y: int) {.nimcall.}
    routeEvent*: proc (event: ref Event) {.nimcall.}
    scrollBy*: proc (x, y: int) {.nimcall.}
    scrollTo*: proc (x, y: int) {.nimcall.}
    setInterval*: proc (code: cstring, pause: int): ref Interval {.nimcall.}
    setTimeout*: proc (code: cstring, pause: int): ref TimeOut {.nimcall.}
    stop*: proc () {.nimcall.}
    frames*: seq[FrameObj]

  Frame* = ref FrameObj
  FrameObj {.importc.} = object of WindowObj

  ClassList* {.importc.} = object of RootObj
    add*: proc (class: cstring) {.nimcall.}
    remove*: proc (class: cstring) {.nimcall.}
    contains*: proc (class: cstring):bool {.nimcall.}
    toggle*: proc (class: cstring) {.nimcall.}

  NodeType* = enum
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

  Node* = ref NodeObj
  NodeObj {.importc.} = object of EventHandlers
    attributes*: seq[Node]
    childNodes*: seq[Node]
    children*: seq[Node]
    data*: cstring
    firstChild*: Node
    lastChild*: Node
    nextSibling*: Node
    nodeName*: cstring
    nodeType*: NodeType
    nodeValue*: cstring
    parentNode*: Node
    previousSibling*: Node
    appendChild*: proc (child: Node) {.nimcall.}
    appendData*: proc (data: cstring) {.nimcall.}
    cloneNode*: proc (copyContent: bool): Node {.nimcall.}
    deleteData*: proc (start, len: int) {.nimcall.}
    getAttribute*: proc (attr: cstring): cstring {.nimcall.}
    getAttributeNode*: proc (attr: cstring): Node {.nimcall.}
    hasChildNodes*: proc (): bool {.nimcall.}
    innerHTML*: cstring
    insertBefore*: proc (newNode, before: Node) {.nimcall.}
    insertData*: proc (position: int, data: cstring) {.nimcall.}
    removeAttribute*: proc (attr: cstring) {.nimcall.}
    removeAttributeNode*: proc (attr: Node) {.nimcall.}
    removeChild*: proc (child: Node) {.nimcall.}
    replaceChild*: proc (newNode, oldNode: Node) {.nimcall.}
    replaceData*: proc (start, len: int, text: cstring) {.nimcall.}
    scrollIntoView*: proc () {.nimcall.}
    setAttribute*: proc (name, value: cstring) {.nimcall.}
    setAttributeNode*: proc (attr: Node) {.nimcall.}
    style*: ref Style

  Document* = ref DocumentObj
  DocumentObj {.importc.} = object of NodeObj
    alinkColor*: cstring
    bgColor*: cstring
    body*: Element
    charset*: cstring
    cookie*: cstring
    defaultCharset*: cstring
    fgColor*: cstring
    head*: Element
    lastModified*: cstring
    linkColor*: cstring
    referrer*: cstring
    title*: cstring
    URL*: cstring
    vlinkColor*: cstring
    captureEvents*: proc (eventMask: int) {.nimcall.}
    createAttribute*: proc (identifier: cstring): Node {.nimcall.}
    createElement*: proc (identifier: cstring): Element {.nimcall.}
    createTextNode*: proc (identifier: cstring): Node {.nimcall.}
    getElementById*: proc (id: cstring): Element {.nimcall.}
    getElementsByName*: proc (name: cstring): seq[Element] {.nimcall.}
    getElementsByTagName*: proc (name: cstring): seq[Element] {.nimcall.}
    getElementsByClassName*: proc (name: cstring): seq[Element] {.nimcall.}
    getSelection*: proc (): cstring {.nimcall.}
    handleEvent*: proc (event: ref Event) {.nimcall.}
    open*: proc () {.nimcall.}
    releaseEvents*: proc (eventMask: int) {.nimcall.}
    routeEvent*: proc (event: ref Event) {.nimcall.}
    write*: proc (text: cstring) {.nimcall.}
    writeln*: proc (text: cstring) {.nimcall.}
    anchors*: seq[AnchorElement]
    forms*: seq[FormElement]
    images*: seq[ImageElement]
    applets*: seq[ref Applet]
    embeds*: seq[EmbedElement]
    links*: seq[LinkElement]

  Element* = ref ElementObj
  ElementObj {.importc.} = object of NodeObj
    classList*: ref Classlist
    checked*: bool
    defaultChecked*: bool
    defaultValue*: cstring
    disabled*: bool
    form*: FormElement
    name*: cstring
    readOnly*: bool
    blur*: proc () {.nimcall.}
    click*: proc () {.nimcall.}
    focus*: proc () {.nimcall.}
    handleEvent*: proc (event: ref Event) {.nimcall.}
    select*: proc () {.nimcall.}
    options*: seq[OptionElement]
    getElementsByTagName*: proc (name: cstring): seq[Element] {.nimcall.}
    getElementsByClassName*: proc (name: cstring): seq[Element] {.nimcall.}

  LinkElement* = ref LinkObj
  LinkObj {.importc.} = object of ElementObj
    target*: cstring
    text*: cstring
    x*: int
    y*: int

  EmbedElement* = ref EmbedObj
  EmbedObj {.importc.} = object of ElementObj
    height*: int
    hspace*: int
    src*: cstring
    width*: int
    `type`*: cstring
    vspace*: int
    play*: proc () {.nimcall.}
    stop*: proc () {.nimcall.}

  AnchorElement* = ref AnchorObj
  AnchorObj {.importc.} = object of ElementObj
    text*: cstring
    x*, y*: int

  Applet* {.importc.} = object of RootObj

  OptionElement* = ref OptionObj
  OptionObj {.importc.} = object of ElementObj
    defaultSelected*: bool
    selected*: bool
    selectedIndex*: int
    text*: cstring
    value*: cstring

  FormElement* = ref FormObj
  FormObj {.importc.} = object of ElementObj
    action*: cstring
    encoding*: cstring
    `method`*: cstring
    target*: cstring
    reset*: proc () {.nimcall.}
    submit*: proc () {.nimcall.}
    elements*: seq[Element]

  ImageElement* = ref ImageObj
  ImageObj {.importc.} = object of ElementObj
    border*: int
    complete*: bool
    height*: int
    hspace*: int
    lowsrc*: cstring
    src*: cstring
    vspace*: int
    width*: int


  Style* {.importc.} = object of RootObj
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

  Event* {.importc.} = object of RootObj
    target*: Node
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

  Location* {.importc.} = object of RootObj
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

  History* {.importc.} = object of RootObj
    length*: int
    back*: proc () {.nimcall.}
    forward*: proc () {.nimcall.}
    go*: proc (pagesToJump: int) {.nimcall.}

  Navigator* {.importc.} = object of RootObj
    appCodeName*: cstring
    appName*: cstring
    appVersion*: cstring
    cookieEnabled*: bool
    language*: cstring
    platform*: cstring
    userAgent*: cstring
    javaEnabled*: proc (): bool {.nimcall.}
    mimeTypes*: seq[ref MimeType]

  Plugin* {.importc.} = object of RootObj
    description*: cstring
    filename*: cstring
    name*: cstring

  MimeType* {.importc.} = object of RootObj
    description*: cstring
    enabledPlugin*: ref Plugin
    suffixes*: seq[cstring]
    `type`*: cstring

  LocationBar* {.importc.} = object of RootObj
    visible*: bool
  MenuBar* = LocationBar
  PersonalBar* = LocationBar
  ScrollBars* = LocationBar
  ToolBar* = LocationBar
  StatusBar* = LocationBar

  Screen* {.importc.} = object of RootObj
    availHeight*: int
    availWidth*: int
    colorDepth*: int
    height*: int
    pixelDepth*: int
    width*: int

  TimeOut* {.importc.} = object of RootObj
  Interval* {.importc.} = object of RootObj
{.deprecated: [TEventHandlers: EventHandlers, TEvent: Event, TNodeType: NodeType,
              TInterval: Interval, TTimeOut: TimeOut, TStatusBar: StatusBar,
              TMenuBar: MenuBar, TApplet: Applet, TLocation: Location,
              THistory: History, TNavigator: Navigator, TPlugin: Plugin,
              TMimeType: MimeType, TLocationBar: LocationBar, TPersonalBar: PersonalBar,
              TScrollBars: ScrollBars, TToolBar: ToolBar, TScreen: Screen].}

var
  window* {.importc, nodecl.}: Window
  document* {.importc, nodecl.}: Document
  navigator* {.importc, nodecl.}: ref Navigator
  screen* {.importc, nodecl.}: ref Screen

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


type
  TWindow* {.deprecated.} = WindowObj
  TFrame* {.deprecated.} = FrameObj
  TNode* {.deprecated.} = NodeObj
  TDocument* {.deprecated.} = DocumentObj
  TElement* {.deprecated.} = ElementObj
  TLink* {.deprecated.} = LinkObj
  TEmbed* {.deprecated.} = EmbedObj
  TAnchor* {.deprecated.} = AnchorObj
  TOption* {.deprecated.} = OptionObj
  TForm* {.deprecated.} = FormObj
  TImage* {.deprecated.} = ImageObj
