#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Declaration of the Document Object Model for the ECMAScript backend.

when not defined(ecmascript):
  {.error: "This module only works on the ECMAScript platform".}

type
  TEventHandlers* {.importc.} = object of TObject
    onabort*: proc (event: ref TEvent)
    onblur*: proc (event: ref TEvent)
    onchange*: proc (event: ref TEvent)
    onclick*: proc (event: ref TEvent)
    ondblclick*: proc (event: ref TEvent)
    onerror*: proc (event: ref TEvent)
    onfocus*: proc (event: ref TEvent)
    onkeydown*: proc (event: ref TEvent)
    onkeypress*: proc (event: ref TEvent)
    onkeyup*: proc (event: ref TEvent)
    onload*: proc (event: ref TEvent)
    onmousedown*: proc (event: ref TEvent)
    onmousemove*: proc (event: ref TEvent)
    onmouseout*: proc (event: ref TEvent)
    onmouseover*: proc (event: ref TEvent)
    onmouseup*: proc (event: ref TEvent)
    onreset*: proc (event: ref TEvent)
    onselect*: proc (event: ref TEvent)
    onsubmit*: proc (event: ref TEvent)
    onunload*: proc (event: ref TEvent)

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

    alert*: proc (msg: cstring)
    back*: proc ()
    blur*: proc ()
    captureEvents*: proc (eventMask: int)
    clearInterval*: proc (interval: ref TInterval)
    clearTimeout*: proc (timeout: ref TTimeOut)
    close*: proc ()
    confirm*: proc (msg: cstring): bool
    disableExternalCapture*: proc ()
    enableExternalCapture*: proc ()
    find*: proc (text: cstring, caseSensitive = false, backwards = false)
    focus*: proc ()
    forward*: proc ()
    handleEvent*: proc (e: ref TEvent)
    home*: proc ()
    moveBy*: proc (x, y: int)
    moveTo*: proc (x, y: int)
    open*: proc (uri, windowname: cstring,
                 properties: cstring = nil): ref TWindow
    print*: proc ()
    prompt*: proc (text, default: cstring): cstring
    releaseEvents*: proc (eventMask: int)
    resizeBy*: proc (x, y: int)
    resizeTo*: proc (x, y: int)
    routeEvent*: proc (event: ref TEvent)
    scrollBy*: proc (x, y: int)
    scrollTo*: proc (x, y: int)
    setInterval*: proc (code: cstring, pause: int): ref TInterval
    setTimeout*: proc (code: cstring, pause: int): ref TTimeOut
    stop*: proc ()
    frames*: seq[TFrame]

  TFrame* {.importc.} = object of TWindow

  TDocument* {.importc.} = object of TEventHandlers
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
    captureEvents*: proc (eventMask: int)
    createAttribute*: proc (identifier: cstring): ref TNode
    createElement*: proc (identifier: cstring): ref TNode
    createTextNode*: proc (identifier: cstring): ref TNode
    getElementById*: proc (id: cstring): ref TNode
    getElementsByName*: proc (name: cstring): seq[ref TNode]
    getElementsByTagName*: proc (name: cstring): seq[ref TNode]
    getSelection*: proc (): cstring
    handleEvent*: proc (event: ref TEvent)
    open*: proc ()
    releaseEvents*: proc (eventMask: int)
    routeEvent*: proc (event: ref TEvent)
    write*: proc (text: cstring)
    writeln*: proc (text: cstring)
    anchors*: seq[ref TAnchor]
    forms*: seq[ref TForm]
    images*: seq[ref TImage]
    applets*: seq[ref TApplet]
    embeds*: seq[ref TEmbed]
    links*: seq[ref TLink]

  TLink* {.importc.} = object of TObject
    name*: cstring
    target*: cstring
    text*: cstring
    x*: int
    y*: int

  TEmbed* {.importc.} = object of TObject
    height*: int
    hspace*: int
    name*: cstring
    src*: cstring
    width*: int
    `type`*: cstring
    vspace*: int
    play*: proc ()
    stop*: proc ()

  TAnchor* {.importc.} = object of TObject
    name*: cstring
    text*: cstring
    x*, y*: int

  TApplet* {.importc.} = object of TObject

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
    blur*: proc ()
    click*: proc ()
    focus*: proc ()
    handleEvent*: proc (event: ref TEvent)
    select*: proc ()
    options*: seq[ref TOption]

  TOption* {.importc.} = object of TObject
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
    handleEvent*: proc (event: ref TEvent)
    reset*: proc ()
    submit*: proc ()
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
    handleEvent*: proc (event: ref TEvent)

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
    appendChild*: proc (child: ref TNode)
    appendData*: proc (data: cstring)
    cloneNode*: proc (copyContent: bool)
    deleteData*: proc (start, len: int)
    getAttribute*: proc (attr: cstring): cstring
    getAttributeNode*: proc (attr: cstring): ref TNode
    getElementsByTagName*: proc (): seq[ref TNode]
    hasChildNodes*: proc (): bool
    innerHTML*: cstring
    insertBefore*: proc (newNode, before: ref TNode)
    insertData*: proc (position: int, data: cstring)
    removeAttribute*: proc (attr: cstring)
    removeAttributeNode*: proc (attr: ref TNode)
    removeChild*: proc (child: ref TNode)
    replaceChild*: proc (newNode, oldNode: ref TNode)
    replaceData*: proc (start, len: int, text: cstring)
    setAttribute*: proc (name, value: cstring)
    setAttributeNode*: proc (attr: ref TNode)
    style*: ref TStyle

  TStyle* {.importc.} = object of TObject
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
    getAttribute*: proc (attr: cstring, caseSensitive=false): cstring
    removeAttribute*: proc (attr: cstring, caseSensitive=false)
    setAttribute*: proc (attr, value: cstring, caseSensitive=false)

  TEvent* {.importc.} = object of TObject
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

  TLocation* {.importc.} = object of TObject
    hash*: cstring
    host*: cstring
    hostname*: cstring
    href*: cstring
    pathname*: cstring
    port*: cstring
    protocol*: cstring
    search*: cstring
    reload*: proc ()
    replace*: proc (s: cstring)

  THistory* {.importc.} = object of TObject
    length*: int
    back*: proc ()
    forward*: proc ()
    go*: proc (pagesToJump: int)

  TNavigator* {.importc.} = object of TObject
    appCodeName*: cstring
    appName*: cstring
    appVersion*: cstring
    cookieEnabled*: bool
    language*: cstring
    platform*: cstring
    userAgent*: cstring
    javaEnabled*: proc (): bool
    mimeTypes*: seq[ref TMimeType]

  TPlugin* {.importc.} = object of TObject
    description*: cstring
    filename*: cstring
    name*: cstring

  TMimeType* {.importc.} = object of TObject
    description*: cstring
    enabledPlugin*: ref TPlugin
    suffixes*: seq[cstring]
    `type`*: cstring

  TLocationBar* {.importc.} = object of TObject
    visible*: bool
  TMenuBar* = TLocationBar
  TPersonalBar* = TLocationBar
  TScrollBars* = TLocationBar
  TToolBar* = TLocationBar
  TStatusBar* = TLocationBar

  TScreen* {.importc.} = object of TObject
    availHeight*: int
    availWidth*: int
    colorDepth*: int
    height*: int
    pixelDepth*: int
    width*: int

  TTimeOut* {.importc.} = object of TObject
  TInterval* {.importc.} = object of TObject

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
proc isFinite*(x: biggestFloat): bool {.importc, nodecl.}
proc isNaN*(x: biggestFloat): bool {.importc, nodecl.}
proc parseFloat*(s: cstring): biggestFloat {.importc, nodecl.}
proc parseInt*(s: cstring): int {.importc, nodecl.}
