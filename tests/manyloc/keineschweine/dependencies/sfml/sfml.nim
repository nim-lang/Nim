import
  strutils, math
when defined(linux):
  const
    LibG = "libcsfml-graphics.so.2.0"
    LibS = "libcsfml-system.so.2.0"
    LibW = "libcsfml-window.so.2.0"
else:
  # We only compile for testing here, so it doesn't matter it's not supported
  const
    LibG = "libcsfml-graphics.so.2.0"
    LibS = "libcsfml-system.so.2.0"
    LibW = "libcsfml-window.so.2.0"
  #{.error: "Platform unsupported".}

{.pragma: pf, pure, final.}
type
  PClock* = ptr TClock
  TClock* {.pf.} = object
  TTime* {.pf.} = object
    microseconds*: int64
  TVector2i* {.pf.} = object
    x*, y*: cint
  TVector2f* {.pf.} = object
    x*, y*: cfloat
  TVector3f* {.pf.} = object
    x*, y*, z*: cfloat

  PInputStream* = ptr TInputStream
  TInputStream* {.pf.} = object
    read*: TInputStreamReadFunc
    seek*: TInputStreamSeekFunc
    tell*: TInputStreamTellFunc
    getSize*: TInputStreamGetSizeFunc
    userData*: pointer
  TInputStreamReadFunc* = proc (data: pointer, size: int64, userData: pointer): int64{.
    cdecl.}
  TInputStreamSeekFunc* = proc (position: int16, userData: pointer): int64{.
    cdecl.}
  TInputStreamTellFunc* = proc (userData: pointer): int64 {.cdecl.}
  TInputStreamGetSizeFunc* = proc (userData: pointer): int64 {.cdecl.}
  PWindow* = ptr TWindow
  TWindow* {.pf.} = object
  PContextSettings* = ptr TContextSettings
  TContextSettings*{.pf.} = object
    depthBits: cint
    stencilBits: cint
    antialiasingLevel: cint
    majorVersion: cint
    minorVersion: cint
  TVideoMode* {.pf.} = object
    width*: cint
    height*: cint
    bitsPerPixel*: cint
  TEventType*{.size: sizeof(cint).} = enum
    EvtClosed, EvtResized, EvtLostFocus, EvtGainedFocus,
    EvtTextEntered, EvtKeyPressed, EvtKeyReleased, EvtMouseWheelMoved,
    EvtMouseButtonPressed, EvtMouseButtonReleased, EvtMouseMoved,
    EvtMouseEntered, EvtMouseLeft, EvtJoystickButtonPressed,
    EvtJoystickButtonReleased, EvtJoystickMoved, EvtJoystickConnected,
    EvtJoystickDisconnected
  TKeyEvent*{.pf.} = object
    code*: TKeyCode
    alt*    : bool
    control*: bool
    shift*  : bool
    system* : bool
  TJoystickConnectEvent*{.pf.} = object
    joystickId*: cint
  TJoystickButtonEvent*{.pf.} = object
    joystickId*: cint
    button*: cint
  TJoystickMoveEvent*{.pf.} = object
    joystickId*: cint
    axis*: TJoystickAxis
    position*: cfloat
  TMouseWheelEvent*{.pf.} = object
    delta*: cint
    x*: cint
    y*: cint
  TMouseButtonEvent*{.pf.} = object
    button*: TMouseButton
    x*: cint
    y*: cint
  TMouseMoveEvent*{.pf.} = object
    x*: cint
    y*: cint
  TTextEvent*{.pf.} = object
    unicode*: cint
  PEvent* = ptr TEvent
  TEvent*{.pf.} = object
    case kind*: TEventType
    of EvtKeyPressed, EvtKeyReleased:
      key*: TKeyEvent
    of EvtMouseButtonPressed, EvtMouseButtonReleased:
      mouseButton*: TMouseButtonEvent
    of EvtTextEntered:
      text*: TTextEvent
    of EvtJoystickConnected, EvtJoystickDisconnected:
      joystickConnect*: TJoystickConnectEvent
    of EvtJoystickMoved:
      joystickMove*: TJoystickMoveEvent
    of EvtJoystickButtonPressed, EvtJoystickButtonReleased:
      joystickButton*: TJoystickButtonEvent
    of EvtResized:
      size*: TSizeEvent
    of EvtMouseMoved, EvtMouseEntered, EvtMouseLeft:
      mouseMove*: TMouseMoveEvent
    of EvtMouseWheelMoved:
      mouseWheel*: TMouseWheelEvent
    else: nil
  TJoystickAxis*{.size: sizeof(cint).} = enum
    JoystickX, JoystickY, JoystickZ, JoystickR,
    JoystickU, JoystickV, JoystickPovX, JoystickPovY
  TSizeEvent*{.pf.} = object
    width*: cint
    height*: cint
  TMouseButton*{.size: sizeof(cint).} = enum
    MouseLeft, MouseRight, MouseMiddle,
    MouseXButton1, MouseXButton2, MouseButtonCount
  TKeyCode*{.size: sizeof(cint).} = enum
    KeyUnknown = - 1, KeyA, KeyB, KeyC, KeyD, KeyE,
    KeyF, KeyG, KeyH, KeyI, KeyJ, KeyK, KeyL, KeyM,                 #/< The M key
    KeyN, KeyO, KeyP, KeyQ, KeyR, KeyS, KeyT, KeyU,                 #/< The U key
    KeyV, KeyW, KeyX, KeyY, KeyZ, KeyNum0, KeyNum1,              #/< The 1 key
    KeyNum2, KeyNum3, KeyNum4, KeyNum5, KeyNum6,              #/< The 6 key
    KeyNum7, KeyNum8, KeyNum9, KeyEscape, KeyLControl,          #/< The left Control key
    KeyLShift, KeyLAlt, KeyLSystem, KeyRControl,          #/< The right Control key
    KeyRShift, KeyRAlt, KeyRSystem, KeyMenu,              #/< The Menu key
    KeyLBracket, KeyRBracket, KeySemiColon, KeyComma,             #/< The , key
    KeyPeriod, KeyQuote, KeySlash, KeyBackSlash,         #/< The \ key
    KeyTilde, KeyEqual, KeyDash, KeySpace, KeyReturn,            #/< The Return key
    KeyBack, KeyTab, KeyPageUp, KeyPageDown, KeyEnd,               #/< The End key
    KeyHome, KeyInsert, KeyDelete, KeyAdd, KeySubtract,          #/< -
    KeyMultiply, KeyDivide, KeyLeft, KeyRight, KeyUp,                #/< Up arrow
    KeyDown, KeyNumpad0, KeyNumpad1, KeyNumpad2,           #/< The numpad 2 key
    KeyNumpad3,           #/< The numpad 3 key
    KeyNumpad4,           #/< The numpad 4 key
    KeyNumpad5,           #/< The numpad 5 key
    KeyNumpad6,           #/< The numpad 6 key
    KeyNumpad7,           #/< The numpad 7 key
    KeyNumpad8,           #/< The numpad 8 key
    KeyNumpad9,           #/< The numpad 9 key
    KeyF1,                #/< The F1 key
    KeyF2,                #/< The F2 key
    KeyF3,                #/< The F3 key
    KeyF4,                #/< The F4 key
    KeyF5,                #/< The F5 key
    KeyF6,                #/< The F6 key
    KeyF7,                #/< The F7 key
    KeyF8,                #/< The F8 key
    KeyF9,                #/< The F8 key
    KeyF10,               #/< The F10 key
    KeyF11,               #/< The F11 key
    KeyF12,               #/< The F12 key
    KeyF13,               #/< The F13 key
    KeyF14,               #/< The F14 key
    KeyF15,               #/< The F15 key
    KeyPause,             #/< The Pause key
    KeyCount              #/< Keep last -- the total number of keyboard keys

type TWindowHandle* = clong

#elif defined(mac):
#  type TWindowHandle* = pointer ##typedef void* sfWindowHandle; <- whatever the hell that is
#elif defined(windows):
#  type TWindowHandle* = HWND__ ? windows is crazy. ##struct HWND__; typedef struct HWND__* sfWindowHandle;
const
  sfNone*         = 0
  sfTitlebar*     = 1 shl 0
  sfResize*       = 1 shl 1
  sfClose*        = 1 shl 2
  sfFullscreen*   = 1 shl 3
  sfDefaultStyle* = sfTitlebar or sfResize or sfClose
type
  PRenderWindow* = ptr TRenderWindow
  TRenderWindow* {.pf.} = object

  PFont* = ptr TFont
  TFont* {.pf.} = object
  PImage* = ptr TImage
  TImage* {.pf.} = object
  PShader* = ptr TShader
  TShader* {.pf.} = object
  PSprite* = ptr TSprite
  TSprite* {.pf.} = object
  PText* = ptr TText
  TText* {.pf.} = object
  PTexture* = ptr TTexture
  TTexture* {.pf.} = object
  PVertexArray* = ptr TVertexArray
  TVertexArray* {.pf.} = object
  PView* = ptr TView
  TView* {.pf.} = object
  PRenderTexture* = ptr TRenderTexture
  TRenderTexture* {.pf.} = object

  PShape* = ptr TShape
  TShape* {.pf.} = object
  PCircleShape* = ptr TCircleShape
  TCircleShape* {.pf.} = object
  PRectangleShape* = ptr TRectangleShape
  TRectangleShape* {.pf.} = object
  PConvexShape* = ptr TConvexShape
  TConvexShape* {.pf.} = object

  TTextStyle*{.size: sizeof(cint).} = enum
    TextRegular = 0, TextBold = 1 shl 0, TextItalic = 1 shl 1,
    TextUnderlined = 1 shl 2

  TBlendMode*{.size: sizeof(cint).} = enum
      BlendAlpha, BlendAdd, BlendMultiply, BlendNone
  PRenderStates* = ptr TRenderStates
  TRenderStates* {.pf.} = object
    blendMode*: TBlendMode
    transform*: TTransform
    texture*: PTexture
    shader*: PShader

  PTransform* = ptr TTransform
  TTransform* {.pf.} = object
    matrix*: array[0..8, cfloat]
  TColor* {.pf.} = object
    r*: uint8
    g*: uint8
    b*: uint8
    a*: uint8
  PFloatRect* = ptr TFloatRect
  TFloatRect*{.pf.} = object
    left*: cfloat
    top*: cfloat
    width*: cfloat
    height*: cfloat
  PIntRect* = ptr TIntRect
  TIntRect*{.pf.} = object
    left*: cint
    top*: cint
    width*: cint
    height*: cint
  TGlyph* {.pf.} = object
    advance*: cint
    bounds*: TIntRect
    textureRect*: TIntRect
  PVertex* = ptr TVertex
  TVertex* {.pf.} = object
    position*: TVector2f
    color*: TColor
    texCoords*: TVector2f
  TPrimitiveType*{.size: sizeof(cint).} = enum
    Points,               #/< List of individual points
    Lines,                #/< List of individual lines
    LinesStrip,           #/< List of connected lines, a point uses the previous point to form a line
    Triangles,            #/< List of individual triangles
    TrianglesStrip,       #/< List of connected triangles, a point uses the two previous points to form a triangle
    TrianglesFan,         #/< List of connected triangles, a point uses the common center and the previous point to form a triangle
    Quads


proc newWindow*(mode: TVideoMode, title: cstring, style: uint32, settings: PContextSettings = nil): PWindow {.
  cdecl, importc: "sfWindow_create", dynlib: LibW.}

proc close*(window: PWindow) {.
  cdecl, importc: "sfWindow_close", dynlib: LibW.}
proc isOpen*(window: PWindow): bool {.cdecl, importc: "sfWindow_isOpen", dynlib: LibW.}

proc pollEvent*(window: PWindow, event: PEvent): bool {.
  cdecl, importc: "sfWindow_pollEvent", dynlib: LibW.}
proc waitEvent*(window: PWindow, event: PEvent): bool {.
  cdecl, importc: "sfWindow_waitEvent", dynlib: LibW.}

proc getDesktopMode*(): TVideoMode {.
  cdecl, importc: "sfVideoMode_getDesktopMode", dynlib: LibW.}
proc isKeyPressed*(key: TKeyCode): bool {.
  cdecl, importc: "sfKeyboard_isKeyPressed", dynlib: LibW.}

proc mouseIsButtonPressed*(button: TMouseButton): bool {.
  cdecl, importc: "sfMouse_isButtonPressed", dynlib: LibW.}
proc mouseGetPosition*(relativeTo: PWindow): TVector2i {.
  cdecl, importc: "sfMouse_getPosition", dynlib: LibW.}
proc mouseSetPosition*(position: TVector2i, relativeTo: PWindow) {.
  cdecl, importc: "sfMouse_setPosition", dynlib: LibW.}

proc joystickIsConnected*(joystick: cint): bool {.
  cdecl, importc: "sfJoystick_isConnected", dynlib: LibW.}
proc joystickGetButtonCount*(joystick: cint): cint {.
  cdecl, importc: "sfJoystick_getButtonCount", dynlib: LibW.}
proc joystickHasAxis*(joystick: cint, axis: TJoystickAxis): bool {.
  cdecl, importc: "sfJoystick_hasAxis", dynlib: LibW.}
proc joystickIsButtonPressed*(joystick: cint, button: cint): bool {.
  cdecl, importc: "sfJoystick_isButtonPressed", dynlib: LibW.}
proc joystickGetAxisPosition*(joystick: cint, axis: TJoystickAxis): float {.
  cdecl, importc: "sfJoystick_getAxisPosition", dynlib: LibW.}
proc joystickUpdate*(): void {.
  cdecl, importc: "sfJoystick_update", dynlib: LibW.}


proc newRenderWindow*(handle: TWindowHandle, settings: PContextSettings = nil): PRenderWindow{.
  cdecl, importc: "sfRenderWindow_createFromHandle", dynlib: LibG.}
proc newRenderWindow*(mode: TVideoMode, title: cstring, style: int32, settings: PContextSettings = nil): PRenderWindow {.
  cdecl, importc: "sfRenderWindow_create", dynlib: LibG.}

proc destroy*(window: PRenderWindow) {.
  cdecl, importc: "sfRenderWindow_destroy", dynlib: LibG.}
proc close*(window: PRenderWindow) {.
  cdecl, importc: "sfRenderWindow_close", dynlib: LibG.}
proc isOpen*(window: PRenderWindow): bool {.
  cdecl, importc: "sfRenderWindow_isOpen", dynlib: LibG.}

#void sfRenderWindow_setIcon(sfRenderWindow* renderWindow, unsigned int width, unsigned int height, const sfuint8* pixels);
#proc setIcon*(window: PRenderWindow, width, height: cint, pixels: seq[uint8]) {.
#  cdecl, importc: "sfRenderWindow_setIcon", dynlib: LibG.}

proc getSettings*(window: PRenderWindow): TContextSettings {.
  cdecl, importc: "sfRenderWindow_getSettings", dynlib: LibG.}

proc pollEvent*(window: PRenderWindow, event: PEvent): bool {.
  cdecl, importc: "sfRenderWindow_pollEvent", dynlib: LibG.}
proc pollEvent*(window: PRenderWindow; event: var TEvent): bool {.
  cdecl, importc: "sfRenderWindow_pollEvent", dynlib: LibG.}
proc waitEvent*(window: PRenderWindow, event: PEvent): bool {.
  cdecl, importc: "sfRenderWindow_waitEvent", dynlib: LibG.}
proc waitEvent*(window: PRenderWindow, event: var TEvent): bool {.
  cdecl, importc: "sfRenderWindow_waitEvent", dynlib: LibG.}
proc getPosition*(window: PRenderWindow): TVector2i {.
  cdecl, importc: "sfRenderWindow_getPosition", dynlib: LibG.}
proc setPosition*(window: PRenderWindow, position: TVector2i) {.
  cdecl, importc: "sfRenderWindow_setPosition", dynlib: LibG.}
proc getSize*(window: PRenderWindow): TVector2i {.
  cdecl, importc: "sfRenderWindow_getSize", dynlib: LibG.}
proc setSize*(window: PRenderWindow, size: TVector2i): void {.
  cdecl, importc: "sfRenderWindow_setSize", dynlib: LibG.}
proc setTitle*(window: PRenderWindow, title: cstring): void {.
  cdecl, importc: "sfRenderWindow_setTitle", dynlib: LibG.}

proc setVisible*(window: PRenderWindow, visible: bool) {.
  cdecl, importc: "sfRenderWindow_setVisible", dynlib: LibG.}
proc setMouseCursorVisible*(window: PRenderWindow, show: bool) {.
  cdecl, importc: "sfRenderWindow_setMouseCursorVisible", dynlib: LibG.}
proc setVerticalSyncEnabled*(window: PRenderWindow, enabled: bool) {.
  cdecl, importc: "sfRenderWindow_setVerticalSyncEnabled", dynlib: LibG.}
proc setKeyRepeatEnabled*(window: PRenderWindow, enabled: bool) {.
  cdecl, importc: "sfRenderWindow_setKeyRepeatEnabled", dynlib: LibG.}
proc setActive*(window: PRenderWindow, active: bool): bool {.
  cdecl, importc: "sfRenderWindow_setActive", dynlib: LibG.}
proc display*(window: PRenderWindow) {.
  cdecl, importc: "sfRenderWindow_display", dynlib: LibG.}
proc setFramerateLimit*(window: PRenderWindow, limit: uint) {.
  cdecl, importc: "sfRenderWindow_setFramerateLimit", dynlib: LibG.}
proc setJoystickThreshold*(window: PRenderWindow, threshold: float) {.
  cdecl, importc: "sfRenderWindow_setJoystickThreshold", dynlib: LibG.}
proc getSystemHandle*(window: PRenderWindow): TWindowHandle {.
  cdecl, importc: "sfRenderWindow_getSystemHandle", dynlib: LibG.}

proc clear*(window: PRenderWindow, color: TColor) {.
  cdecl, importc: "sfRenderWindow_clear", dynlib: LibG.}

proc setView*(window: PRenderWindow, view: PView) {.
  cdecl, importc: "sfRenderWindow_setView", dynlib: LibG.}
proc getView*(window: PRenderWindow): PView {.
  cdecl, importc: "sfRenderWindow_getView", dynlib: LibG.}
proc getDefaultView*(window: PRenderWindow): PView {.
  cdecl, importc: "sfRenderWindow_getDefaultView", dynlib: LibG.}
proc getViewport*(window: PRenderWindow, view: PView): TIntRect {.
  cdecl, importc: "sfRenderWindow_getViewport", dynlib: LibG.}

proc convertCoords*(window: PRenderWindow, point: TVector2i, targetView: PView): TVector2f {.
  cdecl, importc: "sfRenderWindow_convertCoords", dynlib: LibG.}

proc draw*(window: PRenderWindow, sprite: PSprite, states: PRenderStates = nil) {.
  cdecl, importc: "sfRenderWindow_drawSprite", dynlib: LibG.}
proc draw*(window: PRenderWindow, text: PText, states: PRenderStates = nil) {.
  cdecl, importc: "sfRenderWindow_drawText", dynlib: LibG.}
proc draw*(window: PRenderWindow, shape: PShape, states: PRenderStates = nil) {.
  cdecl, importc: "sfRenderWindow_drawShape", dynlib: LibG.}
proc draw*(window: PRenderWindow, shape: PCircleShape, states: PRenderStates = nil) {.
  cdecl, importc: "sfRenderWindow_drawCircleShape", dynlib: LibG.}
proc draw*(window: PRenderWindow, shape: PRectangleShape, states: PRenderStates = nil) {.
  cdecl, importc: "sfRenderWindow_drawRectangleShape", dynlib: LibG.}

proc draw*(window: PRenderWindow, shape: PConvexShape, states: PRenderStates = nil) {.
  cdecl, importc: "sfRenderWindow_drawConvexShape", dynlib: LibG.}
proc draw*(window: PRenderWindow, shape: PVertexArray, states: PRenderStates = nil) {.
  cdecl, importc: "sfRenderWindow_drawVertexArray", dynlib: LibG.}
proc draw*(window: PRenderWindow, vertices: PVertex, vertexCount: cint,
           vertexType: TPrimitiveType, states: PRenderStates = nil) {.
  cdecl, importc: "sfRenderWindow_drawPrimitives", dynlib: LibG.}

proc pushGlStates*(window: PRenderWindow) {.
  cdecl, importc: "sfRenderWindow_pushGLStates", dynlib: LibG.}
proc popGlStates*(window: PRenderWindow) {.
  cdecl, importc: "sfRenderWindow_popGLStates", dynlib: LibG.}
proc resetGlStates*(window: PRenderWindow) {.
  cdecl, importc: "sfRenderWindow_resetGLStates", dynlib: LibG.}
proc capture*(window: PRenderWindow): PImage {.
  cdecl, importc: "sfRenderWindow_capture", dynlib: LibG.}

#Construct a new render texture
proc newRenderTexture*(width, height: cint; depthBuffer: bool): PRenderTexture {.
  cdecl, importc: "sfRenderTexture_create", dynlib: LibG.}
#Destroy an existing render texture
proc destroy*(renderTexture: PRenderTexture){.
  cdecl, importc: "sfRenderTexture_destroy", dynlib: LibG.}
#Get the size of the rendering region of a render texture
proc getSize*(renderTexture: PRenderTexture): TVector2i {.
  cdecl, importc: "sfRenderTexture_getSize", dynlib: LibG.}
#Activate or deactivate a render texture as the current target for rendering
proc setActive*(renderTexture: PRenderTexture; active: bool): bool{.
  cdecl, importc: "sfRenderTexture_setActive", dynlib: LibG.}
#Update the contents of the target texture
proc display*(renderTexture: PRenderTexture){.
  cdecl, importc: "sfRenderTexture_display", dynlib: LibG.}
#Clear the rendertexture with the given color
proc clear*(renderTexture: PRenderTexture; color: TColor){.
  cdecl, importc: "sfRenderTexture_clear", dynlib: LibG.}
#Change the current active view of a render texture
proc setView*(renderTexture: PRenderTexture; view: PView){.
  cdecl, importc: "sfRenderTexture_setView", dynlib: LibG.}
#Get the current active view of a render texture
proc getView*(renderTexture: PRenderTexture): PView{.
  cdecl, importc: "sfRenderTexture_getView", dynlib: LibG.}
#Get the default view of a render texture
proc getDefaultView*(renderTexture: PRenderTexture): PView{.
  cdecl, importc: "sfRenderTexture_getDefaultView", dynlib: LibG.}
#Get the viewport of a view applied to this target
proc getViewport*(renderTexture: PRenderTexture; view: PView): TIntRect{.
  cdecl, importc: "sfRenderTexture_getViewport", dynlib: LibG.}
#Convert a point in texture coordinates into view coordinates
proc convertCoords*(renderTexture: PRenderTexture; point: TVector2i; targetView: PView): TVector2f{.
  cdecl, importc: "sfRenderTexture_convertCoords", dynlib: LibG.}
#Draw a drawable object to the render-target
proc draw*(renderTexture: PRenderTexture; sprite: PSprite; states: PRenderStates){.
  cdecl, importc: "sfRenderTexture_drawSprite", dynlib: LibG.}
proc draw*(renderTexture: PRenderTexture; text: PText; states: PRenderStates){.
  cdecl, importc: "sfRenderTexture_drawText", dynlib: LibG.}
proc draw*(renderTexture: PRenderTexture; shape: PShape; states: PRenderStates){.
  cdecl, importc: "sfRenderTexture_drawShape", dynlib: LibG.}
proc draw*(renderTexture: PRenderTexture; shape: PCircleShape;
            states: PRenderStates){.
  cdecl, importc: "sfRenderTexture_drawCircleShape", dynlib: LibG.}
proc draw*(renderTexture: PRenderTexture; shape: PConvexShape;
            states: PRenderStates){.
  cdecl, importc: "sfRenderTexture_drawConvexShape", dynlib: LibG.}
proc draw*(renderTexture: PRenderTexture; shape: PRectangleShape;
            states: PRenderStates){.
  cdecl, importc: "sfRenderTexture_drawRectangleShape", dynlib: LibG.}
proc draw*(renderTexture: PRenderTexture; va: PVertexArray;
            states: PRenderStates){.
  cdecl, importc: "sfRenderTexture_drawVertexArray", dynlib: LibG.}
#Draw primitives defined by an array of vertices to a render texture
proc draw*(renderTexture: PRenderTexture; vertices: PVertex; vertexCount: cint;
            primitiveType: TPrimitiveType; states: PRenderStates){.
  cdecl, importc: "sfRenderTexture_drawPrimitives", dynlib: LibG.}
#Save the current OpenGL render states and matrices
#/
#/ This function can be used when you mix SFML drawing
#/ and direct OpenGL rendering. Combined with popGLStates,
#/ it ensures that:
#/ * SFML's internal states are not messed up by your OpenGL code
#/ * your OpenGL states are not modified by a call to a SFML function
#/
#/ Note that this function is quite expensive: it saves all the
#/ possible OpenGL states and matrices, even the ones you
#/ don't care about. Therefore it should be used wisely.
#/ It is provided for convenience, but the best results will
#/ be achieved if you handle OpenGL states yourself (because
#/ you know which states have really changed, and need to be
#/ saved and restored). Take a look at the resetGLStates
#/ function if you do so.
proc pushGLStates*(renderTexture: PRenderTexture){.
  cdecl, importc: "sfRenderTexture_pushGLStates", dynlib: LibG.}
#Restore the previously saved OpenGL render states and matrices
#/
#/ See the description of pushGLStates to get a detailed
#/ description of these functions.
proc popGLStates*(renderTexture: PRenderTexture){.
  cdecl, importc: "sfRenderTexture_popGLStates", dynlib: LibG.}
#Reset the internal OpenGL states so that the target is ready for drawing
#/
#/ This function can be used when you mix SFML drawing
#/ and direct OpenGL rendering, if you choose not to use
#/ pushGLStates/popGLStates. It makes sure that all OpenGL
#/ states needed by SFML are set, so that subsequent sfRenderTexture_draw*()
#/ calls will work as expected.
proc resetGLStates*(renderTexture: PRenderTexture){.
  cdecl, importc: "sfRenderTexture_resetGLStates", dynlib: LibG.}
#Get the target texture of a render texture
proc getTexture*(renderTexture: PRenderTexture): PTexture{.
  cdecl, importc: "sfRenderTexture_getTexture", dynlib: LibG.}
#Enable or disable the smooth filter on a render texture
proc setSmooth*(renderTexture: PRenderTexture; smooth: bool){.
  cdecl, importc: "sfRenderTexture_setSmooth", dynlib: LibG.}
#Tell whether the smooth filter is enabled or not for a render texture
proc isSmooth*(renderTexture: PRenderTexture): bool {.
  cdecl, importc: "sfRenderTexture_isSmooth", dynlib: LibG.}

proc intRect*(left, top, width, height: cint): TIntRect =
  result.left   = left
  result.top    = top
  result.width  = width
  result.height = height
proc floatRect*(left, top, width, height: cfloat): TFloatRect =
  result.left   = left
  result.top    = top
  result.width  = width
  result.height = height
proc contains*(rect: PFloatRect, x, y: cfloat): bool {.
  cdecl, importc: "sfFloatRect_contains", dynlib: LibG.}
proc contains*(rect: PIntRect, x: cint, y: cint): bool{.cdecl,
  importc: "sfIntRect_contains", dynlib: LibG.}
proc intersects*(rect1, rect2, intersection: PFloatRect): bool {.
  cdecl, importc: "sfFloatRect_intersects", dynlib: LibG.}
proc intersects*(rect1, rect2, intersection: PIntRect): bool {.
  cdecl, importc: "sfIntRect_intersects", dynlib: LibG.}

proc newFont*(filename: cstring): PFont {.
  cdecl, importc: "sfFont_createFromFile", dynlib: LibG.}
proc newFont*(data: pointer, sizeInBytes: cint): PFont {.
  cdecl, importc: "sfFont_createFromMemory", dynlib: LibG.}
proc newFont*(stream: PInputStream): PFont {.
  cdecl, importc: "sfFont_createFromStream", dynlib: LibG.}
proc copy*(font: PFont): PFont {.
  cdecl, importc: "sfFont_copy", dynlib: LibG.}
proc destroy*(font: PFont) {.
  cdecl, importc: "sfFont_destroy", dynlib: LibG.}
proc getGlyph*(font: PFont, codePoint: uint32, characterSize: cint, bold: bool): TGlyph{.
  cdecl, importc: "sfFont_getGlyph", dynlib: LibG.}
proc getKerning*(font: PFont, first: uint32, second: uint32, characterSize: cint): cint {.
  cdecl, importc: "sfFont_getKerning", dynlib: LibG.}
proc getLineSpacing*(font: PFont, characterSize: cint): cint {.
  cdecl, importc: "sfFont_getLineSpacing", dynlib: LibG.}
proc getTexture*(font: PFont, characterSize: cint): PTexture {.
  cdecl, importc: "sfFont_getTexture", dynlib: LibG.}
#getDefaultFont() has been removed from CSFML
proc getDefaultFont*(): PFont {.
  error, cdecl, importc: "sfFont_getDefaultFont", dynlib: LibG.}

proc newCircleShape*(): PCircleShape {.
  cdecl, importc: "sfCircleShape_create", dynlib: LibG.}
proc copy*(shape: PCircleShape): PCircleShape {.
  cdecl, importc: "sfCircleShape_copy", dynlib: LibG.}
proc destroy*(shape: PCircleShape) {.
  cdecl, importc: "sfCircleShape_destroy", dynlib: LibG.}
proc setPosition*(shape: PCircleShape, position: TVector2f) {.
  cdecl, importc: "sfCircleShape_setPosition", dynlib: LibG.}
proc setRotation*(shape: PCircleShape, angle: cfloat) {.
  cdecl, importc: "sfCircleShape_setRotation", dynlib: LibG.}
proc setScale*(shape: PCircleShape, scale: TVector2f) {.
  cdecl, importc: "sfCircleShape_setScale", dynlib: LibG.}
proc setOrigin*(shape: PCircleShape, origin: TVector2f) {.
  cdecl, importc: "sfCircleShape_setOrigin", dynlib: LibG.}
proc getPosition*(shape: PCircleShape): TVector2f {.
  cdecl, importc: "sfCircleShape_getPosition", dynlib: LibG.}
proc getRotation*(shape: PCircleShape): cfloat {.
  cdecl, importc: "sfCircleShape_getRotation", dynlib: LibG.}
proc getScale*(shape: PCircleShape): TVector2f {.
  cdecl, importc: "sfCircleShape_getScale", dynlib: LibG.}
proc getOrigin*(shape: PCircleShape): TVector2f {.
  cdecl, importc: "sfCircleShape_getOrigin", dynlib: LibG.}
proc move*(shape: PCircleShape, offset: TVector2f) {.
  cdecl, importc: "sfCircleShape_move", dynlib: LibG.}
proc rotate*(shape: PCircleShape, angle: cfloat){.
  cdecl, importc: "sfCircleShape_rotate", dynlib: LibG.}
proc scale*(shape: PCircleShape, factors: TVector2f) {.
  cdecl, importc: "sfCircleShape_scale", dynlib: LibG.}
proc getTransform*(shape: PCircleShape): TTransform {.
  cdecl, importc: "sfCircleShape_getTransform", dynlib: LibG.}
proc getInverseTransform*(shape: PCircleShape): TTransform {.
  cdecl, importc: "sfCircleShape_getInverseTransform", dynlib: LibG.}
proc setTexture*(shape: PCircleShape, texture: PTexture, resetRect: bool) {.
  cdecl, importc: "sfCircleShape_setTexture", dynlib: LibG.}
proc setTextureRect*(shape: PCircleShape, rect: TIntRect) {.
  cdecl, importc: "sfCircleShape_setTextureRect", dynlib: LibG.}
proc setFillColor*(shape: PCircleShape, color: TColor) {.
  cdecl, importc: "sfCircleShape_setFillColor", dynlib: LibG.}
proc setOutlineColor*(shape: PCircleShape, color: TColor) {.
  cdecl, importc: "sfCircleShape_setOutlineColor", dynlib: LibG.}
proc setOutlineThickness*(shape: PCircleShape, thickness: cfloat) {.
  cdecl, importc: "sfCircleShape_setOutlineThickness", dynlib: LibG.}
proc getTexture*(shape: PCircleShape): PTexture {.
  cdecl, importc: "sfCircleShape_getTexture", dynlib: LibG.}
proc getTextureRect*(shape: PCircleShape): TIntRect {.
  cdecl, importc: "sfCircleShape_getTextureRect", dynlib: LibG.}
proc getFillColor*(shape: PCircleShape): TColor {.
  cdecl, importc: "sfCircleShape_getFillColor", dynlib: LibG.}
proc getOutlineColor*(shape: PCircleShape): TColor {.
  cdecl, importc: "sfCircleShape_getOutlineColor", dynlib: LibG.}
proc getOutlineThickness*(shape: PCircleShape): cfloat {.
  cdecl, importc: "sfCircleShape_getOutlineThickness", dynlib: LibG.}
proc getPointCount*(shape: PCircleShape): cint {.
  cdecl, importc: "sfCircleShape_getPointCount", dynlib: LibG.}
proc getPoint*(shape: PCircleShape, index: cint): TVector2f {.
  cdecl, importc: "sfCircleShape_getPoint", dynlib: LibG.}
proc setRadius*(shape: PCircleShape, radius: cfloat) {.
  cdecl, importc: "sfCircleShape_setRadius", dynlib: LibG.}
proc getRadius*(shape: PCircleShape): cfloat {.
  cdecl, importc: "sfCircleShape_getRadius", dynlib: LibG.}
proc setPointCount*(shape: PCircleShape, count: cint) {.
  cdecl, importc: "sfCircleShape_setPointCount", dynlib: LibG.}
proc getLocalBounds*(shape: PCircleShape): TFloatRect {.
  cdecl, importc: "sfCircleShape_getLocalBounds", dynlib: LibG.}
proc getGlobalBounds*(shape: PCircleShape): TFloatRect {.
  cdecl, importc: "sfCircleShape_getGlobalBounds", dynlib: LibG.}

proc newRectangleShape*(): PRectangleShape {.
  cdecl, importc: "sfRectangleShape_create", dynlib: LibG.}
proc copy*(shape: PRectangleShape): PRectangleShape {.
  cdecl, importc: "sfRectangleShape_copy", dynlib: LibG.}
proc destroy*(shape: PRectangleShape){.
  cdecl, importc: "sfRectangleShape_destroy", dynlib: LibG.}
proc setPosition*(shape: PRectangleShape, position: TVector2f) {.
  cdecl, importc: "sfRectangleShape_setPosition", dynlib: LibG.}
proc setRotation*(shape: PRectangleShape, angle: cfloat) {.
  cdecl, importc: "sfRectangleShape_setRotation", dynlib: LibG.}
proc setScale*(shape: PRectangleShape, scale: TVector2f) {.
  cdecl, importc: "sfRectangleShape_setScale", dynlib: LibG.}
proc setOrigin*(shape: PRectangleShape, origin: TVector2f) {.
  cdecl, importc: "sfRectangleShape_setOrigin", dynlib: LibG.}
proc getPosition*(shape: PRectangleShape): TVector2f {.
  cdecl, importc: "sfRectangleShape_getPosition", dynlib: LibG.}
proc getRotation*(shape: PRectangleShape): cfloat {.
  cdecl, importc: "sfRectangleShape_getRotation", dynlib: LibG.}
proc getScale*(shape: PRectangleShape): TVector2f {.
  cdecl, importc: "sfRectangleShape_getScale", dynlib: LibG.}
proc getOrigin*(shape: PRectangleShape): TVector2f {.
  cdecl, importc: "sfRectangleShape_getOrigin", dynlib: LibG.}
proc move*(shape: PRectangleShape, offset: TVector2f) {.
  cdecl, importc: "sfRectangleShape_move", dynlib: LibG.}
proc rotate*(shape: PRectangleShape, angle: cfloat) {.
  cdecl, importc: "sfRectangleShape_rotate", dynlib: LibG.}
proc scale*(shape: PRectangleShape, factors: TVector2f) {.
  cdecl, importc: "sfRectangleShape_scale", dynlib: LibG.}
proc getTransform*(shape: PRectangleShape): TTransform {.
  cdecl, importc: "sfRectangleShape_getTransform", dynlib: LibG.}
proc getInverseTransform*(shape: PRectangleShape): TTransform {.
  cdecl, importc: "sfRectangleShape_getInverseTransform", dynlib: LibG.}
proc setTexture*(shape: PRectangleShape, texture: PTexture, resetRect: bool) {.
  cdecl, importc: "sfRectangleShape_setTexture", dynlib: LibG.}
proc setTextureRect*(shape: PRectangleShape, rect: TIntRect) {.
  cdecl, importc: "sfRectangleShape_setTextureRect", dynlib: LibG.}
proc setFillColor*(shape: PRectangleShape, color: TColor) {.
  cdecl, importc: "sfRectangleShape_setFillColor", dynlib: LibG.}
proc setOutlineColor*(shape: PRectangleShape, color: TColor) {.
  cdecl, importc: "sfRectangleShape_setOutlineColor", dynlib: LibG.}
proc setOutlineThickness*(shape: PRectangleShape, thickness: cfloat) {.
  cdecl, importc: "sfRectangleShape_setOutlineThickness", dynlib: LibG.}
proc getTexture*(shape: PRectangleShape): PTexture {.
  cdecl, importc: "sfRectangleShape_getTexture", dynlib: LibG.}
proc getTextureRect*(shape: PRectangleShape): TIntRect {.
  cdecl, importc: "sfRectangleShape_getTextureRect", dynlib: LibG.}
proc getFillColor*(shape: PRectangleShape): TColor {.
  cdecl, importc: "sfRectangleShape_getFillColor", dynlib: LibG.}
proc getOutlineColor*(shape: PRectangleShape): TColor {.
  cdecl, importc: "sfRectangleShape_getOutlineColor", dynlib: LibG.}
proc getOutlineThickness*(shape: PRectangleShape): cfloat {.
  cdecl, importc: "sfRectangleShape_getOutlineThickness", dynlib: LibG.}
proc getPointCount*(shape: PRectangleShape): cint {.
  cdecl, importc: "sfRectangleShape_getPointCount", dynlib: LibG.}
proc getPoint*(shape: PRectangleShape, index: cint): TVector2f {.
  cdecl, importc: "sfRectangleShape_getPoint", dynlib: LibG.}
proc setSize*(shape: PRectangleShape, size: TVector2f) {.
  cdecl, importc: "sfRectangleShape_setSize", dynlib: LibG.}
proc getSize*(shape: PRectangleShape): TVector2f {.
  cdecl, importc: "sfRectangleShape_getSize", dynlib: LibG.}
proc getLocalBounds*(shape: PRectangleShape): TFloatRect {.
  cdecl, importc: "sfRectangleShape_getLocalBounds", dynlib: LibG.}
proc getGlobalBounds*(shape: PRectangleShape): TFloatRect {.
  cdecl, importc: "sfRectangleShape_getGlobalBounds", dynlib: LibG.}


proc newView*(): PView {.
  cdecl, importc: "sfView_create", dynlib: LibG.}
proc viewFromRect*(rectangle: TFloatRect): PView{.
  cdecl, importc: "sfView_createFromRect", dynlib: LibG.}
proc copy*(view: PView): PView {.
  cdecl, importc: "sfView_copy", dynlib: LibG.}
proc destroy*(view: PView) {.
  cdecl, importc: "sfView_destroy", dynlib: LibG.}
proc setCenter*(view: PView, center: TVector2f) {.
  cdecl, importc: "sfView_setCenter", dynlib: LibG.}
proc setSize*(view: PView, size: TVector2f) {.
  cdecl, importc: "sfView_setSize", dynlib: LibG.}
proc setRotation*(view: PView, angle: cfloat) {.
  cdecl, importc: "sfView_setRotation", dynlib: LibG.}
proc setViewport*(view: PView, viewport: TFloatRect) {.
  cdecl, importc: "sfView_setViewport", dynlib: LibG.}
proc reset*(view: PView, rectangle: TFloatRect) {.
  cdecl, importc: "sfView_reset", dynlib: LibG.}
proc getCenter*(view: PView): TVector2f {.
  cdecl, importc: "sfView_getCenter", dynlib: LibG.}
proc getSize*(view: PView): TVector2f {.
  cdecl, importc: "sfView_getSize", dynlib: LibG.}
proc getRotation*(view: PView): cfloat {.
  cdecl, importc: "sfView_getRotation", dynlib: LibG.}
proc getViewport*(view: PView): TFloatRect {.
  cdecl, importc: "sfView_getViewport", dynlib: LibG.}
proc move*(view: PView, offset: TVector2f) {.
  cdecl, importc: "sfView_move", dynlib: LibG.}
proc rotate*(view: PView, angle: cfloat) {.
  cdecl, importc: "sfView_rotate", dynlib: LibG.}
proc zoom*(view: PView, factor: cfloat) {.
  cdecl, importc: "sfView_zoom", dynlib: LibG.}

proc newImage*(width, height: cint): PImage {.
  cdecl, importc: "sfImage_create", dynlib: LibG.}
proc newImage*(width, height: cint, color: TColor): PImage {.
  cdecl, importc: "sfImage_createFromColor", dynlib: LibG.}
proc newImage*(width, height: cint, pixels: pointer): PImage {. ##same deal as setIcon()
  cdecl, importc: "sfImage_createFromPixels", dynlib: LibG.}
proc newImage*(filename: cstring): PImage {.
  cdecl, importc: "sfImage_createFromFile", dynlib: LibG.}
proc newImage*(data: pointer, size: cint): PImage {.
  cdecl, importc: "sfImage_createFromMemory", dynlib: LibG.}
proc newImage*(stream: PInputStream): PImage {.
  cdecl, importc: "sfImage_createFromStream", dynlib: LibG.}
proc copy*(image: PImage): PImage {.
  cdecl, importc: "sfImage_copy", dynlib: LibG.}
proc destroy*(image: PImage) {.
  cdecl, importc: "sfImage_destroy", dynlib: LibG.}
proc save*(image: PImage, filename: cstring): bool {.
  cdecl, importc: "sfImage_saveToFile", dynlib: LibG.}
proc getSize*(image: PImage): TVector2i {.
  cdecl, importc: "sfImage_getSize", dynlib: LibG.}
proc createMask*(image: PImage, color: TColor, alpha: cchar) {.
  cdecl, importc: "sfImage_createMaskFromColor", dynlib: LibG.}
proc copy*(destination, source: PImage, destX, destY: cint;
            sourceRect: TIntRect, applyAlpha: bool) {.
  cdecl, importc: "sfImage_copyImage", dynlib: LibG.}
proc setPixel*(image: PImage, x, y: cint, color: TColor) {.
  cdecl, importc: "sfImage_setPixel", dynlib: LibG.}
proc getPixel*(image: PImage, x, y: cint): TColor {.
  cdecl, importc: "sfImage_getPixel", dynlib: LibG.}
proc getPixels*(image: PImage): pointer {.
  cdecl, importc: "sfImage_getPixelsPtr", dynlib: LibG.}
proc flipHorizontally*(image: PImage) {.
  cdecl, importc: "sfImage_flipHorizontally", dynlib: LibG.}
proc flipVertically*(image: PImage) {.
  cdecl, importc: "sfImage_flipVertically", dynlib: LibG.}

proc newSprite*(): PSprite {.
  cdecl, importc: "sfSprite_create", dynlib: LibG.}
proc copy*(sprite: PSprite): PSprite {.
  cdecl, importc: "sfSprite_copy", dynlib: LibG.}
proc destroy*(sprite: PSprite) {.
  cdecl, importc: "sfSprite_destroy", dynlib: LibG.}
proc setPosition*(sprite: PSprite, position: TVector2f) {.
  cdecl, importc: "sfSprite_setPosition", dynlib: LibG.}
proc setRotation*(sprite: PSprite, angle: cfloat) {.
  cdecl, importc: "sfSprite_setRotation", dynlib: LibG.}
proc setScale*(sprite: PSprite, scale: TVector2f) {.
  cdecl, importc: "sfSprite_setScale", dynlib: LibG.}
proc setOrigin*(sprite: PSprite, origin: TVector2f) {.
  cdecl, importc: "sfSprite_setOrigin", dynlib: LibG.}
proc getPosition*(sprite: PSprite): TVector2f {.
  cdecl, importc: "sfSprite_getPosition", dynlib: LibG.}
proc getRotation*(sprite: PSprite): cfloat {.
  cdecl, importc: "sfSprite_getRotation", dynlib: LibG.}
proc getScale*(sprite: PSprite): TVector2f {.
  cdecl, importc: "sfSprite_getScale", dynlib: LibG.}
proc getOrigin*(sprite: PSprite): TVector2f {.
  cdecl, importc: "sfSprite_getOrigin", dynlib: LibG.}
proc move*(sprite: PSprite, offset: TVector2f) {.
  cdecl, importc: "sfSprite_move", dynlib: LibG.}
proc rotate*(sprite: PSprite, angle: cfloat) {.
  cdecl, importc: "sfSprite_rotate", dynlib: LibG.}
proc scale*(sprite: PSprite, factor: TVector2f) {.
  cdecl, importc: "sfSprite_scale", dynlib: LibG.}
proc getTransform*(sprite: PSprite): TTransform {.
  cdecl, importc: "sfSprite_getTransform", dynlib: LibG.}
proc getInverseTransform*(sprite: PSprite): TTransform {.
  cdecl, importc: "sfSprite_getInverseTransform", dynlib: LibG.}
proc setTexture*(sprite: PSprite, texture: PTexture, resetRect: bool) {.
  cdecl, importc: "sfSprite_setTexture", dynlib: LibG.}
proc setTextureRect*(sprite: PSprite, rectangle: TIntRect) {.
  cdecl, importc: "sfSprite_setTextureRect", dynlib: LibG.}
proc setColor*(sprite: PSprite, color: TColor) {.
  cdecl, importc: "sfSprite_setColor", dynlib: LibG.}
proc getTexture*(sprite: PSprite): TTexture {.
  cdecl, importc: "sfSprite_getTexture", dynlib: LibG.}
proc getTextureRect*(sprite: PSprite): TIntRect {.
  cdecl, importc: "sfSprite_getTextureRect", dynlib: LibG.}
proc getColor*(sprite: PSprite): TColor {.
  cdecl, importc: "sfSprite_getColor", dynlib: LibG.}
proc getLocalBounds*(sprite: PSprite): TFloatRect {.
  cdecl, importc: "sfSprite_getLocalBounds", dynlib: LibG.}
proc getGlobalBounds*(sprite: PSprite): TFloatRect {.
  cdecl, importc: "sfSprite_getGlobalBounds", dynlib: LibG.}

proc newTexture*(width, height: cint): PTexture {.
  cdecl, importc: "sfTexture_create", dynlib: LibG.}
proc newTexture*(filename: cstring): PTexture {.
  cdecl, importc: "sfTexture_createFromFile", dynlib: LibG.}
proc newTexture*(data: pointer, size: cint, area: PIntRect): PTexture {.
  cdecl, importc: "sfTexture_createFromMemory", dynlib: LibG.}
proc newTexture*(stream: PInputStream, area: PIntRect): PTexture {.
  cdecl, importc: "sfTexture_createFromStream", dynlib: LibG.}
proc newTexture*(image: PImage, area: PIntRect = nil): PTexture {.
  cdecl, importc: "sfTexture_createFromImage", dynlib: LibG.}
proc copy*(texture: PTexture): PTexture {.
  cdecl, importc: "sfTexture_copy", dynlib: LibG.}
proc destroy*(texture: PTexture) {.
  cdecl, importc: "sfTexture_destroy", dynlib: LibG.}
proc getSize*(texture: PTexture): TVector2i {.
  cdecl, importc: "sfTexture_getSize", dynlib: LibG.}
proc copyToImage*(texture: PTexture): PImage {.
  cdecl, importc: "sfTexture_copyToImage", dynlib: LibG.}
proc updateFromPixels*(texture: PTexture, pixels: pointer, width, height, x, y: cint) {.
  cdecl, importc: "sfTexture_updateFromPixels", dynlib: LibG.}
proc updateFromImage*(texture: PTexture, image: PImage, x, y: cint) {.
  cdecl, importc: "sfTexture_updateFromImage", dynlib: LibG.}
proc updateFromWindow*(texture: PTexture, window: PWindow, x, y: cint) {.
  cdecl, importc: "sfTexture_updateFromWindow", dynlib: LibG.}
proc updateFromWindow*(texture: PTexture, window: PRenderWindow, x, y: cint) {.
  cdecl, importc: "sfTexture_updateFromRenderWindow", dynlib: LibG.}
proc bindGL*(texture: PTexture) {.
  cdecl, importc: "sfTexture_bind", dynlib: LibG.}
proc setSmooth*(texture: PTexture, smooth: bool) {.
  cdecl, importc: "sfTexture_setSmooth", dynlib: LibG.}
proc isSmooth*(texture: PTexture): bool {.
  cdecl, importc: "sfTexture_isSmooth", dynlib: LibG.}
proc setRepeated*(texture: PTexture, repeated: bool) {.
  cdecl, importc: "sfTexture_setRepeated", dynlib: LibG.}
proc isRepeated*(texture: PTexture): bool {.
  cdecl, importc: "sfTexture_isRepeated", dynlib: LibG.}
proc textureMaxSize*(): cint {.
  cdecl, importc: "sfTexture_getMaximumSize", dynlib: LibG.}

proc newVertexArray*(): PVertexArray {.
  cdecl, importc: "sfVertexArray_create", dynlib: LibG.}
proc copy*(vertexArray: PVertexArray): PVertexArray {.
  cdecl, importc: "sfVertexArray_copy", dynlib: LibG.}
proc destroy*(va: PVertexArray) {.
  cdecl, importc: "sfVertexArray_destroy", dynlib: LibG.}
proc getVertexCount*(va: PVertexArray): cint {.
  cdecl, importc: "sfVertexArray_getVertexCount", dynlib: LibG.}
proc getVertex*(va: PVertexArray, index: cint): PVertex {.
  cdecl, importc: "sfVertexArray_getVertex", dynlib: LibG.}
proc clear*(va: PVertexArray) {.
  cdecl, importc: "sfVertexArray_clear", dynlib: LibG.}
proc resize*(va: PVertexArray, size: cint) {.
  cdecl, importc: "sfVertexArray_resize", dynlib: LibG.}
proc append*(va: PVertexArray, vertex: TVertex) {.
  cdecl, importc: "sfVertexArray_append", dynlib: LibG.}
proc setPrimitiveType*(va: PVertexArray, primitiveType: TPrimitiveType) {.
  cdecl, importc: "sfVertexArray_setPrimitiveType", dynlib: LibG.}
proc getPrimitiveType*(va: PVertexArray): TPrimitiveType {.
  cdecl, importc: "sfVertexArray_getPrimitiveType", dynlib: LibG.}
proc getBounds*(va: PVertexArray): TFloatRect {.
  cdecl, importc: "sfVertexArray_getBounds", dynlib: LibG.}


proc newText*(): PText {.
  cdecl, importc: "sfText_create", dynlib: LibG.}
proc copy*(text: PText): PText {.
  cdecl, importc: "sfText_copy", dynlib: LibG.}
proc destroy*(text: PText) {.
  cdecl, importc: "sfText_destroy", dynlib: LibG.}
proc setPosition*(text: PText, position: TVector2f) {.
  cdecl, importc: "sfText_setPosition", dynlib: LibG.}
proc setRotation*(text: PText, angle: cfloat) {.
  cdecl, importc: "sfText_setRotation", dynlib: LibG.}
proc setScale*(text: PText, scale: TVector2f) {.
  cdecl, importc: "sfText_setScale", dynlib: LibG.}
proc setOrigin*(text: PText, origin: TVector2f) {.
  cdecl, importc: "sfText_setOrigin", dynlib: LibG.}
proc getPosition*(text: PText): TVector2f {.
  cdecl, importc: "sfText_getPosition", dynlib: LibG.}
proc getRotation*(text: PText): cfloat {.
  cdecl, importc: "sfText_getRotation", dynlib: LibG.}
proc getScale*(text: PText): TVector2f {.
  cdecl, importc: "sfText_getScale", dynlib: LibG.}
proc getOrigin*(text: PText): TVector2f {.
  cdecl, importc: "sfText_getOrigin", dynlib: LibG.}
proc move*(text: PText, offset: TVector2f) {.
  cdecl, importc: "sfText_move", dynlib: LibG.}
proc rotate*(text: PText, angle: cfloat) {.
  cdecl, importc: "sfText_rotate", dynlib: LibG.}
proc scale*(text: PText, factors: TVector2f) {.
  cdecl, importc: "sfText_scale", dynlib: LibG.}
proc getTransform*(text: PText): TTransform {.
  cdecl, importc: "sfText_getTransform", dynlib: LibG.}
proc getInverseTransform*(text: PText): TTransform {.
  cdecl, importc: "sfText_getInverseTransform", dynlib: LibG.}
proc setString*(text: PText, string: cstring) {.
  cdecl, importc: "sfText_setString", dynlib: LibG.}
proc setUnicodeString*(text: PText, string: ptr uint32) {.
  cdecl, importc: "sfText_setUnicodeString", dynlib: LibG.}
proc setFont*(text: PText, font: PFont) {.
  cdecl, importc: "sfText_setFont", dynlib: LibG.}
proc setCharacterSize*(text: PText, size: cint) {.
  cdecl, importc: "sfText_setCharacterSize", dynlib: LibG.}
proc setStyle*(text: PText, style: TTextStyle) {.
  cdecl, importc: "sfText_setStyle", dynlib: LibG.}
proc setColor*(text: PText, color: TColor) {.
  cdecl, importc: "sfText_setColor", dynlib: LibG.}
proc getString*(text: PText): cstring {.
  cdecl, importc: "sfText_getString", dynlib: LibG.}
proc getUnicodeString*(text: PText): ptr uint32 {.cdecl,
  importc: "sfText_getUnicodeString", dynlib: LibG.}
proc getFont*(text: PText): PFont {.
  cdecl, importc: "sfText_getFont", dynlib: LibG.}
proc getCharacterSize*(text: PText): cint {.
  cdecl, importc: "sfText_getCharacterSize", dynlib: LibG.}
proc getStyle*(text: PText): uint32 {.
  cdecl, importc: "sfText_getStyle", dynlib: LibG.}
proc getColor*(text: PText): TColor {.
  cdecl, importc: "sfText_getColor", dynlib: LibG.}
proc findCharacterPos*(text: PText, index: cint): TVector2f {.
  cdecl, importc: "sfText_findCharacterPos", dynlib: LibG.}
proc getLocalBounds*(text: PText): TFloatRect {.
  cdecl, importc: "sfText_getLocalBounds", dynlib: LibG.}
proc getGlobalBounds*(text: PText): TFloatRect {.
  cdecl, importc: "sfText_getGlobalBounds", dynlib: LibG.}

proc transformFromMatrix*(a00, a01, a02, a10, a11, a12, a20, a21, a22: cfloat): TTransform {.
  cdecl, importc: "sfTransform_fromMatrix", dynlib: LibG.}
proc getMatrix*(transform: PTransform, matrix: ptr cfloat) {.
  cdecl, importc: "sfTransform_getMatrix", dynlib: LibG.}
proc getInverse*(transform: PTransform): TTransform {.
  cdecl, importc: "sfTransform_getInverse", dynlib: LibG.}
proc transformPoint*(transform: PTransform, point: TVector2f): TVector2f {.
  cdecl, importc: "sfTransform_transformPoint", dynlib: LibG.}
proc transformRect*(transform: PTransform, rectangle: TFloatRect): TFloatRect {.
  cdecl, importc: "sfTransform_transformRect", dynlib: LibG.}
proc combine*(transform: PTransform, other: PTransform) {.
  cdecl, importc: "sfTransform_combine", dynlib: LibG.}
proc translate*(transform: PTransform, x, y: cfloat) {.
  cdecl, importc: "sfTransform_translate", dynlib: LibG.}
proc rotate*(transform: PTransform, angle: cfloat) {.
  cdecl, importc: "sfTransform_rotate", dynlib: LibG.}
proc rotateWithCenter*(transform: PTransform, angle, centerX, centerY: cfloat){.
  cdecl, importc: "sfTransform_rotateWithCenter", dynlib: LibG.}
proc scale*(transform: PTransform, scaleX, scaleY: cfloat) {.
  cdecl, importc: "sfTransform_scale", dynlib: LibG.}
proc scaleWithCenter*(transform: PTransform, scaleX, scaleY, centerX, centerY: cfloat) {.
  cdecl, importc: "sfTransform_scaleWithCenter", dynlib: LibG.}
let IdentityMatrix*: TTransform = transformFromMatrix(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0)


proc newShader*(VSfilename: cstring, fragmentShaderFilename: cstring): PShader {.
  cdecl, importc: "sfShader_createFromFile", dynlib: LibG.}
proc newShaderFromStr*(vertexShader: cstring, fragmentShader: cstring): PShader {.
  cdecl, importc: "sfShader_createFromMemory", dynlib: LibG.}
proc newShader*(vertexShaderStream: PInputStream, fragmentShaderStream: PInputStream): PShader {.
  cdecl, importc: "sfShader_createFromStream", dynlib: LibG.}
proc destroy*(shader: PShader) {.
  cdecl, importc: "sfShader_destroy", dynlib: LibG.}
proc setFloatParameter*(shader: PShader, name: cstring, x: cfloat) {.
  cdecl, importc: "sfShader_setFloatParameter", dynlib: LibG.}
proc setFloat2Parameter*(shader: PShader, name: cstring, x, y: cfloat) {.
  cdecl, importc: "sfShader_setFloat2Parameter", dynlib: LibG.}
proc setFloat3Parameter*(shader: PShader, name: cstring, x, y, z: cfloat) {.
  cdecl, importc: "sfShader_setFloat3Parameter", dynlib: LibG.}
proc setFloat4Parameter*(shader: PShader, name: cstring, x, y, z, w: cfloat) {.
  cdecl, importc: "sfShader_setFloat4Parameter", dynlib: LibG.}
proc setVector2Parameter*(shader: PShader, name: cstring, vector: TVector2f) {.
  cdecl, importc: "sfShader_setVector2Parameter", dynlib: LibG.}
proc setVector3Parameter*(shader: PShader, name: cstring, vector: TVector3f) {.
  cdecl, importc: "sfShader_setVector3Parameter", dynlib: LibG.}
proc setColorParameter*(shader: PShader, name: cstring, color: TColor) {.
  cdecl, importc: "sfShader_setColorParameter", dynlib: LibG.}
proc setTransformParameter*(shader: PShader, name: cstring, transform: TTransform) {.
  cdecl, importc: "sfShader_setTransformParameter", dynlib: LibG.}
proc setTextureParameter*(shader: PShader, name: cstring, texture: PTexture) {.
  cdecl, importc: "sfShader_setTextureParameter", dynlib: LibG.}
proc setCurrentTextureParameter*(shader: PShader, name: cstring) {.
  cdecl, importc: "sfShader_setCurrentTextureParameter", dynlib: LibG.}
proc bindGL*(shader: PShader) {.
  cdecl, importc: "sfShader_bind", dynlib: LibG.}
proc unbindGL*(shader: PShader) {.
  cdecl, importc: "sfShader_unbind", dynlib: LibG.}
proc shaderIsAvailable*(): bool {.
  cdecl, importc: "sfShader_isAvailable", dynlib: LibG.}

proc color*(red, green, blue: cchar): TColor {.
  cdecl, importc: "sfColor_fromRGB", dynlib: LibG.}
proc color*(red, green, blue: int): TColor {.inline.} =
  return color(red.cchar, green.cchar, blue.cchar)
proc color*(red, green, blue, alpha: cchar): TColor {.
  cdecl, importc: "sfColor_fromRGBA", dynlib: LibG.}
proc color*(red, green, blue, alpha: int): TColor {.inline.} =
  return color(red.cchar, green.cchar, blue.cchar, alpha.cchar)
proc `+`*(color1, color2: TColor): TColor {.
  cdecl, importc: "sfColor_add", dynlib: LibG.}
proc `*`*(color1, color2: TColor): TColor {.
  cdecl, importc: "sfColor_modulate", dynlib: LibG.}
proc newColor*(r,g,b: int): TColor {.inline.} =
  return color(r,g,b)
proc newColor*(r,g,b,a: int): TColor {.inline.} =
  return color(r,g,b,a)

proc newClock*(): PClock {.
  cdecl, importc: "sfClock_create", dynlib: LibS.}
proc copy*(clocK: PClock): PClock {.
  cdecl, importc: "sfClock_copy", dynlib: LibS.}
proc destroy*(clock: PClock): PClock {.
  cdecl, importc: "sfClock_destroy", dynlib: LibS.}
proc getElapsedTime*(clock: PClock): TTime {.
  cdecl, importc: "sfClock_getElapsedTime", dynlib: LibS.}
proc restart*(clock: PClock): TTime {.
  cdecl, importc: "sfClock_restart", dynlib: LibS, discardable.}
proc asSeconds*(time: TTime): cfloat {.
  cdecl, importc: "sfTime_asSeconds", dynlib: LibS.}
proc asMilliseconds*(time: TTime): int32 {.
  cdecl, importc: "sfTime_asMilliseconds", dynlib: LibS.}
proc asMicroseconds*(time: TTime): int64 {.
  cdecl, importc: "sfTime_asMicroseconds", dynlib: LibS.}
proc seconds*(seconds: cfloat): TTime {.
  cdecl, importc: "sfSeconds", dynlib: LibS.}
proc milliseconds*(ms: int32): TTime {.
  cdecl, importc: "sfMilliseconds", dynlib: LibS.}
proc microseconds*(us: int64): TTime {.
  cdecl, importc: "sfMicroseconds", dynlib: LibS.}

proc newContextSettings*(depthBits: cint = 0,
                         stencilBits: cint = 0,
                         antialiasingLevel: cint = 0,
                         majorVersion: cint = 0,
                         minorVersion: cint = 0): TContextSettings =
  result.depthBits = depthBits
  result.stencilBits = stencilBits
  result.antialiasingLevel = antialiasingLevel
  result.majorVersion = majorVersion
  result.minorVersion = minorVersion

proc newCircleShape*(radius: cfloat; pointCount: cint = 30): PCircleShape =
  result = newCircleShape()
  result.setRadius radius
  result.setPointCount pointCount
proc newText*(str: string, font: PFont, size: int): PText =
  result = newText()
  result.setString(str)
  result.setFont(font)
  result.setCharacterSize(size.cint)
proc newVertexArray*(primitiveType: TPrimitiveType, vertexCount: cint = 0): PVertexArray =
  result = newVertexArray()
  result.setPrimitiveType(primitiveType)
  if vertexCount != 0:
    result.resize(vertexCount)
proc videoMode*(width, height, bpp: cint): TVideoMode =
  result.width = width
  result.height = height
  result.bitsPerPixel = bpp

proc `[]`*(a: PVertexArray, index: int): PVertex =
  return getVertex(a, index.cint)

proc `$` *(a: TContextSettings): string =
  return "<TContextSettings stencil=$1 aa=$2 major=$3 minor=$4 depth=$5>" % [
    $a.stencilBits, $a.antialiasingLevel, $a.majorVersion, $a.minorVersion, $a.depthBits]
proc `$` *(a: TVideoMode): string =
  return "<TVideoMode $1x$2 $3bpp>" % [$a.width, $a.height, $a.bitsPerPixel]
proc `$` *(a: TFloatRect): string =
  return "<TFloatRect $1,$2 $3x$4>" % [$a.left, $a.top, $a.width, $a.height]
proc `$` *(a: PView): string =
  return $a.getViewport()
proc `$` *(a: TVector2f): string =
  return "<TVector2f $1,$2>" % [$a.x, $a.y]

proc vec2i*(x, y: int): TVector2i =
  result.x = x.cint
  result.y = y.cint
proc vec2f*(x, y: float): TVector2f =
  result.x = x.cfloat
  result.y = y.cfloat

proc `+`*(a, b: TVector2f): TVector2f {.inline.} =
  result.x = a.x + b.x
  result.y = a.y + b.y
proc `-`*(a: TVector2f): TVector2f {.inline.} =
  result.x = -a.x
  result.y = -a.y
proc `-`*(a, b: TVector2f): TVector2f {.inline.}=
  result.x = a.x - b.x
  result.y = a.y - b.y
proc `*`*(a: TVector2f, b: cfloat): TVector2f {.inline.} =
  result.x = a.x * b
  result.y = a.y * b
proc `*`*(a, b: TVector2f): TVector2f {.inline.} =
  result.x = a.x * b.x
  result.y = a.y * b.y
proc `/`*(a: TVector2f, b: cfloat): TVector2f {.inline.} =
  result.x = a.x / b
  result.y = a.y / b
proc `+=` *(a: var TVector2f, b: TVector2f) {.inline, noSideEffect.} =
  a = a + b
proc `-=` *(a: var TVector2f, b: TVector2f) {.inline, noSideEffect.} =
  a = a - b
proc `*=` *(a: var TVector2f, b: float) {.inline, noSideEffect.} =
  a = a * b
proc `*=` *(a: var TVector2f, b: TVector2f) {.inline, noSideEffect.} =
  a = a * b
proc `/=` *(a: var TVector2f, b: float) {.inline, noSideEffect.} =
  a = a / b
proc `<` *(a, b: TVector2f): bool {.inline, noSideEffect.} =
  return a.x < b.x or (a.x == b.x and a.y < b.y)
proc `<=` *(a, b: TVector2f): bool {.inline, noSideEffect.} =
  return a.x <= b.x and a.y <= b.y
proc `==` *(a, b: TVector2f): bool {.inline, noSideEffect.} =
  return a.x == b.x and a.y == b.y
proc length*(a: TVector2f): float {.inline.} =
  return sqrt(pow(a.x, 2.0) + pow(a.y, 2.0))
proc lengthSq*(a: TVector2f): float {.inline.} =
  return pow(a.x, 2.0) + pow(a.y, 2.0)
proc distanceSq*(a, b: TVector2f): float {.inline.} =
  return pow(a.x - b.x, 2.0) + pow(a.y - b.y, 2.0)
proc distance*(a, b: TVector2f): float {.inline.} =
  return sqrt(pow(a.x - b.x, 2.0) + pow(a.y - b.y, 2.0))
proc permul*(a, b: TVector2f): TVector2f =
  result.x = a.x * b.x
  result.y = a.y * b.y
proc rotate*(a: TVector2f, phi: float): TVector2f =
  var c = cos(phi)
  var s = sin(phi)
  result.x = a.x * c - a.y * s
  result.y = a.x * s + a.y * c
proc perpendicular(a: TVector2f): TVector2f =
  result.x = -a.x
  result.y =  a.y
proc cross(a, b: TVector2f): float =
  return a.x * b.y - a.y * b.x

