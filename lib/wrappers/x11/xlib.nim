
import 
  x

const 
  libX11* = "libX11.so"

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
    data*: array[0..19, char]

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

proc XLoadQueryFont*(para1: PDisplay, para2: cstring): PXFontStruct{.cdecl, 
    dynlib: libX11, importc.}
proc XQueryFont*(para1: PDisplay, para2: TXID): PXFontStruct{.cdecl, 
    dynlib: libX11, importc.}
proc XGetMotionEvents*(para1: PDisplay, para2: TWindow, para3: TTime, 
                       para4: TTime, para5: Pcint): PXTimeCoord{.cdecl, 
    dynlib: libX11, importc.}
proc XDeleteModifiermapEntry*(para1: PXModifierKeymap, para2: TKeyCode, 
                              para3: cint): PXModifierKeymap{.cdecl, 
    dynlib: libX11, importc.}
proc XGetModifierMapping*(para1: PDisplay): PXModifierKeymap{.cdecl, 
    dynlib: libX11, importc.}
proc XInsertModifiermapEntry*(para1: PXModifierKeymap, para2: TKeyCode, 
                              para3: cint): PXModifierKeymap{.cdecl, 
    dynlib: libX11, importc.}
proc XNewModifiermap*(para1: cint): PXModifierKeymap{.cdecl, dynlib: libX11, 
    importc.}
proc XCreateImage*(para1: PDisplay, para2: PVisual, para3: cuint, para4: cint, 
                   para5: cint, para6: cstring, para7: cuint, para8: cuint, 
                   para9: cint, para10: cint): PXImage{.cdecl, dynlib: libX11, 
    importc.}
proc XInitImage*(para1: PXImage): TStatus{.cdecl, dynlib: libX11, importc.}
proc XGetImage*(para1: PDisplay, para2: TDrawable, para3: cint, para4: cint, 
                para5: cuint, para6: cuint, para7: culong, para8: cint): PXImage{.
    cdecl, dynlib: libX11, importc.}
proc XGetSubImage*(para1: PDisplay, para2: TDrawable, para3: cint, para4: cint, 
                   para5: cuint, para6: cuint, para7: culong, para8: cint, 
                   para9: PXImage, para10: cint, para11: cint): PXImage{.cdecl, 
    dynlib: libX11, importc.}
proc XOpenDisplay*(para1: cstring): PDisplay{.cdecl, dynlib: libX11, importc.}
proc XrmInitialize*(){.cdecl, dynlib: libX11, importc.}
proc XFetchBytes*(para1: PDisplay, para2: Pcint): cstring{.cdecl, 
    dynlib: libX11, importc.}
proc XFetchBuffer*(para1: PDisplay, para2: Pcint, para3: cint): cstring{.cdecl, 
    dynlib: libX11, importc.}
proc XGetAtomName*(para1: PDisplay, para2: TAtom): cstring{.cdecl, 
    dynlib: libX11, importc.}
proc XGetAtomNames*(para1: PDisplay, para2: PAtom, para3: cint, para4: PPchar): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XGetDefault*(para1: PDisplay, para2: cstring, para3: cstring): cstring{.
    cdecl, dynlib: libX11, importc.}
proc XDisplayName*(para1: cstring): cstring{.cdecl, dynlib: libX11, importc.}
proc XKeysymToString*(para1: TKeySym): cstring{.cdecl, dynlib: libX11, importc.}
proc XSynchronize*(para1: PDisplay, para2: TBool): funcdisp{.cdecl, 
    dynlib: libX11, importc.}
proc XSetAfterFunction*(para1: PDisplay, para2: funcdisp): funcdisp{.cdecl, 
    dynlib: libX11, importc.}
proc XInternAtom*(para1: PDisplay, para2: cstring, para3: TBool): TAtom{.cdecl, 
    dynlib: libX11, importc.}
proc XInternAtoms*(para1: PDisplay, para2: PPchar, para3: cint, para4: TBool, 
                   para5: PAtom): TStatus{.cdecl, dynlib: libX11, importc.}
proc XCopyColormapAndFree*(para1: PDisplay, para2: TColormap): TColormap{.cdecl, 
    dynlib: libX11, importc.}
proc XCreateColormap*(para1: PDisplay, para2: TWindow, para3: PVisual, 
                      para4: cint): TColormap{.cdecl, dynlib: libX11, importc.}
proc XCreatePixmapCursor*(para1: PDisplay, para2: TPixmap, para3: TPixmap, 
                          para4: PXColor, para5: PXColor, para6: cuint, 
                          para7: cuint): TCursor{.cdecl, dynlib: libX11, importc.}
proc XCreateGlyphCursor*(para1: PDisplay, para2: TFont, para3: TFont, 
                         para4: cuint, para5: cuint, para6: PXColor, 
                         para7: PXColor): TCursor{.cdecl, dynlib: libX11, 
    importc.}
proc XCreateFontCursor*(para1: PDisplay, para2: cuint): TCursor{.cdecl, 
    dynlib: libX11, importc.}
proc XLoadFont*(para1: PDisplay, para2: cstring): TFont{.cdecl, dynlib: libX11, 
    importc.}
proc XCreateGC*(para1: PDisplay, para2: TDrawable, para3: culong, 
                para4: PXGCValues): TGC{.cdecl, dynlib: libX11, importc.}
proc XGContextFromGC*(para1: TGC): TGContext{.cdecl, dynlib: libX11, importc.}
proc XFlushGC*(para1: PDisplay, para2: TGC){.cdecl, dynlib: libX11, importc.}
proc XCreatePixmap*(para1: PDisplay, para2: TDrawable, para3: cuint, 
                    para4: cuint, para5: cuint): TPixmap{.cdecl, dynlib: libX11, 
    importc.}
proc XCreateBitmapFromData*(para1: PDisplay, para2: TDrawable, para3: cstring, 
                            para4: cuint, para5: cuint): TPixmap{.cdecl, 
    dynlib: libX11, importc.}
proc XCreatePixmapFromBitmapData*(para1: PDisplay, para2: TDrawable, 
                                  para3: cstring, para4: cuint, para5: cuint, 
                                  para6: culong, para7: culong, para8: cuint): TPixmap{.
    cdecl, dynlib: libX11, importc.}
proc XCreateSimpleWindow*(para1: PDisplay, para2: TWindow, para3: cint, 
                          para4: cint, para5: cuint, para6: cuint, para7: cuint, 
                          para8: culong, para9: culong): TWindow{.cdecl, 
    dynlib: libX11, importc.}
proc XGetSelectionOwner*(para1: PDisplay, para2: TAtom): TWindow{.cdecl, 
    dynlib: libX11, importc.}
proc XCreateWindow*(para1: PDisplay, para2: TWindow, para3: cint, para4: cint, 
                    para5: cuint, para6: cuint, para7: cuint, para8: cint, 
                    para9: cuint, para10: PVisual, para11: culong, 
                    para12: PXSetWindowAttributes): TWindow{.cdecl, 
    dynlib: libX11, importc.}
proc XListInstalledColormaps*(para1: PDisplay, para2: TWindow, para3: Pcint): PColormap{.
    cdecl, dynlib: libX11, importc.}
proc XListFonts*(para1: PDisplay, para2: cstring, para3: cint, para4: Pcint): PPChar{.
    cdecl, dynlib: libX11, importc.}
proc XListFontsWithInfo*(para1: PDisplay, para2: cstring, para3: cint, 
                         para4: Pcint, para5: PPXFontStruct): PPChar{.cdecl, 
    dynlib: libX11, importc.}
proc XGetFontPath*(para1: PDisplay, para2: Pcint): PPChar{.cdecl, 
    dynlib: libX11, importc.}
proc XListExtensions*(para1: PDisplay, para2: Pcint): PPChar{.cdecl, 
    dynlib: libX11, importc.}
proc XListProperties*(para1: PDisplay, para2: TWindow, para3: Pcint): PAtom{.
    cdecl, dynlib: libX11, importc.}
proc XListHosts*(para1: PDisplay, para2: Pcint, para3: PBool): PXHostAddress{.
    cdecl, dynlib: libX11, importc.}
proc XKeycodeToKeysym*(para1: PDisplay, para2: TKeyCode, para3: cint): TKeySym{.
    cdecl, dynlib: libX11, importc.}
proc XLookupKeysym*(para1: PXKeyEvent, para2: cint): TKeySym{.cdecl, 
    dynlib: libX11, importc.}
proc XGetKeyboardMapping*(para1: PDisplay, para2: TKeyCode, para3: cint, 
                          para4: Pcint): PKeySym{.cdecl, dynlib: libX11, importc.}
proc XStringToKeysym*(para1: cstring): TKeySym{.cdecl, dynlib: libX11, importc.}
proc XMaxRequestSize*(para1: PDisplay): clong{.cdecl, dynlib: libX11, importc.}
proc XExtendedMaxRequestSize*(para1: PDisplay): clong{.cdecl, dynlib: libX11, 
    importc.}
proc XResourceManagerString*(para1: PDisplay): cstring{.cdecl, dynlib: libX11, 
    importc.}
proc XScreenResourceString*(para1: PScreen): cstring{.cdecl, dynlib: libX11, 
    importc.}
proc XDisplayMotionBufferSize*(para1: PDisplay): culong{.cdecl, dynlib: libX11, 
    importc.}
proc XVisualIDFromVisual*(para1: PVisual): TVisualID{.cdecl, dynlib: libX11, 
    importc.}
proc XInitThreads*(): TStatus{.cdecl, dynlib: libX11, importc.}
proc XLockDisplay*(para1: PDisplay){.cdecl, dynlib: libX11, importc.}
proc XUnlockDisplay*(para1: PDisplay){.cdecl, dynlib: libX11, importc.}
proc XInitExtension*(para1: PDisplay, para2: cstring): PXExtCodes{.cdecl, 
    dynlib: libX11, importc.}
proc XAddExtension*(para1: PDisplay): PXExtCodes{.cdecl, dynlib: libX11, importc.}
proc XFindOnExtensionList*(para1: PPXExtData, para2: cint): PXExtData{.cdecl, 
    dynlib: libX11, importc.}
proc XEHeadOfExtensionList*(para1: TXEDataObject): PPXExtData{.cdecl, 
    dynlib: libX11, importc.}
proc XRootWindow*(para1: PDisplay, para2: cint): TWindow{.cdecl, dynlib: libX11, 
    importc.}
proc XDefaultRootWindow*(para1: PDisplay): TWindow{.cdecl, dynlib: libX11, 
    importc.}
proc XRootWindowOfScreen*(para1: PScreen): TWindow{.cdecl, dynlib: libX11, 
    importc.}
proc XDefaultVisual*(para1: PDisplay, para2: cint): PVisual{.cdecl, 
    dynlib: libX11, importc.}
proc XDefaultVisualOfScreen*(para1: PScreen): PVisual{.cdecl, dynlib: libX11, 
    importc.}
proc XDefaultGC*(para1: PDisplay, para2: cint): TGC{.cdecl, dynlib: libX11, 
    importc.}
proc XDefaultGCOfScreen*(para1: PScreen): TGC{.cdecl, dynlib: libX11, importc.}
proc XBlackPixel*(para1: PDisplay, para2: cint): culong{.cdecl, dynlib: libX11, 
    importc.}
proc XWhitePixel*(para1: PDisplay, para2: cint): culong{.cdecl, dynlib: libX11, 
    importc.}
proc XAllPlanes*(): culong{.cdecl, dynlib: libX11, importc.}
proc XBlackPixelOfScreen*(para1: PScreen): culong{.cdecl, dynlib: libX11, 
    importc.}
proc XWhitePixelOfScreen*(para1: PScreen): culong{.cdecl, dynlib: libX11, 
    importc.}
proc XNextRequest*(para1: PDisplay): culong{.cdecl, dynlib: libX11, importc.}
proc XLastKnownRequestProcessed*(para1: PDisplay): culong{.cdecl, 
    dynlib: libX11, importc.}
proc XServerVendor*(para1: PDisplay): cstring{.cdecl, dynlib: libX11, importc.}
proc XDisplayString*(para1: PDisplay): cstring{.cdecl, dynlib: libX11, importc.}
proc XDefaultColormap*(para1: PDisplay, para2: cint): TColormap{.cdecl, 
    dynlib: libX11, importc.}
proc XDefaultColormapOfScreen*(para1: PScreen): TColormap{.cdecl, 
    dynlib: libX11, importc.}
proc XDisplayOfScreen*(para1: PScreen): PDisplay{.cdecl, dynlib: libX11, importc.}
proc XScreenOfDisplay*(para1: PDisplay, para2: cint): PScreen{.cdecl, 
    dynlib: libX11, importc.}
proc XDefaultScreenOfDisplay*(para1: PDisplay): PScreen{.cdecl, dynlib: libX11, 
    importc.}
proc XEventMaskOfScreen*(para1: PScreen): clong{.cdecl, dynlib: libX11, importc.}
proc XScreenNumberOfScreen*(para1: PScreen): cint{.cdecl, dynlib: libX11, 
    importc.}
type 
  TXErrorHandler* = proc (para1: PDisplay, para2: PXErrorEvent): cint{.cdecl.}

proc XSetErrorHandler*(para1: TXErrorHandler): TXErrorHandler{.cdecl, 
    dynlib: libX11, importc.}
type 
  TXIOErrorHandler* = proc (para1: PDisplay): cint{.cdecl.}

proc XSetIOErrorHandler*(para1: TXIOErrorHandler): TXIOErrorHandler{.cdecl, 
    dynlib: libX11, importc.}
proc XListPixmapFormats*(para1: PDisplay, para2: Pcint): PXPixmapFormatValues{.
    cdecl, dynlib: libX11, importc.}
proc XListDepths*(para1: PDisplay, para2: cint, para3: Pcint): Pcint{.cdecl, 
    dynlib: libX11, importc.}
proc XReconfigureWMWindow*(para1: PDisplay, para2: TWindow, para3: cint, 
                           para4: cuint, para5: PXWindowChanges): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XGetWMProtocols*(para1: PDisplay, para2: TWindow, para3: PPAtom, 
                      para4: Pcint): TStatus{.cdecl, dynlib: libX11, importc.}
proc XSetWMProtocols*(para1: PDisplay, para2: TWindow, para3: PAtom, para4: cint): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XIconifyWindow*(para1: PDisplay, para2: TWindow, para3: cint): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XWithdrawWindow*(para1: PDisplay, para2: TWindow, para3: cint): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XGetCommand*(para1: PDisplay, para2: TWindow, para3: PPPchar, para4: Pcint): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XGetWMColormapWindows*(para1: PDisplay, para2: TWindow, para3: PPWindow, 
                            para4: Pcint): TStatus{.cdecl, dynlib: libX11, 
    importc.}
proc XSetWMColormapWindows*(para1: PDisplay, para2: TWindow, para3: PWindow, 
                            para4: cint): TStatus{.cdecl, dynlib: libX11, 
    importc.}
proc XFreeStringList*(para1: PPchar){.cdecl, dynlib: libX11, importc.}
proc XSetTransientForHint*(para1: PDisplay, para2: TWindow, para3: TWindow): cint{.
    cdecl, dynlib: libX11, importc.}
proc XActivateScreenSaver*(para1: PDisplay): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XAddHost*(para1: PDisplay, para2: PXHostAddress): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XAddHosts*(para1: PDisplay, para2: PXHostAddress, para3: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XAddToExtensionList*(para1: PPXExtData, para2: PXExtData): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XAddToSaveSet*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XAllocColor*(para1: PDisplay, para2: TColormap, para3: PXColor): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XAllocColorCells*(para1: PDisplay, para2: TColormap, para3: TBool, 
                       para4: Pculong, para5: cuint, para6: Pculong, 
                       para7: cuint): TStatus{.cdecl, dynlib: libX11, importc.}
proc XAllocColorPlanes*(para1: PDisplay, para2: TColormap, para3: TBool, 
                        para4: Pculong, para5: cint, para6: cint, para7: cint, 
                        para8: cint, para9: Pculong, para10: Pculong, 
                        para11: Pculong): TStatus{.cdecl, dynlib: libX11, 
    importc.}
proc XAllocNamedColor*(para1: PDisplay, para2: TColormap, para3: cstring, 
                       para4: PXColor, para5: PXColor): TStatus{.cdecl, 
    dynlib: libX11, importc.}
proc XAllowEvents*(para1: PDisplay, para2: cint, para3: TTime): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XAutoRepeatOff*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XAutoRepeatOn*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XBell*(para1: PDisplay, para2: cint): cint{.cdecl, dynlib: libX11, importc.}
proc XBitmapBitOrder*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XBitmapPad*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XBitmapUnit*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XCellsOfScreen*(para1: PScreen): cint{.cdecl, dynlib: libX11, importc.}
proc XChangeActivePointerGrab*(para1: PDisplay, para2: cuint, para3: TCursor, 
                               para4: TTime): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XChangeGC*(para1: PDisplay, para2: TGC, para3: culong, para4: PXGCValues): cint{.
    cdecl, dynlib: libX11, importc.}
proc XChangeKeyboardControl*(para1: PDisplay, para2: culong, 
                             para3: PXKeyboardControl): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XChangeKeyboardMapping*(para1: PDisplay, para2: cint, para3: cint, 
                             para4: PKeySym, para5: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XChangePointerControl*(para1: PDisplay, para2: TBool, para3: TBool, 
                            para4: cint, para5: cint, para6: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XChangeProperty*(para1: PDisplay, para2: TWindow, para3: TAtom, 
                      para4: TAtom, para5: cint, para6: cint, para7: Pcuchar, 
                      para8: cint): cint{.cdecl, dynlib: libX11, importc.}
proc XChangeSaveSet*(para1: PDisplay, para2: TWindow, para3: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XChangeWindowAttributes*(para1: PDisplay, para2: TWindow, para3: culong, 
                              para4: PXSetWindowAttributes): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XCheckIfEvent*(para1: PDisplay, para2: PXEvent, para3: funcifevent, 
                    para4: TXPointer): TBool{.cdecl, dynlib: libX11, importc.}
proc XCheckMaskEvent*(para1: PDisplay, para2: clong, para3: PXEvent): TBool{.
    cdecl, dynlib: libX11, importc.}
proc XCheckTypedEvent*(para1: PDisplay, para2: cint, para3: PXEvent): TBool{.
    cdecl, dynlib: libX11, importc.}
proc XCheckTypedWindowEvent*(para1: PDisplay, para2: TWindow, para3: cint, 
                             para4: PXEvent): TBool{.cdecl, dynlib: libX11, 
    importc.}
proc XCheckWindowEvent*(para1: PDisplay, para2: TWindow, para3: clong, 
                        para4: PXEvent): TBool{.cdecl, dynlib: libX11, importc.}
proc XCirculateSubwindows*(para1: PDisplay, para2: TWindow, para3: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XCirculateSubwindowsDown*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XCirculateSubwindowsUp*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XClearArea*(para1: PDisplay, para2: TWindow, para3: cint, para4: cint, 
                 para5: cuint, para6: cuint, para7: TBool): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XClearWindow*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XCloseDisplay*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XConfigureWindow*(para1: PDisplay, para2: TWindow, para3: cuint, 
                       para4: PXWindowChanges): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XConnectionNumber*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XConvertSelection*(para1: PDisplay, para2: TAtom, para3: TAtom, 
                        para4: TAtom, para5: TWindow, para6: TTime): cint{.
    cdecl, dynlib: libX11, importc.}
proc XCopyArea*(para1: PDisplay, para2: TDrawable, para3: TDrawable, para4: TGC, 
                para5: cint, para6: cint, para7: cuint, para8: cuint, 
                para9: cint, para10: cint): cint{.cdecl, dynlib: libX11, importc.}
proc XCopyGC*(para1: PDisplay, para2: TGC, para3: culong, para4: TGC): cint{.
    cdecl, dynlib: libX11, importc.}
proc XCopyPlane*(para1: PDisplay, para2: TDrawable, para3: TDrawable, 
                 para4: TGC, para5: cint, para6: cint, para7: cuint, 
                 para8: cuint, para9: cint, para10: cint, para11: culong): cint{.
    cdecl, dynlib: libX11, importc.}
proc XDefaultDepth*(para1: PDisplay, para2: cint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XDefaultDepthOfScreen*(para1: PScreen): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XDefaultScreen*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XDefineCursor*(para1: PDisplay, para2: TWindow, para3: TCursor): cint{.
    cdecl, dynlib: libX11, importc.}
proc XDeleteProperty*(para1: PDisplay, para2: TWindow, para3: TAtom): cint{.
    cdecl, dynlib: libX11, importc.}
proc XDestroyWindow*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XDestroySubwindows*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XDoesBackingStore*(para1: PScreen): cint{.cdecl, dynlib: libX11, importc.}
proc XDoesSaveUnders*(para1: PScreen): TBool{.cdecl, dynlib: libX11, importc.}
proc XDisableAccessControl*(para1: PDisplay): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XDisplayCells*(para1: PDisplay, para2: cint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XDisplayHeight*(para1: PDisplay, para2: cint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XDisplayHeightMM*(para1: PDisplay, para2: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XDisplayKeycodes*(para1: PDisplay, para2: Pcint, para3: Pcint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XDisplayPlanes*(para1: PDisplay, para2: cint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XDisplayWidth*(para1: PDisplay, para2: cint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XDisplayWidthMM*(para1: PDisplay, para2: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XDrawArc*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
               para5: cint, para6: cuint, para7: cuint, para8: cint, para9: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XDrawArcs*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: PXArc, 
                para5: cint): cint{.cdecl, dynlib: libX11, importc.}
proc XDrawImageString*(para1: PDisplay, para2: TDrawable, para3: TGC, 
                       para4: cint, para5: cint, para6: cstring, para7: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XDrawImageString16*(para1: PDisplay, para2: TDrawable, para3: TGC, 
                         para4: cint, para5: cint, para6: PXChar2b, para7: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XDrawLine*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
                para5: cint, para6: cint, para7: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XDrawLines*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: PXPoint, 
                 para5: cint, para6: cint): cint{.cdecl, dynlib: libX11, importc.}
proc XDrawPoint*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
                 para5: cint): cint{.cdecl, dynlib: libX11, importc.}
proc XDrawPoints*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: PXPoint, 
                  para5: cint, para6: cint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XDrawRectangle*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
                     para5: cint, para6: cuint, para7: cuint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XDrawRectangles*(para1: PDisplay, para2: TDrawable, para3: TGC, 
                      para4: PXRectangle, para5: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XDrawSegments*(para1: PDisplay, para2: TDrawable, para3: TGC, 
                    para4: PXSegment, para5: cint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XDrawString*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
                  para5: cint, para6: cstring, para7: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XDrawString16*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
                    para5: cint, para6: PXChar2b, para7: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XDrawText*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
                para5: cint, para6: PXTextItem, para7: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XDrawText16*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
                  para5: cint, para6: PXTextItem16, para7: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XEnableAccessControl*(para1: PDisplay): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XEventsQueued*(para1: PDisplay, para2: cint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XFetchName*(para1: PDisplay, para2: TWindow, para3: PPchar): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XFillArc*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
               para5: cint, para6: cuint, para7: cuint, para8: cint, para9: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XFillArcs*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: PXArc, 
                para5: cint): cint{.cdecl, dynlib: libX11, importc.}
proc XFillPolygon*(para1: PDisplay, para2: TDrawable, para3: TGC, 
                   para4: PXPoint, para5: cint, para6: cint, para7: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XFillRectangle*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
                     para5: cint, para6: cuint, para7: cuint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XFillRectangles*(para1: PDisplay, para2: TDrawable, para3: TGC, 
                      para4: PXRectangle, para5: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XFlush*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XForceScreenSaver*(para1: PDisplay, para2: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XFree*(para1: pointer): cint{.cdecl, dynlib: libX11, importc.}
proc XFreeColormap*(para1: PDisplay, para2: TColormap): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XFreeColors*(para1: PDisplay, para2: TColormap, para3: Pculong, 
                  para4: cint, para5: culong): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XFreeCursor*(para1: PDisplay, para2: TCursor): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XFreeExtensionList*(para1: PPchar): cint{.cdecl, dynlib: libX11, importc.}
proc XFreeFont*(para1: PDisplay, para2: PXFontStruct): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XFreeFontInfo*(para1: PPchar, para2: PXFontStruct, para3: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XFreeFontNames*(para1: PPchar): cint{.cdecl, dynlib: libX11, importc.}
proc XFreeFontPath*(para1: PPchar): cint{.cdecl, dynlib: libX11, importc.}
proc XFreeGC*(para1: PDisplay, para2: TGC): cint{.cdecl, dynlib: libX11, importc.}
proc XFreeModifiermap*(para1: PXModifierKeymap): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XFreePixmap*(para1: PDisplay, para2: TPixmap): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XGeometry*(para1: PDisplay, para2: cint, para3: cstring, para4: cstring, 
                para5: cuint, para6: cuint, para7: cuint, para8: cint, 
                para9: cint, para10: Pcint, para11: Pcint, para12: Pcint, 
                para13: Pcint): cint{.cdecl, dynlib: libX11, importc.}
proc XGetErrorDatabaseText*(para1: PDisplay, para2: cstring, para3: cstring, 
                            para4: cstring, para5: cstring, para6: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XGetErrorText*(para1: PDisplay, para2: cint, para3: cstring, para4: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XGetFontProperty*(para1: PXFontStruct, para2: TAtom, para3: Pculong): TBool{.
    cdecl, dynlib: libX11, importc.}
proc XGetGCValues*(para1: PDisplay, para2: TGC, para3: culong, para4: PXGCValues): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XGetGeometry*(para1: PDisplay, para2: TDrawable, para3: PWindow, 
                   para4: Pcint, para5: Pcint, para6: Pcuint, para7: Pcuint, 
                   para8: Pcuint, para9: Pcuint): TStatus{.cdecl, 
    dynlib: libX11, importc.}
proc XGetIconName*(para1: PDisplay, para2: TWindow, para3: PPchar): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XGetInputFocus*(para1: PDisplay, para2: PWindow, para3: Pcint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XGetKeyboardControl*(para1: PDisplay, para2: PXKeyboardState): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XGetPointerControl*(para1: PDisplay, para2: Pcint, para3: Pcint, 
                         para4: Pcint): cint{.cdecl, dynlib: libX11, importc.}
proc XGetPointerMapping*(para1: PDisplay, para2: Pcuchar, para3: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XGetScreenSaver*(para1: PDisplay, para2: Pcint, para3: Pcint, para4: Pcint, 
                      para5: Pcint): cint{.cdecl, dynlib: libX11, importc.}
proc XGetTransientForHint*(para1: PDisplay, para2: TWindow, para3: PWindow): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XGetWindowProperty*(para1: PDisplay, para2: TWindow, para3: TAtom, 
                         para4: clong, para5: clong, para6: TBool, para7: TAtom, 
                         para8: PAtom, para9: Pcint, para10: Pculong, 
                         para11: Pculong, para12: PPcuchar): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XGetWindowAttributes*(para1: PDisplay, para2: TWindow, 
                           para3: PXWindowAttributes): TStatus{.cdecl, 
    dynlib: libX11, importc.}
proc XGrabButton*(para1: PDisplay, para2: cuint, para3: cuint, para4: TWindow, 
                  para5: TBool, para6: cuint, para7: cint, para8: cint, 
                  para9: TWindow, para10: TCursor): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XGrabKey*(para1: PDisplay, para2: cint, para3: cuint, para4: TWindow, 
               para5: TBool, para6: cint, para7: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XGrabKeyboard*(para1: PDisplay, para2: TWindow, para3: TBool, para4: cint, 
                    para5: cint, para6: TTime): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XGrabPointer*(para1: PDisplay, para2: TWindow, para3: TBool, para4: cuint, 
                   para5: cint, para6: cint, para7: TWindow, para8: TCursor, 
                   para9: TTime): cint{.cdecl, dynlib: libX11, importc.}
proc XGrabServer*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XHeightMMOfScreen*(para1: PScreen): cint{.cdecl, dynlib: libX11, importc.}
proc XHeightOfScreen*(para1: PScreen): cint{.cdecl, dynlib: libX11, importc.}
proc XIfEvent*(para1: PDisplay, para2: PXEvent, para3: funcifevent, 
               para4: TXPointer): cint{.cdecl, dynlib: libX11, importc.}
proc XImageByteOrder*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XInstallColormap*(para1: PDisplay, para2: TColormap): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XKeysymToKeycode*(para1: PDisplay, para2: TKeySym): TKeyCode{.cdecl, 
    dynlib: libX11, importc.}
proc XKillClient*(para1: PDisplay, para2: TXID): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XLookupColor*(para1: PDisplay, para2: TColormap, para3: cstring, 
                   para4: PXColor, para5: PXColor): TStatus{.cdecl, 
    dynlib: libX11, importc.}
proc XLowerWindow*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XMapRaised*(para1: PDisplay, para2: TWindow): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XMapSubwindows*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XMapWindow*(para1: PDisplay, para2: TWindow): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XMaskEvent*(para1: PDisplay, para2: clong, para3: PXEvent): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XMaxCmapsOfScreen*(para1: PScreen): cint{.cdecl, dynlib: libX11, importc.}
proc XMinCmapsOfScreen*(para1: PScreen): cint{.cdecl, dynlib: libX11, importc.}
proc XMoveResizeWindow*(para1: PDisplay, para2: TWindow, para3: cint, 
                        para4: cint, para5: cuint, para6: cuint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XMoveWindow*(para1: PDisplay, para2: TWindow, para3: cint, para4: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XNextEvent*(para1: PDisplay, para2: PXEvent): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XNoOp*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XParseColor*(para1: PDisplay, para2: TColormap, para3: cstring, 
                  para4: PXColor): TStatus{.cdecl, dynlib: libX11, importc.}
proc XParseGeometry*(para1: cstring, para2: Pcint, para3: Pcint, para4: Pcuint, 
                     para5: Pcuint): cint{.cdecl, dynlib: libX11, importc.}
proc XPeekEvent*(para1: PDisplay, para2: PXEvent): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XPeekIfEvent*(para1: PDisplay, para2: PXEvent, para3: funcifevent, 
                   para4: TXPointer): cint{.cdecl, dynlib: libX11, importc.}
proc XPending*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XPlanesOfScreen*(para1: PScreen): cint{.cdecl, dynlib: libX11, importc.}
proc XProtocolRevision*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XProtocolVersion*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XPutBackEvent*(para1: PDisplay, para2: PXEvent): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XPutImage*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: PXImage, 
                para5: cint, para6: cint, para7: cint, para8: cint, 
                para9: cuint, para10: cuint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XQLength*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XQueryBestCursor*(para1: PDisplay, para2: TDrawable, para3: cuint, 
                       para4: cuint, para5: Pcuint, para6: Pcuint): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XQueryBestSize*(para1: PDisplay, para2: cint, para3: TDrawable, 
                     para4: cuint, para5: cuint, para6: Pcuint, para7: Pcuint): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XQueryBestStipple*(para1: PDisplay, para2: TDrawable, para3: cuint, 
                        para4: cuint, para5: Pcuint, para6: Pcuint): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XQueryBestTile*(para1: PDisplay, para2: TDrawable, para3: cuint, 
                     para4: cuint, para5: Pcuint, para6: Pcuint): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XQueryColor*(para1: PDisplay, para2: TColormap, para3: PXColor): cint{.
    cdecl, dynlib: libX11, importc.}
proc XQueryColors*(para1: PDisplay, para2: TColormap, para3: PXColor, 
                   para4: cint): cint{.cdecl, dynlib: libX11, importc.}
proc XQueryExtension*(para1: PDisplay, para2: cstring, para3: Pcint, 
                      para4: Pcint, para5: Pcint): TBool{.cdecl, dynlib: libX11, 
    importc.}
  #?
proc XQueryKeymap*(para1: PDisplay, para2: chararr32): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XQueryPointer*(para1: PDisplay, para2: TWindow, para3: PWindow, 
                    para4: PWindow, para5: Pcint, para6: Pcint, para7: Pcint, 
                    para8: Pcint, para9: Pcuint): TBool{.cdecl, dynlib: libX11, 
    importc.}
proc XQueryTextExtents*(para1: PDisplay, para2: TXID, para3: cstring, 
                        para4: cint, para5: Pcint, para6: Pcint, para7: Pcint, 
                        para8: PXCharStruct): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XQueryTextExtents16*(para1: PDisplay, para2: TXID, para3: PXChar2b, 
                          para4: cint, para5: Pcint, para6: Pcint, para7: Pcint, 
                          para8: PXCharStruct): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XQueryTree*(para1: PDisplay, para2: TWindow, para3: PWindow, 
                 para4: PWindow, para5: PPWindow, para6: Pcuint): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XRaiseWindow*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XReadBitmapFile*(para1: PDisplay, para2: TDrawable, para3: cstring, 
                      para4: Pcuint, para5: Pcuint, para6: PPixmap, 
                      para7: Pcint, para8: Pcint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XReadBitmapFileData*(para1: cstring, para2: Pcuint, para3: Pcuint, 
                          para4: PPcuchar, para5: Pcint, para6: Pcint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XRebindKeysym*(para1: PDisplay, para2: TKeySym, para3: PKeySym, 
                    para4: cint, para5: Pcuchar, para6: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XRecolorCursor*(para1: PDisplay, para2: TCursor, para3: PXColor, 
                     para4: PXColor): cint{.cdecl, dynlib: libX11, importc.}
proc XRefreshKeyboardMapping*(para1: PXMappingEvent): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XRemoveFromSaveSet*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XRemoveHost*(para1: PDisplay, para2: PXHostAddress): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XRemoveHosts*(para1: PDisplay, para2: PXHostAddress, para3: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XReparentWindow*(para1: PDisplay, para2: TWindow, para3: TWindow, 
                      para4: cint, para5: cint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XResetScreenSaver*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XResizeWindow*(para1: PDisplay, para2: TWindow, para3: cuint, para4: cuint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XRestackWindows*(para1: PDisplay, para2: PWindow, para3: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XRotateBuffers*(para1: PDisplay, para2: cint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XRotateWindowProperties*(para1: PDisplay, para2: TWindow, para3: PAtom, 
                              para4: cint, para5: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XScreenCount*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XSelectInput*(para1: PDisplay, para2: TWindow, para3: clong): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSendEvent*(para1: PDisplay, para2: TWindow, para3: TBool, para4: clong, 
                 para5: PXEvent): TStatus{.cdecl, dynlib: libX11, importc.}
proc XSetAccessControl*(para1: PDisplay, para2: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetArcMode*(para1: PDisplay, para2: TGC, para3: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetBackground*(para1: PDisplay, para2: TGC, para3: culong): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetClipMask*(para1: PDisplay, para2: TGC, para3: TPixmap): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetClipOrigin*(para1: PDisplay, para2: TGC, para3: cint, para4: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetClipRectangles*(para1: PDisplay, para2: TGC, para3: cint, para4: cint, 
                         para5: PXRectangle, para6: cint, para7: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetCloseDownMode*(para1: PDisplay, para2: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetCommand*(para1: PDisplay, para2: TWindow, para3: PPchar, para4: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetDashes*(para1: PDisplay, para2: TGC, para3: cint, para4: cstring, 
                 para5: cint): cint{.cdecl, dynlib: libX11, importc.}
proc XSetFillRule*(para1: PDisplay, para2: TGC, para3: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetFillStyle*(para1: PDisplay, para2: TGC, para3: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetFont*(para1: PDisplay, para2: TGC, para3: TFont): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetFontPath*(para1: PDisplay, para2: PPchar, para3: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetForeground*(para1: PDisplay, para2: TGC, para3: culong): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetFunction*(para1: PDisplay, para2: TGC, para3: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetGraphicsExposures*(para1: PDisplay, para2: TGC, para3: TBool): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetIconName*(para1: PDisplay, para2: TWindow, para3: cstring): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetInputFocus*(para1: PDisplay, para2: TWindow, para3: cint, para4: TTime): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetLineAttributes*(para1: PDisplay, para2: TGC, para3: cuint, para4: cint, 
                         para5: cint, para6: cint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XSetModifierMapping*(para1: PDisplay, para2: PXModifierKeymap): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetPlaneMask*(para1: PDisplay, para2: TGC, para3: culong): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetPointerMapping*(para1: PDisplay, para2: Pcuchar, para3: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetScreenSaver*(para1: PDisplay, para2: cint, para3: cint, para4: cint, 
                      para5: cint): cint{.cdecl, dynlib: libX11, importc.}
proc XSetSelectionOwner*(para1: PDisplay, para2: TAtom, para3: TWindow, 
                         para4: TTime): cint{.cdecl, dynlib: libX11, importc.}
proc XSetState*(para1: PDisplay, para2: TGC, para3: culong, para4: culong, 
                para5: cint, para6: culong): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XSetStipple*(para1: PDisplay, para2: TGC, para3: TPixmap): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetSubwindowMode*(para1: PDisplay, para2: TGC, para3: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetTSOrigin*(para1: PDisplay, para2: TGC, para3: cint, para4: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetTile*(para1: PDisplay, para2: TGC, para3: TPixmap): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XSetWindowBackground*(para1: PDisplay, para2: TWindow, para3: culong): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetWindowBackgroundPixmap*(para1: PDisplay, para2: TWindow, para3: TPixmap): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetWindowBorder*(para1: PDisplay, para2: TWindow, para3: culong): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetWindowBorderPixmap*(para1: PDisplay, para2: TWindow, para3: TPixmap): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetWindowBorderWidth*(para1: PDisplay, para2: TWindow, para3: cuint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSetWindowColormap*(para1: PDisplay, para2: TWindow, para3: TColormap): cint{.
    cdecl, dynlib: libX11, importc.}
proc XStoreBuffer*(para1: PDisplay, para2: cstring, para3: cint, para4: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XStoreBytes*(para1: PDisplay, para2: cstring, para3: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XStoreColor*(para1: PDisplay, para2: TColormap, para3: PXColor): cint{.
    cdecl, dynlib: libX11, importc.}
proc XStoreColors*(para1: PDisplay, para2: TColormap, para3: PXColor, 
                   para4: cint): cint{.cdecl, dynlib: libX11, importc.}
proc XStoreName*(para1: PDisplay, para2: TWindow, para3: cstring): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XStoreNamedColor*(para1: PDisplay, para2: TColormap, para3: cstring, 
                       para4: culong, para5: cint): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XSync*(para1: PDisplay, para2: TBool): cint{.cdecl, dynlib: libX11, importc.}
proc XTextExtents*(para1: PXFontStruct, para2: cstring, para3: cint, 
                   para4: Pcint, para5: Pcint, para6: Pcint, para7: PXCharStruct): cint{.
    cdecl, dynlib: libX11, importc.}
proc XTextExtents16*(para1: PXFontStruct, para2: PXChar2b, para3: cint, 
                     para4: Pcint, para5: Pcint, para6: Pcint, 
                     para7: PXCharStruct): cint{.cdecl, dynlib: libX11, importc.}
proc XTextWidth*(para1: PXFontStruct, para2: cstring, para3: cint): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XTextWidth16*(para1: PXFontStruct, para2: PXChar2b, para3: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XTranslateCoordinates*(para1: PDisplay, para2: TWindow, para3: TWindow, 
                            para4: cint, para5: cint, para6: Pcint, 
                            para7: Pcint, para8: PWindow): TBool{.cdecl, 
    dynlib: libX11, importc.}
proc XUndefineCursor*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XUngrabButton*(para1: PDisplay, para2: cuint, para3: cuint, para4: TWindow): cint{.
    cdecl, dynlib: libX11, importc.}
proc XUngrabKey*(para1: PDisplay, para2: cint, para3: cuint, para4: TWindow): cint{.
    cdecl, dynlib: libX11, importc.}
proc XUngrabKeyboard*(para1: PDisplay, para2: TTime): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XUngrabPointer*(para1: PDisplay, para2: TTime): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XUngrabServer*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XUninstallColormap*(para1: PDisplay, para2: TColormap): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XUnloadFont*(para1: PDisplay, para2: TFont): cint{.cdecl, dynlib: libX11, 
    importc.}
proc XUnmapSubwindows*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XUnmapWindow*(para1: PDisplay, para2: TWindow): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XVendorRelease*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XWarpPointer*(para1: PDisplay, para2: TWindow, para3: TWindow, para4: cint, 
                   para5: cint, para6: cuint, para7: cuint, para8: cint, 
                   para9: cint): cint{.cdecl, dynlib: libX11, importc.}
proc XWidthMMOfScreen*(para1: PScreen): cint{.cdecl, dynlib: libX11, importc.}
proc XWidthOfScreen*(para1: PScreen): cint{.cdecl, dynlib: libX11, importc.}
proc XWindowEvent*(para1: PDisplay, para2: TWindow, para3: clong, para4: PXEvent): cint{.
    cdecl, dynlib: libX11, importc.}
proc XWriteBitmapFile*(para1: PDisplay, para2: cstring, para3: TPixmap, 
                       para4: cuint, para5: cuint, para6: cint, para7: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XSupportsLocale*(): TBool{.cdecl, dynlib: libX11, importc.}
proc XSetLocaleModifiers*(para1: cstring): cstring{.cdecl, dynlib: libX11, 
    importc.}
proc XOpenOM*(para1: PDisplay, para2: PXrmHashBucketRec, para3: cstring, 
              para4: cstring): TXOM{.cdecl, dynlib: libX11, importc.}
proc XCloseOM*(para1: TXOM): TStatus{.cdecl, dynlib: libX11, importc.}
proc XSetOMValues*(para1: TXOM): cstring{.varargs, cdecl, dynlib: libX11, 
    importc.}
proc XGetOMValues*(para1: TXOM): cstring{.varargs, cdecl, dynlib: libX11, 
    importc.}
proc XDisplayOfOM*(para1: TXOM): PDisplay{.cdecl, dynlib: libX11, importc.}
proc XLocaleOfOM*(para1: TXOM): cstring{.cdecl, dynlib: libX11, importc.}
proc XCreateOC*(para1: TXOM): TXOC{.varargs, cdecl, dynlib: libX11, importc.}
proc XDestroyOC*(para1: TXOC){.cdecl, dynlib: libX11, importc.}
proc XOMOfOC*(para1: TXOC): TXOM{.cdecl, dynlib: libX11, importc.}
proc XSetOCValues*(para1: TXOC): cstring{.varargs, cdecl, dynlib: libX11, 
    importc.}
proc XGetOCValues*(para1: TXOC): cstring{.varargs, cdecl, dynlib: libX11, 
    importc.}
proc XCreateFontSet*(para1: PDisplay, para2: cstring, para3: PPPchar, 
                     para4: Pcint, para5: PPchar): TXFontSet{.cdecl, 
    dynlib: libX11, importc.}
proc XFreeFontSet*(para1: PDisplay, para2: TXFontSet){.cdecl, dynlib: libX11, 
    importc.}
proc XFontsOfFontSet*(para1: TXFontSet, para2: PPPXFontStruct, para3: PPPchar): cint{.
    cdecl, dynlib: libX11, importc.}
proc XBaseFontNameListOfFontSet*(para1: TXFontSet): cstring{.cdecl, 
    dynlib: libX11, importc.}
proc XLocaleOfFontSet*(para1: TXFontSet): cstring{.cdecl, dynlib: libX11, 
    importc.}
proc XContextDependentDrawing*(para1: TXFontSet): TBool{.cdecl, dynlib: libX11, 
    importc.}
proc XDirectionalDependentDrawing*(para1: TXFontSet): TBool{.cdecl, 
    dynlib: libX11, importc.}
proc XContextualDrawing*(para1: TXFontSet): TBool{.cdecl, dynlib: libX11, 
    importc.}
proc XExtentsOfFontSet*(para1: TXFontSet): PXFontSetExtents{.cdecl, 
    dynlib: libX11, importc.}
proc XmbTextEscapement*(para1: TXFontSet, para2: cstring, para3: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XwcTextEscapement*(para1: TXFontSet, para2: PWideChar, para3: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc Xutf8TextEscapement*(para1: TXFontSet, para2: cstring, para3: cint): cint{.
    cdecl, dynlib: libX11, importc.}
proc XmbTextExtents*(para1: TXFontSet, para2: cstring, para3: cint, 
                     para4: PXRectangle, para5: PXRectangle): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XwcTextExtents*(para1: TXFontSet, para2: PWideChar, para3: cint, 
                     para4: PXRectangle, para5: PXRectangle): cint{.cdecl, 
    dynlib: libX11, importc.}
proc Xutf8TextExtents*(para1: TXFontSet, para2: cstring, para3: cint, 
                       para4: PXRectangle, para5: PXRectangle): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XmbTextPerCharExtents*(para1: TXFontSet, para2: cstring, para3: cint, 
                            para4: PXRectangle, para5: PXRectangle, para6: cint, 
                            para7: Pcint, para8: PXRectangle, para9: PXRectangle): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XwcTextPerCharExtents*(para1: TXFontSet, para2: PWideChar, para3: cint, 
                            para4: PXRectangle, para5: PXRectangle, para6: cint, 
                            para7: Pcint, para8: PXRectangle, para9: PXRectangle): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc Xutf8TextPerCharExtents*(para1: TXFontSet, para2: cstring, para3: cint, 
                              para4: PXRectangle, para5: PXRectangle, 
                              para6: cint, para7: Pcint, para8: PXRectangle, 
                              para9: PXRectangle): TStatus{.cdecl, 
    dynlib: libX11, importc.}
proc XmbDrawText*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
                  para5: cint, para6: PXmbTextItem, para7: cint){.cdecl, 
    dynlib: libX11, importc.}
proc XwcDrawText*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
                  para5: cint, para6: PXwcTextItem, para7: cint){.cdecl, 
    dynlib: libX11, importc.}
proc Xutf8DrawText*(para1: PDisplay, para2: TDrawable, para3: TGC, para4: cint, 
                    para5: cint, para6: PXmbTextItem, para7: cint){.cdecl, 
    dynlib: libX11, importc.}
proc XmbDrawString*(para1: PDisplay, para2: TDrawable, para3: TXFontSet, 
                    para4: TGC, para5: cint, para6: cint, para7: cstring, 
                    para8: cint){.cdecl, dynlib: libX11, importc.}
proc XwcDrawString*(para1: PDisplay, para2: TDrawable, para3: TXFontSet, 
                    para4: TGC, para5: cint, para6: cint, para7: PWideChar, 
                    para8: cint){.cdecl, dynlib: libX11, importc.}
proc Xutf8DrawString*(para1: PDisplay, para2: TDrawable, para3: TXFontSet, 
                      para4: TGC, para5: cint, para6: cint, para7: cstring, 
                      para8: cint){.cdecl, dynlib: libX11, importc.}
proc XmbDrawImageString*(para1: PDisplay, para2: TDrawable, para3: TXFontSet, 
                         para4: TGC, para5: cint, para6: cint, para7: cstring, 
                         para8: cint){.cdecl, dynlib: libX11, importc.}
proc XwcDrawImageString*(para1: PDisplay, para2: TDrawable, para3: TXFontSet, 
                         para4: TGC, para5: cint, para6: cint, para7: PWideChar, 
                         para8: cint){.cdecl, dynlib: libX11, importc.}
proc Xutf8DrawImageString*(para1: PDisplay, para2: TDrawable, para3: TXFontSet, 
                           para4: TGC, para5: cint, para6: cint, para7: cstring, 
                           para8: cint){.cdecl, dynlib: libX11, importc.}
proc XOpenIM*(para1: PDisplay, para2: PXrmHashBucketRec, para3: cstring, 
              para4: cstring): TXIM{.cdecl, dynlib: libX11, importc.}
proc XCloseIM*(para1: TXIM): TStatus{.cdecl, dynlib: libX11, importc.}
proc XGetIMValues*(para1: TXIM): cstring{.varargs, cdecl, dynlib: libX11, 
    importc.}
proc XSetIMValues*(para1: TXIM): cstring{.varargs, cdecl, dynlib: libX11, 
    importc.}
proc XDisplayOfIM*(para1: TXIM): PDisplay{.cdecl, dynlib: libX11, importc.}
proc XLocaleOfIM*(para1: TXIM): cstring{.cdecl, dynlib: libX11, importc.}
proc XCreateIC*(para1: TXIM): TXIC{.varargs, cdecl, dynlib: libX11, importc.}
proc XDestroyIC*(para1: TXIC){.cdecl, dynlib: libX11, importc.}
proc XSetICFocus*(para1: TXIC){.cdecl, dynlib: libX11, importc.}
proc XUnsetICFocus*(para1: TXIC){.cdecl, dynlib: libX11, importc.}
proc XwcResetIC*(para1: TXIC): PWideChar{.cdecl, dynlib: libX11, importc.}
proc XmbResetIC*(para1: TXIC): cstring{.cdecl, dynlib: libX11, importc.}
proc Xutf8ResetIC*(para1: TXIC): cstring{.cdecl, dynlib: libX11, importc.}
proc XSetICValues*(para1: TXIC): cstring{.varargs, cdecl, dynlib: libX11, 
    importc.}
proc XGetICValues*(para1: TXIC): cstring{.varargs, cdecl, dynlib: libX11, 
    importc.}
proc XIMOfIC*(para1: TXIC): TXIM{.cdecl, dynlib: libX11, importc.}
proc XFilterEvent*(para1: PXEvent, para2: TWindow): TBool{.cdecl, 
    dynlib: libX11, importc.}
proc XmbLookupString*(para1: TXIC, para2: PXKeyPressedEvent, para3: cstring, 
                      para4: cint, para5: PKeySym, para6: PStatus): cint{.cdecl, 
    dynlib: libX11, importc.}
proc XwcLookupString*(para1: TXIC, para2: PXKeyPressedEvent, para3: PWideChar, 
                      para4: cint, para5: PKeySym, para6: PStatus): cint{.cdecl, 
    dynlib: libX11, importc.}
proc Xutf8LookupString*(para1: TXIC, para2: PXKeyPressedEvent, para3: cstring, 
                        para4: cint, para5: PKeySym, para6: PStatus): cint{.
    cdecl, dynlib: libX11, importc.}
proc XVaCreateNestedList*(unused: cint): TXVaNestedList{.varargs, cdecl, 
    dynlib: libX11, importc.}
proc XRegisterIMInstantiateCallback*(para1: PDisplay, para2: PXrmHashBucketRec, 
                                     para3: cstring, para4: cstring, 
                                     para5: TXIDProc, para6: TXPointer): TBool{.
    cdecl, dynlib: libX11, importc.}
proc XUnregisterIMInstantiateCallback*(para1: PDisplay, 
                                       para2: PXrmHashBucketRec, para3: cstring, 
                                       para4: cstring, para5: TXIDProc, 
                                       para6: TXPointer): TBool{.cdecl, 
    dynlib: libX11, importc.}
type 
  TXConnectionWatchProc* = proc (para1: PDisplay, para2: TXPointer, para3: cint, 
                                 para4: TBool, para5: PXPointer){.cdecl.}

proc XInternalConnectionNumbers*(para1: PDisplay, para2: PPcint, para3: Pcint): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XProcessInternalConnection*(para1: PDisplay, para2: cint){.cdecl, 
    dynlib: libX11, importc.}
proc XAddConnectionWatch*(para1: PDisplay, para2: TXConnectionWatchProc, 
                          para3: TXPointer): TStatus{.cdecl, dynlib: libX11, 
    importc.}
proc XRemoveConnectionWatch*(para1: PDisplay, para2: TXConnectionWatchProc, 
                             para3: TXPointer){.cdecl, dynlib: libX11, importc.}
proc XSetAuthorization*(para1: cstring, para2: cint, para3: cstring, para4: cint){.
    cdecl, dynlib: libX11, importc.}
  #
  #  _Xmbtowc?
  #  _Xwctomb?
  #
when defined(MACROS): 
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

when defined(MACROS): 
  proc ConnectionNumber(dpy: PDisplay): cint = 
    ConnectionNumber = (PXPrivDisplay(dpy))[] .fd

  proc RootWindow(dpy: PDisplay, scr: cint): TWindow = 
    RootWindow = (ScreenOfDisplay(dpy, scr))[] .root

  proc DefaultScreen(dpy: PDisplay): cint = 
    DefaultScreen = (PXPrivDisplay(dpy))[] .default_screen

  proc DefaultRootWindow(dpy: PDisplay): TWindow = 
    DefaultRootWindow = (ScreenOfDisplay(dpy, DefaultScreen(dpy)))[] .root

  proc DefaultVisual(dpy: PDisplay, scr: cint): PVisual = 
    DefaultVisual = (ScreenOfDisplay(dpy, scr))[] .root_visual

  proc DefaultGC(dpy: PDisplay, scr: cint): TGC = 
    DefaultGC = (ScreenOfDisplay(dpy, scr))[] .default_gc

  proc BlackPixel(dpy: PDisplay, scr: cint): culong = 
    BlackPixel = (ScreenOfDisplay(dpy, scr))[] .black_pixel

  proc WhitePixel(dpy: PDisplay, scr: cint): culong = 
    WhitePixel = (ScreenOfDisplay(dpy, scr))[] .white_pixel

  proc QLength(dpy: PDisplay): cint = 
    QLength = (PXPrivDisplay(dpy))[] .qlen

  proc DisplayWidth(dpy: PDisplay, scr: cint): cint = 
    DisplayWidth = (ScreenOfDisplay(dpy, scr))[] .width

  proc DisplayHeight(dpy: PDisplay, scr: cint): cint = 
    DisplayHeight = (ScreenOfDisplay(dpy, scr))[] .height

  proc DisplayWidthMM(dpy: PDisplay, scr: cint): cint = 
    DisplayWidthMM = (ScreenOfDisplay(dpy, scr))[] .mwidth

  proc DisplayHeightMM(dpy: PDisplay, scr: cint): cint = 
    DisplayHeightMM = (ScreenOfDisplay(dpy, scr))[] .mheight

  proc DisplayPlanes(dpy: PDisplay, scr: cint): cint = 
    DisplayPlanes = (ScreenOfDisplay(dpy, scr))[] .root_depth

  proc DisplayCells(dpy: PDisplay, scr: cint): cint = 
    DisplayCells = (DefaultVisual(dpy, scr))[] .map_entries

  proc ScreenCount(dpy: PDisplay): cint = 
    ScreenCount = (PXPrivDisplay(dpy))[] .nscreens

  proc ServerVendor(dpy: PDisplay): cstring = 
    ServerVendor = (PXPrivDisplay(dpy))[] .vendor

  proc ProtocolVersion(dpy: PDisplay): cint = 
    ProtocolVersion = (PXPrivDisplay(dpy))[] .proto_major_version

  proc ProtocolRevision(dpy: PDisplay): cint = 
    ProtocolRevision = (PXPrivDisplay(dpy))[] .proto_minor_version

  proc VendorRelease(dpy: PDisplay): cint = 
    VendorRelease = (PXPrivDisplay(dpy))[] .release

  proc DisplayString(dpy: PDisplay): cstring = 
    DisplayString = (PXPrivDisplay(dpy))[] .display_name

  proc DefaultDepth(dpy: PDisplay, scr: cint): cint = 
    DefaultDepth = (ScreenOfDisplay(dpy, scr))[] .root_depth

  proc DefaultColormap(dpy: PDisplay, scr: cint): TColormap = 
    DefaultColormap = (ScreenOfDisplay(dpy, scr))[] .cmap

  proc BitmapUnit(dpy: PDisplay): cint = 
    BitmapUnit = (PXPrivDisplay(dpy))[] .bitmap_unit

  proc BitmapBitOrder(dpy: PDisplay): cint = 
    BitmapBitOrder = (PXPrivDisplay(dpy))[] .bitmap_bit_order

  proc BitmapPad(dpy: PDisplay): cint = 
    BitmapPad = (PXPrivDisplay(dpy))[] .bitmap_pad

  proc ImageByteOrder(dpy: PDisplay): cint = 
    ImageByteOrder = (PXPrivDisplay(dpy))[] .byte_order

  proc NextRequest(dpy: PDisplay): culong = 
    NextRequest = ((PXPrivDisplay(dpy))[] .request) + 1

  proc LastKnownRequestProcessed(dpy: PDisplay): culong = 
    LastKnownRequestProcessed = (PXPrivDisplay(dpy))[] .last_request_read

  proc ScreenOfDisplay(dpy: PDisplay, scr: cint): PScreen = 
    ScreenOfDisplay = addr((((PXPrivDisplay(dpy))[] .screens)[scr]))

  proc DefaultScreenOfDisplay(dpy: PDisplay): PScreen = 
    DefaultScreenOfDisplay = ScreenOfDisplay(dpy, DefaultScreen(dpy))

  proc DisplayOfScreen(s: PScreen): PDisplay = 
    DisplayOfScreen = s[] .display

  proc RootWindowOfScreen(s: PScreen): TWindow = 
    RootWindowOfScreen = s[] .root

  proc BlackPixelOfScreen(s: PScreen): culong = 
    BlackPixelOfScreen = s[] .black_pixel

  proc WhitePixelOfScreen(s: PScreen): culong = 
    WhitePixelOfScreen = s[] .white_pixel

  proc DefaultColormapOfScreen(s: PScreen): TColormap = 
    DefaultColormapOfScreen = s[] .cmap

  proc DefaultDepthOfScreen(s: PScreen): cint = 
    DefaultDepthOfScreen = s[] .root_depth

  proc DefaultGCOfScreen(s: PScreen): TGC = 
    DefaultGCOfScreen = s[] .default_gc

  proc DefaultVisualOfScreen(s: PScreen): PVisual = 
    DefaultVisualOfScreen = s[] .root_visual

  proc WidthOfScreen(s: PScreen): cint = 
    WidthOfScreen = s[] .width

  proc HeightOfScreen(s: PScreen): cint = 
    HeightOfScreen = s[] .height

  proc WidthMMOfScreen(s: PScreen): cint = 
    WidthMMOfScreen = s[] .mwidth

  proc HeightMMOfScreen(s: PScreen): cint = 
    HeightMMOfScreen = s[] .mheight

  proc PlanesOfScreen(s: PScreen): cint = 
    PlanesOfScreen = s[] .root_depth

  proc CellsOfScreen(s: PScreen): cint = 
    CellsOfScreen = (DefaultVisualOfScreen(s))[] .map_entries

  proc MinCmapsOfScreen(s: PScreen): cint = 
    MinCmapsOfScreen = s[] .min_maps

  proc MaxCmapsOfScreen(s: PScreen): cint = 
    MaxCmapsOfScreen = s[] .max_maps

  proc DoesSaveUnders(s: PScreen): TBool = 
    DoesSaveUnders = s[] .save_unders

  proc DoesBackingStore(s: PScreen): cint = 
    DoesBackingStore = s[] .backing_store

  proc EventMaskOfScreen(s: PScreen): clong = 
    EventMaskOfScreen = s[] .root_input_mask

  proc XAllocID(dpy: PDisplay): TXID = 
    XAllocID = (PXPrivDisplay(dpy))[] .resource_alloc(dpy)
