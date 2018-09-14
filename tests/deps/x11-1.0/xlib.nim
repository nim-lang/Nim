
import
  x

include "x11pragma.nim"

type
  cunsigned* = cint
  Pcint* = ptr cint
  PPcint* = ptr Pcint
  PPcuchar* = ptr ptr cuchar
  PWideChar* = ptr int16
  PPChar* = ptr cstring
  PPPChar* = ptr ptr cstring
  Pculong* = ptr culong
  Pcuchar* = cstring
  Pcuint* = ptr cuint
  Pcushort* = ptr uint16
#  Automatically converted by H2Pas 0.99.15 from xlib.h
#  The following command line parameters were used:
#    -p
#    -T
#    -S
#    -d
#    -c
#    xlib.h

const
  XlibSpecificationRelease* = 6

type
  PXPointer* = ptr TXPointer
  TXPointer* = ptr char
  PBool* = ptr TBool
  TBool* = int           #cint?
  PStatus* = ptr TStatus
  TStatus* = cint

const
  QueuedAlready* = 0
  QueuedAfterReading* = 1
  QueuedAfterFlush* = 2

type
  PPXExtData* = ptr PXExtData
  PXExtData* = ptr TXExtData
  TXExtData*{.final.} = object
    number*: cint
    next*: PXExtData
    free_private*: proc (extension: PXExtData): cint{.cdecl.}
    private_data*: TXPointer

  PXExtCodes* = ptr TXExtCodes
  TXExtCodes*{.final.} = object
    extension*: cint
    major_opcode*: cint
    first_event*: cint
    first_error*: cint

  PXPixmapFormatValues* = ptr TXPixmapFormatValues
  TXPixmapFormatValues*{.final.} = object
    depth*: cint
    bits_per_pixel*: cint
    scanline_pad*: cint

  PXGCValues* = ptr TXGCValues
  TXGCValues*{.final.} = object
    function*: cint
    plane_mask*: culong
    foreground*: culong
    background*: culong
    line_width*: cint
    line_style*: cint
    cap_style*: cint
    join_style*: cint
    fill_style*: cint
    fill_rule*: cint
    arc_mode*: cint
    tile*: TPixmap
    stipple*: TPixmap
    ts_x_origin*: cint
    ts_y_origin*: cint
    font*: TFont
    subwindow_mode*: cint
    graphics_exposures*: TBool
    clip_x_origin*: cint
    clip_y_origin*: cint
    clip_mask*: TPixmap
    dash_offset*: cint
    dashes*: cchar

  PXGC* = ptr TXGC
  TXGC*{.final.} = object
  TGC* = PXGC
  PGC* = ptr TGC
  PVisual* = ptr TVisual
  TVisual*{.final.} = object
    ext_data*: PXExtData
    visualid*: TVisualID
    c_class*: cint
    red_mask*, green_mask*, blue_mask*: culong
    bits_per_rgb*: cint
    map_entries*: cint

  PDepth* = ptr TDepth
  TDepth*{.final.} = object
    depth*: cint
    nvisuals*: cint
    visuals*: PVisual

  PXDisplay* = ptr TXDisplay
  TXDisplay*{.final.} = object
  PScreen* = ptr TScreen
  TScreen*{.final.} = object
    ext_data*: PXExtData
    display*: PXDisplay
    root*: TWindow
    width*, height*: cint
    mwidth*, mheight*: cint
    ndepths*: cint
    depths*: PDepth
    root_depth*: cint
    root_visual*: PVisual
    default_gc*: TGC
    cmap*: TColormap
    white_pixel*: culong
    black_pixel*: culong
    max_maps*, min_maps*: cint
    backing_store*: cint
    save_unders*: TBool
    root_input_mask*: clong

  PScreenFormat* = ptr TScreenFormat
  TScreenFormat*{.final.} = object
    ext_data*: PXExtData
    depth*: cint
    bits_per_pixel*: cint
    scanline_pad*: cint

  PXSetWindowAttributes* = ptr TXSetWindowAttributes
  TXSetWindowAttributes*{.final.} = object
    background_pixmap*: TPixmap
    background_pixel*: culong
    border_pixmap*: TPixmap
    border_pixel*: culong
    bit_gravity*: cint
    win_gravity*: cint
    backing_store*: cint
    backing_planes*: culong
    backing_pixel*: culong
    save_under*: TBool
    event_mask*: clong
    do_not_propagate_mask*: clong
    override_redirect*: TBool
    colormap*: TColormap
    cursor*: TCursor

  PXWindowAttributes* = ptr TXWindowAttributes
  TXWindowAttributes*{.final.} = object
    x*, y*: cint
    width*, height*: cint
    border_width*: cint
    depth*: cint
    visual*: PVisual
    root*: TWindow
    c_class*: cint
    bit_gravity*: cint
    win_gravity*: cint
    backing_store*: cint
    backing_planes*: culong
    backing_pixel*: culong
    save_under*: TBool
    colormap*: TColormap
    map_installed*: TBool
    map_state*: cint
    all_event_masks*: clong
    your_event_mask*: clong
    do_not_propagate_mask*: clong
    override_redirect*: TBool
    screen*: PScreen

  PXHostAddress* = ptr TXHostAddress
  TXHostAddress*{.final.} = object
    family*: cint
    len*: cint
    address*: cstring

  PXServerInterpretedAddress* = ptr TXServerInterpretedAddress
  TXServerInterpretedAddress*{.final.} = object
    typelength*: cint
    valuelength*: cint
    theType*: cstring
    value*: cstring

  PXImage* = ptr TXImage
  TF*{.final.} = object
    create_image*: proc (para1: PXDisplay, para2: PVisual, para3: cuint,
                         para4: cint, para5: cint, para6: cstring, para7: cuint,
                         para8: cuint, para9: cint, para10: cint): PXImage{.
        cdecl.}
    destroy_image*: proc (para1: PXImage): cint{.cdecl.}
    get_pixel*: proc (para1: PXImage, para2: cint, para3: cint): culong{.cdecl.}
    put_pixel*: proc (para1: PXImage, para2: cint, para3: cint, para4: culong): cint{.
        cdecl.}
    sub_image*: proc (para1: PXImage, para2: cint, para3: cint, para4: cuint,
                      para5: cuint): PXImage{.cdecl.}
    add_pixel*: proc (para1: PXImage, para2: clong): cint{.cdecl.}

  TXImage*{.final.} = object
    width*, height*: cint
    xoffset*: cint
    format*: cint
    data*: cstring
    byte_order*: cint
    bitmap_unit*: cint
    bitmap_bit_order*: cint
    bitmap_pad*: cint
    depth*: cint
    bytes_per_line*: cint
    bits_per_pixel*: cint
    red_mask*: culong
    green_mask*: culong
    blue_mask*: culong
    obdata*: TXPointer
    f*: TF

  PXWindowChanges* = ptr TXWindowChanges
  TXWindowChanges*{.final.} = object
    x*, y*: cint
    width*, height*: cint
    border_width*: cint
    sibling*: TWindow
    stack_mode*: cint

  PXColor* = ptr TXColor
  TXColor*{.final.} = object
    pixel*: culong
    red*, green*, blue*: cushort
    flags*: cchar
    pad*: cchar

  PXSegment* = ptr TXSegment
  TXSegment*{.final.} = object
    x1*, y1*, x2*, y2*: cshort

  PXPoint* = ptr TXPoint
  TXPoint*{.final.} = object
    x*, y*: cshort

  PXRectangle* = ptr TXRectangle
  TXRectangle*{.final.} = object
    x*, y*: cshort
    width*, height*: cushort

  PXArc* = ptr TXArc
  TXArc*{.final.} = object
    x*, y*: cshort
    width*, height*: cushort
    angle1*, angle2*: cshort

  PXKeyboardControl* = ptr TXKeyboardControl
  TXKeyboardControl*{.final.} = object
    key_click_percent*: cint
    bell_percent*: cint
    bell_pitch*: cint
    bell_duration*: cint
    led*: cint
    led_mode*: cint
    key*: cint
    auto_repeat_mode*: cint

  PXKeyboardState* = ptr TXKeyboardState
  TXKeyboardState*{.final.} = object
    key_click_percent*: cint
    bell_percent*: cint
    bell_pitch*, bell_duration*: cuint
    led_mask*: culong
    global_auto_repeat*: cint
    auto_repeats*: array[0..31, cchar]

  PXTimeCoord* = ptr TXTimeCoord
  TXTimeCoord*{.final.} = object
    time*: TTime
    x*, y*: cshort

  PXModifierKeymap* = ptr TXModifierKeymap
  TXModifierKeymap*{.final.} = object
    max_keypermod*: cint
    modifiermap*: PKeyCode

  PDisplay* = ptr TDisplay
  TDisplay* = TXDisplay
  PXPrivate* = ptr TXPrivate
  TXPrivate*{.final.} = object
  PXrmHashBucketRec* = ptr TXrmHashBucketRec
  TXrmHashBucketRec*{.final.} = object
  PXPrivDisplay* = ptr TXPrivDisplay
  TXPrivDisplay*{.final.} = object
    ext_data*: PXExtData
    private1*: PXPrivate
    fd*: cint
    private2*: cint
    proto_major_version*: cint
    proto_minor_version*: cint
    vendor*: cstring
    private3*: TXID
    private4*: TXID
    private5*: TXID
    private6*: cint
    resource_alloc*: proc (para1: PXDisplay): TXID{.cdecl.}
    byte_order*: cint
    bitmap_unit*: cint
    bitmap_pad*: cint
    bitmap_bit_order*: cint
    nformats*: cint
    pixmap_format*: PScreenFormat
    private8*: cint
    release*: cint
    private9*, private10*: PXPrivate
    qlen*: cint
    last_request_read*: culong
    request*: culong
    private11*: TXPointer
    private12*: TXPointer
    private13*: TXPointer
    private14*: TXPointer
    max_request_size*: cunsigned
    db*: PXrmHashBucketRec
    private15*: proc (para1: PXDisplay): cint{.cdecl.}
    display_name*: cstring
    default_screen*: cint
    nscreens*: cint
    screens*: PScreen
    motion_buffer*: culong
    private16*: culong
    min_keycode*: cint
    max_keycode*: cint
    private17*: TXPointer
    private18*: TXPointer
    private19*: cint
    xdefaults*: cstring

  PXKeyEvent* = ptr TXKeyEvent
  TXKeyEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    root*: TWindow
    subwindow*: TWindow
    time*: TTime
    x*, y*: cint
    x_root*, y_root*: cint
    state*: cuint
    keycode*: cuint
    same_screen*: TBool

  PXKeyPressedEvent* = ptr TXKeyPressedEvent
  TXKeyPressedEvent* = TXKeyEvent
  PXKeyReleasedEvent* = ptr TXKeyReleasedEvent
  TXKeyReleasedEvent* = TXKeyEvent
  PXButtonEvent* = ptr TXButtonEvent
  TXButtonEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    root*: TWindow
    subwindow*: TWindow
    time*: TTime
    x*, y*: cint
    x_root*, y_root*: cint
    state*: cuint
    button*: cuint
    same_screen*: TBool

  PXButtonPressedEvent* = ptr TXButtonPressedEvent
  TXButtonPressedEvent* = TXButtonEvent
  PXButtonReleasedEvent* = ptr TXButtonReleasedEvent
  TXButtonReleasedEvent* = TXButtonEvent
  PXMotionEvent* = ptr TXMotionEvent
  TXMotionEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    root*: TWindow
    subwindow*: TWindow
    time*: TTime
    x*, y*: cint
    x_root*, y_root*: cint
    state*: cuint
    is_hint*: cchar
    same_screen*: TBool

  PXPointerMovedEvent* = ptr TXPointerMovedEvent
  TXPointerMovedEvent* = TXMotionEvent
  PXCrossingEvent* = ptr TXCrossingEvent
  TXCrossingEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    root*: TWindow
    subwindow*: TWindow
    time*: TTime
    x*, y*: cint
    x_root*, y_root*: cint
    mode*: cint
    detail*: cint
    same_screen*: TBool
    focus*: TBool
    state*: cuint

  PXEnterWindowEvent* = ptr TXEnterWindowEvent
  TXEnterWindowEvent* = TXCrossingEvent
  PXLeaveWindowEvent* = ptr TXLeaveWindowEvent
  TXLeaveWindowEvent* = TXCrossingEvent
  PXFocusChangeEvent* = ptr TXFocusChangeEvent
  TXFocusChangeEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    mode*: cint
    detail*: cint

  PXFocusInEvent* = ptr TXFocusInEvent
  TXFocusInEvent* = TXFocusChangeEvent
  PXFocusOutEvent* = ptr TXFocusOutEvent
  TXFocusOutEvent* = TXFocusChangeEvent
  PXKeymapEvent* = ptr TXKeymapEvent
  TXKeymapEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    key_vector*: array[0..31, cchar]

  PXExposeEvent* = ptr TXExposeEvent
  TXExposeEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    x*, y*: cint
    width*, height*: cint
    count*: cint

  PXGraphicsExposeEvent* = ptr TXGraphicsExposeEvent
  TXGraphicsExposeEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    drawable*: TDrawable
    x*, y*: cint
    width*, height*: cint
    count*: cint
    major_code*: cint
    minor_code*: cint

  PXNoExposeEvent* = ptr TXNoExposeEvent
  TXNoExposeEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    drawable*: TDrawable
    major_code*: cint
    minor_code*: cint

  PXVisibilityEvent* = ptr TXVisibilityEvent
  TXVisibilityEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    state*: cint

  PXCreateWindowEvent* = ptr TXCreateWindowEvent
  TXCreateWindowEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    parent*: TWindow
    window*: TWindow
    x*, y*: cint
    width*, height*: cint
    border_width*: cint
    override_redirect*: TBool

  PXDestroyWindowEvent* = ptr TXDestroyWindowEvent
  TXDestroyWindowEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    event*: TWindow
    window*: TWindow

  PXUnmapEvent* = ptr TXUnmapEvent
  TXUnmapEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    event*: TWindow
    window*: TWindow
    from_configure*: TBool

  PXMapEvent* = ptr TXMapEvent
  TXMapEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    event*: TWindow
    window*: TWindow
    override_redirect*: TBool

  PXMapRequestEvent* = ptr TXMapRequestEvent
  TXMapRequestEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    parent*: TWindow
    window*: TWindow

  PXReparentEvent* = ptr TXReparentEvent
  TXReparentEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    event*: TWindow
    window*: TWindow
    parent*: TWindow
    x*, y*: cint
    override_redirect*: TBool

  PXConfigureEvent* = ptr TXConfigureEvent
  TXConfigureEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    event*: TWindow
    window*: TWindow
    x*, y*: cint
    width*, height*: cint
    border_width*: cint
    above*: TWindow
    override_redirect*: TBool

  PXGravityEvent* = ptr TXGravityEvent
  TXGravityEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    event*: TWindow
    window*: TWindow
    x*, y*: cint

  PXResizeRequestEvent* = ptr TXResizeRequestEvent
  TXResizeRequestEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    width*, height*: cint

  PXConfigureRequestEvent* = ptr TXConfigureRequestEvent
  TXConfigureRequestEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    parent*: TWindow
    window*: TWindow
    x*, y*: cint
    width*, height*: cint
    border_width*: cint
    above*: TWindow
    detail*: cint
    value_mask*: culong

  PXCirculateEvent* = ptr TXCirculateEvent
  TXCirculateEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    event*: TWindow
    window*: TWindow
    place*: cint

  PXCirculateRequestEvent* = ptr TXCirculateRequestEvent
  TXCirculateRequestEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    parent*: TWindow
    window*: TWindow
    place*: cint

  PXPropertyEvent* = ptr TXPropertyEvent
  TXPropertyEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    atom*: TAtom
    time*: TTime
    state*: cint

  PXSelectionClearEvent* = ptr TXSelectionClearEvent
  TXSelectionClearEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    selection*: TAtom
    time*: TTime

  PXSelectionRequestEvent* = ptr TXSelectionRequestEvent
  TXSelectionRequestEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    owner*: TWindow
    requestor*: TWindow
    selection*: TAtom
    target*: TAtom
    property*: TAtom
    time*: TTime

  PXSelectionEvent* = ptr TXSelectionEvent
  TXSelectionEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    requestor*: TWindow
    selection*: TAtom
    target*: TAtom
    property*: TAtom
    time*: TTime

  PXColormapEvent* = ptr TXColormapEvent
  TXColormapEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    colormap*: TColormap
    c_new*: TBool
    state*: cint

  PXClientMessageEvent* = ptr TXClientMessageEvent
  TXClientMessageEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    message_type*: TAtom
    format*: cint
    data*: array[0..4, clong] # using clong here to be 32/64-bit dependent
        # as the original C union

  PXMappingEvent* = ptr TXMappingEvent
  TXMappingEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow
    request*: cint
    first_keycode*: cint
    count*: cint

  PXErrorEvent* = ptr TXErrorEvent
  TXErrorEvent*{.final.} = object
    theType*: cint
    display*: PDisplay
    resourceid*: TXID
    serial*: culong
    error_code*: cuchar
    request_code*: cuchar
    minor_code*: cuchar

  PXAnyEvent* = ptr TXAnyEvent
  TXAnyEvent*{.final.} = object
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    window*: TWindow

  PXEvent* = ptr TXEvent
  TXEvent*{.final.} = object
    theType*: cint
    pad*: array[0..22, clong] #
                              #       case longint of
                              #          0 : ( theType : cint );
                              #          1 : ( xany : TXAnyEvent );
                              #          2 : ( xkey : TXKeyEvent );
                              #          3 : ( xbutton : TXButtonEvent );
                              #          4 : ( xmotion : TXMotionEvent );
                              #          5 : ( xcrossing : TXCrossingEvent );
                              #          6 : ( xfocus : TXFocusChangeEvent );
                              #          7 : ( xexpose : TXExposeEvent );
                              #          8 : ( xgraphicsexpose : TXGraphicsExposeEvent );
                              #          9 : ( xnoexpose : TXNoExposeEvent );
                              #          10 : ( xvisibility : TXVisibilityEvent );
                              #          11 : ( xcreatewindow : TXCreateWindowEvent );
                              #          12 : ( xdestroywindow : TXDestroyWindowEvent );
                              #          13 : ( xunmap : TXUnmapEvent );
                              #          14 : ( xmap : TXMapEvent );
                              #          15 : ( xmaprequest : TXMapRequestEvent );
                              #          16 : ( xreparent : TXReparentEvent );
                              #          17 : ( xconfigure : TXConfigureEvent );
                              #          18 : ( xgravity : TXGravityEvent );
                              #          19 : ( xresizerequest : TXResizeRequestEvent );
                              #          20 : ( xconfigurerequest : TXConfigureRequestEvent );
                              #          21 : ( xcirculate : TXCirculateEvent );
                              #          22 : ( xcirculaterequest : TXCirculateRequestEvent );
                              #          23 : ( xproperty : TXPropertyEvent );
                              #          24 : ( xselectionclear : TXSelectionClearEvent );
                              #          25 : ( xselectionrequest : TXSelectionRequestEvent );
                              #          26 : ( xselection : TXSelectionEvent );
                              #          27 : ( xcolormap : TXColormapEvent );
                              #          28 : ( xclient : TXClientMessageEvent );
                              #          29 : ( xmapping : TXMappingEvent );
                              #          30 : ( xerror : TXErrorEvent );
                              #          31 : ( xkeymap : TXKeymapEvent );
                              #          32 : ( pad : array[0..23] of clong );
                              #


proc xclient*(e: PXEvent): PXClientMessageEvent =
    ## Treats XEvent as XClientMessageEvent
    return cast[PXClientMessageEvent](e)

proc xclient*(e: var TXEvent): PXClientMessageEvent =
    return xclient(PXEvent(e.addr))

type
  PXCharStruct* = ptr TXCharStruct
  TXCharStruct*{.final.} = object
    lbearing*: cshort
    rbearing*: cshort
    width*: cshort
    ascent*: cshort
    descent*: cshort
    attributes*: cushort

  PXFontProp* = ptr TXFontProp
  TXFontProp*{.final.} = object
    name*: TAtom
    card32*: culong

  PPPXFontStruct* = ptr PPXFontStruct
  PPXFontStruct* = ptr PXFontStruct
  PXFontStruct* = ptr TXFontStruct
  TXFontStruct*{.final.} = object
    ext_data*: PXExtData
    fid*: TFont
    direction*: cunsigned
    min_char_or_byte2*: cunsigned
    max_char_or_byte2*: cunsigned
    min_byte1*: cunsigned
    max_byte1*: cunsigned
    all_chars_exist*: TBool
    default_char*: cunsigned
    n_properties*: cint
    properties*: PXFontProp
    min_bounds*: TXCharStruct
    max_bounds*: TXCharStruct
    per_char*: PXCharStruct
    ascent*: cint
    descent*: cint

  PXTextItem* = ptr TXTextItem
  TXTextItem*{.final.} = object
    chars*: cstring
    nchars*: cint
    delta*: cint
    font*: TFont

  PXChar2b* = ptr TXChar2b
  TXChar2b*{.final.} = object
    byte1*: cuchar
    byte2*: cuchar

  PXTextItem16* = ptr TXTextItem16
  TXTextItem16*{.final.} = object
    chars*: PXChar2b
    nchars*: cint
    delta*: cint
    font*: TFont

  PXEDataObject* = ptr TXEDataObject
  TXEDataObject*{.final.} = object
    display*: PDisplay        #case longint of
                              #          0 : ( display : PDisplay );
                              #          1 : ( gc : TGC );
                              #          2 : ( visual : PVisual );
                              #          3 : ( screen : PScreen );
                              #          4 : ( pixmap_format : PScreenFormat );
                              #          5 : ( font : PXFontStruct );

  PXFontSetExtents* = ptr TXFontSetExtents
  TXFontSetExtents*{.final.} = object
    max_ink_extent*: TXRectangle
    max_logical_extent*: TXRectangle

  PXOM* = ptr TXOM
  TXOM*{.final.} = object
  PXOC* = ptr TXOC
  TXOC*{.final.} = object
  TXFontSet* = PXOC
  PXFontSet* = ptr TXFontSet
  PXmbTextItem* = ptr TXmbTextItem
  TXmbTextItem*{.final.} = object
    chars*: cstring
    nchars*: cint
    delta*: cint
    font_set*: TXFontSet

  PXwcTextItem* = ptr TXwcTextItem
  TXwcTextItem*{.final.} = object
    chars*: PWideChar         #wchar_t*
    nchars*: cint
    delta*: cint
    font_set*: TXFontSet


const
  XNRequiredCharSet* = "requiredCharSet"
  XNQueryOrientation* = "queryOrientation"
  XNBaseFontName* = "baseFontName"
  XNOMAutomatic* = "omAutomatic"
  XNMissingCharSet* = "missingCharSet"
  XNDefaultString* = "defaultString"
  XNOrientation* = "orientation"
  XNDirectionalDependentDrawing* = "directionalDependentDrawing"
  XNContextualDrawing* = "contextualDrawing"
  XNFontInfo* = "fontInfo"

type
  PXOMCharSetList* = ptr TXOMCharSetList
  TXOMCharSetList*{.final.} = object
    charset_count*: cint
    charset_list*: PPChar

  PXOrientation* = ptr TXOrientation
  TXOrientation* = enum
    XOMOrientation_LTR_TTB, XOMOrientation_RTL_TTB, XOMOrientation_TTB_LTR,
    XOMOrientation_TTB_RTL, XOMOrientation_Context
  PXOMOrientation* = ptr TXOMOrientation
  TXOMOrientation*{.final.} = object
    num_orientation*: cint
    orientation*: PXOrientation

  PXOMFontInfo* = ptr TXOMFontInfo
  TXOMFontInfo*{.final.} = object
    num_font*: cint
    font_struct_list*: ptr PXFontStruct
    font_name_list*: PPChar

  PXIM* = ptr TXIM
  TXIM*{.final.} = object
  PXIC* = ptr TXIC
  TXIC*{.final.} = object
  TXIMProc* = proc (para1: TXIM, para2: TXPointer, para3: TXPointer){.cdecl.}
  TXICProc* = proc (para1: TXIC, para2: TXPointer, para3: TXPointer): TBool{.
      cdecl.}
  TXIDProc* = proc (para1: PDisplay, para2: TXPointer, para3: TXPointer){.cdecl.}
  PXIMStyle* = ptr TXIMStyle
  TXIMStyle* = culong
  PXIMStyles* = ptr TXIMStyles
  TXIMStyles*{.final.} = object
    count_styles*: cushort
    supported_styles*: PXIMStyle


const
  XIMPreeditArea* = 0x00000001
  XIMPreeditCallbacks* = 0x00000002
  XIMPreeditPosition* = 0x00000004
  XIMPreeditNothing* = 0x00000008
  XIMPreeditNone* = 0x00000010
  XIMStatusArea* = 0x00000100
  XIMStatusCallbacks* = 0x00000200
  XIMStatusNothing* = 0x00000400
  XIMStatusNone* = 0x00000800
  XNVaNestedList* = "XNVaNestedList"
  XNQueryInputStyle* = "queryInputStyle"
  XNClientWindow* = "clientWindow"
  XNInputStyle* = "inputStyle"
  XNFocusWindow* = "focusWindow"
  XNResourceName* = "resourceName"
  XNResourceClass* = "resourceClass"
  XNGeometryCallback* = "geometryCallback"
  XNDestroyCallback* = "destroyCallback"
  XNFilterEvents* = "filterEvents"
  XNPreeditStartCallback* = "preeditStartCallback"
  XNPreeditDoneCallback* = "preeditDoneCallback"
  XNPreeditDrawCallback* = "preeditDrawCallback"
  XNPreeditCaretCallback* = "preeditCaretCallback"
  XNPreeditStateNotifyCallback* = "preeditStateNotifyCallback"
  XNPreeditAttributes* = "preeditAttributes"
  XNStatusStartCallback* = "statusStartCallback"
  XNStatusDoneCallback* = "statusDoneCallback"
  XNStatusDrawCallback* = "statusDrawCallback"
  XNStatusAttributes* = "statusAttributes"
  XNArea* = "area"
  XNAreaNeeded* = "areaNeeded"
  XNSpotLocation* = "spotLocation"
  XNColormap* = "colorMap"
  XNStdColormap* = "stdColorMap"
  XNForeground* = "foreground"
  XNBackground* = "background"
  XNBackgroundPixmap* = "backgroundPixmap"
  XNFontSet* = "fontSet"
  XNLineSpace* = "lineSpace"
  XNCursor* = "cursor"
  XNQueryIMValuesList* = "queryIMValuesList"
  XNQueryICValuesList* = "queryICValuesList"
  XNVisiblePosition* = "visiblePosition"
  XNR6PreeditCallback* = "r6PreeditCallback"
  XNStringConversionCallback* = "stringConversionCallback"
  XNStringConversion* = "stringConversion"
  XNResetState* = "resetState"
  XNHotKey* = "hotKey"
  XNHotKeyState* = "hotKeyState"
  XNPreeditState* = "preeditState"
  XNSeparatorofNestedList* = "separatorofNestedList"
  XBufferOverflow* = - (1)
  XLookupNone* = 1
  XLookupChars* = 2
  XLookupKeySymVal* = 3
  XLookupBoth* = 4

type
  PXVaNestedList* = ptr TXVaNestedList
  TXVaNestedList* = pointer
  PXIMCallback* = ptr TXIMCallback
  TXIMCallback*{.final.} = object
    client_data*: TXPointer
    callback*: TXIMProc

  PXICCallback* = ptr TXICCallback
  TXICCallback*{.final.} = object
    client_data*: TXPointer
    callback*: TXICProc

  PXIMFeedback* = ptr TXIMFeedback
  TXIMFeedback* = culong

const
  XIMReverse* = 1
  XIMUnderline* = 1 shl 1
  XIMHighlight* = 1 shl 2
  XIMPrimary* = 1 shl 5
  XIMSecondary* = 1 shl 6
  XIMTertiary* = 1 shl 7
  XIMVisibleToForward* = 1 shl 8
  XIMVisibleToBackword* = 1 shl 9
  XIMVisibleToCenter* = 1 shl 10

type
  PXIMText* = ptr TXIMText
  TXIMText*{.final.} = object
    len*: cushort
    feedback*: PXIMFeedback
    encoding_is_wchar*: TBool
    multi_byte*: cstring

  PXIMPreeditState* = ptr TXIMPreeditState
  TXIMPreeditState* = culong

const
  XIMPreeditUnKnown* = 0
  XIMPreeditEnable* = 1
  XIMPreeditDisable* = 1 shl 1

type
  PXIMPreeditStateNotifyCallbackStruct* = ptr TXIMPreeditStateNotifyCallbackStruct
  TXIMPreeditStateNotifyCallbackStruct*{.final.} = object
    state*: TXIMPreeditState

  PXIMResetState* = ptr TXIMResetState
  TXIMResetState* = culong

const
  XIMInitialState* = 1
  XIMPreserveState* = 1 shl 1

type
  PXIMStringConversionFeedback* = ptr TXIMStringConversionFeedback
  TXIMStringConversionFeedback* = culong

const
  XIMStringConversionLeftEdge* = 0x00000001
  XIMStringConversionRightEdge* = 0x00000002
  XIMStringConversionTopEdge* = 0x00000004
  XIMStringConversionBottomEdge* = 0x00000008
  XIMStringConversionConcealed* = 0x00000010
  XIMStringConversionWrapped* = 0x00000020

type
  PXIMStringConversionText* = ptr TXIMStringConversionText
  TXIMStringConversionText*{.final.} = object
    len*: cushort
    feedback*: PXIMStringConversionFeedback
    encoding_is_wchar*: TBool
    mbs*: cstring

  PXIMStringConversionPosition* = ptr TXIMStringConversionPosition
  TXIMStringConversionPosition* = cushort
  PXIMStringConversionType* = ptr TXIMStringConversionType
  TXIMStringConversionType* = cushort

const
  XIMStringConversionBuffer* = 0x00000001
  XIMStringConversionLine* = 0x00000002
  XIMStringConversionWord* = 0x00000003
  XIMStringConversionChar* = 0x00000004

type
  PXIMStringConversionOperation* = ptr TXIMStringConversionOperation
  TXIMStringConversionOperation* = cushort

const
  XIMStringConversionSubstitution* = 0x00000001
  XIMStringConversionRetrieval* = 0x00000002

type
  PXIMCaretDirection* = ptr TXIMCaretDirection
  TXIMCaretDirection* = enum
    XIMForwardChar, XIMBackwardChar, XIMForwardWord, XIMBackwardWord,
    XIMCaretUp, XIMCaretDown, XIMNextLine, XIMPreviousLine, XIMLineStart,
    XIMLineEnd, XIMAbsolutePosition, XIMDontChange
  PXIMStringConversionCallbackStruct* = ptr TXIMStringConversionCallbackStruct
  TXIMStringConversionCallbackStruct*{.final.} = object
    position*: TXIMStringConversionPosition
    direction*: TXIMCaretDirection
    operation*: TXIMStringConversionOperation
    factor*: cushort
    text*: PXIMStringConversionText

  PXIMPreeditDrawCallbackStruct* = ptr TXIMPreeditDrawCallbackStruct
  TXIMPreeditDrawCallbackStruct*{.final.} = object
    caret*: cint
    chg_first*: cint
    chg_length*: cint
    text*: PXIMText

  PXIMCaretStyle* = ptr TXIMCaretStyle
  TXIMCaretStyle* = enum
    XIMIsInvisible, XIMIsPrimary, XIMIsSecondary
  PXIMPreeditCaretCallbackStruct* = ptr TXIMPreeditCaretCallbackStruct
  TXIMPreeditCaretCallbackStruct*{.final.} = object
    position*: cint
    direction*: TXIMCaretDirection
    style*: TXIMCaretStyle

  PXIMStatusDataType* = ptr TXIMStatusDataType
  TXIMStatusDataType* = enum
    XIMTextType, XIMBitmapType
  PXIMStatusDrawCallbackStruct* = ptr TXIMStatusDrawCallbackStruct
  TXIMStatusDrawCallbackStruct*{.final.} = object
    theType*: TXIMStatusDataType
    bitmap*: TPixmap

  PXIMHotKeyTrigger* = ptr TXIMHotKeyTrigger
  TXIMHotKeyTrigger*{.final.} = object
    keysym*: TKeySym
    modifier*: cint
    modifier_mask*: cint

  PXIMHotKeyTriggers* = ptr TXIMHotKeyTriggers
  TXIMHotKeyTriggers*{.final.} = object
    num_hot_key*: cint
    key*: PXIMHotKeyTrigger

  PXIMHotKeyState* = ptr TXIMHotKeyState
  TXIMHotKeyState* = culong

const
  XIMHotKeyStateON* = 0x00000001
  XIMHotKeyStateOFF* = 0x00000002

type
  PXIMValuesList* = ptr TXIMValuesList
  TXIMValuesList*{.final.} = object
    count_values*: cushort
    supported_values*: PPChar


type
  funcdisp* = proc (display: PDisplay): cint{.cdecl.}
  funcifevent* = proc (display: PDisplay, event: PXEvent, p: TXPointer): TBool{.
      cdecl.}
  chararr32* = array[0..31, char]

const
  AllPlanes*: culong = culong(not 0)

proc XLoadQueryFont*(para1: PDisplay, para2: cstring): PXFontStruct{.libx11.}
proc XQueryFont*(para1: PDisplay, para2: TXID): PXFontStruct{.libx11.}
proc XGetMotionEvents*(para1: PDisplay, para2: TWindow, para3: TTime,
                       para4: TTime, para5: Pcint): PXTimeCoord{.libx11.}
proc XDeleteModifiermapEntry*(para1: PXModifierKeymap, para2: TKeyCode,
                              para3: cint): PXModifierKeymap{.libx11.}
proc XGetModifierMapping*(para1: PDisplay): PXModifierKeymap{.libx11.}
proc XInsertModifiermapEntry*(para1: PXModifierKeymap, para2: TKeyCode,
                              para3: cint): PXModifierKeymap{.libx11.}
proc XNewModifiermap*(para1: cint): PXModifierKeymap{.libx11.}
proc XCreateImage*(para1: PDisplay, para2: PVisual, para3: cuint, para4: cint,
                   para5: cint, para6: cstring, para7: cuint, para8: cuint,
                   para9: cint, para10: cint): PXImage{.libx11.}
proc XInitImage*(para1: PXImage): TStatus{.libx11.}
proc XGetImage*(para1: PDisplay, para2: TDrawable, para3: cint, para4: cint,
                para5: cuint, para6: cuint, para7: culong, para8: cint): PXImage{.
    libx11.}
proc XGetSubImage*(para1: PDisplay, para2: TDrawable, para3: cint, para4: cint,
                   para5: cuint, para6: cuint, para7: culong, para8: cint,
                   para9: PXImage, para10: cint, para11: cint): PXImage{.libx11.}
proc XOpenDisplay*(para1: cstring): PDisplay{.libx11.}
proc XrmInitialize*(){.libx11.}
proc XFetchBytes*(para1: PDisplay, para2: Pcint): cstring{.libx11.}
proc XFetchBuffer*(para1: PDisplay, para2: Pcint, para3: cint): cstring{.libx11.}
proc XGetAtomName*(para1: PDisplay, para2: TAtom): cstring{.libx11.}
proc XGetAtomNames*(para1: PDisplay, para2: PAtom, para3: cint, para4: PPchar): TStatus{.
    libx11.}
proc XGetDefault*(para1: PDisplay, para2: cstring, para3: cstring): cstring{.
    libx11.}
proc XDisplayName*(para1: cstring): cstring{.libx11.}
proc XKeysymToString*(para1: TKeySym): cstring{.libx11.}
proc XSynchronize*(para1: PDisplay, para2: TBool): funcdisp{.libx11.}
proc XSetAfterFunction*(para1: PDisplay, para2: funcdisp): funcdisp{.libx11.}
proc XInternAtom*(para1: PDisplay, para2: cstring, para3: TBool): TAtom{.libx11.}
proc XInternAtoms*(para1: PDisplay, para2: PPchar, para3: cint, para4: TBool,
                   para5: PAtom): TStatus{.libx11.}
proc XCopyColormapAndFree*(para1: PDisplay, para2: TColormap): TColormap{.libx11.}
proc XCreateColormap*(para1: PDisplay, para2: TWindow, para3: PVisual,
                      para4: cint): TColormap{.libx11.}
proc XCreatePixmapCursor*(para1: PDisplay, para2: TPixmap, para3: TPixmap,
                          para4: PXColor, para5: PXColor, para6: cuint,
                          para7: cuint): TCursor{.libx11.}
proc XCreateGlyphCursor*(para1: PDisplay, para2: TFont, para3: TFont,
                         para4: cuint, para5: cuint, para6: PXColor,
                         para7: PXColor): TCursor{.libx11.}
proc XCreateFontCursor*(para1: PDisplay, para2: cuint): TCursor{.libx11.}
proc XLoadFont*(para1: PDisplay, para2: cstring): TFont{.libx11.}
proc XCreateGC*(para1: PDisplay, para2: TDrawable, para3: culong,
                para4: PXGCValues): TGC{.libx11.}
proc XGContextFromGC*(para1: TGC): TGContext{.libx11.}
proc XFlushGC*(para1: PDisplay, para2: TGC){.libx11.}
proc XCreatePixmap*(para1: PDisplay, para2: TDrawable, para3: cuint,
                    para4: cuint, para5: cuint): TPixmap{.libx11.}
proc XCreateBitmapFromData*(para1: PDisplay, para2: TDrawable, para3: cstring,
                            para4: cuint, para5: cuint): TPixmap{.libx11.}
proc XCreatePixmapFromBitmapData*(para1: PDisplay, para2: TDrawable,
                                  para3: cstring, para4: cuint, para5: cuint,
                                  para6: culong, para7: culong, para8: cuint): TPixmap{.
    libx11.}
proc XCreateSimpleWindow*(para1: PDisplay, para2: TWindow, para3: cint,
                          para4: cint, para5: cuint, para6: cuint, para7: cuint,
                          para8: culong, para9: culong): TWindow{.libx11.}
proc XGetSelectionOwner*(para1: PDisplay, para2: TAtom): TWindow{.libx11.}
proc XCreateWindow*(para1: PDisplay, para2: TWindow, para3: cint, para4: cint,
                    para5: cuint, para6: cuint, para7: cuint, para8: cint,
                    para9: cuint, para10: PVisual, para11: culong,
                    para12: PXSetWindowAttributes): TWindow{.libx11.}
proc XListInstalledColormaps*(para1: PDisplay, para2: TWindow, para3: Pcint): PColormap{.
    libx11.}
proc XListFonts*(para1: PDisplay, para2: cstring, para3: cint, para4: Pcint): PPChar{.
    libx11.}
proc XListFontsWithInfo*(para1: PDisplay, para2: cstring, para3: cint,
                         para4: Pcint, para5: PPXFontStruct): PPChar{.libx11.}
proc XGetFontPath*(para1: PDisplay, para2: Pcint): PPChar{.libx11.}
proc XListExtensions*(para1: PDisplay, para2: Pcint): PPChar{.libx11.}
proc XListProperties*(para1: PDisplay, para2: TWindow, para3: Pcint): PAtom{.
    libx11.}
proc XListHosts*(para1: PDisplay, para2: Pcint, para3: PBool): PXHostAddress{.
    libx11.}
proc XKeycodeToKeysym*(para1: PDisplay, para2: TKeyCode, para3: cint): TKeySym{.
    libx11.}
proc XLookupKeysym*(para1: PXKeyEvent, para2: cint): TKeySym{.libx11.}
proc XGetKeyboardMapping*(para1: PDisplay, para2: TKeyCode, para3: cint,
                          para4: Pcint): PKeySym{.libx11.}
proc XStringToKeysym*(para1: cstring): TKeySym{.libx11.}
proc XMaxRequestSize*(para1: PDisplay): clong{.libx11.}
proc XExtendedMaxRequestSize*(para1: PDisplay): clong{.libx11.}
proc XResourceManagerString*(para1: PDisplay): cstring{.libx11.}
proc XScreenResourceString*(para1: PScreen): cstring{.libx11.}
proc XDisplayMotionBufferSize*(para1: PDisplay): culong{.libx11.}
proc XVisualIDFromVisual*(para1: PVisual): TVisualID{.libx11.}
proc XInitThreads*(): TStatus{.libx11.}
proc XLockDisplay*(para1: PDisplay){.libx11.}
proc XUnlockDisplay*(para1: PDisplay){.libx11.}
proc XInitExtension*(para1: PDisplay, para2: cstring): PXExtCodes{.libx11.}
proc XAddExtension*(para1: PDisplay): PXExtCodes{.libx11.}
proc XFindOnExtensionList*(para1: PPXExtData, para2: cint): PXExtData{.libx11.}
proc XEHeadOfExtensionList*(para1: TXEDataObject): PPXExtData{.libx11.}
proc XRootWindow*(para1: PDisplay, para2: cint): TWindow{.libx11.}
proc XDefaultRootWindow*(para1: PDisplay): TWindow{.libx11.}
proc XRootWindowOfScreen*(para1: PScreen): TWindow{.libx11.}
proc XDefaultVisual*(para1: PDisplay, para2: cint): PVisual{.libx11.}
proc XDefaultVisualOfScreen*(para1: PScreen): PVisual{.libx11.}
proc XDefaultGC*(para1: PDisplay, para2: cint): TGC{.libx11.}
proc XDefaultGCOfScreen*(para1: PScreen): TGC{.libx11.}
proc XBlackPixel*(para1: PDisplay, para2: cint): culong{.libx11.}
proc XWhitePixel*(para1: PDisplay, para2: cint): culong{.libx11.}
proc XAllPlanes*(): culong{.libx11.}
proc XBlackPixelOfScreen*(para1: PScreen): culong{.libx11.}
proc XWhitePixelOfScreen*(para1: PScreen): culong{.libx11.}
proc XNextRequest*(para1: PDisplay): culong{.libx11.}
proc XLastKnownRequestProcessed*(para1: PDisplay): culong{.libx11.}
proc XServerVendor*(para1: PDisplay): cstring{.libx11.}
proc XDisplayString*(para1: PDisplay): cstring{.libx11.}
proc XDefaultColormap*(para1: PDisplay, para2: cint): TColormap{.libx11.}
proc XDefaultColormapOfScreen*(para1: PScreen): TColormap{.libx11.}
proc XDisplayOfScreen*(para1: PScreen): PDisplay{.libx11.}
proc XScreenOfDisplay*(para1: PDisplay, para2: cint): PScreen{.libx11.}
proc XDefaultScreenOfDisplay*(para1: PDisplay): PScreen{.libx11.}
proc XEventMaskOfScreen*(para1: PScreen): clong{.libx11.}
proc XScreenNumberOfScreen*(para1: PScreen): cint{.libx11.}
type
  TXErrorHandler* = proc (para1: PDisplay, para2: PXErrorEvent): cint{.cdecl.}

proc XSetErrorHandler*(para1: TXErrorHandler): TXErrorHandler{.libx11.}
type
  TXIOErrorHandler* = proc (para1: PDisplay): cint{.cdecl.}

proc XSetIOErrorHandler*(para1: TXIOErrorHandler): TXIOErrorHandler{.libx11.}
proc XListPixmapFormats*(para1: PDisplay, para2: Pcint): PXPixmapFormatValues{.
    libx11.}
proc XListDepths*(para1: PDisplay, para2: cint, para3: Pcint): Pcint{.libx11.}
proc XReconfigureWMWindow*(para1: PDisplay, para2: TWindow, para3: cint,
                           para4: cuint, para5: PXWindowChanges): TStatus{.
    libx11.}
proc XGetWMProtocols*(para1: PDisplay, para2: TWindow, para3: PPAtom,
                      para4: Pcint): TStatus{.libx11.}
proc XSetWMProtocols*(para1: PDisplay, para2: TWindow, para3: PAtom, para4: cint): TStatus{.
    libx11.}
proc XIconifyWindow*(para1: PDisplay, para2: TWindow, para3: cint): TStatus{.
    libx11.}
proc XWithdrawWindow*(para1: PDisplay, para2: TWindow, para3: cint): TStatus{.
    libx11.}
proc XGetCommand*(para1: PDisplay, para2: TWindow, para3: PPPchar, para4: Pcint): TStatus{.
    libx11.}
proc XGetWMColormapWindows*(para1: PDisplay, para2: TWindow, para3: PPWindow,
                            para4: Pcint): TStatus{.libx11.}
proc XSetWMColormapWindows*(para1: PDisplay, para2: TWindow, para3: PWindow,
                            para4: cint): TStatus{.libx11.}
proc XFreeStringList*(para1: PPchar){.libx11.}
proc XSetTransientForHint*(para1: PDisplay, para2: TWindow, para3: TWindow): cint{.
    libx11.}
proc XActivateScreenSaver*(para1: PDisplay): cint{.libx11.}
proc XAddHost*(para1: PDisplay, para2: PXHostAddress): cint{.libx11.}
proc XAddHosts*(para1: PDisplay, para2: PXHostAddress, para3: cint): cint{.
    libx11.}
proc XAddToExtensionList*(para1: PPXExtData, para2: PXExtData): cint{.libx11.}
proc XAddToSaveSet*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XAllocColor*(para1: PDisplay, para2: TColormap, para3: PXColor): TStatus{.
    libx11.}
proc XAllocColorCells*(para1: PDisplay, para2: TColormap, para3: TBool,
                       para4: Pculong, para5: cuint, para6: Pculong,
                       para7: cuint): TStatus{.libx11.}
proc XAllocColorPlanes*(para1: PDisplay, para2: TColormap, para3: TBool,
                        para4: Pculong, para5: cint, para6: cint, para7: cint,
                        para8: cint, para9: Pculong, para10: Pculong,
                        para11: Pculong): TStatus{.libx11.}
proc XAllocNamedColor*(para1: PDisplay, para2: TColormap, para3: cstring,
                       para4: PXColor, para5: PXColor): TStatus{.libx11.}
proc XAllowEvents*(para1: PDisplay, para2: cint, para3: TTime): cint{.libx11.}
proc XAutoRepeatOff*(para1: PDisplay): cint{.libx11.}
proc XAutoRepeatOn*(para1: PDisplay): cint{.libx11.}
proc XBell*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XBitmapBitOrder*(para1: PDisplay): cint{.libx11.}
proc XBitmapPad*(para1: PDisplay): cint{.libx11.}
proc XBitmapUnit*(para1: PDisplay): cint{.libx11.}
proc XCellsOfScreen*(para1: PScreen): cint{.libx11.}
proc XChangeActivePointerGrab*(para1: PDisplay, para2: cuint, para3: TCursor,
                               para4: TTime): cint{.libx11.}
proc XChangeGC*(para1: PDisplay, para2: TGC, para3: culong, para4: PXGCValues): cint{.
    libx11.}
proc XChangeKeyboardControl*(para1: PDisplay, para2: culong,
                             para3: PXKeyboardControl): cint{.libx11.}
proc XChangeKeyboardMapping*(para1: PDisplay, para2: cint, para3: cint,
                             para4: PKeySym, para5: cint): cint{.libx11.}
proc XChangePointerControl*(para1: PDisplay, para2: TBool, para3: TBool,
                            para4: cint, para5: cint, para6: cint): cint{.libx11.}
proc XChangeProperty*(para1: PDisplay, para2: TWindow, para3: TAtom,
                      para4: TAtom, para5: cint, para6: cint, para7: Pcuchar,
                      para8: cint): cint{.libx11.}
proc XChangeSaveSet*(para1: PDisplay, para2: TWindow, para3: cint): cint{.libx11.}
proc XChangeWindowAttributes*(para1: PDisplay, para2: TWindow, para3: culong,
                              para4: PXSetWindowAttributes): cint{.libx11.}
proc XCheckIfEvent*(para1: PDisplay, para2: PXEvent, para3: funcifevent,
                    para4: TXPointer): TBool{.libx11.}
proc XCheckMaskEvent*(para1: PDisplay, para2: clong, para3: PXEvent): TBool{.
    libx11.}
proc XCheckTypedEvent*(para1: PDisplay, para2: cint, para3: PXEvent): TBool{.
    libx11.}
proc XCheckTypedWindowEvent*(para1: PDisplay, para2: TWindow, para3: cint,
                             para4: PXEvent): TBool{.libx11.}
proc XCheckWindowEvent*(para1: PDisplay, para2: TWindow, para3: clong,
                        para4: PXEvent): TBool{.libx11.}
proc XCirculateSubwindows*(para1: PDisplay, para2: TWindow, para3: cint): cint{.
    libx11.}
proc XCirculateSubwindowsDown*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XCirculateSubwindowsUp*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XClearArea*(para1: PDisplay, para2: TWindow, para3: cint, para4: cint,
                 para5: cuint, para6: cuint, para7: TBool): cint{.libx11.}
proc XClearWindow*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XCloseDisplay*(para1: PDisplay): cint{.libx11.}
proc XConfigureWindow*(para1: PDisplay, para2: TWindow, para3: cuint,
                       para4: PXWindowChanges): cint{.libx11.}
proc XConnectionNumber*(para1: PDisplay): cint{.libx11.}
proc XConvertSelection*(para1: PDisplay, para2: TAtom, para3: TAtom,
                        para4: TAtom, para5: TWindow, para6: TTime): cint{.
    libx11.}
proc XCopyArea*(para1: PDisplay, para2: TDrawable, para3: TDrawable, para4: TGC,
                para5: cint, para6: cint, para7: cuint, para8: cuint,
                para9: cint, para10: cint): cint{.libx11.}
proc XCopyGC*(para1: PDisplay, para2: TGC, para3: culong, para4: TGC): cint{.
    libx11.}
proc XCopyPlane*(para1: PDisplay, para2: TDrawable, para3: TDrawable,
                 para4: TGC, para5: cint, para6: cint, para7: cuint,
                 para8: cuint, para9: cint, para10: cint, para11: culong): cint{.
    libx11.}
proc XDefaultDepth*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XDefaultDepthOfScreen*(para1: PScreen): cint{.libx11.}
proc XDefaultScreen*(para1: PDisplay): cint{.libx11.}
proc XDefineCursor*(para1: PDisplay, para2: TWindow, para3: TCursor): cint{.
    libx11.}
proc XDeleteProperty*(para1: PDisplay, para2: TWindow, para3: TAtom): cint{.
    libx11.}
proc XDestroyWindow*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XDestroySubwindows*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XDoesBackingStore*(para1: PScreen): cint{.libx11.}
proc XDoesSaveUnders*(para1: PScreen): TBool{.libx11.}
proc XDisableAccessControl*(para1: PDisplay): cint{.libx11.}
proc XDisplayCells*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XDisplayHeight*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XDisplayHeightMM*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XDisplayKeycodes*(para1: PDisplay, para2: Pcint, para3: Pcint): cint{.
    libx11.}
proc XDisplayPlanes*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XDisplayWidth*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XDisplayWidthMM*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XDrawArc*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
               para5: cint, para6: cuint, para7: cuint, para8: cint, para9: cint): cint{.
    libx11.}
proc XDrawArcs*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: PXArc,
                para5: cint): cint{.libx11.}
proc XDrawImageString*(para1: PDisplay, para2: TDrawable, para3: TGC,
                       para4: cint, para5: cint, para6: cstring, para7: cint): cint{.
    libx11.}
proc XDrawImageString16*(para1: PDisplay, para2: TDrawable, para3: TGC,
                         para4: cint, para5: cint, para6: PXChar2b, para7: cint): cint{.
    libx11.}
proc XDrawLine*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
                para5: cint, para6: cint, para7: cint): cint{.libx11.}
proc XDrawLines*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: PXPoint,
                 para5: cint, para6: cint): cint{.libx11.}
proc XDrawPoint*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
                 para5: cint): cint{.libx11.}
proc XDrawPoints*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: PXPoint,
                  para5: cint, para6: cint): cint{.libx11.}
proc XDrawRectangle*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
                     para5: cint, para6: cuint, para7: cuint): cint{.libx11.}
proc XDrawRectangles*(para1: PDisplay, para2: TDrawable, para3: TGC,
                      para4: PXRectangle, para5: cint): cint{.libx11.}
proc XDrawSegments*(para1: PDisplay, para2: TDrawable, para3: TGC,
                    para4: PXSegment, para5: cint): cint{.libx11.}
proc XDrawString*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
                  para5: cint, para6: cstring, para7: cint): cint{.libx11.}
proc XDrawString16*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
                    para5: cint, para6: PXChar2b, para7: cint): cint{.libx11.}
proc XDrawText*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
                para5: cint, para6: PXTextItem, para7: cint): cint{.libx11.}
proc XDrawText16*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
                  para5: cint, para6: PXTextItem16, para7: cint): cint{.libx11.}
proc XEnableAccessControl*(para1: PDisplay): cint{.libx11.}
proc XEventsQueued*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XFetchName*(para1: PDisplay, para2: TWindow, para3: PPchar): TStatus{.
    libx11.}
proc XFillArc*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
               para5: cint, para6: cuint, para7: cuint, para8: cint, para9: cint): cint{.
    libx11.}
proc XFillArcs*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: PXArc,
                para5: cint): cint{.libx11.}
proc XFillPolygon*(para1: PDisplay, para2: TDrawable, para3: TGC,
                   para4: PXPoint, para5: cint, para6: cint, para7: cint): cint{.
    libx11.}
proc XFillRectangle*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
                     para5: cint, para6: cuint, para7: cuint): cint{.libx11.}
proc XFillRectangles*(para1: PDisplay, para2: TDrawable, para3: TGC,
                      para4: PXRectangle, para5: cint): cint{.libx11.}
proc XFlush*(para1: PDisplay): cint{.libx11.}
proc XForceScreenSaver*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XFree*(para1: pointer): cint{.libx11.}
proc XFreeColormap*(para1: PDisplay, para2: TColormap): cint{.libx11.}
proc XFreeColors*(para1: PDisplay, para2: TColormap, para3: Pculong,
                  para4: cint, para5: culong): cint{.libx11.}
proc XFreeCursor*(para1: PDisplay, para2: TCursor): cint{.libx11.}
proc XFreeExtensionList*(para1: PPchar): cint{.libx11.}
proc XFreeFont*(para1: PDisplay, para2: PXFontStruct): cint{.libx11.}
proc XFreeFontInfo*(para1: PPchar, para2: PXFontStruct, para3: cint): cint{.
    libx11.}
proc XFreeFontNames*(para1: PPchar): cint{.libx11.}
proc XFreeFontPath*(para1: PPchar): cint{.libx11.}
proc XFreeGC*(para1: PDisplay, para2: TGC): cint{.libx11.}
proc XFreeModifiermap*(para1: PXModifierKeymap): cint{.libx11.}
proc XFreePixmap*(para1: PDisplay, para2: TPixmap): cint{.libx11.}
proc XGeometry*(para1: PDisplay, para2: cint, para3: cstring, para4: cstring,
                para5: cuint, para6: cuint, para7: cuint, para8: cint,
                para9: cint, para10: Pcint, para11: Pcint, para12: Pcint,
                para13: Pcint): cint{.libx11.}
proc XGetErrorDatabaseText*(para1: PDisplay, para2: cstring, para3: cstring,
                            para4: cstring, para5: cstring, para6: cint): cint{.
    libx11.}
proc XGetErrorText*(para1: PDisplay, para2: cint, para3: cstring, para4: cint): cint{.
    libx11.}
proc XGetFontProperty*(para1: PXFontStruct, para2: TAtom, para3: Pculong): TBool{.
    libx11.}
proc XGetGCValues*(para1: PDisplay, para2: TGC, para3: culong, para4: PXGCValues): TStatus{.
    libx11.}
proc XGetGeometry*(para1: PDisplay, para2: TDrawable, para3: PWindow,
                   para4: Pcint, para5: Pcint, para6: Pcuint, para7: Pcuint,
                   para8: Pcuint, para9: Pcuint): TStatus{.libx11.}
proc XGetIconName*(para1: PDisplay, para2: TWindow, para3: PPchar): TStatus{.
    libx11.}
proc XGetInputFocus*(para1: PDisplay, para2: PWindow, para3: Pcint): cint{.
    libx11.}
proc XGetKeyboardControl*(para1: PDisplay, para2: PXKeyboardState): cint{.libx11.}
proc XGetPointerControl*(para1: PDisplay, para2: Pcint, para3: Pcint,
                         para4: Pcint): cint{.libx11.}
proc XGetPointerMapping*(para1: PDisplay, para2: Pcuchar, para3: cint): cint{.
    libx11.}
proc XGetScreenSaver*(para1: PDisplay, para2: Pcint, para3: Pcint, para4: Pcint,
                      para5: Pcint): cint{.libx11.}
proc XGetTransientForHint*(para1: PDisplay, para2: TWindow, para3: PWindow): TStatus{.
    libx11.}
proc XGetWindowProperty*(para1: PDisplay, para2: TWindow, para3: TAtom,
                         para4: clong, para5: clong, para6: TBool, para7: TAtom,
                         para8: PAtom, para9: Pcint, para10: Pculong,
                         para11: Pculong, para12: PPcuchar): cint{.libx11.}
proc XGetWindowAttributes*(para1: PDisplay, para2: TWindow,
                           para3: PXWindowAttributes): TStatus{.libx11.}
proc XGrabButton*(para1: PDisplay, para2: cuint, para3: cuint, para4: TWindow,
                  para5: TBool, para6: cuint, para7: cint, para8: cint,
                  para9: TWindow, para10: TCursor): cint{.libx11.}
proc XGrabKey*(para1: PDisplay, para2: cint, para3: cuint, para4: TWindow,
               para5: TBool, para6: cint, para7: cint): cint{.libx11.}
proc XGrabKeyboard*(para1: PDisplay, para2: TWindow, para3: TBool, para4: cint,
                    para5: cint, para6: TTime): cint{.libx11.}
proc XGrabPointer*(para1: PDisplay, para2: TWindow, para3: TBool, para4: cuint,
                   para5: cint, para6: cint, para7: TWindow, para8: TCursor,
                   para9: TTime): cint{.libx11.}
proc XGrabServer*(para1: PDisplay): cint{.libx11.}
proc XHeightMMOfScreen*(para1: PScreen): cint{.libx11.}
proc XHeightOfScreen*(para1: PScreen): cint{.libx11.}
proc XIfEvent*(para1: PDisplay, para2: PXEvent, para3: funcifevent,
               para4: TXPointer): cint{.libx11.}
proc XImageByteOrder*(para1: PDisplay): cint{.libx11.}
proc XInstallColormap*(para1: PDisplay, para2: TColormap): cint{.libx11.}
proc XKeysymToKeycode*(para1: PDisplay, para2: TKeySym): TKeyCode{.libx11.}
proc XKillClient*(para1: PDisplay, para2: TXID): cint{.libx11.}
proc XLookupColor*(para1: PDisplay, para2: TColormap, para3: cstring,
                   para4: PXColor, para5: PXColor): TStatus{.libx11.}
proc XLowerWindow*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XMapRaised*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XMapSubwindows*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XMapWindow*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XMaskEvent*(para1: PDisplay, para2: clong, para3: PXEvent): cint{.libx11.}
proc XMaxCmapsOfScreen*(para1: PScreen): cint{.libx11.}
proc XMinCmapsOfScreen*(para1: PScreen): cint{.libx11.}
proc XMoveResizeWindow*(para1: PDisplay, para2: TWindow, para3: cint,
                        para4: cint, para5: cuint, para6: cuint): cint{.libx11.}
proc XMoveWindow*(para1: PDisplay, para2: TWindow, para3: cint, para4: cint): cint{.
    libx11.}
proc XNextEvent*(para1: PDisplay, para2: PXEvent): cint{.libx11.}
proc XNoOp*(para1: PDisplay): cint{.libx11.}
proc XParseColor*(para1: PDisplay, para2: TColormap, para3: cstring,
                  para4: PXColor): TStatus{.libx11.}
proc XParseGeometry*(para1: cstring, para2: Pcint, para3: Pcint, para4: Pcuint,
                     para5: Pcuint): cint{.libx11.}
proc XPeekEvent*(para1: PDisplay, para2: PXEvent): cint{.libx11.}
proc XPeekIfEvent*(para1: PDisplay, para2: PXEvent, para3: funcifevent,
                   para4: TXPointer): cint{.libx11.}
proc XPending*(para1: PDisplay): cint{.libx11.}
proc XPlanesOfScreen*(para1: PScreen): cint{.libx11.}
proc XProtocolRevision*(para1: PDisplay): cint{.libx11.}
proc XProtocolVersion*(para1: PDisplay): cint{.libx11.}
proc XPutBackEvent*(para1: PDisplay, para2: PXEvent): cint{.libx11.}
proc XPutImage*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: PXImage,
                para5: cint, para6: cint, para7: cint, para8: cint,
                para9: cuint, para10: cuint): cint{.libx11.}
proc XQLength*(para1: PDisplay): cint{.libx11.}
proc XQueryBestCursor*(para1: PDisplay, para2: TDrawable, para3: cuint,
                       para4: cuint, para5: Pcuint, para6: Pcuint): TStatus{.
    libx11.}
proc XQueryBestSize*(para1: PDisplay, para2: cint, para3: TDrawable,
                     para4: cuint, para5: cuint, para6: Pcuint, para7: Pcuint): TStatus{.
    libx11.}
proc XQueryBestStipple*(para1: PDisplay, para2: TDrawable, para3: cuint,
                        para4: cuint, para5: Pcuint, para6: Pcuint): TStatus{.
    libx11.}
proc XQueryBestTile*(para1: PDisplay, para2: TDrawable, para3: cuint,
                     para4: cuint, para5: Pcuint, para6: Pcuint): TStatus{.
    libx11.}
proc XQueryColor*(para1: PDisplay, para2: TColormap, para3: PXColor): cint{.
    libx11.}
proc XQueryColors*(para1: PDisplay, para2: TColormap, para3: PXColor,
                   para4: cint): cint{.libx11.}
proc XQueryExtension*(para1: PDisplay, para2: cstring, para3: Pcint,
                      para4: Pcint, para5: Pcint): TBool{.libx11.}
  #?
proc XQueryKeymap*(para1: PDisplay, para2: chararr32): cint{.libx11.}
proc XQueryPointer*(para1: PDisplay, para2: TWindow, para3: PWindow,
                    para4: PWindow, para5: Pcint, para6: Pcint, para7: Pcint,
                    para8: Pcint, para9: Pcuint): TBool{.libx11.}
proc XQueryTextExtents*(para1: PDisplay, para2: TXID, para3: cstring,
                        para4: cint, para5: Pcint, para6: Pcint, para7: Pcint,
                        para8: PXCharStruct): cint{.libx11.}
proc XQueryTextExtents16*(para1: PDisplay, para2: TXID, para3: PXChar2b,
                          para4: cint, para5: Pcint, para6: Pcint, para7: Pcint,
                          para8: PXCharStruct): cint{.libx11.}
proc XQueryTree*(para1: PDisplay, para2: TWindow, para3: PWindow,
                 para4: PWindow, para5: PPWindow, para6: Pcuint): TStatus{.
    libx11.}
proc XRaiseWindow*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XReadBitmapFile*(para1: PDisplay, para2: TDrawable, para3: cstring,
                      para4: Pcuint, para5: Pcuint, para6: PPixmap,
                      para7: Pcint, para8: Pcint): cint{.libx11.}
proc XReadBitmapFileData*(para1: cstring, para2: Pcuint, para3: Pcuint,
                          para4: PPcuchar, para5: Pcint, para6: Pcint): cint{.
    libx11.}
proc XRebindKeysym*(para1: PDisplay, para2: TKeySym, para3: PKeySym,
                    para4: cint, para5: Pcuchar, para6: cint): cint{.libx11.}
proc XRecolorCursor*(para1: PDisplay, para2: TCursor, para3: PXColor,
                     para4: PXColor): cint{.libx11.}
proc XRefreshKeyboardMapping*(para1: PXMappingEvent): cint{.libx11.}
proc XRemoveFromSaveSet*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XRemoveHost*(para1: PDisplay, para2: PXHostAddress): cint{.libx11.}
proc XRemoveHosts*(para1: PDisplay, para2: PXHostAddress, para3: cint): cint{.
    libx11.}
proc XReparentWindow*(para1: PDisplay, para2: TWindow, para3: TWindow,
                      para4: cint, para5: cint): cint{.libx11.}
proc XResetScreenSaver*(para1: PDisplay): cint{.libx11.}
proc XResizeWindow*(para1: PDisplay, para2: TWindow, para3: cuint, para4: cuint): cint{.
    libx11.}
proc XRestackWindows*(para1: PDisplay, para2: PWindow, para3: cint): cint{.
    libx11.}
proc XRotateBuffers*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XRotateWindowProperties*(para1: PDisplay, para2: TWindow, para3: PAtom,
                              para4: cint, para5: cint): cint{.libx11.}
proc XScreenCount*(para1: PDisplay): cint{.libx11.}
proc XSelectInput*(para1: PDisplay, para2: TWindow, para3: clong): cint{.libx11.}
proc XSendEvent*(para1: PDisplay, para2: TWindow, para3: TBool, para4: clong,
                 para5: PXEvent): TStatus{.libx11.}
proc XSetAccessControl*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XSetArcMode*(para1: PDisplay, para2: TGC, para3: cint): cint{.libx11.}
proc XSetBackground*(para1: PDisplay, para2: TGC, para3: culong): cint{.libx11.}
proc XSetClipMask*(para1: PDisplay, para2: TGC, para3: TPixmap): cint{.libx11.}
proc XSetClipOrigin*(para1: PDisplay, para2: TGC, para3: cint, para4: cint): cint{.
    libx11.}
proc XSetClipRectangles*(para1: PDisplay, para2: TGC, para3: cint, para4: cint,
                         para5: PXRectangle, para6: cint, para7: cint): cint{.
    libx11.}
proc XSetCloseDownMode*(para1: PDisplay, para2: cint): cint{.libx11.}
proc XSetCommand*(para1: PDisplay, para2: TWindow, para3: PPchar, para4: cint): cint{.
    libx11.}
proc XSetDashes*(para1: PDisplay, para2: TGC, para3: cint, para4: cstring,
                 para5: cint): cint{.libx11.}
proc XSetFillRule*(para1: PDisplay, para2: TGC, para3: cint): cint{.libx11.}
proc XSetFillStyle*(para1: PDisplay, para2: TGC, para3: cint): cint{.libx11.}
proc XSetFont*(para1: PDisplay, para2: TGC, para3: TFont): cint{.libx11.}
proc XSetFontPath*(para1: PDisplay, para2: PPchar, para3: cint): cint{.libx11.}
proc XSetForeground*(para1: PDisplay, para2: TGC, para3: culong): cint{.libx11.}
proc XSetFunction*(para1: PDisplay, para2: TGC, para3: cint): cint{.libx11.}
proc XSetGraphicsExposures*(para1: PDisplay, para2: TGC, para3: TBool): cint{.
    libx11.}
proc XSetIconName*(para1: PDisplay, para2: TWindow, para3: cstring): cint{.
    libx11.}
proc XSetInputFocus*(para1: PDisplay, para2: TWindow, para3: cint, para4: TTime): cint{.
    libx11.}
proc XSetLineAttributes*(para1: PDisplay, para2: TGC, para3: cuint, para4: cint,
                         para5: cint, para6: cint): cint{.libx11.}
proc XSetModifierMapping*(para1: PDisplay, para2: PXModifierKeymap): cint{.
    libx11.}
proc XSetPlaneMask*(para1: PDisplay, para2: TGC, para3: culong): cint{.libx11.}
proc XSetPointerMapping*(para1: PDisplay, para2: Pcuchar, para3: cint): cint{.
    libx11.}
proc XSetScreenSaver*(para1: PDisplay, para2: cint, para3: cint, para4: cint,
                      para5: cint): cint{.libx11.}
proc XSetSelectionOwner*(para1: PDisplay, para2: TAtom, para3: TWindow,
                         para4: TTime): cint{.libx11.}
proc XSetState*(para1: PDisplay, para2: TGC, para3: culong, para4: culong,
                para5: cint, para6: culong): cint{.libx11.}
proc XSetStipple*(para1: PDisplay, para2: TGC, para3: TPixmap): cint{.libx11.}
proc XSetSubwindowMode*(para1: PDisplay, para2: TGC, para3: cint): cint{.libx11.}
proc XSetTSOrigin*(para1: PDisplay, para2: TGC, para3: cint, para4: cint): cint{.
    libx11.}
proc XSetTile*(para1: PDisplay, para2: TGC, para3: TPixmap): cint{.libx11.}
proc XSetWindowBackground*(para1: PDisplay, para2: TWindow, para3: culong): cint{.
    libx11.}
proc XSetWindowBackgroundPixmap*(para1: PDisplay, para2: TWindow, para3: TPixmap): cint{.
    libx11.}
proc XSetWindowBorder*(para1: PDisplay, para2: TWindow, para3: culong): cint{.
    libx11.}
proc XSetWindowBorderPixmap*(para1: PDisplay, para2: TWindow, para3: TPixmap): cint{.
    libx11.}
proc XSetWindowBorderWidth*(para1: PDisplay, para2: TWindow, para3: cuint): cint{.
    libx11.}
proc XSetWindowColormap*(para1: PDisplay, para2: TWindow, para3: TColormap): cint{.
    libx11.}
proc XStoreBuffer*(para1: PDisplay, para2: cstring, para3: cint, para4: cint): cint{.
    libx11.}
proc XStoreBytes*(para1: PDisplay, para2: cstring, para3: cint): cint{.libx11.}
proc XStoreColor*(para1: PDisplay, para2: TColormap, para3: PXColor): cint{.
    libx11.}
proc XStoreColors*(para1: PDisplay, para2: TColormap, para3: PXColor,
                   para4: cint): cint{.libx11.}
proc XStoreName*(para1: PDisplay, para2: TWindow, para3: cstring): cint{.libx11.}
proc XStoreNamedColor*(para1: PDisplay, para2: TColormap, para3: cstring,
                       para4: culong, para5: cint): cint{.libx11.}
proc XSync*(para1: PDisplay, para2: TBool): cint{.libx11.}
proc XTextExtents*(para1: PXFontStruct, para2: cstring, para3: cint,
                   para4: Pcint, para5: Pcint, para6: Pcint, para7: PXCharStruct): cint{.
    libx11.}
proc XTextExtents16*(para1: PXFontStruct, para2: PXChar2b, para3: cint,
                     para4: Pcint, para5: Pcint, para6: Pcint,
                     para7: PXCharStruct): cint{.libx11.}
proc XTextWidth*(para1: PXFontStruct, para2: cstring, para3: cint): cint{.libx11.}
proc XTextWidth16*(para1: PXFontStruct, para2: PXChar2b, para3: cint): cint{.
    libx11.}
proc XTranslateCoordinates*(para1: PDisplay, para2: TWindow, para3: TWindow,
                            para4: cint, para5: cint, para6: Pcint,
                            para7: Pcint, para8: PWindow): TBool{.libx11.}
proc XUndefineCursor*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XUngrabButton*(para1: PDisplay, para2: cuint, para3: cuint, para4: TWindow): cint{.
    libx11.}
proc XUngrabKey*(para1: PDisplay, para2: cint, para3: cuint, para4: TWindow): cint{.
    libx11.}
proc XUngrabKeyboard*(para1: PDisplay, para2: TTime): cint{.libx11.}
proc XUngrabPointer*(para1: PDisplay, para2: TTime): cint{.libx11.}
proc XUngrabServer*(para1: PDisplay): cint{.libx11.}
proc XUninstallColormap*(para1: PDisplay, para2: TColormap): cint{.libx11.}
proc XUnloadFont*(para1: PDisplay, para2: TFont): cint{.libx11.}
proc XUnmapSubwindows*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XUnmapWindow*(para1: PDisplay, para2: TWindow): cint{.libx11.}
proc XVendorRelease*(para1: PDisplay): cint{.libx11.}
proc XWarpPointer*(para1: PDisplay, para2: TWindow, para3: TWindow, para4: cint,
                   para5: cint, para6: cuint, para7: cuint, para8: cint,
                   para9: cint): cint{.libx11.}
proc XWidthMMOfScreen*(para1: PScreen): cint{.libx11.}
proc XWidthOfScreen*(para1: PScreen): cint{.libx11.}
proc XWindowEvent*(para1: PDisplay, para2: TWindow, para3: clong, para4: PXEvent): cint{.
    libx11.}
proc XWriteBitmapFile*(para1: PDisplay, para2: cstring, para3: TPixmap,
                       para4: cuint, para5: cuint, para6: cint, para7: cint): cint{.
    libx11.}
proc XSupportsLocale*(): TBool{.libx11.}
proc XSetLocaleModifiers*(para1: cstring): cstring{.libx11.}
proc XOpenOM*(para1: PDisplay, para2: PXrmHashBucketRec, para3: cstring,
              para4: cstring): TXOM{.libx11.}
proc XCloseOM*(para1: TXOM): TStatus{.libx11.}
proc XSetOMValues*(para1: TXOM): cstring{.varargs, libx11.}
proc XGetOMValues*(para1: TXOM): cstring{.varargs, libx11.}
proc XDisplayOfOM*(para1: TXOM): PDisplay{.libx11.}
proc XLocaleOfOM*(para1: TXOM): cstring{.libx11.}
proc XCreateOC*(para1: TXOM): TXOC{.varargs, libx11.}
proc XDestroyOC*(para1: TXOC){.libx11.}
proc XOMOfOC*(para1: TXOC): TXOM{.libx11.}
proc XSetOCValues*(para1: TXOC): cstring{.varargs, libx11.}
proc XGetOCValues*(para1: TXOC): cstring{.varargs, libx11.}
proc XCreateFontSet*(para1: PDisplay, para2: cstring, para3: PPPchar,
                     para4: Pcint, para5: PPchar): TXFontSet{.libx11.}
proc XFreeFontSet*(para1: PDisplay, para2: TXFontSet){.libx11.}
proc XFontsOfFontSet*(para1: TXFontSet, para2: PPPXFontStruct, para3: PPPchar): cint{.
    libx11.}
proc XBaseFontNameListOfFontSet*(para1: TXFontSet): cstring{.libx11.}
proc XLocaleOfFontSet*(para1: TXFontSet): cstring{.libx11.}
proc XContextDependentDrawing*(para1: TXFontSet): TBool{.libx11.}
proc XDirectionalDependentDrawing*(para1: TXFontSet): TBool{.libx11.}
proc XContextualDrawing*(para1: TXFontSet): TBool{.libx11.}
proc XExtentsOfFontSet*(para1: TXFontSet): PXFontSetExtents{.libx11.}
proc XmbTextEscapement*(para1: TXFontSet, para2: cstring, para3: cint): cint{.
    libx11.}
proc XwcTextEscapement*(para1: TXFontSet, para2: PWideChar, para3: cint): cint{.
    libx11.}
proc Xutf8TextEscapement*(para1: TXFontSet, para2: cstring, para3: cint): cint{.
    libx11.}
proc XmbTextExtents*(para1: TXFontSet, para2: cstring, para3: cint,
                     para4: PXRectangle, para5: PXRectangle): cint{.libx11.}
proc XwcTextExtents*(para1: TXFontSet, para2: PWideChar, para3: cint,
                     para4: PXRectangle, para5: PXRectangle): cint{.libx11.}
proc Xutf8TextExtents*(para1: TXFontSet, para2: cstring, para3: cint,
                       para4: PXRectangle, para5: PXRectangle): cint{.libx11.}
proc XmbTextPerCharExtents*(para1: TXFontSet, para2: cstring, para3: cint,
                            para4: PXRectangle, para5: PXRectangle, para6: cint,
                            para7: Pcint, para8: PXRectangle, para9: PXRectangle): TStatus{.
    libx11.}
proc XwcTextPerCharExtents*(para1: TXFontSet, para2: PWideChar, para3: cint,
                            para4: PXRectangle, para5: PXRectangle, para6: cint,
                            para7: Pcint, para8: PXRectangle, para9: PXRectangle): TStatus{.
    libx11.}
proc Xutf8TextPerCharExtents*(para1: TXFontSet, para2: cstring, para3: cint,
                              para4: PXRectangle, para5: PXRectangle,
                              para6: cint, para7: Pcint, para8: PXRectangle,
                              para9: PXRectangle): TStatus{.libx11.}
proc XmbDrawText*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
                  para5: cint, para6: PXmbTextItem, para7: cint){.libx11.}
proc XwcDrawText*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
                  para5: cint, para6: PXwcTextItem, para7: cint){.libx11.}
proc Xutf8DrawText*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint,
                    para5: cint, para6: PXmbTextItem, para7: cint){.libx11.}
proc XmbDrawString*(para1: PDisplay, para2: TDrawable, para3: TXFontSet,
                    para4: TGC, para5: cint, para6: cint, para7: cstring,
                    para8: cint){.libx11.}
proc XwcDrawString*(para1: PDisplay, para2: TDrawable, para3: TXFontSet,
                    para4: TGC, para5: cint, para6: cint, para7: PWideChar,
                    para8: cint){.libx11.}
proc Xutf8DrawString*(para1: PDisplay, para2: TDrawable, para3: TXFontSet,
                      para4: TGC, para5: cint, para6: cint, para7: cstring,
                      para8: cint){.libx11.}
proc XmbDrawImageString*(para1: PDisplay, para2: TDrawable, para3: TXFontSet,
                         para4: TGC, para5: cint, para6: cint, para7: cstring,
                         para8: cint){.libx11.}
proc XwcDrawImageString*(para1: PDisplay, para2: TDrawable, para3: TXFontSet,
                         para4: TGC, para5: cint, para6: cint, para7: PWideChar,
                         para8: cint){.libx11.}
proc Xutf8DrawImageString*(para1: PDisplay, para2: TDrawable, para3: TXFontSet,
                           para4: TGC, para5: cint, para6: cint, para7: cstring,
                           para8: cint){.libx11.}
proc XOpenIM*(para1: PDisplay, para2: PXrmHashBucketRec, para3: cstring,
              para4: cstring): TXIM{.libx11.}
proc XCloseIM*(para1: TXIM): TStatus{.libx11.}
proc XGetIMValues*(para1: TXIM): cstring{.varargs, libx11.}
proc XSetIMValues*(para1: TXIM): cstring{.varargs, libx11.}
proc XDisplayOfIM*(para1: TXIM): PDisplay{.libx11.}
proc XLocaleOfIM*(para1: TXIM): cstring{.libx11.}
proc XCreateIC*(para1: TXIM): TXIC{.varargs, libx11.}
proc XDestroyIC*(para1: TXIC){.libx11.}
proc XSetICFocus*(para1: TXIC){.libx11.}
proc XUnsetICFocus*(para1: TXIC){.libx11.}
proc XwcResetIC*(para1: TXIC): PWideChar{.libx11.}
proc XmbResetIC*(para1: TXIC): cstring{.libx11.}
proc Xutf8ResetIC*(para1: TXIC): cstring{.libx11.}
proc XSetICValues*(para1: TXIC): cstring{.varargs, libx11.}
proc XGetICValues*(para1: TXIC): cstring{.varargs, libx11.}
proc XIMOfIC*(para1: TXIC): TXIM{.libx11.}
proc XFilterEvent*(para1: PXEvent, para2: TWindow): TBool{.libx11.}
proc XmbLookupString*(para1: TXIC, para2: PXKeyPressedEvent, para3: cstring,
                      para4: cint, para5: PKeySym, para6: PStatus): cint{.libx11.}
proc XwcLookupString*(para1: TXIC, para2: PXKeyPressedEvent, para3: PWideChar,
                      para4: cint, para5: PKeySym, para6: PStatus): cint{.libx11.}
proc Xutf8LookupString*(para1: TXIC, para2: PXKeyPressedEvent, para3: cstring,
                        para4: cint, para5: PKeySym, para6: PStatus): cint{.
    libx11.}
proc XVaCreateNestedList*(unused: cint): TXVaNestedList{.varargs, libx11.}
proc XRegisterIMInstantiateCallback*(para1: PDisplay, para2: PXrmHashBucketRec,
                                     para3: cstring, para4: cstring,
                                     para5: TXIDProc, para6: TXPointer): TBool{.
    libx11.}
proc XUnregisterIMInstantiateCallback*(para1: PDisplay,
                                       para2: PXrmHashBucketRec, para3: cstring,
                                       para4: cstring, para5: TXIDProc,
                                       para6: TXPointer): TBool{.libx11.}
type
  TXConnectionWatchProc* = proc (para1: PDisplay, para2: TXPointer, para3: cint,
                                 para4: TBool, para5: PXPointer){.cdecl.}

proc XInternalConnectionNumbers*(para1: PDisplay, para2: PPcint, para3: Pcint): TStatus{.
    libx11.}
proc XProcessInternalConnection*(para1: PDisplay, para2: cint){.libx11.}
proc XAddConnectionWatch*(para1: PDisplay, para2: TXConnectionWatchProc,
                          para3: TXPointer): TStatus{.libx11.}
proc XRemoveConnectionWatch*(para1: PDisplay, para2: TXConnectionWatchProc,
                             para3: TXPointer){.libx11.}
proc XSetAuthorization*(para1: cstring, para2: cint, para3: cstring, para4: cint){.
    libx11.}
  #
  #  _Xmbtowc?
  #  _Xwctomb?
  #
#when defined(MACROS):
proc ConnectionNumber*(dpy: PDisplay): cint
proc RootWindow*(dpy: PDisplay, scr: cint): TWindow
proc DefaultScreen*(dpy: PDisplay): cint
proc DefaultRootWindow*(dpy: PDisplay): TWindow
proc DefaultVisual*(dpy: PDisplay, scr: cint): PVisual
proc DefaultGC*(dpy: PDisplay, scr: cint): TGC
proc BlackPixel*(dpy: PDisplay, scr: cint): culong
proc WhitePixel*(dpy: PDisplay, scr: cint): culong
proc QLength*(dpy: PDisplay): cint
proc DisplayWidth*(dpy: PDisplay, scr: cint): cint
proc DisplayHeight*(dpy: PDisplay, scr: cint): cint
proc DisplayWidthMM*(dpy: PDisplay, scr: cint): cint
proc DisplayHeightMM*(dpy: PDisplay, scr: cint): cint
proc DisplayPlanes*(dpy: PDisplay, scr: cint): cint
proc DisplayCells*(dpy: PDisplay, scr: cint): cint
proc ScreenCount*(dpy: PDisplay): cint
proc ServerVendor*(dpy: PDisplay): cstring
proc ProtocolVersion*(dpy: PDisplay): cint
proc ProtocolRevision*(dpy: PDisplay): cint
proc VendorRelease*(dpy: PDisplay): cint
proc DisplayString*(dpy: PDisplay): cstring
proc DefaultDepth*(dpy: PDisplay, scr: cint): cint
proc DefaultColormap*(dpy: PDisplay, scr: cint): TColormap
proc BitmapUnit*(dpy: PDisplay): cint
proc BitmapBitOrder*(dpy: PDisplay): cint
proc BitmapPad*(dpy: PDisplay): cint
proc ImageByteOrder*(dpy: PDisplay): cint
proc NextRequest*(dpy: PDisplay): culong
proc LastKnownRequestProcessed*(dpy: PDisplay): culong
proc ScreenOfDisplay*(dpy: PDisplay, scr: cint): PScreen
proc DefaultScreenOfDisplay*(dpy: PDisplay): PScreen
proc DisplayOfScreen*(s: PScreen): PDisplay
proc RootWindowOfScreen*(s: PScreen): TWindow
proc BlackPixelOfScreen*(s: PScreen): culong
proc WhitePixelOfScreen*(s: PScreen): culong
proc DefaultColormapOfScreen*(s: PScreen): TColormap
proc DefaultDepthOfScreen*(s: PScreen): cint
proc DefaultGCOfScreen*(s: PScreen): TGC
proc DefaultVisualOfScreen*(s: PScreen): PVisual
proc WidthOfScreen*(s: PScreen): cint
proc HeightOfScreen*(s: PScreen): cint
proc WidthMMOfScreen*(s: PScreen): cint
proc HeightMMOfScreen*(s: PScreen): cint
proc PlanesOfScreen*(s: PScreen): cint
proc CellsOfScreen*(s: PScreen): cint
proc MinCmapsOfScreen*(s: PScreen): cint
proc MaxCmapsOfScreen*(s: PScreen): cint
proc DoesSaveUnders*(s: PScreen): TBool
proc DoesBackingStore*(s: PScreen): cint
proc EventMaskOfScreen*(s: PScreen): clong
proc XAllocID*(dpy: PDisplay): TXID
# implementation

#when defined(MACROS):
template privDisp : expr = cast[PXPrivDisplay](dpy)

proc ConnectionNumber(dpy: PDisplay): cint =
  privDisp.fd

proc RootWindow(dpy: PDisplay, scr: cint): TWindow =
  ScreenOfDisplay(dpy, scr).root

proc DefaultScreen(dpy: PDisplay): cint =
  privDisp.default_screen

proc DefaultRootWindow(dpy: PDisplay): TWindow =
  ScreenOfDisplay(dpy, DefaultScreen(dpy)).root

proc DefaultVisual(dpy: PDisplay, scr: cint): PVisual =
  ScreenOfDisplay(dpy, scr).root_visual

proc DefaultGC(dpy: PDisplay, scr: cint): TGC =
  ScreenOfDisplay(dpy, scr).default_gc

proc BlackPixel(dpy: PDisplay, scr: cint): culong =
  ScreenOfDisplay(dpy, scr).black_pixel

proc WhitePixel(dpy: PDisplay, scr: cint): culong =
  ScreenOfDisplay(dpy, scr).white_pixel

proc QLength(dpy: PDisplay): cint =
  privDisp.qlen

proc DisplayWidth(dpy: PDisplay, scr: cint): cint =
  ScreenOfDisplay(dpy, scr).width

proc DisplayHeight(dpy: PDisplay, scr: cint): cint =
  ScreenOfDisplay(dpy, scr).height

proc DisplayWidthMM(dpy: PDisplay, scr: cint): cint =
  ScreenOfDisplay(dpy, scr).mwidth

proc DisplayHeightMM(dpy: PDisplay, scr: cint): cint =
  ScreenOfDisplay(dpy, scr).mheight

proc DisplayPlanes(dpy: PDisplay, scr: cint): cint =
  ScreenOfDisplay(dpy, scr).root_depth

proc DisplayCells(dpy: PDisplay, scr: cint): cint =
  DefaultVisual(dpy, scr).map_entries

proc ScreenCount(dpy: PDisplay): cint =
  privDisp.nscreens

proc ServerVendor(dpy: PDisplay): cstring =
  privDisp.vendor

proc ProtocolVersion(dpy: PDisplay): cint =
  privDisp.proto_major_version

proc ProtocolRevision(dpy: PDisplay): cint =
  privDisp.proto_minor_version

proc VendorRelease(dpy: PDisplay): cint =
  privDisp.release

proc DisplayString(dpy: PDisplay): cstring =
  privDisp.display_name

proc DefaultDepth(dpy: PDisplay, scr: cint): cint =
  ScreenOfDisplay(dpy, scr).root_depth

proc DefaultColormap(dpy: PDisplay, scr: cint): TColormap =
  ScreenOfDisplay(dpy, scr).cmap

proc BitmapUnit(dpy: PDisplay): cint =
  privDisp.bitmap_unit

proc BitmapBitOrder(dpy: PDisplay): cint =
  privDisp.bitmap_bit_order

proc BitmapPad(dpy: PDisplay): cint =
  privDisp.bitmap_pad

proc ImageByteOrder(dpy: PDisplay): cint =
  privDisp.byte_order

proc NextRequest(dpy: PDisplay): culong =
  privDisp.request + 1.culong

proc LastKnownRequestProcessed(dpy: PDisplay): culong =
  privDisp.last_request_read

# from fowltek/pointer_arithm, required for ScreenOfDisplay()
proc offset[A] (some: ptr A; b: int): ptr A =
  cast[ptr A](cast[int](some) + (b * sizeof(A)))
proc ScreenOfDisplay(dpy: PDisplay, scr: cint): PScreen =
  #addr(((privDisp.screens)[scr]))
  privDisp.screens.offset(scr.int)

proc DefaultScreenOfDisplay(dpy: PDisplay): PScreen =
  ScreenOfDisplay(dpy, DefaultScreen(dpy))

proc DisplayOfScreen(s: PScreen): PDisplay =
  s.display

proc RootWindowOfScreen(s: PScreen): TWindow =
  s.root

proc BlackPixelOfScreen(s: PScreen): culong =
  s.black_pixel

proc WhitePixelOfScreen(s: PScreen): culong =
  s.white_pixel

proc DefaultColormapOfScreen(s: PScreen): TColormap =
  s.cmap

proc DefaultDepthOfScreen(s: PScreen): cint =
  s.root_depth

proc DefaultGCOfScreen(s: PScreen): TGC =
  s.default_gc

proc DefaultVisualOfScreen(s: PScreen): PVisual =
  s.root_visual

proc WidthOfScreen(s: PScreen): cint =
  s.width

proc HeightOfScreen(s: PScreen): cint =
  s.height

proc WidthMMOfScreen(s: PScreen): cint =
  s.mwidth

proc HeightMMOfScreen(s: PScreen): cint =
  s.mheight

proc PlanesOfScreen(s: PScreen): cint =
  s.root_depth

proc CellsOfScreen(s: PScreen): cint =
  DefaultVisualOfScreen(s).map_entries

proc MinCmapsOfScreen(s: PScreen): cint =
  s.min_maps

proc MaxCmapsOfScreen(s: PScreen): cint =
  s.max_maps

proc DoesSaveUnders(s: PScreen): TBool =
  s.save_unders

proc DoesBackingStore(s: PScreen): cint =
  s.backing_store

proc EventMaskOfScreen(s: PScreen): clong =
  s.root_input_mask

proc XAllocID(dpy: PDisplay): TXID =
  privDisp.resource_alloc(dpy)
