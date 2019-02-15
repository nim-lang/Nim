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

const
  DomApiVersion* = 3 ## the version of DOM API we try to follow. No guarantees though.

type
  EventTarget* = ref EventTargetObj
  EventTargetObj {.importc.} = object of RootObj
    onabort*: proc (event: Event) {.nimcall.}
    onblur*: proc (event: Event) {.nimcall.}
    onchange*: proc (event: Event) {.nimcall.}
    onclick*: proc (event: Event) {.nimcall.}
    ondblclick*: proc (event: Event) {.nimcall.}
    onerror*: proc (event: Event) {.nimcall.}
    onfocus*: proc (event: Event) {.nimcall.}
    onkeydown*: proc (event: Event) {.nimcall.}
    onkeypress*: proc (event: Event) {.nimcall.}
    onkeyup*: proc (event: Event) {.nimcall.}
    onload*: proc (event: Event) {.nimcall.}
    onmousedown*: proc (event: Event) {.nimcall.}
    onmousemove*: proc (event: Event) {.nimcall.}
    onmouseout*: proc (event: Event) {.nimcall.}
    onmouseover*: proc (event: Event) {.nimcall.}
    onmouseup*: proc (event: Event) {.nimcall.}
    onreset*: proc (event: Event) {.nimcall.}
    onselect*: proc (event: Event) {.nimcall.}
    onsubmit*: proc (event: Event) {.nimcall.}
    onunload*: proc (event: Event) {.nimcall.}

  # https://developer.mozilla.org/en-US/docs/Web/Events
  DomEvent* {.pure.} = enum
    Abort = "abort",
    BeforeInput = "beforeinput",
    Blur = "blur",
    Click = "click",
    CompositionEnd = "compositionend",
    CompositionStart = "compositionstart",
    CompositionUpdate = "compositionupdate",
    DblClick = "dblclick",
    Error = "error",
    Focus = "focus",
    FocusIn = "focusin",
    FocusOut = "focusout",
    Input = "input",
    KeyDown = "keydown",
    KeyPress = "keypress",
    KeyUp = "keyup",
    Load = "load",
    MouseDown = "mousedown",
    MouseEnter = "mouseenter",
    MouseLeave = "mouseleave",
    MouseMove = "mousemove",
    MouseOut = "mouseout",
    MouseOver = "mouseover",
    MouseUp = "mouseup",
    Resize = "resize",
    Scroll = "scroll",
    Select = "select",
    Unload = "unload",
    Wheel = "wheel"

  PerformanceMemory* {.importc.} = ref object
    jsHeapSizeLimit*: float
    totalJSHeapSize*: float
    usedJSHeapSize*: float

  PerformanceTiming* {.importc.} = ref object
    connectStart*: float
    domComplete*: float
    domContentLoadedEventEnd*: float
    domContentLoadedEventStart*: float
    domInteractive*: float
    domLoading*: float
    domainLookupEnd*: float
    domainLookupStart*: float
    fetchStart*: float
    loadEventEnd*: float
    loadEventStart*: float
    navigationStart*: float
    redirectEnd*: float
    redirectStart*: float
    requestStart*: float
    responseEnd*: float
    responseStart*: float
    secureConnectionStart*: float
    unloadEventEnd*: float
    unloadEventStart*: float

  Performance* {.importc.} = ref object
    memory*: PerformanceMemory
    timing*: PerformanceTiming

  Window* = ref WindowObj
  WindowObj {.importc.} = object of EventTargetObj
    document*: Document
    event*: Event
    history*: History
    location*: Location
    closed*: bool
    defaultStatus*: cstring
    devicePixelRatio*: float
    innerHeight*, innerWidth*: int
    locationbar*: ref LocationBar
    menubar*: ref MenuBar
    name*: cstring
    outerHeight*, outerWidth*: int
    pageXOffset*, pageYOffset*: int
    scrollX*: float
    scrollY*: float
    personalbar*: ref PersonalBar
    scrollbars*: ref ScrollBars
    statusbar*: ref StatusBar
    status*: cstring
    toolbar*: ref ToolBar
    frames*: seq[Frame]
    screen*: Screen
    performance*: Performance
    onpopstate*: proc (event: Event)

  Frame* = ref FrameObj
  FrameObj {.importc.} = object of WindowObj

  ClassList* = ref ClassListObj
  ClassListObj {.importc.} = object of RootObj

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
  NodeObj {.importc.} = object of EventTargetObj
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
    innerHTML*: cstring
    style*: Style

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
    anchors*: seq[AnchorElement]
    forms*: seq[FormElement]
    images*: seq[ImageElement]
    applets*: seq[Element]
    embeds*: seq[EmbedElement]
    links*: seq[LinkElement]

  Element* = ref ElementObj
  ElementObj {.importc.} = object of NodeObj
    classList*: ClassList
    checked*: bool
    defaultChecked*: bool
    defaultValue*: cstring
    disabled*: bool
    form*: FormElement
    name*: cstring
    readOnly*: bool
    options*: seq[OptionElement]
    selectedOptions*: seq[OptionElement]
    clientWidth*, clientHeight*: int
    contentEditable*: cstring
    isContentEditable*: bool
    dir*: cstring
    offsetHeight*: int
    offsetWidth*: int
    offsetLeft*: int
    offsetTop*: int

  # https://developer.mozilla.org/en-US/docs/Web/API/ValidityState
  ValidityState* = ref ValidityStateObj
  ValidityStateObj {.importc.} = object
    badInput*: bool
    customError*: bool
    patternMismatch*: bool
    rangeOverflow*: bool
    rangeUnderflow*: bool
    stepMismatch*: bool
    tooLong*: bool
    tooShort*: bool
    typeMismatch*: bool
    valid*: bool
    valueMissing*: bool

  # https://developer.mozilla.org/en-US/docs/Web/API/Blob
  Blob* = ref BlobObj
  BlobObj {.importc.} = object of RootObj
    size*: int
    `type`*: cstring

  # https://developer.mozilla.org/en-US/docs/Web/API/File
  File* = ref FileObj
  FileObj {.importc.} = object of Blob
    lastModified*: int
    name*: cstring

  # https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement
  InputElement* = ref InputElementObj
  InputElementObj {.importc.} = object of Element
    # Properties related to the parent form
    formAction*: cstring
    formEncType*: cstring
    formMethod*: cstring
    formNoValidate*: bool
    formTarget*: cstring

    # Properties that apply to any type of input element that is not hidden
    `type`*: cstring
    autofocus*: bool
    required*: bool
    value*: cstring
    validity*: ValidityState
    validationMessage*: cstring
    willValidate*: bool

    # Properties that apply only to elements of type "checkbox" or "radio"
    indeterminate*: bool

    # Properties that apply only to elements of type "image"
    alt*: cstring
    height*: cstring
    src*: cstring
    width*: cstring

    # Properties that apply only to elements of type "file"
    accept*: cstring
    files*: seq[Blob]

    # Properties that apply only to text/number-containing or elements
    autocomplete*: cstring
    maxLength*: int
    size*: int
    pattern*: cstring
    placeholder*: cstring
    min*: cstring
    max*: cstring
    selectionStart*: int
    selectionEnd*: int
    selectionDirection*: cstring

    # Properties not yet categorized
    dirName*: cstring
    accessKey*: cstring
    list*: Element
    multiple*: bool
    labels*: seq[Element]
    step*: cstring
    valueAsDate*: cstring
    valueAsNumber*: float

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

  AnchorElement* = ref AnchorObj
  AnchorObj {.importc.} = object of ElementObj
    text*: cstring
    x*, y*: int

  OptionElement* = ref OptionObj
  OptionObj {.importc.} = object of ElementObj
    defaultSelected*: bool
    selected*: bool
    selectedIndex*: int
    text*: cstring
    value*: cstring

  # https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement
  FormElement* = ref FormObj
  FormObj {.importc.} = object of ElementObj
    acceptCharset*: cstring
    action*: cstring
    autocomplete*: cstring
    elements*: seq[Element]
    encoding*: cstring
    enctype*: cstring
    length*: int
    `method`*: cstring
    noValidate*: bool
    target*: cstring

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

  Style* = ref StyleObj
  StyleObj {.importc.} = object of RootObj
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
    pointerEvents*: cstring
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
    transform*: cstring
    top*: cstring
    verticalAlign*: cstring
    visibility*: cstring
    width*: cstring
    wordSpacing*: cstring
    zIndex*: int

  EventPhase* = enum
    None = 0,
    CapturingPhase,
    AtTarget,
    BubblingPhase

  # https://developer.mozilla.org/en-US/docs/Web/API/Event
  Event* = ref EventObj
  EventObj {.importc.} = object of RootObj
    bubbles*: bool
    cancelBubble*: bool
    cancelable*: bool
    composed*: bool
    currentTarget*: Node
    defaultPrevented*: bool
    eventPhase*: int
    target*: Node
    `type`*: cstring
    isTrusted*: bool

  # https://developer.mozilla.org/en-US/docs/Web/API/UIEvent
  UIEvent* = ref UIEventObj
  UIEventObj {.importc.} = object of Event
    detail*: int64
    view*: Window

  # https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent
  KeyboardEvent* = ref KeyboardEventObj
  KeyboardEventObj {.importc.} = object of UIEvent
    altKey*, ctrlKey*, metaKey*, shiftKey*: bool
    code*: cstring
    isComposing*: bool
    key*: cstring
    keyCode*: int
    location*: int

  # https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key/Key_Values
  KeyboardEventKey* {.pure.} = enum
    # Modifier keys
    Alt,
    AltGraph,
    CapsLock,
    Control,
    Fn,
    FnLock,
    Hyper,
    Meta,
    NumLock,
    ScrollLock,
    Shift,
    Super,
    Symbol,
    SymbolLock,

    # Whitespace keys
    ArrowDown,
    ArrowLeft,
    ArrowRight,
    ArrowUp,
    End,
    Home,
    PageDown,
    PageUp,

    # Editing keys
    Backspace,
    Clear,
    Copy,
    CrSel,
    Cut,
    Delete,
    EraseEof,
    ExSel,
    Insert,
    Paste,
    Redo,
    Undo,

    # UI keys
    Accept,
    Again,
    Attn,
    Cancel,
    ContextMenu,
    Escape,
    Execute,
    Find,
    Finish,
    Help,
    Pause,
    Play,
    Props,
    Select,
    ZoomIn,
    ZoomOut,

    # Device keys
    BrigtnessDown,
    BrigtnessUp,
    Eject,
    LogOff,
    Power,
    PowerOff,
    PrintScreen,
    Hibernate,
    Standby,
    WakeUp,

    # Common IME keys
    AllCandidates,
    Alphanumeric,
    CodeInput,
    Compose,
    Convert,
    Dead,
    FinalMode,
    GroupFirst,
    GroupLast,
    GroupNext,
    GroupPrevious,
    ModeChange,
    NextCandidate,
    NonConvert,
    PreviousCandidate,
    Process,
    SingleCandidate,

    # Korean keyboards only
    HangulMode,
    HanjaMode,
    JunjaMode,

    # Japanese keyboards only
    Eisu,
    Hankaku,
    Hiragana,
    HiraganaKatakana,
    KanaMode,
    KanjiMode,
    Katakana,
    Romaji,
    Zenkaku,
    ZenkakuHanaku,

    # Function keys
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
    F13,
    F14,
    F15,
    F16,
    F17,
    F18,
    F19,
    F20,
    Soft1,
    Soft2,
    Soft3,
    Soft4,

    # Phone keys
    AppSwitch,
    Call,
    Camera,
    CameraFocus,
    EndCall,
    GoBack,
    GoHome,
    HeadsetHook,
    LastNumberRedial,
    Notification,
    MannerMode,
    VoiceDial,

    # Multimedia keys
    ChannelDown,
    ChannelUp,
    MediaFastForward,
    MediaPause,
    MediaPlay,
    MediaPlayPause,
    MediaRecord,
    MediaRewind,
    MediaStop,
    MediaTrackNext,
    MediaTrackPrevious,

    # Audio control keys
    AudioBalanceLeft,
    AudioBalanceRight,
    AudioBassDown,
    AudioBassBoostDown,
    AudioBassBoostToggle,
    AudioBassBoostUp,
    AudioBassUp,
    AudioFaderFront,
    AudioFaderRear,
    AudioSurroundModeNext,
    AudioTrebleDown,
    AudioTrebleUp,
    AudioVolumeDown,
    AUdioVolumeMute,
    AudioVolumeUp,
    MicrophoneToggle,
    MicrophoneVolumeDown,
    MicrophoneVolumeMute,
    MicrophoneVolumeUp,

    # TV control keys
    TV,
    TV3DMode,
    TVAntennaCable,
    TVAudioDescription,
    TVAudioDescriptionMixDown,
    TVAudioDescriptionMixUp,
    TVContentsMenu,
    TVDataService,
    TVInput,
    TVInputComponent1,
    TVInputComponent2,
    TVInputComposite1,
    TVInputComposite2,
    TVInputHDMI1,
    TVInputHDMI2,
    TVInputHDMI3,
    TVInputHDMI4,
    TVInputVGA1,
    TVMediaContext,
    TVNetwork,
    TVNumberEntry,
    TVPower,
    TVRadioService,
    TVSatellite,
    TVSatelliteBS,
    TVSatelliteCS,
    TVSatelliteToggle,
    TVTerrestrialAnalog,
    TVTerrestrialDigital,
    TVTimer,

    # Media controller keys
    AVRInput,
    AVRPower,
    ColorF0Red,
    ColorF1Green,
    ColorF2Yellow,
    ColorF3Blue,
    ColorF4Grey,
    ColorF5Brown,
    ClosedCaptionToggle,
    Dimmer,
    DisplaySwap,
    DVR,
    Exit,
    FavoriteClear0,
    FavoriteClear1,
    FavoriteClear2,
    FavoriteClear3,
    FavoriteRecall0,
    FavoriteRecall1,
    FavoriteRecall2,
    FavoriteRecall3,
    FavoriteStore0,
    FavoriteStore1,
    FavoriteStore2,
    FavoriteStore3,
    Guide,
    GuideNextDay,
    GuidePreviousDay,
    Info,
    InstantReplay,
    Link,
    ListProgram,
    LiveContent,
    Lock,
    MediaApps,
    MediaAudioTrack,
    MediaLast,
    MediaSkipBackward,
    MediaSkipForward,
    MediaStepBackward,
    MediaStepForward,
    MediaTopMenu,
    NavigateIn,
    NavigateNext,
    NavigateOut,
    NavigatePrevious,
    NextFavoriteChannel,
    NextUserProfile,
    OnDemand,
    Pairing,
    PinPDown,
    PinPMove,
    PinPUp,
    PlaySpeedDown,
    PlaySpeedReset,
    PlaySpeedUp,
    RandomToggle,
    RcLowBattery,
    RecordSpeedNext,
    RfBypass,
    ScanChannelsToggle,
    ScreenModeNext,
    Settings,
    SplitScreenToggle,
    STBInput,
    STBPower,
    Subtitle,
    Teletext,
    VideoModeNext,
    Wink,
    ZoomToggle,

    # Speech recognition keys
    SpeechCorrectionList,
    SpeechInputToggle,

    # Document keys
    Close,
    New,
    Open,
    Print,
    Save,
    SpellCheck,
    MailForward,
    MailReply,
    MailSend,

    # Application selector keys
    LaunchCalculator,
    LaunchCalendar,
    LaunchContacts,
    LaunchMail,
    LaunchMediaPlayer,
    LaunchMusicPlayer,
    LaunchMyComputer,
    LaunchPhone,
    LaunchScreenSaver,
    LaunchSpreadsheet,
    LaunchWebBrowser,
    LaunchWebCam,
    LaunchWordProcessor,
    LaunchApplication1,
    LaunchApplication2,
    LaunchApplication3,
    LaunchApplication4,
    LaunchApplication5,
    LaunchApplication6,
    LaunchApplication7,
    LaunchApplication8,
    LaunchApplication9,
    LaunchApplication10,
    LaunchApplication11,
    LaunchApplication12,
    LaunchApplication13,
    LaunchApplication14,
    LaunchApplication15,
    LaunchApplication16,

    # Browser control keys
    BrowserBack,
    BrowserFavorites,
    BrowserForward,
    BrowserHome,
    BrowserRefresh,
    BrowserSearch,
    BrowserStop,

    # Numeric keypad keys
    Key11,
    Key12,
    Separator

  MouseButtons* = enum
    NoButton = 0,
    PrimaryButton = 1,
    SecondaryButton = 2,
    AuxilaryButton = 4,
    FourthButton = 8,
    FifthButton = 16

  # https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent
  MouseEvent* = ref MouseEventObj
  MouseEventObj {.importc.} = object of UIEvent
    altKey*, ctrlKey*, metaKey*, shiftKey*: bool
    button*: int
    buttons*: int
    clientX*, clientY*: int
    movementX*, movementY*: int
    offsetX*, offsetY*: int
    pageX*, pageY*: int
    relatedTarget*: EventTarget
    #region*: cstring
    screenX*, screenY*: int
    x*, y*: int

  DataTransferItemKind* {.pure.} = enum
    File = "file",
    String = "string"

  # https://developer.mozilla.org/en-US/docs/Web/API/DataTransferItem
  DataTransferItem* = ref DataTransferItemObj
  DataTransferItemObj {.importc.} = object of RootObj
    kind*: cstring
    `type`*: cstring

  # https://developer.mozilla.org/en-US/docs/Web/API/DataTransfer
  DataTransfer* = ref DataTransferObj
  DataTransferObj {.importc.} = object of RootObj
    dropEffect*: cstring
    effectAllowed*: cstring
    files*: seq[Element]
    items*: seq[DataTransferItem]
    types*: seq[cstring]

  DataTransferDropEffect* {.pure.} = enum
    None = "none",
    Copy = "copy",
    Link = "link",
    Move = "move"

  DataTransferEffectAllowed* {.pure.} = enum
    None = "none",
    Copy = "copy",
    CopyLink = "copyLink",
    CopyMove = "copyMove",
    Link = "link",
    LinkMove = "linkMove",
    Move = "move",
    All = "all",
    Uninitialized = "uninitialized"

  DragEventTypes* = enum
    Drag = "drag",
    DragEnd = "dragend",
    DragEnter = "dragenter",
    DragExit = "dragexit",
    DragLeave = "dragleave",
    DragOver = "dragover",
    DragStart = "dragstart",
    Drop = "drop"

  # https://developer.mozilla.org/en-US/docs/Web/API/DragEvent
  DragEvent* {.importc.} = object of MouseEvent
    dataTransfer*: DataTransfer

  TouchList* {.importc.} = ref object of RootObj
    length*: int

  Touch* = ref TouchObj
  TouchObj {.importc.} = object of RootObj
    identifier*: int
    screenX*, screenY*, clientX*, clientY*, pageX*, pageY*: int
    target*: Element
    radiusX*, radiusY*: int
    rotationAngle*: int
    force*: float

  TouchEvent* = ref TouchEventObj
  TouchEventObj {.importc.} = object of UIEvent
    changedTouches*, targetTouches*, touches*: seq[Touch]

  Location* = ref LocationObj
  LocationObj {.importc.} = object of RootObj
    hash*: cstring
    host*: cstring
    hostname*: cstring
    href*: cstring
    pathname*: cstring
    port*: cstring
    protocol*: cstring
    search*: cstring

  History* = ref HistoryObj
  HistoryObj {.importc.} = object of RootObj
    length*: int

  Navigator* = ref NavigatorObj
  NavigatorObj {.importc.} = object of RootObj
    appCodeName*: cstring
    appName*: cstring
    appVersion*: cstring
    cookieEnabled*: bool
    language*: cstring
    platform*: cstring
    userAgent*: cstring
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

  Screen = ref ScreenObj
  ScreenObj {.importc.} = object of RootObj
    availHeight*: int
    availWidth*: int
    colorDepth*: int
    height*: int
    pixelDepth*: int
    width*: int

  TimeOut* {.importc.} = ref object of RootObj
  Interval* {.importc.} = object of RootObj

  AddEventListenerOptions* = object
    capture*: bool
    once*: bool
    passive*: bool

proc id*(n: Node): cstring {.importcpp: "#.id", nodecl.}
proc `id=`*(n: Node; x: cstring) {.importcpp: "#.id = #", nodecl.}
proc class*(n: Node): cstring {.importcpp: "#.className", nodecl.}
proc `class=`*(n: Node; v: cstring) {.importcpp: "#.className = #", nodecl.}

proc value*(n: Node): cstring {.importcpp: "#.value", nodecl.}
proc `value=`*(n: Node; v: cstring) {.importcpp: "#.value = #", nodecl.}

proc `disabled=`*(n: Node; v: bool) {.importcpp: "#.disabled = #", nodecl.}

when defined(nodejs):
  # we provide a dummy DOM for nodejs for testing purposes
  proc len*(x: Node): int = x.childNodes.len
  proc `[]`*(x: Node; idx: int): Element =
    assert idx >= 0 and idx < x.childNodes.len
    result = cast[Element](x.childNodes[idx])

  var document* = Document(nodeType: DocumentNode)

  proc getElem(x: Element; id: cstring): Element =
    if x.id == id: return x
    for i in 0..<x.len:
      result = getElem(x[i], id)
      if result != nil: return result

  proc getElementById*(doc: Document; id: cstring): Element =
    getElem(doc.body, id)
  proc getElementById*(id: cstring): Element = document.getElementById(id)

  proc appendChild*(parent, n: Node) =
    n.parentNode = parent
    parent.childNodes.add n

  proc replaceChild*(parent, newNode, oldNode: Node) =
    newNode.parentNode = parent
    oldNode.parentNode = nil
    var i = 0
    while i < parent.len:
      if Node(parent[i]) == oldNode:
        parent.childNodes[i] = newNode
        return
      inc i
    doAssert false, "old node not in node list"

  proc removeChild*(parent, child: Node) =
    child.parentNode = nil
    var i = 0
    while i < parent.len:
      if Node(parent[i]) == child:
        parent.childNodes.delete(i)
        return
      inc i
    doAssert false, "old node not in node list"

  proc insertBefore*(parent, newNode, before: Node) =
    appendChild(parent, newNode)
    var i = 0
    while i < parent.len-1:
      if Node(parent[i]) == before:
        for j in countdown(parent.len-1, i-1):
          parent.childNodes[j] = parent.childNodes[j-1]
        parent.childNodes[i-1] = newNode
        return
      inc i
    #doAssert false, "before not in node list"

  proc createElement*(d: Document, identifier: cstring): Element =
    new(result)
    result.nodeName = identifier
    result.nodeType = NodeType.ElementNode

  proc createTextNode*(d: Document, identifier: cstring): Node =
    new(result)
    result.nodeName = "#text"
    result.nodeValue = identifier
    result.nodeType = NodeType.TextNode

else:
  proc len*(x: Node): int {.importcpp: "#.childNodes.length".}
  proc `[]`*(x: Node; idx: int): Element {.importcpp: "#.childNodes[#]".}
  proc getElementById*(id: cstring): Element {.importc: "document.getElementById", nodecl.}
  proc appendChild*(n, child: Node) {.importcpp.}
  proc removeChild*(n, child: Node) {.importcpp.}
  proc replaceChild*(n, newNode, oldNode: Node) {.importcpp.}
  proc insertBefore*(n, newNode, before: Node) {.importcpp.}
  proc getElementById*(d: Document, id: cstring): Element {.importcpp.}
  proc createElement*(d: Document, identifier: cstring): Element {.importcpp.}
  proc createTextNode*(d: Document, identifier: cstring): Node {.importcpp.}

proc setTimeout*(action: proc(); ms: int): Timeout {.importc, nodecl.}
proc clearTimeout*(t: Timeout) {.importc, nodecl.}

{.push importcpp.}

# EventTarget "methods"
proc addEventListener*(et: EventTarget, ev: cstring, cb: proc(ev: Event), useCapture: bool = false)
proc addEventListener*(et: EventTarget, ev: cstring, cb: proc(ev: Event), options: AddEventListenerOptions)
proc dispatchEvent*(et: EventTarget, ev: Event)
proc removeEventListener*(et: EventTarget; ev: cstring; cb: proc(ev: Event))

# Window "methods"
proc alert*(w: Window, msg: cstring)
proc back*(w: Window)
proc blur*(w: Window)
proc captureEvents*(w: Window, eventMask: int) {.deprecated.}
proc clearInterval*(w: Window, interval: ref Interval)
proc clearTimeout*(w: Window, timeout: ref TimeOut)
proc close*(w: Window)
proc confirm*(w: Window, msg: cstring): bool
proc disableExternalCapture*(w: Window)
proc enableExternalCapture*(w: Window)
proc find*(w: Window, text: cstring, caseSensitive = false,
           backwards = false)
proc focus*(w: Window)
proc forward*(w: Window)
proc getComputedStyle*(w: Window, e: Node, pe:Node = nil): Style
proc handleEvent*(w: Window, e: Event)
proc home*(w: Window)
proc moveBy*(w: Window, x, y: int)
proc moveTo*(w: Window, x, y: int)
proc open*(w: Window, uri, windowname: cstring,
           properties: cstring = nil): Window
proc print*(w: Window)
proc prompt*(w: Window, text, default: cstring): cstring
proc releaseEvents*(w: Window, eventMask: int) {.deprecated.}
proc resizeBy*(w: Window, x, y: int)
proc resizeTo*(w: Window, x, y: int)
proc routeEvent*(w: Window, event: Event)
proc scrollBy*(w: Window, x, y: int)
proc scrollTo*(w: Window, x, y: int)
proc setInterval*(w: Window, code: cstring, pause: int): ref Interval
proc setInterval*(w: Window, function: proc (), pause: int): ref Interval
proc setTimeout*(w: Window, code: cstring, pause: int): ref TimeOut
proc setTimeout*(w: Window, function: proc (), pause: int): ref Interval
proc stop*(w: Window)
proc requestAnimationFrame*(w: Window, function: proc (time: float)): int
proc cancelAnimationFrame*(w: Window, id: int)

# Node "methods"
proc appendData*(n: Node, data: cstring)
proc cloneNode*(n: Node, copyContent: bool): Node
proc deleteData*(n: Node, start, len: int)
proc focus*(e: Node)
proc getAttribute*(n: Node, attr: cstring): cstring
proc getAttributeNode*(n: Node, attr: cstring): Node
proc hasChildNodes*(n: Node): bool
proc insertData*(n: Node, position: int, data: cstring)
proc removeAttribute*(n: Node, attr: cstring)
proc removeAttributeNode*(n, attr: Node)
proc replaceData*(n: Node, start, len: int, text: cstring)
proc scrollIntoView*(n: Node)
proc setAttribute*(n: Node, name, value: cstring)
proc setAttributeNode*(n: Node, attr: Node)

# Document "methods"
proc captureEvents*(d: Document, eventMask: int) {.deprecated.}
proc createAttribute*(d: Document, identifier: cstring): Node
proc getElementsByName*(d: Document, name: cstring): seq[Element]
proc getElementsByTagName*(d: Document, name: cstring): seq[Element]
proc getElementsByClassName*(d: Document, name: cstring): seq[Element]
proc getSelection*(d: Document): cstring
proc handleEvent*(d: Document, event: Event)
proc open*(d: Document)
proc releaseEvents*(d: Document, eventMask: int) {.deprecated.}
proc routeEvent*(d: Document, event: Event)
proc write*(d: Document, text: cstring)
proc writeln*(d: Document, text: cstring)
proc querySelector*(d: Document, selectors: cstring): Element
proc querySelectorAll*(d: Document, selectors: cstring): seq[Element]

# Element "methods"
proc blur*(e: Element)
proc click*(e: Element)
proc focus*(e: Element)
proc handleEvent*(e: Element, event: Event)
proc select*(e: Element)
proc getElementsByTagName*(e: Element, name: cstring): seq[Element]
proc getElementsByClassName*(e: Element, name: cstring): seq[Element]

# FormElement "methods"
proc reset*(f: FormElement)
proc submit*(f: FormElement)
proc checkValidity*(e: FormElement): bool
proc reportValidity*(e: FormElement): bool

# EmbedElement "methods"
proc play*(e: EmbedElement)
proc stop*(e: EmbedElement)

# Location "methods"
proc reload*(loc: Location)
proc replace*(loc: Location, s: cstring)

# History "methods"
proc back*(h: History)
proc forward*(h: History)
proc go*(h: History, pagesToJump: int)
proc pushState*[T](h: History, stateObject: T, title, url: cstring)

# Navigator "methods"
proc javaEnabled*(h: Navigator): bool

# ClassList "methods"
proc add*(c: ClassList, class: cstring)
proc remove*(c: ClassList, class: cstring)
proc contains*(c: ClassList, class: cstring): bool
proc toggle*(c: ClassList, class: cstring)

# Style "methods"
proc getPropertyValue*(s: Style, property: cstring): cstring
proc removeProperty*(s: Style, property: cstring)
proc setProperty*(s: Style, property, value: cstring, priority = "")
proc getPropertyPriority*(s: Style, property: cstring): cstring

# Event "methods"
proc preventDefault*(ev: Event)
proc stopImmediatePropagation*(ev: Event)
proc stopPropagation*(ev: Event)

# KeyboardEvent "methods"
proc getModifierState*(ev: KeyboardEvent, keyArg: cstring): bool

# MouseEvent "methods"
proc getModifierState*(ev: MouseEvent, keyArg: cstring): bool

# TouchEvent "methods"
proc identifiedTouch*(list: TouchList): Touch
proc item*(list: TouchList, i: int): Touch

# DataTransfer "methods"
proc clearData*(dt: DataTransfer, format: cstring)
proc getData*(dt: DataTransfer, format: cstring): cstring
proc setData*(dt: DataTransfer, format: cstring, data: cstring)
proc setDragImage*(dt: DataTransfer, img: Element, xOffset: int64, yOffset: int64)

# DataTransferItem "methods"
proc getAsFile*(dti: DataTransferItem): File

# InputElement "methods"
proc setSelectionRange*(e: InputElement, selectionStart: int, selectionEnd: int, selectionDirection: cstring = "none")
proc setRangeText*(e: InputElement, replacement: cstring, startindex: int = 0, endindex: int = 0, selectionMode: cstring = "preserve")
proc setCustomValidity*(e: InputElement, error: cstring)
proc checkValidity*(e: InputElement): bool

# Blob "methods"
proc slice*(e: Blob, startindex: int = 0, endindex: int = e.size, contentType: cstring = "")

{.pop.}

proc setAttr*(n: Node; key, val: cstring) {.importcpp: "#.setAttribute(@)".}

var
  window* {.importc, nodecl.}: Window
  navigator* {.importc, nodecl.}: Navigator
  screen* {.importc, nodecl.}: Screen

when not defined(nodejs):
  var document* {.importc, nodecl.}: Document

proc decodeURI*(uri: cstring): cstring {.importc, nodecl.}
proc encodeURI*(uri: cstring): cstring {.importc, nodecl.}

proc escape*(uri: cstring): cstring {.importc, nodecl.}
proc unescape*(uri: cstring): cstring {.importc, nodecl.}

proc decodeURIComponent*(uri: cstring): cstring {.importc, nodecl.}
proc encodeURIComponent*(uri: cstring): cstring {.importc, nodecl.}
proc isFinite*(x: BiggestFloat): bool {.importc, nodecl.}
proc isNaN*(x: BiggestFloat): bool {.importc, nodecl.}

proc newEvent*(name: cstring): Event {.importcpp: "new Event(@)", constructor.}

proc getElementsByClass*(n: Node; name: cstring): seq[Node] {.
  importcpp: "#.getElementsByClassName(#)", nodecl.}


type
  BoundingRect* {.importc.} = object
    top*, bottom*, left*, right*, x*, y*, width*, height*: float

proc getBoundingClientRect*(e: Node): BoundingRect {.
  importcpp: "getBoundingClientRect", nodecl.}
proc clientHeight*(): int {.
  importcpp: "(window.innerHeight || document.documentElement.clientHeight)@", nodecl.}
proc clientWidth*(): int {.
  importcpp: "(window.innerWidth || document.documentElement.clientWidth)@", nodecl.}

proc inViewport*(el: Node): bool =
  let rect = el.getBoundingClientRect()
  result = rect.top >= 0 and rect.left >= 0 and
           rect.bottom <= clientHeight().float and
           rect.right <= clientWidth().float

proc scrollTop*(e: Node): int {.importcpp: "#.scrollTop", nodecl.}
proc scrollLeft*(e: Node): int {.importcpp: "#.scrollLeft", nodecl.}
proc scrollHeight*(e: Node): int {.importcpp: "#.scrollHeight", nodecl.}
proc scrollWidth*(e: Node): int {.importcpp: "#.scrollWidth", nodecl.}
proc offsetHeight*(e: Node): int {.importcpp: "#.offsetHeight", nodecl.}
proc offsetWidth*(e: Node): int {.importcpp: "#.offsetWidth", nodecl.}
proc offsetTop*(e: Node): int {.importcpp: "#.offsetTop", nodecl.}
proc offsetLeft*(e: Node): int {.importcpp: "#.offsetLeft", nodecl.}
