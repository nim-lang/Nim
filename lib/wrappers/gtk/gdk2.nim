{.deadCodeElim: on.}
import
  glib2, gdk2pixbuf, pango

when defined(win32):
  const
    lib = "libgdk-win32-2.0-0.dll"
elif defined(macosx):
  #    linklib gtk-x11-2.0
  #    linklib gdk-x11-2.0
  #    linklib pango-1.0.0
  #    linklib glib-2.0.0
  #    linklib gobject-2.0.0
  #    linklib gdk_pixbuf-2.0.0
  #    linklib atk-1.0.0
  const
    lib = "libgdk-x11-2.0.dylib"
else:
  const
    lib = "libgdk-x11-2.0.so(|.0)"
const
  NUMPTSTOBUFFER* = 200
  MAX_TIMECOORD_AXES* = 128

type
  PDeviceClass* = ptr TDeviceClass
  TDeviceClass* = object of TGObjectClass
  PVisualClass* = ptr TVisualClass
  TVisualClass* = object of TGObjectClass
  PColor* = ptr TColor
  TColor*{.final, pure.} = object
    pixel*: guint32
    red*: guint16
    green*: guint16
    blue*: guint16

  PColormap* = ptr TColormap
  PDrawable* = ptr TDrawable
  TDrawable* = object of TGObject
  PWindow* = ptr TWindow
  TWindow* = TDrawable
  PPixmap* = ptr TPixmap
  TPixmap* = TDrawable
  PBitmap* = ptr TBitmap
  TBitmap* = TDrawable
  PFontType* = ptr TFontType
  TFontType* = enum
    FONT_FONT, FONT_FONTSET
  PFont* = ptr TFont
  TFont*{.final, pure.} = object
    `type`*: TFontType
    ascent*: gint
    descent*: gint

  PFunction* = ptr TFunction
  TFunction* = enum
    funcCOPY, funcINVERT, funcXOR, funcCLEAR, funcAND,
    funcAND_REVERSE, funcAND_INVERT, funcNOOP, funcOR, funcEQUIV,
    funcOR_REVERSE, funcCOPY_INVERT, funcOR_INVERT, funcNAND, funcNOR, funcSET
  PCapStyle* = ptr TCapStyle
  TCapStyle* = enum
    CAP_NOT_LAST, CAP_BUTT, CAP_ROUND, CAP_PROJECTING
  PFill* = ptr TFill
  TFill* = enum
    SOLID, TILED, STIPPLED, OPAQUE_STIPPLED
  PJoinStyle* = ptr TJoinStyle
  TJoinStyle* = enum
    JOIN_MITER, JOIN_ROUND, JOIN_BEVEL
  PLineStyle* = ptr TLineStyle
  TLineStyle* = enum
    LINE_SOLID, LINE_ON_OFF_DASH, LINE_DOUBLE_DASH
  PSubwindowMode* = ptr TSubwindowMode
  TSubwindowMode* = int
  PGCValuesMask* = ptr TGCValuesMask
  TGCValuesMask* = int32
  PGCValues* = ptr TGCValues
  TGCValues*{.final, pure.} = object
    foreground*: TColor
    background*: TColor
    font*: PFont
    `function`*: TFunction
    fill*: TFill
    tile*: PPixmap
    stipple*: PPixmap
    clip_mask*: PPixmap
    subwindow_mode*: TSubwindowMode
    ts_x_origin*: gint
    ts_y_origin*: gint
    clip_x_origin*: gint
    clip_y_origin*: gint
    graphics_exposures*: gint
    line_width*: gint
    line_style*: TLineStyle
    cap_style*: TCapStyle
    join_style*: TJoinStyle

  PGC* = ptr TGC
  TGC* = object of TGObject
    clip_x_origin*: gint
    clip_y_origin*: gint
    ts_x_origin*: gint
    ts_y_origin*: gint
    colormap*: PColormap

  PImageType* = ptr TImageType
  TImageType* = enum
    IMAGE_NORMAL, IMAGE_SHARED, IMAGE_FASTEST
  PImage* = ptr TImage
  PDevice* = ptr TDevice
  PTimeCoord* = ptr TTimeCoord
  PPTimeCoord* = ptr PTimeCoord
  PRgbDither* = ptr TRgbDither
  TRgbDither* = enum
    RGB_DITHER_NONE, RGB_DITHER_NORMAL, RGB_DITHER_MAX
  PDisplay* = ptr TDisplay
  PScreen* = ptr TScreen
  TScreen* = object of TGObject
  PInputCondition* = ptr TInputCondition
  TInputCondition* = int32
  PStatus* = ptr TStatus
  TStatus* = int32
  TPoint*{.final, pure.} = object
    x*: gint
    y*: gint

  PPoint* = ptr TPoint
  PPPoint* = ptr PPoint
  PSpan* = ptr TSpan
  PWChar* = ptr TWChar
  TWChar* = guint32
  PSegment* = ptr TSegment
  TSegment*{.final, pure.} = object
    x1*: gint
    y1*: gint
    x2*: gint
    y2*: gint

  PRectangle* = ptr TRectangle
  TRectangle*{.final, pure.} = object
    x*: gint
    y*: gint
    width*: gint
    height*: gint

  PAtom* = ptr TAtom
  TAtom* = gulong
  PByteOrder* = ptr TByteOrder
  TByteOrder* = enum
    LSB_FIRST, MSB_FIRST
  PModifierType* = ptr TModifierType
  TModifierType* = gint
  PVisualType* = ptr TVisualType
  TVisualType* = enum
    VISUAL_STATIC_GRAY, VISUAL_GRAYSCALE, VISUAL_STATIC_COLOR,
    VISUAL_PSEUDO_COLOR, VISUAL_TRUE_COLOR, VISUAL_DIRECT_COLOR
  PVisual* = ptr TVisual
  TVisual* = object of TGObject
    TheType*: TVisualType
    depth*: gint
    byte_order*: TByteOrder
    colormap_size*: gint
    bits_per_rgb*: gint
    red_mask*: guint32
    red_shift*: gint
    red_prec*: gint
    green_mask*: guint32
    green_shift*: gint
    green_prec*: gint
    blue_mask*: guint32
    blue_shift*: gint
    blue_prec*: gint
    screen*: PScreen

  PColormapClass* = ptr TColormapClass
  TColormapClass* = object of TGObjectClass
  TColormap* = object of TGObject
    size*: gint
    colors*: PColor
    visual*: PVisual
    windowing_data*: gpointer
    screen*: PScreen

  PCursorType* = ptr TCursorType
  TCursorType* = gint
  PCursor* = ptr TCursor
  TCursor*{.final, pure.} = object
    `type`*: TCursorType
    ref_count*: guint

  PDragAction* = ptr TDragAction
  TDragAction* = int32
  PDragProtocol* = ptr TDragProtocol
  TDragProtocol* = enum
    DRAG_PROTO_MOTIF, DRAG_PROTO_XDND, DRAG_PROTO_ROOTWIN, DRAG_PROTO_NONE,
    DRAG_PROTO_WIN32_DROPFILES, DRAG_PROTO_OLE2, DRAG_PROTO_LOCAL
  PDragContext* = ptr TDragContext
  TDragContext* = object of TGObject
    protocol*: TDragProtocol
    is_source*: gboolean
    source_window*: PWindow
    dest_window*: PWindow
    targets*: PGList
    actions*: TDragAction
    suggested_action*: TDragAction
    action*: TDragAction
    start_time*: guint32
    windowing_data*: gpointer

  PDragContextClass* = ptr TDragContextClass
  TDragContextClass* = object of TGObjectClass
  PRegionBox* = ptr TRegionBox
  TRegionBox* = TSegment
  PRegion* = ptr TRegion
  TRegion*{.final, pure.} = object
    size*: int32
    numRects*: int32
    rects*: PRegionBox
    extents*: TRegionBox

  PPOINTBLOCK* = ptr TPOINTBLOCK
  TPOINTBLOCK*{.final, pure.} = object
    pts*: array[0..(NUMPTSTOBUFFER) - 1, TPoint]
    next*: PPOINTBLOCK

  PDrawableClass* = ptr TDrawableClass
  TDrawableClass* = object of TGObjectClass
    create_gc*: proc (drawable: PDrawable, values: PGCValues,
                      mask: TGCValuesMask): PGC{.cdecl.}
    draw_rectangle*: proc (drawable: PDrawable, gc: PGC, filled: gint, x: gint,
                           y: gint, width: gint, height: gint){.cdecl.}
    draw_arc*: proc (drawable: PDrawable, gc: PGC, filled: gint, x: gint,
                     y: gint, width: gint, height: gint, angle1: gint,
                     angle2: gint){.cdecl.}
    draw_polygon*: proc (drawable: PDrawable, gc: PGC, filled: gint,
                         points: PPoint, npoints: gint){.cdecl.}
    draw_text*: proc (drawable: PDrawable, font: PFont, gc: PGC, x: gint,
                      y: gint, text: cstring, text_length: gint){.cdecl.}
    draw_text_wc*: proc (drawable: PDrawable, font: PFont, gc: PGC, x: gint,
                         y: gint, text: PWChar, text_length: gint){.cdecl.}
    draw_drawable*: proc (drawable: PDrawable, gc: PGC, src: PDrawable,
                          xsrc: gint, ysrc: gint, xdest: gint, ydest: gint,
                          width: gint, height: gint){.cdecl.}
    draw_points*: proc (drawable: PDrawable, gc: PGC, points: PPoint,
                        npoints: gint){.cdecl.}
    draw_segments*: proc (drawable: PDrawable, gc: PGC, segs: PSegment,
                          nsegs: gint){.cdecl.}
    draw_lines*: proc (drawable: PDrawable, gc: PGC, points: PPoint,
                       npoints: gint){.cdecl.}
    draw_glyphs*: proc (drawable: PDrawable, gc: PGC, font: PFont, x: gint,
                        y: gint, glyphs: PGlyphString){.cdecl.}
    draw_image*: proc (drawable: PDrawable, gc: PGC, image: PImage, xsrc: gint,
                       ysrc: gint, xdest: gint, ydest: gint, width: gint,
                       height: gint){.cdecl.}
    get_depth*: proc (drawable: PDrawable): gint{.cdecl.}
    get_size*: proc (drawable: PDrawable, width: Pgint, height: Pgint){.cdecl.}
    set_colormap*: proc (drawable: PDrawable, cmap: PColormap){.cdecl.}
    get_colormap*: proc (drawable: PDrawable): PColormap{.cdecl.}
    get_visual*: proc (drawable: PDrawable): PVisual{.cdecl.}
    get_screen*: proc (drawable: PDrawable): PScreen{.cdecl.}
    get_image*: proc (drawable: PDrawable, x: gint, y: gint, width: gint,
                      height: gint): PImage{.cdecl.}
    get_clip_region*: proc (drawable: PDrawable): PRegion{.cdecl.}
    get_visible_region*: proc (drawable: PDrawable): PRegion{.cdecl.}
    get_composite_drawable*: proc (drawable: PDrawable, x: gint, y: gint,
                                   width: gint, height: gint,
                                   composite_x_offset: Pgint,
                                   composite_y_offset: Pgint): PDrawable{.cdecl.}
    `draw_pixbuf`*: proc (drawable: PDrawable, gc: PGC, pixbuf: PPixbuf,
                          src_x: gint, src_y: gint, dest_x: gint, dest_y: gint,
                          width: gint, height: gint, dither: TRgbDither,
                          x_dither: gint, y_dither: gint){.cdecl.}
    `copy_to_image`*: proc (drawable: PDrawable, image: PImage, src_x: gint,
                            src_y: gint, dest_x: gint, dest_y: gint,
                            width: gint, height: gint): PImage{.cdecl.}
    `reserved1`: proc (){.cdecl.}
    `reserved2`: proc (){.cdecl.}
    `reserved3`: proc (){.cdecl.}
    `reserved4`: proc (){.cdecl.}
    `reserved5`: proc (){.cdecl.}
    `reserved6`: proc (){.cdecl.}
    `reserved7`: proc (){.cdecl.}
    `reserved9`: proc (){.cdecl.}
    `reserved10`: proc (){.cdecl.}
    `reserved11`: proc (){.cdecl.}
    `reserved12`: proc (){.cdecl.}
    `reserved13`: proc (){.cdecl.}
    `reserved14`: proc (){.cdecl.}
    `reserved15`: proc (){.cdecl.}
    `reserved16`: proc (){.cdecl.}

  PEvent* = ptr TEvent
  TEventFunc* = proc (event: PEvent, data: gpointer){.cdecl.}
  PXEvent* = ptr TXEvent
  TXEvent* = proc () {.cdecl.}
  PFilterReturn* = ptr TFilterReturn
  TFilterReturn* = enum
    FILTER_CONTINUE, FILTER_TRANSLATE, FILTER_REMOVE
  TFilterFunc* = proc (xevent: PXEvent, event: PEvent, data: gpointer): TFilterReturn{.
      cdecl.}
  PEventType* = ptr TEventType
  TEventType* = gint
  PEventMask* = ptr TEventMask
  TEventMask* = gint32
  PVisibilityState* = ptr TVisibilityState
  TVisibilityState* = enum
    VISIBILITY_UNOBSCURED, VISIBILITY_PARTIAL, VISIBILITY_FULLY_OBSCURED
  PScrollDirection* = ptr TScrollDirection
  TScrollDirection* = enum
    SCROLL_UP, SCROLL_DOWN, SCROLL_LEFT, SCROLL_RIGHT
  PNotifyType* = ptr TNotifyType
  TNotifyType* = int
  PCrossingMode* = ptr TCrossingMode
  TCrossingMode* = enum
    CROSSING_NORMAL, CROSSING_GRAB, CROSSING_UNGRAB
  PPropertyState* = ptr TPropertyState
  TPropertyState* = enum
    PROPERTY_NEW_VALUE, PROPERTY_STATE_DELETE
  PWindowState* = ptr TWindowState
  TWindowState* = gint
  PSettingAction* = ptr TSettingAction
  TSettingAction* = enum
    SETTING_ACTION_NEW, SETTING_ACTION_CHANGED, SETTING_ACTION_DELETED
  PEventAny* = ptr TEventAny
  TEventAny*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8

  PEventExpose* = ptr TEventExpose
  TEventExpose*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    area*: TRectangle
    region*: PRegion
    count*: gint

  PEventNoExpose* = ptr TEventNoExpose
  TEventNoExpose*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8

  PEventVisibility* = ptr TEventVisibility
  TEventVisibility*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    state*: TVisibilityState

  PEventMotion* = ptr TEventMotion
  TEventMotion*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    time*: guint32
    x*: gdouble
    y*: gdouble
    axes*: Pgdouble
    state*: guint
    is_hint*: gint16
    device*: PDevice
    x_root*: gdouble
    y_root*: gdouble

  PEventButton* = ptr TEventButton
  TEventButton*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    time*: guint32
    x*: gdouble
    y*: gdouble
    axes*: Pgdouble
    state*: guint
    button*: guint
    device*: PDevice
    x_root*: gdouble
    y_root*: gdouble

  PEventScroll* = ptr TEventScroll
  TEventScroll*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    time*: guint32
    x*: gdouble
    y*: gdouble
    state*: guint
    direction*: TScrollDirection
    device*: PDevice
    x_root*: gdouble
    y_root*: gdouble

  PEventKey* = ptr TEventKey
  TEventKey*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    time*: guint32
    state*: guint
    keyval*: guint
    length*: gint
    `string`*: cstring
    hardware_keycode*: guint16
    group*: guint8

  PEventCrossing* = ptr TEventCrossing
  TEventCrossing*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    subwindow*: PWindow
    time*: guint32
    x*: gdouble
    y*: gdouble
    x_root*: gdouble
    y_root*: gdouble
    mode*: TCrossingMode
    detail*: TNotifyType
    focus*: gboolean
    state*: guint

  PEventFocus* = ptr TEventFocus
  TEventFocus*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    `in`*: gint16

  PEventConfigure* = ptr TEventConfigure
  TEventConfigure*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    x*: gint
    y*: gint
    width*: gint
    height*: gint

  PEventProperty* = ptr TEventProperty
  TEventProperty*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    atom*: TAtom
    time*: guint32
    state*: guint

  TNativeWindow* = pointer
  PEventSelection* = ptr TEventSelection
  TEventSelection*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    selection*: TAtom
    target*: TAtom
    `property`*: TAtom
    time*: guint32
    requestor*: TNativeWindow

  PEventProximity* = ptr TEventProximity
  TEventProximity*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    time*: guint32
    device*: PDevice

  PmatDUMMY* = ptr TmatDUMMY
  TmatDUMMY*{.final, pure.} = object
    b*: array[0..19, char]

  PEventClient* = ptr TEventClient
  TEventClient*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    message_type*: TAtom
    data_format*: gushort
    b*: array[0..19, char]

  PEventSetting* = ptr TEventSetting
  TEventSetting*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    action*: TSettingAction
    name*: cstring

  PEventWindowState* = ptr TEventWindowState
  TEventWindowState*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    changed_mask*: TWindowState
    new_window_state*: TWindowState

  PEventDND* = ptr TEventDND
  TEventDND*{.final, pure.} = object
    `type`*: TEventType
    window*: PWindow
    send_event*: gint8
    context*: PDragContext
    time*: guint32
    x_root*: gshort
    y_root*: gshort

  TEvent*{.final, pure.} = object
    data*: array[0..255, char] # union of
                               # `type`: TEventType
                               #  any: TEventAny
                               #  expose: TEventExpose
                               #  no_expose: TEventNoExpose
                               #  visibility: TEventVisibility
                               #  motion: TEventMotion
                               #  button: TEventButton
                               #  scroll: TEventScroll
                               #  key: TEventKey
                               #  crossing: TEventCrossing
                               #  focus_change: TEventFocus
                               #  configure: TEventConfigure
                               #  `property`: TEventProperty
                               #  selection: TEventSelection
                               #  proximity: TEventProximity
                               #  client: TEventClient
                               #  dnd: TEventDND
                               #  window_state: TEventWindowState
                               #  setting: TEventSetting

  PGCClass* = ptr TGCClass
  TGCClass* = object of TGObjectClass
    get_values*: proc (gc: PGC, values: PGCValues){.cdecl.}
    set_values*: proc (gc: PGC, values: PGCValues, mask: TGCValuesMask){.cdecl.}
    set_dashes*: proc (gc: PGC, dash_offset: gint, dash_list: openarray[gint8]){.
        cdecl.}
    `reserved1`*: proc (){.cdecl.}
    `reserved2`*: proc (){.cdecl.}
    `reserved3`*: proc (){.cdecl.}
    `reserved4`*: proc (){.cdecl.}

  PImageClass* = ptr TImageClass
  TImageClass* = object of TGObjectClass
  TImage* = object of TGObject
    `type`*: TImageType
    visual*: PVisual
    byte_order*: TByteOrder
    width*: gint
    height*: gint
    depth*: guint16
    bpp*: guint16
    bpl*: guint16
    bits_per_pixel*: guint16
    mem*: gpointer
    colormap*: PColormap
    windowing_data*: gpointer

  PExtensionMode* = ptr TExtensionMode
  TExtensionMode* = enum
    EXTENSION_EVENTS_NONE, EXTENSION_EVENTS_ALL, EXTENSION_EVENTS_CURSOR
  PInputSource* = ptr TInputSource
  TInputSource* = enum
    SOURCE_MOUSE, SOURCE_PEN, SOURCE_ERASER, SOURCE_CURSOR
  PInputMode* = ptr TInputMode
  TInputMode* = enum
    MODE_DISABLED, MODE_SCREEN, MODE_WINDOW
  PAxisUse* = ptr TAxisUse
  TAxisUse* = int32
  PDeviceKey* = ptr TDeviceKey
  TDeviceKey*{.final, pure.} = object
    keyval*: guint
    modifiers*: TModifierType

  PDeviceAxis* = ptr TDeviceAxis
  TDeviceAxis*{.final, pure.} = object
    use*: TAxisUse
    min*: gdouble
    max*: gdouble

  TDevice* = object of TGObject
    name*: cstring
    source*: TInputSource
    mode*: TInputMode
    has_cursor*: gboolean
    num_axes*: gint
    axes*: PDeviceAxis
    num_keys*: gint
    keys*: PDeviceKey

  TTimeCoord*{.final, pure.} = object
    time*: guint32
    axes*: array[0..(MAX_TIMECOORD_AXES) - 1, gdouble]

  PKeymapKey* = ptr TKeymapKey
  TKeymapKey*{.final, pure.} = object
    keycode*: guint
    group*: gint
    level*: gint

  PKeymap* = ptr TKeymap
  TKeymap* = object of TGObject
    display*: PDisplay

  PKeymapClass* = ptr TKeymapClass
  TKeymapClass* = object of TGObjectClass
    direction_changed*: proc (keymap: PKeymap){.cdecl.}

  PAttrStipple* = ptr TAttrStipple
  TAttrStipple*{.final, pure.} = object
    attr*: TAttribute
    stipple*: PBitmap

  PAttrEmbossed* = ptr TAttrEmbossed
  TAttrEmbossed*{.final, pure.} = object
    attr*: TAttribute
    embossed*: gboolean

  PPixmapObject* = ptr TPixmapObject
  TPixmapObject* = object of TDrawable
    impl*: PDrawable
    depth*: gint

  PPixmapObjectClass* = ptr TPixmapObjectClass
  TPixmapObjectClass* = object of TDrawableClass
  PPropMode* = ptr TPropMode
  TPropMode* = enum
    PROP_MODE_REPLACE, PROP_MODE_PREPEND, PROP_MODE_APPEND
  PFillRule* = ptr TFillRule
  TFillRule* = enum
    EVEN_ODD_RULE, WINDING_RULE
  POverlapType* = ptr TOverlapType
  TOverlapType* = enum
    OVERLAP_RECTANGLE_IN, OVERLAP_RECTANGLE_OUT, OVERLAP_RECTANGLE_PART
  TSpanFunc* = proc (span: PSpan, data: gpointer){.cdecl.}
  PRgbCmap* = ptr TRgbCmap
  TRgbCmap*{.final, pure.} = object
    colors*: array[0..255, guint32]
    n_colors*: gint
    info_list*: PGSList

  TDisplay* = object of TGObject
    queued_events*: PGList
    queued_tail*: PGList
    button_click_time*: array[0..1, guint32]
    button_window*: array[0..1, PWindow]
    button_number*: array[0..1, guint]
    double_click_time*: guint

  PDisplayClass* = ptr TDisplayClass
  TDisplayClass* = object of TGObjectClass
    get_display_name*: proc (display: PDisplay): cstring{.cdecl.}
    get_n_screens*: proc (display: PDisplay): gint{.cdecl.}
    get_screen*: proc (display: PDisplay, screen_num: gint): PScreen{.cdecl.}
    get_default_screen*: proc (display: PDisplay): PScreen{.cdecl.}

  PScreenClass* = ptr TScreenClass
  TScreenClass* = object of TGObjectClass
    get_display*: proc (screen: PScreen): PDisplay{.cdecl.}
    get_width*: proc (screen: PScreen): gint{.cdecl.}
    get_height*: proc (screen: PScreen): gint{.cdecl.}
    get_width_mm*: proc (screen: PScreen): gint{.cdecl.}
    get_height_mm*: proc (screen: PScreen): gint{.cdecl.}
    get_root_depth*: proc (screen: PScreen): gint{.cdecl.}
    get_screen_num*: proc (screen: PScreen): gint{.cdecl.}
    get_root_window*: proc (screen: PScreen): PWindow{.cdecl.}
    get_default_colormap*: proc (screen: PScreen): PColormap{.cdecl.}
    set_default_colormap*: proc (screen: PScreen, colormap: PColormap){.cdecl.}
    get_window_at_pointer*: proc (screen: PScreen, win_x: Pgint, win_y: Pgint): PWindow{.
        cdecl.}
    get_n_monitors*: proc (screen: PScreen): gint{.cdecl.}
    get_monitor_geometry*: proc (screen: PScreen, monitor_num: gint,
                                 dest: PRectangle){.cdecl.}

  PGrabStatus* = ptr TGrabStatus
  TGrabStatus* = int
  TInputFunction* = proc (data: gpointer, source: gint,
                          condition: TInputCondition){.cdecl.}
  TDestroyNotify* = proc (data: gpointer){.cdecl.}
  TSpan*{.final, pure.} = object
    x*: gint
    y*: gint
    width*: gint

  PWindowClass* = ptr TWindowClass
  TWindowClass* = enum
    INPUT_OUTPUT, INPUT_ONLY
  PWindowType* = ptr TWindowType
  TWindowType* = enum
    WINDOW_ROOT, WINDOW_TOPLEVEL, WINDOW_CHILD, WINDOW_DIALOG, WINDOW_TEMP,
    WINDOW_FOREIGN
  PWindowAttributesType* = ptr TWindowAttributesType
  TWindowAttributesType* = int32
  PWindowHints* = ptr TWindowHints
  TWindowHints* = int32
  PWindowTypeHint* = ptr TWindowTypeHint
  TWindowTypeHint* = enum
    WINDOW_TYPE_HINT_NORMAL, WINDOW_TYPE_HINT_DIALOG, WINDOW_TYPE_HINT_MENU,
    WINDOW_TYPE_HINT_TOOLBAR, WINDOW_TYPE_HINT_SPLASHSCREEN,
    WINDOW_TYPE_HINT_UTILITY, WINDOW_TYPE_HINT_DOCK,
    WINDOW_TYPE_HINT_DESKTOP, WINDOW_TYPE_HINT_DROPDOWN_MENU,
    WINDOW_TYPE_HINT_POPUP_MENU, WINDOW_TYPE_HINT_TOOLTIP,
    WINDOW_TYPE_HINT_NOTIFICATION, WINDOW_TYPE_HINT_COMBO,
    WINDOW_TYPE_HINT_DND
  PWMDecoration* = ptr TWMDecoration
  TWMDecoration* = int32
  PWMFunction* = ptr TWMFunction
  TWMFunction* = int32
  PGravity* = ptr TGravity
  TGravity* = int
  PWindowEdge* = ptr TWindowEdge
  TWindowEdge* = enum
    WINDOW_EDGE_NORTH_WEST, WINDOW_EDGE_NORTH, WINDOW_EDGE_NORTH_EAST,
    WINDOW_EDGE_WEST, WINDOW_EDGE_EAST, WINDOW_EDGE_SOUTH_WEST,
    WINDOW_EDGE_SOUTH, WINDOW_EDGE_SOUTH_EAST
  PWindowAttr* = ptr TWindowAttr
  TWindowAttr*{.final, pure.} = object
    title*: cstring
    event_mask*: gint
    x*: gint
    y*: gint
    width*: gint
    height*: gint
    wclass*: TWindowClass
    visual*: PVisual
    colormap*: PColormap
    window_type*: TWindowType
    cursor*: PCursor
    wmclass_name*: cstring
    wmclass_class*: cstring
    override_redirect*: gboolean

  PGeometry* = ptr TGeometry
  TGeometry*{.final, pure.} = object
    min_width*: gint
    min_height*: gint
    max_width*: gint
    max_height*: gint
    base_width*: gint
    base_height*: gint
    width_inc*: gint
    height_inc*: gint
    min_aspect*: gdouble
    max_aspect*: gdouble
    win_gravity*: TGravity

  PPointerHooks* = ptr TPointerHooks
  TPointerHooks*{.final, pure.} = object
    get_pointer*: proc (window: PWindow, x: Pgint, y: Pgint, mask: PModifierType): PWindow{.
        cdecl.}
    window_at_pointer*: proc (screen: PScreen, win_x: Pgint, win_y: Pgint): PWindow{.
        cdecl.}

  PWindowObject* = ptr TWindowObject
  TWindowObject* = object of TDrawable
    impl*: PDrawable
    parent*: PWindowObject
    user_data*: gpointer
    x*: gint
    y*: gint
    extension_events*: gint
    filters*: PGList
    children*: PGList
    bg_color*: TColor
    bg_pixmap*: PPixmap
    paint_stack*: PGSList
    update_area*: PRegion
    update_freeze_count*: guint
    window_type*: guint8
    depth*: guint8
    resize_count*: guint8
    state*: TWindowState
    flag0*: guint16
    event_mask*: TEventMask

  PWindowObjectClass* = ptr TWindowObjectClass
  TWindowObjectClass* = object of TDrawableClass
  window_invalidate_maybe_recurse_child_func* = proc (para1: PWindow,
      para2: gpointer): gboolean {.cdecl.}

proc TYPE_COLORMAP*(): GType
proc COLORMAP*(anObject: pointer): PColormap
proc COLORMAP_CLASS*(klass: pointer): PColormapClass
proc IS_COLORMAP*(anObject: pointer): bool
proc IS_COLORMAP_CLASS*(klass: pointer): bool
proc COLORMAP_GET_CLASS*(obj: pointer): PColormapClass
proc TYPE_COLOR*(): GType
proc colormap_get_type*(): GType{.cdecl, dynlib: lib,
                                  importc: "gdk_colormap_get_type".}
proc colormap_new*(visual: PVisual, allocate: gboolean): PColormap{.cdecl,
    dynlib: lib, importc: "gdk_colormap_new".}
proc alloc_colors*(colormap: PColormap, colors: PColor, ncolors: gint,
                            writeable: gboolean, best_match: gboolean,
                            success: Pgboolean): gint{.cdecl, dynlib: lib,
    importc: "gdk_colormap_alloc_colors".}
proc alloc_color*(colormap: PColormap, color: PColor,
                           writeable: gboolean, best_match: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_colormap_alloc_color".}
proc free_colors*(colormap: PColormap, colors: PColor, ncolors: gint){.
    cdecl, dynlib: lib, importc: "gdk_colormap_free_colors".}
proc query_color*(colormap: PColormap, pixel: gulong, result: PColor){.
    cdecl, dynlib: lib, importc: "gdk_colormap_query_color".}
proc get_visual*(colormap: PColormap): PVisual{.cdecl, dynlib: lib,
    importc: "gdk_colormap_get_visual".}
proc copy*(color: PColor): PColor{.cdecl, dynlib: lib,
    importc: "gdk_color_copy".}
proc free*(color: PColor){.cdecl, dynlib: lib, importc: "gdk_color_free".}
proc color_parse*(spec: cstring, color: PColor): gint{.cdecl, dynlib: lib,
    importc: "gdk_color_parse".}
proc hash*(colora: PColor): guint{.cdecl, dynlib: lib,
    importc: "gdk_color_hash".}
proc equal*(colora: PColor, colorb: PColor): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_color_equal".}
proc color_get_type*(): GType{.cdecl, dynlib: lib, importc: "gdk_color_get_type".}
const
  CURSOR_IS_PIXMAP* = - (1)
  X_CURSOR* = 0
  ARROW* = 2
  BASED_ARROW_DOWN* = 4
  BASED_ARROW_UP* = 6
  BOAT* = 8
  BOGOSITY* = 10
  BOTTOM_LEFT_CORNER* = 12
  BOTTOM_RIGHT_CORNER* = 14
  BOTTOM_SIDE* = 16
  BOTTOM_TEE* = 18
  BOX_SPIRAL* = 20
  CENTER_PTR* = 22
  CIRCLE* = 24
  CLOCK* = 26
  COFFEE_MUG* = 28
  CROSS* = 30
  CROSS_REVERSE* = 32
  CROSSHAIR* = 34
  DIAMOND_CROSS* = 36
  DOT* = 38
  DOTBOX* = 40
  DOUBLE_ARROW* = 42
  DRAFT_LARGE* = 44
  DRAFT_SMALL* = 46
  DRAPED_BOX* = 48
  EXCHANGE* = 50
  FLEUR* = 52
  GOBBLER* = 54
  GUMBY* = 56
  HAND1* = 58
  HAND2* = 60
  HEART* = 62
  ICON* = 64
  IRON_CROSS* = 66
  LEFT_PTR* = 68
  LEFT_SIDE* = 70
  LEFT_TEE* = 72
  LEFTBUTTON* = 74
  LL_ANGLE* = 76
  LR_ANGLE* = 78
  MAN* = 80
  MIDDLEBUTTON* = 82
  MOUSE* = 84
  PENCIL* = 86
  PIRATE* = 88
  PLUS* = 90
  QUESTION_ARROW* = 92
  RIGHT_PTR* = 94
  RIGHT_SIDE* = 96
  RIGHT_TEE* = 98
  RIGHTBUTTON* = 100
  RTL_LOGO* = 102
  SAILBOAT* = 104
  SB_DOWN_ARROW* = 106
  SB_H_DOUBLE_ARROW* = 108
  SB_LEFT_ARROW* = 110
  SB_RIGHT_ARROW* = 112
  SB_UP_ARROW* = 114
  SB_V_DOUBLE_ARROW* = 116
  SHUTTLE* = 118
  SIZING* = 120
  SPIDER* = 122
  SPRAYCAN* = 124
  STAR* = 126
  TARGET* = 128
  TCROSS* = 130
  TOP_LEFT_ARROW* = 132
  TOP_LEFT_CORNER* = 134
  TOP_RIGHT_CORNER* = 136
  TOP_SIDE* = 138
  TOP_TEE* = 140
  TREK* = 142
  UL_ANGLE* = 144
  UMBRELLA* = 146
  UR_ANGLE* = 148
  WATCH* = 150
  XTERM* = 152
  LAST_CURSOR* = XTERM + 1

proc TYPE_CURSOR*(): GType
proc cursor_get_type*(): GType{.cdecl, dynlib: lib,
                                importc: "gdk_cursor_get_type".}
proc cursor_new_for_screen*(screen: PScreen, cursor_type: TCursorType): PCursor{.
    cdecl, dynlib: lib, importc: "gdk_cursor_new_for_screen".}
proc cursor_new_from_pixmap*(source: PPixmap, mask: PPixmap, fg: PColor,
                             bg: PColor, x: gint, y: gint): PCursor{.cdecl,
    dynlib: lib, importc: "gdk_cursor_new_from_pixmap".}
proc get_screen*(cursor: PCursor): PScreen{.cdecl, dynlib: lib,
    importc: "gdk_cursor_get_screen".}
proc reference*(cursor: PCursor): PCursor{.cdecl, dynlib: lib,
    importc: "gdk_cursor_ref".}
proc unref*(cursor: PCursor){.cdecl, dynlib: lib,
                                     importc: "gdk_cursor_unref".}
const
  ACTION_DEFAULT* = 1 shl 0
  ACTION_COPY* = 1 shl 1
  ACTION_MOVE* = 1 shl 2
  ACTION_LINK* = 1 shl 3
  ACTION_PRIVATE* = 1 shl 4
  ACTION_ASK* = 1 shl 5

proc TYPE_DRAG_CONTEXT*(): GType
proc DRAG_CONTEXT*(anObject: Pointer): PDragContext
proc DRAG_CONTEXT_CLASS*(klass: Pointer): PDragContextClass
proc IS_DRAG_CONTEXT*(anObject: Pointer): bool
proc IS_DRAG_CONTEXT_CLASS*(klass: Pointer): bool
proc DRAG_CONTEXT_GET_CLASS*(obj: Pointer): PDragContextClass
proc drag_context_get_type*(): GType{.cdecl, dynlib: lib,
                                      importc: "gdk_drag_context_get_type".}
proc drag_context_new*(): PDragContext{.cdecl, dynlib: lib,
                                        importc: "gdk_drag_context_new".}
proc status*(context: PDragContext, action: TDragAction, time: guint32){.
    cdecl, dynlib: lib, importc: "gdk_drag_status".}
proc drop_reply*(context: PDragContext, ok: gboolean, time: guint32){.cdecl,
    dynlib: lib, importc: "gdk_drop_reply".}
proc drop_finish*(context: PDragContext, success: gboolean, time: guint32){.
    cdecl, dynlib: lib, importc: "gdk_drop_finish".}
proc get_selection*(context: PDragContext): TAtom{.cdecl, dynlib: lib,
    importc: "gdk_drag_get_selection".}
proc drag_begin*(window: PWindow, targets: PGList): PDragContext{.cdecl,
    dynlib: lib, importc: "gdk_drag_begin".}
proc drag_get_protocol_for_display*(display: PDisplay, xid: guint32,
                                    protocol: PDragProtocol): guint32{.cdecl,
    dynlib: lib, importc: "gdk_drag_get_protocol_for_display".}
proc find_window*(context: PDragContext, drag_window: PWindow,
                       x_root: gint, y_root: gint, w: var PWindow,
                       protocol: PDragProtocol){.cdecl, dynlib: lib,
    importc: "gdk_drag_find_window".}
proc motion*(context: PDragContext, dest_window: PWindow,
                  protocol: TDragProtocol, x_root: gint, y_root: gint,
                  suggested_action: TDragAction, possible_actions: TDragAction,
                  time: guint32): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_drag_motion".}
proc drop*(context: PDragContext, time: guint32){.cdecl, dynlib: lib,
    importc: "gdk_drag_drop".}
proc abort*(context: PDragContext, time: guint32){.cdecl, dynlib: lib,
    importc: "gdk_drag_abort".}
proc region_EXTENTCHECK*(r1, r2: PRegionBox): bool
proc EXTENTS*(r: PRegionBox, idRect: PRegion)
proc MEMCHECK*(reg: PRegion, ARect, firstrect: var PRegionBox): bool
proc CHECK_PREVIOUS*(Reg: PRegion, R: PRegionBox,
                            Rx1, Ry1, Rx2, Ry2: gint): bool
proc ADDRECT*(reg: PRegion, r: PRegionBox, rx1, ry1, rx2, ry2: gint)
proc ADDRECTNOX*(reg: PRegion, r: PRegionBox, rx1, ry1, rx2, ry2: gint)
proc EMPTY_REGION*(pReg: PRegion): bool
proc REGION_NOT_EMPTY*(pReg: PRegion): bool
proc region_INBOX*(r: TRegionBox, x, y: gint): bool
proc TYPE_DRAWABLE*(): GType
proc DRAWABLE*(anObject: Pointer): PDrawable
proc DRAWABLE_CLASS*(klass: Pointer): PDrawableClass
proc IS_DRAWABLE*(anObject: Pointer): bool
proc IS_DRAWABLE_CLASS*(klass: Pointer): bool
proc DRAWABLE_GET_CLASS*(obj: Pointer): PDrawableClass
proc drawable_get_type*(): GType{.cdecl, dynlib: lib,
                                  importc: "gdk_drawable_get_type".}
proc get_size*(drawable: PDrawable, width: Pgint, height: Pgint){.
    cdecl, dynlib: lib, importc: "gdk_drawable_get_size".}
proc set_colormap*(drawable: PDrawable, colormap: PColormap){.cdecl,
    dynlib: lib, importc: "gdk_drawable_set_colormap".}
proc get_colormap*(drawable: PDrawable): PColormap{.cdecl, dynlib: lib,
    importc: "gdk_drawable_get_colormap".}
proc get_visual*(drawable: PDrawable): PVisual{.cdecl, dynlib: lib,
    importc: "gdk_drawable_get_visual".}
proc get_depth*(drawable: PDrawable): gint{.cdecl, dynlib: lib,
    importc: "gdk_drawable_get_depth".}
proc get_screen*(drawable: PDrawable): PScreen{.cdecl, dynlib: lib,
    importc: "gdk_drawable_get_screen".}
proc get_display*(drawable: PDrawable): PDisplay{.cdecl, dynlib: lib,
    importc: "gdk_drawable_get_display".}
proc point*(drawable: PDrawable, gc: PGC, x: gint, y: gint){.cdecl,
    dynlib: lib, importc: "gdk_draw_point".}
proc line*(drawable: PDrawable, gc: PGC, x1: gint, y1: gint, x2: gint,
                y2: gint){.cdecl, dynlib: lib, importc: "gdk_draw_line".}
proc rectangle*(drawable: PDrawable, gc: PGC, filled: gint, x: gint,
                     y: gint, width: gint, height: gint){.cdecl, dynlib: lib,
    importc: "gdk_draw_rectangle".}
proc arc*(drawable: PDrawable, gc: PGC, filled: gint, x: gint, y: gint,
               width: gint, height: gint, angle1: gint, angle2: gint){.cdecl,
    dynlib: lib, importc: "gdk_draw_arc".}
proc polygon*(drawable: PDrawable, gc: PGC, filled: gint, points: PPoint,
                   npoints: gint){.cdecl, dynlib: lib,
                                   importc: "gdk_draw_polygon".}
proc drawable*(drawable: PDrawable, gc: PGC, src: PDrawable, xsrc: gint,
                    ysrc: gint, xdest: gint, ydest: gint, width: gint,
                    height: gint){.cdecl, dynlib: lib,
                                   importc: "gdk_draw_drawable".}
proc image*(drawable: PDrawable, gc: PGC, image: PImage, xsrc: gint,
                 ysrc: gint, xdest: gint, ydest: gint, width: gint, height: gint){.
    cdecl, dynlib: lib, importc: "gdk_draw_image".}
proc points*(drawable: PDrawable, gc: PGC, points: PPoint, npoints: gint){.
    cdecl, dynlib: lib, importc: "gdk_draw_points".}
proc segments*(drawable: PDrawable, gc: PGC, segs: PSegment, nsegs: gint){.
    cdecl, dynlib: lib, importc: "gdk_draw_segments".}
proc lines*(drawable: PDrawable, gc: PGC, points: PPoint, npoints: gint){.
    cdecl, dynlib: lib, importc: "gdk_draw_lines".}
proc glyphs*(drawable: PDrawable, gc: PGC, font: PFont, x: gint,
                  y: gint, glyphs: PGlyphString){.cdecl, dynlib: lib,
    importc: "gdk_draw_glyphs".}
proc layout_line*(drawable: PDrawable, gc: PGC, x: gint, y: gint,
                       line: PLayoutLine){.cdecl, dynlib: lib,
    importc: "gdk_draw_layout_line".}
proc layout*(drawable: PDrawable, gc: PGC, x: gint, y: gint,
                  layout: PLayout){.cdecl, dynlib: lib,
    importc: "gdk_draw_layout".}
proc layout_line*(drawable: PDrawable, gc: PGC, x: gint,
                                   y: gint, line: PLayoutLine,
                                   foreground: PColor, background: PColor){.
    cdecl, dynlib: lib, importc: "gdk_draw_layout_line_with_colors".}
proc layout*(drawable: PDrawable, gc: PGC, x: gint, y: gint,
                              layout: PLayout, foreground: PColor,
                              background: PColor){.cdecl, dynlib: lib,
    importc: "gdk_draw_layout_with_colors".}
proc get_image*(drawable: PDrawable, x: gint, y: gint, width: gint,
                         height: gint): PImage{.cdecl, dynlib: lib,
    importc: "gdk_drawable_get_image".}
proc get_clip_region*(drawable: PDrawable): PRegion{.cdecl,
    dynlib: lib, importc: "gdk_drawable_get_clip_region".}
proc get_visible_region*(drawable: PDrawable): PRegion{.cdecl,
    dynlib: lib, importc: "gdk_drawable_get_visible_region".}
const
  NOTHING* = - (1)
  DELETE* = 0
  constDESTROY* = 1
  EXPOSE* = 2
  MOTION_NOTIFY* = 3
  BUTTON_PRESS* = 4
  BUTTON2_PRESS* = 5
  BUTTON3_PRESS* = 6
  BUTTON_RELEASE* = 7
  KEY_PRESS* = 8
  KEY_RELEASE* = 9
  ENTER_NOTIFY* = 10
  LEAVE_NOTIFY* = 11
  FOCUS_CHANGE* = 12
  CONFIGURE* = 13
  MAP* = 14
  UNMAP* = 15
  PROPERTY_NOTIFY* = 16
  SELECTION_CLEAR* = 17
  SELECTION_REQUEST* = 18
  SELECTION_NOTIFY* = 19
  PROXIMITY_IN* = 20
  PROXIMITY_OUT* = 21
  DRAG_ENTER* = 22
  DRAG_LEAVE* = 23
  DRAG_MOTION_EVENT* = 24
  DRAG_STATUS_EVENT* = 25
  DROP_START* = 26
  DROP_FINISHED* = 27
  CLIENT_EVENT* = 28
  VISIBILITY_NOTIFY* = 29
  NO_EXPOSE* = 30
  constSCROLL* = 31
  WINDOW_STATE* = 32
  SETTING* = 33
  NOTIFY_ANCESTOR* = 0
  NOTIFY_VIRTUAL* = 1
  NOTIFY_INFERIOR* = 2
  NOTIFY_NONLINEAR* = 3
  NOTIFY_NONLINEAR_VIRTUAL* = 4
  NOTIFY_UNKNOWN* = 5

proc TYPE_EVENT*(): GType
const
  G_PRIORITY_DEFAULT* = 0
  PRIORITY_EVENTS* = G_PRIORITY_DEFAULT #GDK_PRIORITY_REDRAW* = G_PRIORITY_HIGH_IDLE + 20
  EXPOSURE_MASK* = 1 shl 1
  POINTER_MOTION_MASK* = 1 shl 2
  POINTER_MOTION_HINT_MASK* = 1 shl 3
  BUTTON_MOTION_MASK* = 1 shl 4
  BUTTON1_MOTION_MASK* = 1 shl 5
  BUTTON2_MOTION_MASK* = 1 shl 6
  BUTTON3_MOTION_MASK* = 1 shl 7
  BUTTON_PRESS_MASK* = 1 shl 8
  BUTTON_RELEASE_MASK* = 1 shl 9
  KEY_PRESS_MASK* = 1 shl 10
  KEY_RELEASE_MASK* = 1 shl 11
  ENTER_NOTIFY_MASK* = 1 shl 12
  LEAVE_NOTIFY_MASK* = 1 shl 13
  FOCUS_CHANGE_MASK* = 1 shl 14
  STRUCTURE_MASK* = 1 shl 15
  PROPERTY_CHANGE_MASK* = 1 shl 16
  VISIBILITY_NOTIFY_MASK* = 1 shl 17
  PROXIMITY_IN_MASK* = 1 shl 18
  PROXIMITY_OUT_MASK* = 1 shl 19
  SUBSTRUCTURE_MASK* = 1 shl 20
  SCROLL_MASK* = 1 shl 21
  ALL_EVENTS_MASK* = 0x003FFFFE
  WINDOW_STATE_WITHDRAWN* = 1 shl 0
  WINDOW_STATE_ICONIFIED* = 1 shl 1
  WINDOW_STATE_MAXIMIZED* = 1 shl 2
  WINDOW_STATE_STICKY* = 1 shl 3

proc event_get_type*(): GType{.cdecl, dynlib: lib, importc: "gdk_event_get_type".}
proc events_pending*(): gboolean{.cdecl, dynlib: lib,
                                  importc: "gdk_events_pending".}
proc event_get*(): PEvent{.cdecl, dynlib: lib, importc: "gdk_event_get".}
proc event_peek*(): PEvent{.cdecl, dynlib: lib, importc: "gdk_event_peek".}
proc event_get_graphics_expose*(window: PWindow): PEvent{.cdecl, dynlib: lib,
    importc: "gdk_event_get_graphics_expose".}
proc put*(event: PEvent){.cdecl, dynlib: lib, importc: "gdk_event_put".}
proc copy*(event: PEvent): PEvent{.cdecl, dynlib: lib,
    importc: "gdk_event_copy".}
proc free*(event: PEvent){.cdecl, dynlib: lib, importc: "gdk_event_free".}
proc get_time*(event: PEvent): guint32{.cdecl, dynlib: lib,
    importc: "gdk_event_get_time".}
proc get_state*(event: PEvent, state: PModifierType): gboolean{.cdecl,
    dynlib: lib, importc: "gdk_event_get_state".}
proc get_coords*(event: PEvent, x_win: Pgdouble, y_win: Pgdouble): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_event_get_coords".}
proc get_root_coords*(event: PEvent, x_root: Pgdouble, y_root: Pgdouble): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_event_get_root_coords".}
proc get_axis*(event: PEvent, axis_use: TAxisUse, value: Pgdouble): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_event_get_axis".}
proc event_handler_set*(func: TEventFunc, data: gpointer,
                        notify: TGDestroyNotify){.cdecl, dynlib: lib,
    importc: "gdk_event_handler_set".}
proc set_show_events*(show_events: gboolean){.cdecl, dynlib: lib,
    importc: "gdk_set_show_events".}
proc get_show_events*(): gboolean{.cdecl, dynlib: lib,
                                   importc: "gdk_get_show_events".}
proc TYPE_FONT*(): GType
proc font_get_type*(): GType{.cdecl, dynlib: lib, importc: "gdk_font_get_type".}
proc font_load_for_display*(display: PDisplay, font_name: cstring): PFont{.
    cdecl, dynlib: lib, importc: "gdk_font_load_for_display".}
proc fontset_load_for_display*(display: PDisplay, fontset_name: cstring): PFont{.
    cdecl, dynlib: lib, importc: "gdk_fontset_load_for_display".}
proc font_from_description_for_display*(display: PDisplay,
                                        font_desc: PFontDescription): PFont{.
    cdecl, dynlib: lib, importc: "gdk_font_from_description_for_display".}
proc reference*(font: PFont): PFont{.cdecl, dynlib: lib, importc: "gdk_font_ref".}
proc unref*(font: PFont){.cdecl, dynlib: lib, importc: "gdk_font_unref".}
proc id*(font: PFont): gint{.cdecl, dynlib: lib, importc: "gdk_font_id".}
proc equal*(fonta: PFont, fontb: PFont): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_font_equal".}
proc string_width*(font: PFont, `string`: cstring): gint{.cdecl, dynlib: lib,
    importc: "gdk_string_width".}
proc text_width*(font: PFont, text: cstring, text_length: gint): gint{.cdecl,
    dynlib: lib, importc: "gdk_text_width".}
proc text_width_wc*(font: PFont, text: PWChar, text_length: gint): gint{.cdecl,
    dynlib: lib, importc: "gdk_text_width_wc".}
proc char_width*(font: PFont, character: gchar): gint{.cdecl, dynlib: lib,
    importc: "gdk_char_width".}
proc char_width_wc*(font: PFont, character: TWChar): gint{.cdecl, dynlib: lib,
    importc: "gdk_char_width_wc".}
proc string_measure*(font: PFont, `string`: cstring): gint{.cdecl, dynlib: lib,
    importc: "gdk_string_measure".}
proc text_measure*(font: PFont, text: cstring, text_length: gint): gint{.cdecl,
    dynlib: lib, importc: "gdk_text_measure".}
proc char_measure*(font: PFont, character: gchar): gint{.cdecl, dynlib: lib,
    importc: "gdk_char_measure".}
proc string_height*(font: PFont, `string`: cstring): gint{.cdecl, dynlib: lib,
    importc: "gdk_string_height".}
proc text_height*(font: PFont, text: cstring, text_length: gint): gint{.cdecl,
    dynlib: lib, importc: "gdk_text_height".}
proc char_height*(font: PFont, character: gchar): gint{.cdecl, dynlib: lib,
    importc: "gdk_char_height".}
proc text_extents*(font: PFont, text: cstring, text_length: gint,
                   lbearing: Pgint, rbearing: Pgint, width: Pgint,
                   ascent: Pgint, descent: Pgint){.cdecl, dynlib: lib,
    importc: "gdk_text_extents".}
proc text_extents_wc*(font: PFont, text: PWChar, text_length: gint,
                      lbearing: Pgint, rbearing: Pgint, width: Pgint,
                      ascent: Pgint, descent: Pgint){.cdecl, dynlib: lib,
    importc: "gdk_text_extents_wc".}
proc string_extents*(font: PFont, `string`: cstring, lbearing: Pgint,
                     rbearing: Pgint, width: Pgint, ascent: Pgint,
                     descent: Pgint){.cdecl, dynlib: lib,
                                      importc: "gdk_string_extents".}
proc get_display*(font: PFont): PDisplay{.cdecl, dynlib: lib,
    importc: "gdk_font_get_display".}
const
  GC_FOREGROUND* = 1 shl 0
  GC_BACKGROUND* = 1 shl 1
  GC_FONT* = 1 shl 2
  GC_FUNCTION* = 1 shl 3
  GC_FILL* = 1 shl 4
  GC_TILE* = 1 shl 5
  GC_STIPPLE* = 1 shl 6
  GC_CLIP_MASK* = 1 shl 7
  GC_SUBWINDOW* = 1 shl 8
  GC_TS_X_ORIGIN* = 1 shl 9
  GC_TS_Y_ORIGIN* = 1 shl 10
  GC_CLIP_X_ORIGIN* = 1 shl 11
  GC_CLIP_Y_ORIGIN* = 1 shl 12
  GC_EXPOSURES* = 1 shl 13
  GC_LINE_WIDTH* = 1 shl 14
  GC_LINE_STYLE* = 1 shl 15
  GC_CAP_STYLE* = 1 shl 16
  GC_JOIN_STYLE* = 1 shl 17
  CLIP_BY_CHILDREN* = 0
  INCLUDE_INFERIORS* = 1

proc TYPE_GC*(): GType
proc GC*(anObject: Pointer): PGC
proc GC_CLASS*(klass: Pointer): PGCClass
proc IS_GC*(anObject: Pointer): bool
proc IS_GC_CLASS*(klass: Pointer): bool
proc GC_GET_CLASS*(obj: Pointer): PGCClass
proc gc_get_type*(): GType{.cdecl, dynlib: lib, importc: "gdk_gc_get_type".}
proc gc_new*(drawable: PDrawable): PGC{.cdecl, dynlib: lib,
                                        importc: "gdk_gc_new".}
proc gc_new*(drawable: PDrawable, values: PGCValues,
                         values_mask: TGCValuesMask): PGC{.cdecl, dynlib: lib,
    importc: "gdk_gc_new_with_values".}
proc get_values*(gc: PGC, values: PGCValues){.cdecl, dynlib: lib,
    importc: "gdk_gc_get_values".}
proc set_values*(gc: PGC, values: PGCValues, values_mask: TGCValuesMask){.
    cdecl, dynlib: lib, importc: "gdk_gc_set_values".}
proc set_foreground*(gc: PGC, color: PColor){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_foreground".}
proc set_background*(gc: PGC, color: PColor){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_background".}
proc set_function*(gc: PGC, `function`: TFunction){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_function".}
proc set_fill*(gc: PGC, fill: TFill){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_fill".}
proc set_tile*(gc: PGC, tile: PPixmap){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_tile".}
proc set_stipple*(gc: PGC, stipple: PPixmap){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_stipple".}
proc set_ts_origin*(gc: PGC, x: gint, y: gint){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_ts_origin".}
proc set_clip_origin*(gc: PGC, x: gint, y: gint){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_clip_origin".}
proc set_clip_mask*(gc: PGC, mask: PBitmap){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_clip_mask".}
proc set_clip_rectangle*(gc: PGC, rectangle: PRectangle){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_clip_rectangle".}
proc set_clip_region*(gc: PGC, region: PRegion){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_clip_region".}
proc set_subwindow*(gc: PGC, mode: TSubwindowMode){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_subwindow".}
proc set_exposures*(gc: PGC, exposures: gboolean){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_exposures".}
proc set_line_attributes*(gc: PGC, line_width: gint, line_style: TLineStyle,
                             cap_style: TCapStyle, join_style: TJoinStyle){.
    cdecl, dynlib: lib, importc: "gdk_gc_set_line_attributes".}
proc set_dashes*(gc: PGC, dash_offset: gint, dash_list: openarray[gint8]){.
    cdecl, dynlib: lib, importc: "gdk_gc_set_dashes".}
proc offset*(gc: PGC, x_offset: gint, y_offset: gint){.cdecl, dynlib: lib,
    importc: "gdk_gc_offset".}
proc copy*(dst_gc: PGC, src_gc: PGC){.cdecl, dynlib: lib,
    importc: "gdk_gc_copy".}
proc set_colormap*(gc: PGC, colormap: PColormap){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_colormap".}
proc get_colormap*(gc: PGC): PColormap{.cdecl, dynlib: lib,
    importc: "gdk_gc_get_colormap".}
proc set_rgb_fg_color*(gc: PGC, color: PColor){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_rgb_fg_color".}
proc set_rgb_bg_color*(gc: PGC, color: PColor){.cdecl, dynlib: lib,
    importc: "gdk_gc_set_rgb_bg_color".}
proc get_screen*(gc: PGC): PScreen{.cdecl, dynlib: lib,
                                       importc: "gdk_gc_get_screen".}
proc TYPE_IMAGE*(): GType
proc IMAGE*(anObject: Pointer): PImage
proc IMAGE_CLASS*(klass: Pointer): PImageClass
proc IS_IMAGE*(anObject: Pointer): bool
proc IS_IMAGE_CLASS*(klass: Pointer): bool
proc IMAGE_GET_CLASS*(obj: Pointer): PImageClass
proc image_get_type*(): GType{.cdecl, dynlib: lib, importc: "gdk_image_get_type".}
proc image_new*(`type`: TImageType, visual: PVisual, width: gint, height: gint): PImage{.
    cdecl, dynlib: lib, importc: "gdk_image_new".}
proc put_pixel*(image: PImage, x: gint, y: gint, pixel: guint32){.cdecl,
    dynlib: lib, importc: "gdk_image_put_pixel".}
proc get_pixel*(image: PImage, x: gint, y: gint): guint32{.cdecl,
    dynlib: lib, importc: "gdk_image_get_pixel".}
proc set_colormap*(image: PImage, colormap: PColormap){.cdecl,
    dynlib: lib, importc: "gdk_image_set_colormap".}
proc get_colormap*(image: PImage): PColormap{.cdecl, dynlib: lib,
    importc: "gdk_image_get_colormap".}
const
  AXIS_IGNORE* = 0
  AXIS_X* = 1
  AXIS_Y* = 2
  AXIS_PRESSURE* = 3
  AXIS_XTILT* = 4
  AXIS_YTILT* = 5
  AXIS_WHEEL* = 6
  AXIS_LAST* = 7

proc TYPE_DEVICE*(): GType
proc DEVICE*(anObject: Pointer): PDevice
proc DEVICE_CLASS*(klass: Pointer): PDeviceClass
proc IS_DEVICE*(anObject: Pointer): bool
proc IS_DEVICE_CLASS*(klass: Pointer): bool
proc DEVICE_GET_CLASS*(obj: Pointer): PDeviceClass
proc device_get_type*(): GType{.cdecl, dynlib: lib,
                                importc: "gdk_device_get_type".}
proc set_source*(device: PDevice, source: TInputSource){.cdecl,
    dynlib: lib, importc: "gdk_device_set_source".}
proc set_mode*(device: PDevice, mode: TInputMode): gboolean{.cdecl,
    dynlib: lib, importc: "gdk_device_set_mode".}
proc set_key*(device: PDevice, index: guint, keyval: guint,
                     modifiers: TModifierType){.cdecl, dynlib: lib,
    importc: "gdk_device_set_key".}
proc set_axis_use*(device: PDevice, index: guint, use: TAxisUse){.cdecl,
    dynlib: lib, importc: "gdk_device_set_axis_use".}
proc get_state*(device: PDevice, window: PWindow, axes: Pgdouble,
                       mask: PModifierType){.cdecl, dynlib: lib,
    importc: "gdk_device_get_state".}
proc get_history*(device: PDevice, window: PWindow, start: guint32,
                         stop: guint32, s: var PPTimeCoord, n_events: Pgint): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_device_get_history".}
proc device_free_history*(events: PPTimeCoord, n_events: gint){.cdecl,
    dynlib: lib, importc: "gdk_device_free_history".}
proc get_axis*(device: PDevice, axes: Pgdouble, use: TAxisUse,
                      value: Pgdouble): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_device_get_axis".}
proc input_set_extension_events*(window: PWindow, mask: gint,
                                 mode: TExtensionMode){.cdecl, dynlib: lib,
    importc: "gdk_input_set_extension_events".}
proc device_get_core_pointer*(): PDevice{.cdecl, dynlib: lib,
    importc: "gdk_device_get_core_pointer".}
proc TYPE_KEYMAP*(): GType
proc KEYMAP*(anObject: Pointer): PKeymap
proc KEYMAP_CLASS*(klass: Pointer): PKeymapClass
proc IS_KEYMAP*(anObject: Pointer): bool
proc IS_KEYMAP_CLASS*(klass: Pointer): bool
proc KEYMAP_GET_CLASS*(obj: Pointer): PKeymapClass
proc keymap_get_type*(): GType{.cdecl, dynlib: lib,
                                importc: "gdk_keymap_get_type".}
proc keymap_get_for_display*(display: PDisplay): PKeymap{.cdecl, dynlib: lib,
    importc: "gdk_keymap_get_for_display".}
proc lookup_key*(keymap: PKeymap, key: PKeymapKey): guint{.cdecl,
    dynlib: lib, importc: "gdk_keymap_lookup_key".}
proc translate_keyboard_state*(keymap: PKeymap, hardware_keycode: guint,
                                      state: TModifierType, group: gint,
                                      keyval: Pguint, effective_group: Pgint,
                                      level: Pgint,
                                      consumed_modifiers: PModifierType): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_keymap_translate_keyboard_state".}
proc get_entries_for_keyval*(keymap: PKeymap, keyval: guint,
                                    s: var PKeymapKey, n_keys: Pgint): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_keymap_get_entries_for_keyval".}
proc get_entries_for_keycode*(keymap: PKeymap, hardware_keycode: guint,
                                     s: var PKeymapKey, sasdf: var Pguint,
                                     n_entries: Pgint): gboolean{.cdecl,
    dynlib: lib, importc: "gdk_keymap_get_entries_for_keycode".}
proc get_direction*(keymap: PKeymap): TDirection{.cdecl,
    dynlib: lib, importc: "gdk_keymap_get_direction".}
proc keyval_name*(keyval: guint): cstring{.cdecl, dynlib: lib,
    importc: "gdk_keyval_name".}
proc keyval_from_name*(keyval_name: cstring): guint{.cdecl, dynlib: lib,
    importc: "gdk_keyval_from_name".}
proc keyval_convert_case*(symbol: guint, lower: Pguint, upper: Pguint){.cdecl,
    dynlib: lib, importc: "gdk_keyval_convert_case".}
proc keyval_to_upper*(keyval: guint): guint{.cdecl, dynlib: lib,
    importc: "gdk_keyval_to_upper".}
proc keyval_to_lower*(keyval: guint): guint{.cdecl, dynlib: lib,
    importc: "gdk_keyval_to_lower".}
proc keyval_is_upper*(keyval: guint): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_keyval_is_upper".}
proc keyval_is_lower*(keyval: guint): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_keyval_is_lower".}
proc keyval_to_unicode*(keyval: guint): guint32{.cdecl, dynlib: lib,
    importc: "gdk_keyval_to_unicode".}
proc unicode_to_keyval*(wc: guint32): guint{.cdecl, dynlib: lib,
    importc: "gdk_unicode_to_keyval".}
const
  KEY_VoidSymbol* = 0x00FFFFFF
  KEY_BackSpace* = 0x0000FF08
  KEY_Tab* = 0x0000FF09
  KEY_Linefeed* = 0x0000FF0A
  KEY_Clear* = 0x0000FF0B
  KEY_Return* = 0x0000FF0D
  KEY_Pause* = 0x0000FF13
  KEY_Scroll_Lock* = 0x0000FF14
  KEY_Sys_Req* = 0x0000FF15
  KEY_Escape* = 0x0000FF1B
  KEY_Delete* = 0x0000FFFF
  KEY_Multi_key* = 0x0000FF20
  KEY_Codeinput* = 0x0000FF37
  KEY_SingleCandidate* = 0x0000FF3C
  KEY_MultipleCandidate* = 0x0000FF3D
  KEY_PreviousCandidate* = 0x0000FF3E
  KEY_Kanji* = 0x0000FF21
  KEY_Muhenkan* = 0x0000FF22
  KEY_Henkan_Mode* = 0x0000FF23
  KEY_Henkan* = 0x0000FF23
  KEY_Romaji* = 0x0000FF24
  KEY_Hiragana* = 0x0000FF25
  KEY_Katakana* = 0x0000FF26
  KEY_Hiragana_Katakana* = 0x0000FF27
  KEY_Zenkaku* = 0x0000FF28
  KEY_Hankaku* = 0x0000FF29
  KEY_Zenkaku_Hankaku* = 0x0000FF2A
  KEY_Touroku* = 0x0000FF2B
  KEY_Massyo* = 0x0000FF2C
  KEY_Kana_Lock* = 0x0000FF2D
  KEY_Kana_Shift* = 0x0000FF2E
  KEY_Eisu_Shift* = 0x0000FF2F
  KEY_Eisu_toggle* = 0x0000FF30
  KEY_Kanji_Bangou* = 0x0000FF37
  KEY_Zen_Koho* = 0x0000FF3D
  KEY_Mae_Koho* = 0x0000FF3E
  KEY_Home* = 0x0000FF50
  KEY_Left* = 0x0000FF51
  KEY_Up* = 0x0000FF52
  KEY_Right* = 0x0000FF53
  KEY_Down* = 0x0000FF54
  KEY_Prior* = 0x0000FF55
  KEY_Page_Up* = 0x0000FF55
  KEY_Next* = 0x0000FF56
  KEY_Page_Down* = 0x0000FF56
  KEY_End* = 0x0000FF57
  KEY_Begin* = 0x0000FF58
  KEY_Select* = 0x0000FF60
  KEY_Print* = 0x0000FF61
  KEY_Execute* = 0x0000FF62
  KEY_Insert* = 0x0000FF63
  KEY_Undo* = 0x0000FF65
  KEY_Redo* = 0x0000FF66
  KEY_Menu* = 0x0000FF67
  KEY_Find* = 0x0000FF68
  KEY_Cancel* = 0x0000FF69
  KEY_Help* = 0x0000FF6A
  KEY_Break* = 0x0000FF6B
  KEY_Mode_switch* = 0x0000FF7E
  KEY_script_switch* = 0x0000FF7E
  KEY_Num_Lock* = 0x0000FF7F
  KEY_KP_Space* = 0x0000FF80
  KEY_KP_Tab* = 0x0000FF89
  KEY_KP_Enter* = 0x0000FF8D
  KEY_KP_F1* = 0x0000FF91
  KEY_KP_F2* = 0x0000FF92
  KEY_KP_F3* = 0x0000FF93
  KEY_KP_F4* = 0x0000FF94
  KEY_KP_Home* = 0x0000FF95
  KEY_KP_Left* = 0x0000FF96
  KEY_KP_Up* = 0x0000FF97
  KEY_KP_Right* = 0x0000FF98
  KEY_KP_Down* = 0x0000FF99
  KEY_KP_Prior* = 0x0000FF9A
  KEY_KP_Page_Up* = 0x0000FF9A
  KEY_KP_Next* = 0x0000FF9B
  KEY_KP_Page_Down* = 0x0000FF9B
  KEY_KP_End* = 0x0000FF9C
  KEY_KP_Begin* = 0x0000FF9D
  KEY_KP_Insert* = 0x0000FF9E
  KEY_KP_Delete* = 0x0000FF9F
  KEY_KP_Equal* = 0x0000FFBD
  KEY_KP_Multiply* = 0x0000FFAA
  KEY_KP_Add* = 0x0000FFAB
  KEY_KP_Separator* = 0x0000FFAC
  KEY_KP_Subtract* = 0x0000FFAD
  KEY_KP_Decimal* = 0x0000FFAE
  KEY_KP_Divide* = 0x0000FFAF
  KEY_KP_0* = 0x0000FFB0
  KEY_KP_1* = 0x0000FFB1
  KEY_KP_2* = 0x0000FFB2
  KEY_KP_3* = 0x0000FFB3
  KEY_KP_4* = 0x0000FFB4
  KEY_KP_5* = 0x0000FFB5
  KEY_KP_6* = 0x0000FFB6
  KEY_KP_7* = 0x0000FFB7
  KEY_KP_8* = 0x0000FFB8
  KEY_KP_9* = 0x0000FFB9
  KEY_F1* = 0x0000FFBE
  KEY_F2* = 0x0000FFBF
  KEY_F3* = 0x0000FFC0
  KEY_F4* = 0x0000FFC1
  KEY_F5* = 0x0000FFC2
  KEY_F6* = 0x0000FFC3
  KEY_F7* = 0x0000FFC4
  KEY_F8* = 0x0000FFC5
  KEY_F9* = 0x0000FFC6
  KEY_F10* = 0x0000FFC7
  KEY_F11* = 0x0000FFC8
  KEY_L1* = 0x0000FFC8
  KEY_F12* = 0x0000FFC9
  KEY_L2* = 0x0000FFC9
  KEY_F13* = 0x0000FFCA
  KEY_L3* = 0x0000FFCA
  KEY_F14* = 0x0000FFCB
  KEY_L4* = 0x0000FFCB
  KEY_F15* = 0x0000FFCC
  KEY_L5* = 0x0000FFCC
  KEY_F16* = 0x0000FFCD
  KEY_L6* = 0x0000FFCD
  KEY_F17* = 0x0000FFCE
  KEY_L7* = 0x0000FFCE
  KEY_F18* = 0x0000FFCF
  KEY_L8* = 0x0000FFCF
  KEY_F19* = 0x0000FFD0
  KEY_L9* = 0x0000FFD0
  KEY_F20* = 0x0000FFD1
  KEY_L10* = 0x0000FFD1
  KEY_F21* = 0x0000FFD2
  KEY_R1* = 0x0000FFD2
  KEY_F22* = 0x0000FFD3
  KEY_R2* = 0x0000FFD3
  KEY_F23* = 0x0000FFD4
  KEY_R3* = 0x0000FFD4
  KEY_F24* = 0x0000FFD5
  KEY_R4* = 0x0000FFD5
  KEY_F25* = 0x0000FFD6
  KEY_R5* = 0x0000FFD6
  KEY_F26* = 0x0000FFD7
  KEY_R6* = 0x0000FFD7
  KEY_F27* = 0x0000FFD8
  KEY_R7* = 0x0000FFD8
  KEY_F28* = 0x0000FFD9
  KEY_R8* = 0x0000FFD9
  KEY_F29* = 0x0000FFDA
  KEY_R9* = 0x0000FFDA
  KEY_F30* = 0x0000FFDB
  KEY_R10* = 0x0000FFDB
  KEY_F31* = 0x0000FFDC
  KEY_R11* = 0x0000FFDC
  KEY_F32* = 0x0000FFDD
  KEY_R12* = 0x0000FFDD
  KEY_F33* = 0x0000FFDE
  KEY_R13* = 0x0000FFDE
  KEY_F34* = 0x0000FFDF
  KEY_R14* = 0x0000FFDF
  KEY_F35* = 0x0000FFE0
  KEY_R15* = 0x0000FFE0
  KEY_Shift_L* = 0x0000FFE1
  KEY_Shift_R* = 0x0000FFE2
  KEY_Control_L* = 0x0000FFE3
  KEY_Control_R* = 0x0000FFE4
  KEY_Caps_Lock* = 0x0000FFE5
  KEY_Shift_Lock* = 0x0000FFE6
  KEY_Meta_L* = 0x0000FFE7
  KEY_Meta_R* = 0x0000FFE8
  KEY_Alt_L* = 0x0000FFE9
  KEY_Alt_R* = 0x0000FFEA
  KEY_Super_L* = 0x0000FFEB
  KEY_Super_R* = 0x0000FFEC
  KEY_Hyper_L* = 0x0000FFED
  KEY_Hyper_R* = 0x0000FFEE
  KEY_ISO_Lock* = 0x0000FE01
  KEY_ISO_Level2_Latch* = 0x0000FE02
  KEY_ISO_Level3_Shift* = 0x0000FE03
  KEY_ISO_Level3_Latch* = 0x0000FE04
  KEY_ISO_Level3_Lock* = 0x0000FE05
  KEY_ISO_Group_Shift* = 0x0000FF7E
  KEY_ISO_Group_Latch* = 0x0000FE06
  KEY_ISO_Group_Lock* = 0x0000FE07
  KEY_ISO_Next_Group* = 0x0000FE08
  KEY_ISO_Next_Group_Lock* = 0x0000FE09
  KEY_ISO_Prev_Group* = 0x0000FE0A
  KEY_ISO_Prev_Group_Lock* = 0x0000FE0B
  KEY_ISO_First_Group* = 0x0000FE0C
  KEY_ISO_First_Group_Lock* = 0x0000FE0D
  KEY_ISO_Last_Group* = 0x0000FE0E
  KEY_ISO_Last_Group_Lock* = 0x0000FE0F
  KEY_ISO_Left_Tab* = 0x0000FE20
  KEY_ISO_Move_Line_Up* = 0x0000FE21
  KEY_ISO_Move_Line_Down* = 0x0000FE22
  KEY_ISO_Partial_Line_Up* = 0x0000FE23
  KEY_ISO_Partial_Line_Down* = 0x0000FE24
  KEY_ISO_Partial_Space_Left* = 0x0000FE25
  KEY_ISO_Partial_Space_Right* = 0x0000FE26
  KEY_ISO_Set_Margin_Left* = 0x0000FE27
  KEY_ISO_Set_Margin_Right* = 0x0000FE28
  KEY_ISO_Release_Margin_Left* = 0x0000FE29
  KEY_ISO_Release_Margin_Right* = 0x0000FE2A
  KEY_ISO_Release_Both_Margins* = 0x0000FE2B
  KEY_ISO_Fast_Cursor_Left* = 0x0000FE2C
  KEY_ISO_Fast_Cursor_Right* = 0x0000FE2D
  KEY_ISO_Fast_Cursor_Up* = 0x0000FE2E
  KEY_ISO_Fast_Cursor_Down* = 0x0000FE2F
  KEY_ISO_Continuous_Underline* = 0x0000FE30
  KEY_ISO_Discontinuous_Underline* = 0x0000FE31
  KEY_ISO_Emphasize* = 0x0000FE32
  KEY_ISO_Center_Object* = 0x0000FE33
  KEY_ISO_Enter* = 0x0000FE34
  KEY_dead_grave* = 0x0000FE50
  KEY_dead_acute* = 0x0000FE51
  KEY_dead_circumflex* = 0x0000FE52
  KEY_dead_tilde* = 0x0000FE53
  KEY_dead_macron* = 0x0000FE54
  KEY_dead_breve* = 0x0000FE55
  KEY_dead_abovedot* = 0x0000FE56
  KEY_dead_diaeresis* = 0x0000FE57
  KEY_dead_abovering* = 0x0000FE58
  KEY_dead_doubleacute* = 0x0000FE59
  KEY_dead_caron* = 0x0000FE5A
  KEY_dead_cedilla* = 0x0000FE5B
  KEY_dead_ogonek* = 0x0000FE5C
  KEY_dead_iota* = 0x0000FE5D
  KEY_dead_voiced_sound* = 0x0000FE5E
  KEY_dead_semivoiced_sound* = 0x0000FE5F
  KEY_dead_belowdot* = 0x0000FE60
  KEY_First_Virtual_Screen* = 0x0000FED0
  KEY_Prev_Virtual_Screen* = 0x0000FED1
  KEY_Next_Virtual_Screen* = 0x0000FED2
  KEY_Last_Virtual_Screen* = 0x0000FED4
  KEY_Terminate_Server* = 0x0000FED5
  KEY_AccessX_Enable* = 0x0000FE70
  KEY_AccessX_Feedback_Enable* = 0x0000FE71
  KEY_RepeatKeys_Enable* = 0x0000FE72
  KEY_SlowKeys_Enable* = 0x0000FE73
  KEY_BounceKeys_Enable* = 0x0000FE74
  KEY_StickyKeys_Enable* = 0x0000FE75
  KEY_MouseKeys_Enable* = 0x0000FE76
  KEY_MouseKeys_Accel_Enable* = 0x0000FE77
  KEY_Overlay1_Enable* = 0x0000FE78
  KEY_Overlay2_Enable* = 0x0000FE79
  KEY_AudibleBell_Enable* = 0x0000FE7A
  KEY_Pointer_Left* = 0x0000FEE0
  KEY_Pointer_Right* = 0x0000FEE1
  KEY_Pointer_Up* = 0x0000FEE2
  KEY_Pointer_Down* = 0x0000FEE3
  KEY_Pointer_UpLeft* = 0x0000FEE4
  KEY_Pointer_UpRight* = 0x0000FEE5
  KEY_Pointer_DownLeft* = 0x0000FEE6
  KEY_Pointer_DownRight* = 0x0000FEE7
  KEY_Pointer_Button_Dflt* = 0x0000FEE8
  KEY_Pointer_Button1* = 0x0000FEE9
  KEY_Pointer_Button2* = 0x0000FEEA
  KEY_Pointer_Button3* = 0x0000FEEB
  KEY_Pointer_Button4* = 0x0000FEEC
  KEY_Pointer_Button5* = 0x0000FEED
  KEY_Pointer_DblClick_Dflt* = 0x0000FEEE
  KEY_Pointer_DblClick1* = 0x0000FEEF
  KEY_Pointer_DblClick2* = 0x0000FEF0
  KEY_Pointer_DblClick3* = 0x0000FEF1
  KEY_Pointer_DblClick4* = 0x0000FEF2
  KEY_Pointer_DblClick5* = 0x0000FEF3
  KEY_Pointer_Drag_Dflt* = 0x0000FEF4
  KEY_Pointer_Drag1* = 0x0000FEF5
  KEY_Pointer_Drag2* = 0x0000FEF6
  KEY_Pointer_Drag3* = 0x0000FEF7
  KEY_Pointer_Drag4* = 0x0000FEF8
  KEY_Pointer_Drag5* = 0x0000FEFD
  KEY_Pointer_EnableKeys* = 0x0000FEF9
  KEY_Pointer_Accelerate* = 0x0000FEFA
  KEY_Pointer_DfltBtnNext* = 0x0000FEFB
  KEY_Pointer_DfltBtnPrev* = 0x0000FEFC
  KEY_3270_Duplicate* = 0x0000FD01
  KEY_3270_FieldMark* = 0x0000FD02
  KEY_3270_Right2* = 0x0000FD03
  KEY_3270_Left2* = 0x0000FD04
  KEY_3270_BackTab* = 0x0000FD05
  KEY_3270_EraseEOF* = 0x0000FD06
  KEY_3270_EraseInput* = 0x0000FD07
  KEY_3270_Reset* = 0x0000FD08
  KEY_3270_Quit* = 0x0000FD09
  KEY_3270_PA1* = 0x0000FD0A
  KEY_3270_PA2* = 0x0000FD0B
  KEY_3270_PA3* = 0x0000FD0C
  KEY_3270_Test* = 0x0000FD0D
  KEY_3270_Attn* = 0x0000FD0E
  KEY_3270_CursorBlink* = 0x0000FD0F
  KEY_3270_AltCursor* = 0x0000FD10
  KEY_3270_KeyClick* = 0x0000FD11
  KEY_3270_Jump* = 0x0000FD12
  KEY_3270_Ident* = 0x0000FD13
  KEY_3270_Rule* = 0x0000FD14
  KEY_3270_Copy* = 0x0000FD15
  KEY_3270_Play* = 0x0000FD16
  KEY_3270_Setup* = 0x0000FD17
  KEY_3270_Record* = 0x0000FD18
  KEY_3270_ChangeScreen* = 0x0000FD19
  KEY_3270_DeleteWord* = 0x0000FD1A
  KEY_3270_ExSelect* = 0x0000FD1B
  KEY_3270_CursorSelect* = 0x0000FD1C
  KEY_3270_PrintScreen* = 0x0000FD1D
  KEY_3270_Enter* = 0x0000FD1E
  KEY_space* = 0x00000020
  KEY_exclam* = 0x00000021
  KEY_quotedbl* = 0x00000022
  KEY_numbersign* = 0x00000023
  KEY_dollar* = 0x00000024
  KEY_percent* = 0x00000025
  KEY_ampersand* = 0x00000026
  KEY_apostrophe* = 0x00000027
  KEY_quoteright* = 0x00000027
  KEY_parenleft* = 0x00000028
  KEY_parenright* = 0x00000029
  KEY_asterisk* = 0x0000002A
  KEY_plus* = 0x0000002B
  KEY_comma* = 0x0000002C
  KEY_minus* = 0x0000002D
  KEY_period* = 0x0000002E
  KEY_slash* = 0x0000002F
  KEY_0* = 0x00000030
  KEY_1* = 0x00000031
  KEY_2* = 0x00000032
  KEY_3* = 0x00000033
  KEY_4* = 0x00000034
  KEY_5* = 0x00000035
  KEY_6* = 0x00000036
  KEY_7* = 0x00000037
  KEY_8* = 0x00000038
  KEY_9* = 0x00000039
  KEY_colon* = 0x0000003A
  KEY_semicolon* = 0x0000003B
  KEY_less* = 0x0000003C
  KEY_equal* = 0x0000003D
  KEY_greater* = 0x0000003E
  KEY_question* = 0x0000003F
  KEY_at* = 0x00000040
  KEY_CAPITAL_A* = 0x00000041
  KEY_CAPITAL_B* = 0x00000042
  KEY_CAPITAL_C* = 0x00000043
  KEY_CAPITAL_D* = 0x00000044
  KEY_CAPITAL_E* = 0x00000045
  KEY_CAPITAL_F* = 0x00000046
  KEY_CAPITAL_G* = 0x00000047
  KEY_CAPITAL_H* = 0x00000048
  KEY_CAPITAL_I* = 0x00000049
  KEY_CAPITAL_J* = 0x0000004A
  KEY_CAPITAL_K* = 0x0000004B
  KEY_CAPITAL_L* = 0x0000004C
  KEY_CAPITAL_M* = 0x0000004D
  KEY_CAPITAL_N* = 0x0000004E
  KEY_CAPITAL_O* = 0x0000004F
  KEY_CAPITAL_P* = 0x00000050
  KEY_CAPITAL_Q* = 0x00000051
  KEY_CAPITAL_R* = 0x00000052
  KEY_CAPITAL_S* = 0x00000053
  KEY_CAPITAL_T* = 0x00000054
  KEY_CAPITAL_U* = 0x00000055
  KEY_CAPITAL_V* = 0x00000056
  KEY_CAPITAL_W* = 0x00000057
  KEY_CAPITAL_X* = 0x00000058
  KEY_CAPITAL_Y* = 0x00000059
  KEY_CAPITAL_Z* = 0x0000005A
  KEY_bracketleft* = 0x0000005B
  KEY_backslash* = 0x0000005C
  KEY_bracketright* = 0x0000005D
  KEY_asciicircum* = 0x0000005E
  KEY_underscore* = 0x0000005F
  KEY_grave* = 0x00000060
  KEY_quoteleft* = 0x00000060
  KEY_a* = 0x00000061
  KEY_b* = 0x00000062
  KEY_c* = 0x00000063
  KEY_d* = 0x00000064
  KEY_e* = 0x00000065
  KEY_f* = 0x00000066
  KEY_g* = 0x00000067
  KEY_h* = 0x00000068
  KEY_i* = 0x00000069
  KEY_j* = 0x0000006A
  KEY_k* = 0x0000006B
  KEY_l* = 0x0000006C
  KEY_m* = 0x0000006D
  KEY_n* = 0x0000006E
  KEY_o* = 0x0000006F
  KEY_p* = 0x00000070
  KEY_q* = 0x00000071
  KEY_r* = 0x00000072
  KEY_s* = 0x00000073
  KEY_t* = 0x00000074
  KEY_u* = 0x00000075
  KEY_v* = 0x00000076
  KEY_w* = 0x00000077
  KEY_x* = 0x00000078
  KEY_y* = 0x00000079
  KEY_z* = 0x0000007A
  KEY_braceleft* = 0x0000007B
  KEY_bar* = 0x0000007C
  KEY_braceright* = 0x0000007D
  KEY_asciitilde* = 0x0000007E
  KEY_nobreakspace* = 0x000000A0
  KEY_exclamdown* = 0x000000A1
  KEY_cent* = 0x000000A2
  KEY_sterling* = 0x000000A3
  KEY_currency* = 0x000000A4
  KEY_yen* = 0x000000A5
  KEY_brokenbar* = 0x000000A6
  KEY_section* = 0x000000A7
  KEY_diaeresis* = 0x000000A8
  KEY_copyright* = 0x000000A9
  KEY_ordfeminine* = 0x000000AA
  KEY_guillemotleft* = 0x000000AB
  KEY_notsign* = 0x000000AC
  KEY_hyphen* = 0x000000AD
  KEY_registered* = 0x000000AE
  KEY_macron* = 0x000000AF
  KEY_degree* = 0x000000B0
  KEY_plusminus* = 0x000000B1
  KEY_twosuperior* = 0x000000B2
  KEY_threesuperior* = 0x000000B3
  KEY_acute* = 0x000000B4
  KEY_mu* = 0x000000B5
  KEY_paragraph* = 0x000000B6
  KEY_periodcentered* = 0x000000B7
  KEY_cedilla* = 0x000000B8
  KEY_onesuperior* = 0x000000B9
  KEY_masculine* = 0x000000BA
  KEY_guillemotright* = 0x000000BB
  KEY_onequarter* = 0x000000BC
  KEY_onehalf* = 0x000000BD
  KEY_threequarters* = 0x000000BE
  KEY_questiondown* = 0x000000BF
  KEY_CAPITAL_Agrave* = 0x000000C0
  KEY_CAPITAL_Aacute* = 0x000000C1
  KEY_CAPITAL_Acircumflex* = 0x000000C2
  KEY_CAPITAL_Atilde* = 0x000000C3
  KEY_CAPITAL_Adiaeresis* = 0x000000C4
  KEY_CAPITAL_Aring* = 0x000000C5
  KEY_CAPITAL_AE* = 0x000000C6
  KEY_CAPITAL_Ccedilla* = 0x000000C7
  KEY_CAPITAL_Egrave* = 0x000000C8
  KEY_CAPITAL_Eacute* = 0x000000C9
  KEY_CAPITAL_Ecircumflex* = 0x000000CA
  KEY_CAPITAL_Ediaeresis* = 0x000000CB
  KEY_CAPITAL_Igrave* = 0x000000CC
  KEY_CAPITAL_Iacute* = 0x000000CD
  KEY_CAPITAL_Icircumflex* = 0x000000CE
  KEY_CAPITAL_Idiaeresis* = 0x000000CF
  KEY_CAPITAL_ETH* = 0x000000D0
  KEY_CAPITAL_Ntilde* = 0x000000D1
  KEY_CAPITAL_Ograve* = 0x000000D2
  KEY_CAPITAL_Oacute* = 0x000000D3
  KEY_CAPITAL_Ocircumflex* = 0x000000D4
  KEY_CAPITAL_Otilde* = 0x000000D5
  KEY_CAPITAL_Odiaeresis* = 0x000000D6
  KEY_multiply* = 0x000000D7
  KEY_Ooblique* = 0x000000D8
  KEY_CAPITAL_Ugrave* = 0x000000D9
  KEY_CAPITAL_Uacute* = 0x000000DA
  KEY_CAPITAL_Ucircumflex* = 0x000000DB
  KEY_CAPITAL_Udiaeresis* = 0x000000DC
  KEY_CAPITAL_Yacute* = 0x000000DD
  KEY_CAPITAL_THORN* = 0x000000DE
  KEY_ssharp* = 0x000000DF
  KEY_agrave* = 0x000000E0
  KEY_aacute* = 0x000000E1
  KEY_acircumflex* = 0x000000E2
  KEY_atilde* = 0x000000E3
  KEY_adiaeresis* = 0x000000E4
  KEY_aring* = 0x000000E5
  KEY_ae* = 0x000000E6
  KEY_ccedilla* = 0x000000E7
  KEY_egrave* = 0x000000E8
  KEY_eacute* = 0x000000E9
  KEY_ecircumflex* = 0x000000EA
  KEY_ediaeresis* = 0x000000EB
  KEY_igrave* = 0x000000EC
  KEY_iacute* = 0x000000ED
  KEY_icircumflex* = 0x000000EE
  KEY_idiaeresis* = 0x000000EF
  KEY_eth* = 0x000000F0
  KEY_ntilde* = 0x000000F1
  KEY_ograve* = 0x000000F2
  KEY_oacute* = 0x000000F3
  KEY_ocircumflex* = 0x000000F4
  KEY_otilde* = 0x000000F5
  KEY_odiaeresis* = 0x000000F6
  KEY_division* = 0x000000F7
  KEY_oslash* = 0x000000F8
  KEY_ugrave* = 0x000000F9
  KEY_uacute* = 0x000000FA
  KEY_ucircumflex* = 0x000000FB
  KEY_udiaeresis* = 0x000000FC
  KEY_yacute* = 0x000000FD
  KEY_thorn* = 0x000000FE
  KEY_ydiaeresis* = 0x000000FF
  KEY_CAPITAL_Aogonek* = 0x000001A1
  KEY_breve* = 0x000001A2
  KEY_CAPITAL_Lstroke* = 0x000001A3
  KEY_CAPITAL_Lcaron* = 0x000001A5
  KEY_CAPITAL_Sacute* = 0x000001A6
  KEY_CAPITAL_Scaron* = 0x000001A9
  KEY_CAPITAL_Scedilla* = 0x000001AA
  KEY_CAPITAL_Tcaron* = 0x000001AB
  KEY_CAPITAL_Zacute* = 0x000001AC
  KEY_CAPITAL_Zcaron* = 0x000001AE
  KEY_CAPITAL_Zabovedot* = 0x000001AF
  KEY_aogonek* = 0x000001B1
  KEY_ogonek* = 0x000001B2
  KEY_lstroke* = 0x000001B3
  KEY_lcaron* = 0x000001B5
  KEY_sacute* = 0x000001B6
  KEY_caron* = 0x000001B7
  KEY_scaron* = 0x000001B9
  KEY_scedilla* = 0x000001BA
  KEY_tcaron* = 0x000001BB
  KEY_zacute* = 0x000001BC
  KEY_doubleacute* = 0x000001BD
  KEY_zcaron* = 0x000001BE
  KEY_zabovedot* = 0x000001BF
  KEY_CAPITAL_Racute* = 0x000001C0
  KEY_CAPITAL_Abreve* = 0x000001C3
  KEY_CAPITAL_Lacute* = 0x000001C5
  KEY_CAPITAL_Cacute* = 0x000001C6
  KEY_CAPITAL_Ccaron* = 0x000001C8
  KEY_CAPITAL_Eogonek* = 0x000001CA
  KEY_CAPITAL_Ecaron* = 0x000001CC
  KEY_CAPITAL_Dcaron* = 0x000001CF
  KEY_CAPITAL_Dstroke* = 0x000001D0
  KEY_CAPITAL_Nacute* = 0x000001D1
  KEY_CAPITAL_Ncaron* = 0x000001D2
  KEY_CAPITAL_Odoubleacute* = 0x000001D5
  KEY_CAPITAL_Rcaron* = 0x000001D8
  KEY_CAPITAL_Uring* = 0x000001D9
  KEY_CAPITAL_Udoubleacute* = 0x000001DB
  KEY_CAPITAL_Tcedilla* = 0x000001DE
  KEY_racute* = 0x000001E0
  KEY_abreve* = 0x000001E3
  KEY_lacute* = 0x000001E5
  KEY_cacute* = 0x000001E6
  KEY_ccaron* = 0x000001E8
  KEY_eogonek* = 0x000001EA
  KEY_ecaron* = 0x000001EC
  KEY_dcaron* = 0x000001EF
  KEY_dstroke* = 0x000001F0
  KEY_nacute* = 0x000001F1
  KEY_ncaron* = 0x000001F2
  KEY_odoubleacute* = 0x000001F5
  KEY_udoubleacute* = 0x000001FB
  KEY_rcaron* = 0x000001F8
  KEY_uring* = 0x000001F9
  KEY_tcedilla* = 0x000001FE
  KEY_abovedot* = 0x000001FF
  KEY_CAPITAL_Hstroke* = 0x000002A1
  KEY_CAPITAL_Hcircumflex* = 0x000002A6
  KEY_CAPITAL_Iabovedot* = 0x000002A9
  KEY_CAPITAL_Gbreve* = 0x000002AB
  KEY_CAPITAL_Jcircumflex* = 0x000002AC
  KEY_hstroke* = 0x000002B1
  KEY_hcircumflex* = 0x000002B6
  KEY_idotless* = 0x000002B9
  KEY_gbreve* = 0x000002BB
  KEY_jcircumflex* = 0x000002BC
  KEY_CAPITAL_Cabovedot* = 0x000002C5
  KEY_CAPITAL_Ccircumflex* = 0x000002C6
  KEY_CAPITAL_Gabovedot* = 0x000002D5
  KEY_CAPITAL_Gcircumflex* = 0x000002D8
  KEY_CAPITAL_Ubreve* = 0x000002DD
  KEY_CAPITAL_Scircumflex* = 0x000002DE
  KEY_cabovedot* = 0x000002E5
  KEY_ccircumflex* = 0x000002E6
  KEY_gabovedot* = 0x000002F5
  KEY_gcircumflex* = 0x000002F8
  KEY_ubreve* = 0x000002FD
  KEY_scircumflex* = 0x000002FE
  KEY_kra* = 0x000003A2
  KEY_kappa* = 0x000003A2
  KEY_CAPITAL_Rcedilla* = 0x000003A3
  KEY_CAPITAL_Itilde* = 0x000003A5
  KEY_CAPITAL_Lcedilla* = 0x000003A6
  KEY_CAPITAL_Emacron* = 0x000003AA
  KEY_CAPITAL_Gcedilla* = 0x000003AB
  KEY_CAPITAL_Tslash* = 0x000003AC
  KEY_rcedilla* = 0x000003B3
  KEY_itilde* = 0x000003B5
  KEY_lcedilla* = 0x000003B6
  KEY_emacron* = 0x000003BA
  KEY_gcedilla* = 0x000003BB
  KEY_tslash* = 0x000003BC
  KEY_CAPITAL_ENG* = 0x000003BD
  KEY_eng* = 0x000003BF
  KEY_CAPITAL_Amacron* = 0x000003C0
  KEY_CAPITAL_Iogonek* = 0x000003C7
  KEY_CAPITAL_Eabovedot* = 0x000003CC
  KEY_CAPITAL_Imacron* = 0x000003CF
  KEY_CAPITAL_Ncedilla* = 0x000003D1
  KEY_CAPITAL_Omacron* = 0x000003D2
  KEY_CAPITAL_Kcedilla* = 0x000003D3
  KEY_CAPITAL_Uogonek* = 0x000003D9
  KEY_CAPITAL_Utilde* = 0x000003DD
  KEY_CAPITAL_Umacron* = 0x000003DE
  KEY_amacron* = 0x000003E0
  KEY_iogonek* = 0x000003E7
  KEY_eabovedot* = 0x000003EC
  KEY_imacron* = 0x000003EF
  KEY_ncedilla* = 0x000003F1
  KEY_omacron* = 0x000003F2
  KEY_kcedilla* = 0x000003F3
  KEY_uogonek* = 0x000003F9
  KEY_utilde* = 0x000003FD
  KEY_umacron* = 0x000003FE
  KEY_CAPITAL_OE* = 0x000013BC
  KEY_oe* = 0x000013BD
  KEY_CAPITAL_Ydiaeresis* = 0x000013BE
  KEY_overline* = 0x0000047E
  KEY_kana_fullstop* = 0x000004A1
  KEY_kana_openingbracket* = 0x000004A2
  KEY_kana_closingbracket* = 0x000004A3
  KEY_kana_comma* = 0x000004A4
  KEY_kana_conjunctive* = 0x000004A5
  KEY_kana_middledot* = 0x000004A5
  KEY_kana_WO* = 0x000004A6
  KEY_kana_a* = 0x000004A7
  KEY_kana_i* = 0x000004A8
  KEY_kana_u* = 0x000004A9
  KEY_kana_e* = 0x000004AA
  KEY_kana_o* = 0x000004AB
  KEY_kana_ya* = 0x000004AC
  KEY_kana_yu* = 0x000004AD
  KEY_kana_yo* = 0x000004AE
  KEY_kana_tsu* = 0x000004AF
  KEY_kana_tu* = 0x000004AF
  KEY_prolongedsound* = 0x000004B0
  KEY_kana_CAPITAL_A* = 0x000004B1
  KEY_kana_CAPITAL_I* = 0x000004B2
  KEY_kana_CAPITAL_U* = 0x000004B3
  KEY_kana_CAPITAL_E* = 0x000004B4
  KEY_kana_CAPITAL_O* = 0x000004B5
  KEY_kana_KA* = 0x000004B6
  KEY_kana_KI* = 0x000004B7
  KEY_kana_KU* = 0x000004B8
  KEY_kana_KE* = 0x000004B9
  KEY_kana_KO* = 0x000004BA
  KEY_kana_SA* = 0x000004BB
  KEY_kana_SHI* = 0x000004BC
  KEY_kana_SU* = 0x000004BD
  KEY_kana_SE* = 0x000004BE
  KEY_kana_SO* = 0x000004BF
  KEY_kana_TA* = 0x000004C0
  KEY_kana_CHI* = 0x000004C1
  KEY_kana_TI* = 0x000004C1
  KEY_kana_CAPITAL_TSU* = 0x000004C2
  KEY_kana_CAPITAL_TU* = 0x000004C2
  KEY_kana_TE* = 0x000004C3
  KEY_kana_TO* = 0x000004C4
  KEY_kana_NA* = 0x000004C5
  KEY_kana_NI* = 0x000004C6
  KEY_kana_NU* = 0x000004C7
  KEY_kana_NE* = 0x000004C8
  KEY_kana_NO* = 0x000004C9
  KEY_kana_HA* = 0x000004CA
  KEY_kana_HI* = 0x000004CB
  KEY_kana_FU* = 0x000004CC
  KEY_kana_HU* = 0x000004CC
  KEY_kana_HE* = 0x000004CD
  KEY_kana_HO* = 0x000004CE
  KEY_kana_MA* = 0x000004CF
  KEY_kana_MI* = 0x000004D0
  KEY_kana_MU* = 0x000004D1
  KEY_kana_ME* = 0x000004D2
  KEY_kana_MO* = 0x000004D3
  KEY_kana_CAPITAL_YA* = 0x000004D4
  KEY_kana_CAPITAL_YU* = 0x000004D5
  KEY_kana_CAPITAL_YO* = 0x000004D6
  KEY_kana_RA* = 0x000004D7
  KEY_kana_RI* = 0x000004D8
  KEY_kana_RU* = 0x000004D9
  KEY_kana_RE* = 0x000004DA
  KEY_kana_RO* = 0x000004DB
  KEY_kana_WA* = 0x000004DC
  KEY_kana_N* = 0x000004DD
  KEY_voicedsound* = 0x000004DE
  KEY_semivoicedsound* = 0x000004DF
  KEY_kana_switch* = 0x0000FF7E
  KEY_Arabic_comma* = 0x000005AC
  KEY_Arabic_semicolon* = 0x000005BB
  KEY_Arabic_question_mark* = 0x000005BF
  KEY_Arabic_hamza* = 0x000005C1
  KEY_Arabic_maddaonalef* = 0x000005C2
  KEY_Arabic_hamzaonalef* = 0x000005C3
  KEY_Arabic_hamzaonwaw* = 0x000005C4
  KEY_Arabic_hamzaunderalef* = 0x000005C5
  KEY_Arabic_hamzaonyeh* = 0x000005C6
  KEY_Arabic_alef* = 0x000005C7
  KEY_Arabic_beh* = 0x000005C8
  KEY_Arabic_tehmarbuta* = 0x000005C9
  KEY_Arabic_teh* = 0x000005CA
  KEY_Arabic_theh* = 0x000005CB
  KEY_Arabic_jeem* = 0x000005CC
  KEY_Arabic_hah* = 0x000005CD
  KEY_Arabic_khah* = 0x000005CE
  KEY_Arabic_dal* = 0x000005CF
  KEY_Arabic_thal* = 0x000005D0
  KEY_Arabic_ra* = 0x000005D1
  KEY_Arabic_zain* = 0x000005D2
  KEY_Arabic_seen* = 0x000005D3
  KEY_Arabic_sheen* = 0x000005D4
  KEY_Arabic_sad* = 0x000005D5
  KEY_Arabic_dad* = 0x000005D6
  KEY_Arabic_tah* = 0x000005D7
  KEY_Arabic_zah* = 0x000005D8
  KEY_Arabic_ain* = 0x000005D9
  KEY_Arabic_ghain* = 0x000005DA
  KEY_Arabic_tatweel* = 0x000005E0
  KEY_Arabic_feh* = 0x000005E1
  KEY_Arabic_qaf* = 0x000005E2
  KEY_Arabic_kaf* = 0x000005E3
  KEY_Arabic_lam* = 0x000005E4
  KEY_Arabic_meem* = 0x000005E5
  KEY_Arabic_noon* = 0x000005E6
  KEY_Arabic_ha* = 0x000005E7
  KEY_Arabic_heh* = 0x000005E7
  KEY_Arabic_waw* = 0x000005E8
  KEY_Arabic_alefmaksura* = 0x000005E9
  KEY_Arabic_yeh* = 0x000005EA
  KEY_Arabic_fathatan* = 0x000005EB
  KEY_Arabic_dammatan* = 0x000005EC
  KEY_Arabic_kasratan* = 0x000005ED
  KEY_Arabic_fatha* = 0x000005EE
  KEY_Arabic_damma* = 0x000005EF
  KEY_Arabic_kasra* = 0x000005F0
  KEY_Arabic_shadda* = 0x000005F1
  KEY_Arabic_sukun* = 0x000005F2
  KEY_Arabic_switch* = 0x0000FF7E
  KEY_Serbian_dje* = 0x000006A1
  KEY_Macedonia_gje* = 0x000006A2
  KEY_Cyrillic_io* = 0x000006A3
  KEY_Ukrainian_ie* = 0x000006A4
  KEY_Ukranian_je* = 0x000006A4
  KEY_Macedonia_dse* = 0x000006A5
  KEY_Ukrainian_i* = 0x000006A6
  KEY_Ukranian_i* = 0x000006A6
  KEY_Ukrainian_yi* = 0x000006A7
  KEY_Ukranian_yi* = 0x000006A7
  KEY_Cyrillic_je* = 0x000006A8
  KEY_Serbian_je* = 0x000006A8
  KEY_Cyrillic_lje* = 0x000006A9
  KEY_Serbian_lje* = 0x000006A9
  KEY_Cyrillic_nje* = 0x000006AA
  KEY_Serbian_nje* = 0x000006AA
  KEY_Serbian_tshe* = 0x000006AB
  KEY_Macedonia_kje* = 0x000006AC
  KEY_Byelorussian_shortu* = 0x000006AE
  KEY_Cyrillic_dzhe* = 0x000006AF
  KEY_Serbian_dze* = 0x000006AF
  KEY_numerosign* = 0x000006B0
  KEY_Serbian_CAPITAL_DJE* = 0x000006B1
  KEY_Macedonia_CAPITAL_GJE* = 0x000006B2
  KEY_Cyrillic_CAPITAL_IO* = 0x000006B3
  KEY_Ukrainian_CAPITAL_IE* = 0x000006B4
  KEY_Ukranian_CAPITAL_JE* = 0x000006B4
  KEY_Macedonia_CAPITAL_DSE* = 0x000006B5
  KEY_Ukrainian_CAPITAL_I* = 0x000006B6
  KEY_Ukranian_CAPITAL_I* = 0x000006B6
  KEY_Ukrainian_CAPITAL_YI* = 0x000006B7
  KEY_Ukranian_CAPITAL_YI* = 0x000006B7
  KEY_Cyrillic_CAPITAL_JE* = 0x000006B8
  KEY_Serbian_CAPITAL_JE* = 0x000006B8
  KEY_Cyrillic_CAPITAL_LJE* = 0x000006B9
  KEY_Serbian_CAPITAL_LJE* = 0x000006B9
  KEY_Cyrillic_CAPITAL_NJE* = 0x000006BA
  KEY_Serbian_CAPITAL_NJE* = 0x000006BA
  KEY_Serbian_CAPITAL_TSHE* = 0x000006BB
  KEY_Macedonia_CAPITAL_KJE* = 0x000006BC
  KEY_Byelorussian_CAPITAL_SHORTU* = 0x000006BE
  KEY_Cyrillic_CAPITAL_DZHE* = 0x000006BF
  KEY_Serbian_CAPITAL_DZE* = 0x000006BF
  KEY_Cyrillic_yu* = 0x000006C0
  KEY_Cyrillic_a* = 0x000006C1
  KEY_Cyrillic_be* = 0x000006C2
  KEY_Cyrillic_tse* = 0x000006C3
  KEY_Cyrillic_de* = 0x000006C4
  KEY_Cyrillic_ie* = 0x000006C5
  KEY_Cyrillic_ef* = 0x000006C6
  KEY_Cyrillic_ghe* = 0x000006C7
  KEY_Cyrillic_ha* = 0x000006C8
  KEY_Cyrillic_i* = 0x000006C9
  KEY_Cyrillic_shorti* = 0x000006CA
  KEY_Cyrillic_ka* = 0x000006CB
  KEY_Cyrillic_el* = 0x000006CC
  KEY_Cyrillic_em* = 0x000006CD
  KEY_Cyrillic_en* = 0x000006CE
  KEY_Cyrillic_o* = 0x000006CF
  KEY_Cyrillic_pe* = 0x000006D0
  KEY_Cyrillic_ya* = 0x000006D1
  KEY_Cyrillic_er* = 0x000006D2
  KEY_Cyrillic_es* = 0x000006D3
  KEY_Cyrillic_te* = 0x000006D4
  KEY_Cyrillic_u* = 0x000006D5
  KEY_Cyrillic_zhe* = 0x000006D6
  KEY_Cyrillic_ve* = 0x000006D7
  KEY_Cyrillic_softsign* = 0x000006D8
  KEY_Cyrillic_yeru* = 0x000006D9
  KEY_Cyrillic_ze* = 0x000006DA
  KEY_Cyrillic_sha* = 0x000006DB
  KEY_Cyrillic_e* = 0x000006DC
  KEY_Cyrillic_shcha* = 0x000006DD
  KEY_Cyrillic_che* = 0x000006DE
  KEY_Cyrillic_hardsign* = 0x000006DF
  KEY_Cyrillic_CAPITAL_YU* = 0x000006E0
  KEY_Cyrillic_CAPITAL_A* = 0x000006E1
  KEY_Cyrillic_CAPITAL_BE* = 0x000006E2
  KEY_Cyrillic_CAPITAL_TSE* = 0x000006E3
  KEY_Cyrillic_CAPITAL_DE* = 0x000006E4
  KEY_Cyrillic_CAPITAL_IE* = 0x000006E5
  KEY_Cyrillic_CAPITAL_EF* = 0x000006E6
  KEY_Cyrillic_CAPITAL_GHE* = 0x000006E7
  KEY_Cyrillic_CAPITAL_HA* = 0x000006E8
  KEY_Cyrillic_CAPITAL_I* = 0x000006E9
  KEY_Cyrillic_CAPITAL_SHORTI* = 0x000006EA
  KEY_Cyrillic_CAPITAL_KA* = 0x000006EB
  KEY_Cyrillic_CAPITAL_EL* = 0x000006EC
  KEY_Cyrillic_CAPITAL_EM* = 0x000006ED
  KEY_Cyrillic_CAPITAL_EN* = 0x000006EE
  KEY_Cyrillic_CAPITAL_O* = 0x000006EF
  KEY_Cyrillic_CAPITAL_PE* = 0x000006F0
  KEY_Cyrillic_CAPITAL_YA* = 0x000006F1
  KEY_Cyrillic_CAPITAL_ER* = 0x000006F2
  KEY_Cyrillic_CAPITAL_ES* = 0x000006F3
  KEY_Cyrillic_CAPITAL_TE* = 0x000006F4
  KEY_Cyrillic_CAPITAL_U* = 0x000006F5
  KEY_Cyrillic_CAPITAL_ZHE* = 0x000006F6
  KEY_Cyrillic_CAPITAL_VE* = 0x000006F7
  KEY_Cyrillic_CAPITAL_SOFTSIGN* = 0x000006F8
  KEY_Cyrillic_CAPITAL_YERU* = 0x000006F9
  KEY_Cyrillic_CAPITAL_ZE* = 0x000006FA
  KEY_Cyrillic_CAPITAL_SHA* = 0x000006FB
  KEY_Cyrillic_CAPITAL_E* = 0x000006FC
  KEY_Cyrillic_CAPITAL_SHCHA* = 0x000006FD
  KEY_Cyrillic_CAPITAL_CHE* = 0x000006FE
  KEY_Cyrillic_CAPITAL_HARDSIGN* = 0x000006FF
  KEY_Greek_CAPITAL_ALPHAaccent* = 0x000007A1
  KEY_Greek_CAPITAL_EPSILONaccent* = 0x000007A2
  KEY_Greek_CAPITAL_ETAaccent* = 0x000007A3
  KEY_Greek_CAPITAL_IOTAaccent* = 0x000007A4
  KEY_Greek_CAPITAL_IOTAdiaeresis* = 0x000007A5
  KEY_Greek_CAPITAL_OMICRONaccent* = 0x000007A7
  KEY_Greek_CAPITAL_UPSILONaccent* = 0x000007A8
  KEY_Greek_CAPITAL_UPSILONdieresis* = 0x000007A9
  KEY_Greek_CAPITAL_OMEGAaccent* = 0x000007AB
  KEY_Greek_accentdieresis* = 0x000007AE
  KEY_Greek_horizbar* = 0x000007AF
  KEY_Greek_alphaaccent* = 0x000007B1
  KEY_Greek_epsilonaccent* = 0x000007B2
  KEY_Greek_etaaccent* = 0x000007B3
  KEY_Greek_iotaaccent* = 0x000007B4
  KEY_Greek_iotadieresis* = 0x000007B5
  KEY_Greek_iotaaccentdieresis* = 0x000007B6
  KEY_Greek_omicronaccent* = 0x000007B7
  KEY_Greek_upsilonaccent* = 0x000007B8
  KEY_Greek_upsilondieresis* = 0x000007B9
  KEY_Greek_upsilonaccentdieresis* = 0x000007BA
  KEY_Greek_omegaaccent* = 0x000007BB
  KEY_Greek_CAPITAL_ALPHA* = 0x000007C1
  KEY_Greek_CAPITAL_BETA* = 0x000007C2
  KEY_Greek_CAPITAL_GAMMA* = 0x000007C3
  KEY_Greek_CAPITAL_DELTA* = 0x000007C4
  KEY_Greek_CAPITAL_EPSILON* = 0x000007C5
  KEY_Greek_CAPITAL_ZETA* = 0x000007C6
  KEY_Greek_CAPITAL_ETA* = 0x000007C7
  KEY_Greek_CAPITAL_THETA* = 0x000007C8
  KEY_Greek_CAPITAL_IOTA* = 0x000007C9
  KEY_Greek_CAPITAL_KAPPA* = 0x000007CA
  KEY_Greek_CAPITAL_LAMDA* = 0x000007CB
  KEY_Greek_CAPITAL_LAMBDA* = 0x000007CB
  KEY_Greek_CAPITAL_MU* = 0x000007CC
  KEY_Greek_CAPITAL_NU* = 0x000007CD
  KEY_Greek_CAPITAL_XI* = 0x000007CE
  KEY_Greek_CAPITAL_OMICRON* = 0x000007CF
  KEY_Greek_CAPITAL_PI* = 0x000007D0
  KEY_Greek_CAPITAL_RHO* = 0x000007D1
  KEY_Greek_CAPITAL_SIGMA* = 0x000007D2
  KEY_Greek_CAPITAL_TAU* = 0x000007D4
  KEY_Greek_CAPITAL_UPSILON* = 0x000007D5
  KEY_Greek_CAPITAL_PHI* = 0x000007D6
  KEY_Greek_CAPITAL_CHI* = 0x000007D7
  KEY_Greek_CAPITAL_PSI* = 0x000007D8
  KEY_Greek_CAPITAL_OMEGA* = 0x000007D9
  KEY_Greek_alpha* = 0x000007E1
  KEY_Greek_beta* = 0x000007E2
  KEY_Greek_gamma* = 0x000007E3
  KEY_Greek_delta* = 0x000007E4
  KEY_Greek_epsilon* = 0x000007E5
  KEY_Greek_zeta* = 0x000007E6
  KEY_Greek_eta* = 0x000007E7
  KEY_Greek_theta* = 0x000007E8
  KEY_Greek_iota* = 0x000007E9
  KEY_Greek_kappa* = 0x000007EA
  KEY_Greek_lamda* = 0x000007EB
  KEY_Greek_lambda* = 0x000007EB
  KEY_Greek_mu* = 0x000007EC
  KEY_Greek_nu* = 0x000007ED
  KEY_Greek_xi* = 0x000007EE
  KEY_Greek_omicron* = 0x000007EF
  KEY_Greek_pi* = 0x000007F0
  KEY_Greek_rho* = 0x000007F1
  KEY_Greek_sigma* = 0x000007F2
  KEY_Greek_finalsmallsigma* = 0x000007F3
  KEY_Greek_tau* = 0x000007F4
  KEY_Greek_upsilon* = 0x000007F5
  KEY_Greek_phi* = 0x000007F6
  KEY_Greek_chi* = 0x000007F7
  KEY_Greek_psi* = 0x000007F8
  KEY_Greek_omega* = 0x000007F9
  KEY_Greek_switch* = 0x0000FF7E
  KEY_leftradical* = 0x000008A1
  KEY_topleftradical* = 0x000008A2
  KEY_horizconnector* = 0x000008A3
  KEY_topintegral* = 0x000008A4
  KEY_botintegral* = 0x000008A5
  KEY_vertconnector* = 0x000008A6
  KEY_topleftsqbracket* = 0x000008A7
  KEY_botleftsqbracket* = 0x000008A8
  KEY_toprightsqbracket* = 0x000008A9
  KEY_botrightsqbracket* = 0x000008AA
  KEY_topleftparens* = 0x000008AB
  KEY_botleftparens* = 0x000008AC
  KEY_toprightparens* = 0x000008AD
  KEY_botrightparens* = 0x000008AE
  KEY_leftmiddlecurlybrace* = 0x000008AF
  KEY_rightmiddlecurlybrace* = 0x000008B0
  KEY_topleftsummation* = 0x000008B1
  KEY_botleftsummation* = 0x000008B2
  KEY_topvertsummationconnector* = 0x000008B3
  KEY_botvertsummationconnector* = 0x000008B4
  KEY_toprightsummation* = 0x000008B5
  KEY_botrightsummation* = 0x000008B6
  KEY_rightmiddlesummation* = 0x000008B7
  KEY_lessthanequal* = 0x000008BC
  KEY_notequal* = 0x000008BD
  KEY_greaterthanequal* = 0x000008BE
  KEY_integral* = 0x000008BF
  KEY_therefore* = 0x000008C0
  KEY_variation* = 0x000008C1
  KEY_infinity* = 0x000008C2
  KEY_nabla* = 0x000008C5
  KEY_approximate* = 0x000008C8
  KEY_similarequal* = 0x000008C9
  KEY_ifonlyif* = 0x000008CD
  KEY_implies* = 0x000008CE
  KEY_identical* = 0x000008CF
  KEY_radical* = 0x000008D6
  KEY_includedin* = 0x000008DA
  KEY_includes* = 0x000008DB
  KEY_intersection* = 0x000008DC
  KEY_union* = 0x000008DD
  KEY_logicaland* = 0x000008DE
  KEY_logicalor* = 0x000008DF
  KEY_partialderivative* = 0x000008EF
  KEY_function* = 0x000008F6
  KEY_leftarrow* = 0x000008FB
  KEY_uparrow* = 0x000008FC
  KEY_rightarrow* = 0x000008FD
  KEY_downarrow* = 0x000008FE
  KEY_blank* = 0x000009DF
  KEY_soliddiamond* = 0x000009E0
  KEY_checkerboard* = 0x000009E1
  KEY_ht* = 0x000009E2
  KEY_ff* = 0x000009E3
  KEY_cr* = 0x000009E4
  KEY_lf* = 0x000009E5
  KEY_nl* = 0x000009E8
  KEY_vt* = 0x000009E9
  KEY_lowrightcorner* = 0x000009EA
  KEY_uprightcorner* = 0x000009EB
  KEY_upleftcorner* = 0x000009EC
  KEY_lowleftcorner* = 0x000009ED
  KEY_crossinglines* = 0x000009EE
  KEY_horizlinescan1* = 0x000009EF
  KEY_horizlinescan3* = 0x000009F0
  KEY_horizlinescan5* = 0x000009F1
  KEY_horizlinescan7* = 0x000009F2
  KEY_horizlinescan9* = 0x000009F3
  KEY_leftt* = 0x000009F4
  KEY_rightt* = 0x000009F5
  KEY_bott* = 0x000009F6
  KEY_topt* = 0x000009F7
  KEY_vertbar* = 0x000009F8
  KEY_emspace* = 0x00000AA1
  KEY_enspace* = 0x00000AA2
  KEY_em3space* = 0x00000AA3
  KEY_em4space* = 0x00000AA4
  KEY_digitspace* = 0x00000AA5
  KEY_punctspace* = 0x00000AA6
  KEY_thinspace* = 0x00000AA7
  KEY_hairspace* = 0x00000AA8
  KEY_emdash* = 0x00000AA9
  KEY_endash* = 0x00000AAA
  KEY_signifblank* = 0x00000AAC
  KEY_ellipsis* = 0x00000AAE
  KEY_doubbaselinedot* = 0x00000AAF
  KEY_onethird* = 0x00000AB0
  KEY_twothirds* = 0x00000AB1
  KEY_onefifth* = 0x00000AB2
  KEY_twofifths* = 0x00000AB3
  KEY_threefifths* = 0x00000AB4
  KEY_fourfifths* = 0x00000AB5
  KEY_onesixth* = 0x00000AB6
  KEY_fivesixths* = 0x00000AB7
  KEY_careof* = 0x00000AB8
  KEY_figdash* = 0x00000ABB
  KEY_leftanglebracket* = 0x00000ABC
  KEY_decimalpoint* = 0x00000ABD
  KEY_rightanglebracket* = 0x00000ABE
  KEY_marker* = 0x00000ABF
  KEY_oneeighth* = 0x00000AC3
  KEY_threeeighths* = 0x00000AC4
  KEY_fiveeighths* = 0x00000AC5
  KEY_seveneighths* = 0x00000AC6
  KEY_trademark* = 0x00000AC9
  KEY_signaturemark* = 0x00000ACA
  KEY_trademarkincircle* = 0x00000ACB
  KEY_leftopentriangle* = 0x00000ACC
  KEY_rightopentriangle* = 0x00000ACD
  KEY_emopencircle* = 0x00000ACE
  KEY_emopenrectangle* = 0x00000ACF
  KEY_leftsinglequotemark* = 0x00000AD0
  KEY_rightsinglequotemark* = 0x00000AD1
  KEY_leftdoublequotemark* = 0x00000AD2
  KEY_rightdoublequotemark* = 0x00000AD3
  KEY_prescription* = 0x00000AD4
  KEY_minutes* = 0x00000AD6
  KEY_seconds* = 0x00000AD7
  KEY_latincross* = 0x00000AD9
  KEY_hexagram* = 0x00000ADA
  KEY_filledrectbullet* = 0x00000ADB
  KEY_filledlefttribullet* = 0x00000ADC
  KEY_filledrighttribullet* = 0x00000ADD
  KEY_emfilledcircle* = 0x00000ADE
  KEY_emfilledrect* = 0x00000ADF
  KEY_enopencircbullet* = 0x00000AE0
  KEY_enopensquarebullet* = 0x00000AE1
  KEY_openrectbullet* = 0x00000AE2
  KEY_opentribulletup* = 0x00000AE3
  KEY_opentribulletdown* = 0x00000AE4
  KEY_openstar* = 0x00000AE5
  KEY_enfilledcircbullet* = 0x00000AE6
  KEY_enfilledsqbullet* = 0x00000AE7
  KEY_filledtribulletup* = 0x00000AE8
  KEY_filledtribulletdown* = 0x00000AE9
  KEY_leftpointer* = 0x00000AEA
  KEY_rightpointer* = 0x00000AEB
  KEY_club* = 0x00000AEC
  KEY_diamond* = 0x00000AED
  KEY_heart* = 0x00000AEE
  KEY_maltesecross* = 0x00000AF0
  KEY_dagger* = 0x00000AF1
  KEY_doubledagger* = 0x00000AF2
  KEY_checkmark* = 0x00000AF3
  KEY_ballotcross* = 0x00000AF4
  KEY_musicalsharp* = 0x00000AF5
  KEY_musicalflat* = 0x00000AF6
  KEY_malesymbol* = 0x00000AF7
  KEY_femalesymbol* = 0x00000AF8
  KEY_telephone* = 0x00000AF9
  KEY_telephonerecorder* = 0x00000AFA
  KEY_phonographcopyright* = 0x00000AFB
  KEY_caret* = 0x00000AFC
  KEY_singlelowquotemark* = 0x00000AFD
  KEY_doublelowquotemark* = 0x00000AFE
  KEY_cursor* = 0x00000AFF
  KEY_leftcaret* = 0x00000BA3
  KEY_rightcaret* = 0x00000BA6
  KEY_downcaret* = 0x00000BA8
  KEY_upcaret* = 0x00000BA9
  KEY_overbar* = 0x00000BC0
  KEY_downtack* = 0x00000BC2
  KEY_upshoe* = 0x00000BC3
  KEY_downstile* = 0x00000BC4
  KEY_underbar* = 0x00000BC6
  KEY_jot* = 0x00000BCA
  KEY_quad* = 0x00000BCC
  KEY_uptack* = 0x00000BCE
  KEY_circle* = 0x00000BCF
  KEY_upstile* = 0x00000BD3
  KEY_downshoe* = 0x00000BD6
  KEY_rightshoe* = 0x00000BD8
  KEY_leftshoe* = 0x00000BDA
  KEY_lefttack* = 0x00000BDC
  KEY_righttack* = 0x00000BFC
  KEY_hebrew_doublelowline* = 0x00000CDF
  KEY_hebrew_aleph* = 0x00000CE0
  KEY_hebrew_bet* = 0x00000CE1
  KEY_hebrew_beth* = 0x00000CE1
  KEY_hebrew_gimel* = 0x00000CE2
  KEY_hebrew_gimmel* = 0x00000CE2
  KEY_hebrew_dalet* = 0x00000CE3
  KEY_hebrew_daleth* = 0x00000CE3
  KEY_hebrew_he* = 0x00000CE4
  KEY_hebrew_waw* = 0x00000CE5
  KEY_hebrew_zain* = 0x00000CE6
  KEY_hebrew_zayin* = 0x00000CE6
  KEY_hebrew_chet* = 0x00000CE7
  KEY_hebrew_het* = 0x00000CE7
  KEY_hebrew_tet* = 0x00000CE8
  KEY_hebrew_teth* = 0x00000CE8
  KEY_hebrew_yod* = 0x00000CE9
  KEY_hebrew_finalkaph* = 0x00000CEA
  KEY_hebrew_kaph* = 0x00000CEB
  KEY_hebrew_lamed* = 0x00000CEC
  KEY_hebrew_finalmem* = 0x00000CED
  KEY_hebrew_mem* = 0x00000CEE
  KEY_hebrew_finalnun* = 0x00000CEF
  KEY_hebrew_nun* = 0x00000CF0
  KEY_hebrew_samech* = 0x00000CF1
  KEY_hebrew_samekh* = 0x00000CF1
  KEY_hebrew_ayin* = 0x00000CF2
  KEY_hebrew_finalpe* = 0x00000CF3
  KEY_hebrew_pe* = 0x00000CF4
  KEY_hebrew_finalzade* = 0x00000CF5
  KEY_hebrew_finalzadi* = 0x00000CF5
  KEY_hebrew_zade* = 0x00000CF6
  KEY_hebrew_zadi* = 0x00000CF6
  KEY_hebrew_qoph* = 0x00000CF7
  KEY_hebrew_kuf* = 0x00000CF7
  KEY_hebrew_resh* = 0x00000CF8
  KEY_hebrew_shin* = 0x00000CF9
  KEY_hebrew_taw* = 0x00000CFA
  KEY_hebrew_taf* = 0x00000CFA
  KEY_Hebrew_switch* = 0x0000FF7E
  KEY_Thai_kokai* = 0x00000DA1
  KEY_Thai_khokhai* = 0x00000DA2
  KEY_Thai_khokhuat* = 0x00000DA3
  KEY_Thai_khokhwai* = 0x00000DA4
  KEY_Thai_khokhon* = 0x00000DA5
  KEY_Thai_khorakhang* = 0x00000DA6
  KEY_Thai_ngongu* = 0x00000DA7
  KEY_Thai_chochan* = 0x00000DA8
  KEY_Thai_choching* = 0x00000DA9
  KEY_Thai_chochang* = 0x00000DAA
  KEY_Thai_soso* = 0x00000DAB
  KEY_Thai_chochoe* = 0x00000DAC
  KEY_Thai_yoying* = 0x00000DAD
  KEY_Thai_dochada* = 0x00000DAE
  KEY_Thai_topatak* = 0x00000DAF
  KEY_Thai_thothan* = 0x00000DB0
  KEY_Thai_thonangmontho* = 0x00000DB1
  KEY_Thai_thophuthao* = 0x00000DB2
  KEY_Thai_nonen* = 0x00000DB3
  KEY_Thai_dodek* = 0x00000DB4
  KEY_Thai_totao* = 0x00000DB5
  KEY_Thai_thothung* = 0x00000DB6
  KEY_Thai_thothahan* = 0x00000DB7
  KEY_Thai_thothong* = 0x00000DB8
  KEY_Thai_nonu* = 0x00000DB9
  KEY_Thai_bobaimai* = 0x00000DBA
  KEY_Thai_popla* = 0x00000DBB
  KEY_Thai_phophung* = 0x00000DBC
  KEY_Thai_fofa* = 0x00000DBD
  KEY_Thai_phophan* = 0x00000DBE
  KEY_Thai_fofan* = 0x00000DBF
  KEY_Thai_phosamphao* = 0x00000DC0
  KEY_Thai_moma* = 0x00000DC1
  KEY_Thai_yoyak* = 0x00000DC2
  KEY_Thai_rorua* = 0x00000DC3
  KEY_Thai_ru* = 0x00000DC4
  KEY_Thai_loling* = 0x00000DC5
  KEY_Thai_lu* = 0x00000DC6
  KEY_Thai_wowaen* = 0x00000DC7
  KEY_Thai_sosala* = 0x00000DC8
  KEY_Thai_sorusi* = 0x00000DC9
  KEY_Thai_sosua* = 0x00000DCA
  KEY_Thai_hohip* = 0x00000DCB
  KEY_Thai_lochula* = 0x00000DCC
  KEY_Thai_oang* = 0x00000DCD
  KEY_Thai_honokhuk* = 0x00000DCE
  KEY_Thai_paiyannoi* = 0x00000DCF
  KEY_Thai_saraa* = 0x00000DD0
  KEY_Thai_maihanakat* = 0x00000DD1
  KEY_Thai_saraaa* = 0x00000DD2
  KEY_Thai_saraam* = 0x00000DD3
  KEY_Thai_sarai* = 0x00000DD4
  KEY_Thai_saraii* = 0x00000DD5
  KEY_Thai_saraue* = 0x00000DD6
  KEY_Thai_sarauee* = 0x00000DD7
  KEY_Thai_sarau* = 0x00000DD8
  KEY_Thai_sarauu* = 0x00000DD9
  KEY_Thai_phinthu* = 0x00000DDA
  KEY_Thai_maihanakat_maitho* = 0x00000DDE
  KEY_Thai_baht* = 0x00000DDF
  KEY_Thai_sarae* = 0x00000DE0
  KEY_Thai_saraae* = 0x00000DE1
  KEY_Thai_sarao* = 0x00000DE2
  KEY_Thai_saraaimaimuan* = 0x00000DE3
  KEY_Thai_saraaimaimalai* = 0x00000DE4
  KEY_Thai_lakkhangyao* = 0x00000DE5
  KEY_Thai_maiyamok* = 0x00000DE6
  KEY_Thai_maitaikhu* = 0x00000DE7
  KEY_Thai_maiek* = 0x00000DE8
  KEY_Thai_maitho* = 0x00000DE9
  KEY_Thai_maitri* = 0x00000DEA
  KEY_Thai_maichattawa* = 0x00000DEB
  KEY_Thai_thanthakhat* = 0x00000DEC
  KEY_Thai_nikhahit* = 0x00000DED
  KEY_Thai_leksun* = 0x00000DF0
  KEY_Thai_leknung* = 0x00000DF1
  KEY_Thai_leksong* = 0x00000DF2
  KEY_Thai_leksam* = 0x00000DF3
  KEY_Thai_leksi* = 0x00000DF4
  KEY_Thai_lekha* = 0x00000DF5
  KEY_Thai_lekhok* = 0x00000DF6
  KEY_Thai_lekchet* = 0x00000DF7
  KEY_Thai_lekpaet* = 0x00000DF8
  KEY_Thai_lekkao* = 0x00000DF9
  KEY_Hangul* = 0x0000FF31
  KEY_Hangul_Start* = 0x0000FF32
  KEY_Hangul_End* = 0x0000FF33
  KEY_Hangul_Hanja* = 0x0000FF34
  KEY_Hangul_Jamo* = 0x0000FF35
  KEY_Hangul_Romaja* = 0x0000FF36
  KEY_Hangul_Codeinput* = 0x0000FF37
  KEY_Hangul_Jeonja* = 0x0000FF38
  KEY_Hangul_Banja* = 0x0000FF39
  KEY_Hangul_PreHanja* = 0x0000FF3A
  KEY_Hangul_PostHanja* = 0x0000FF3B
  KEY_Hangul_SingleCandidate* = 0x0000FF3C
  KEY_Hangul_MultipleCandidate* = 0x0000FF3D
  KEY_Hangul_PreviousCandidate* = 0x0000FF3E
  KEY_Hangul_Special* = 0x0000FF3F
  KEY_Hangul_switch* = 0x0000FF7E
  KEY_Hangul_Kiyeog* = 0x00000EA1
  KEY_Hangul_SsangKiyeog* = 0x00000EA2
  KEY_Hangul_KiyeogSios* = 0x00000EA3
  KEY_Hangul_Nieun* = 0x00000EA4
  KEY_Hangul_NieunJieuj* = 0x00000EA5
  KEY_Hangul_NieunHieuh* = 0x00000EA6
  KEY_Hangul_Dikeud* = 0x00000EA7
  KEY_Hangul_SsangDikeud* = 0x00000EA8
  KEY_Hangul_Rieul* = 0x00000EA9
  KEY_Hangul_RieulKiyeog* = 0x00000EAA
  KEY_Hangul_RieulMieum* = 0x00000EAB
  KEY_Hangul_RieulPieub* = 0x00000EAC
  KEY_Hangul_RieulSios* = 0x00000EAD
  KEY_Hangul_RieulTieut* = 0x00000EAE
  KEY_Hangul_RieulPhieuf* = 0x00000EAF
  KEY_Hangul_RieulHieuh* = 0x00000EB0
  KEY_Hangul_Mieum* = 0x00000EB1
  KEY_Hangul_Pieub* = 0x00000EB2
  KEY_Hangul_SsangPieub* = 0x00000EB3
  KEY_Hangul_PieubSios* = 0x00000EB4
  KEY_Hangul_Sios* = 0x00000EB5
  KEY_Hangul_SsangSios* = 0x00000EB6
  KEY_Hangul_Ieung* = 0x00000EB7
  KEY_Hangul_Jieuj* = 0x00000EB8
  KEY_Hangul_SsangJieuj* = 0x00000EB9
  KEY_Hangul_Cieuc* = 0x00000EBA
  KEY_Hangul_Khieuq* = 0x00000EBB
  KEY_Hangul_Tieut* = 0x00000EBC
  KEY_Hangul_Phieuf* = 0x00000EBD
  KEY_Hangul_Hieuh* = 0x00000EBE
  KEY_Hangul_A* = 0x00000EBF
  KEY_Hangul_AE* = 0x00000EC0
  KEY_Hangul_YA* = 0x00000EC1
  KEY_Hangul_YAE* = 0x00000EC2
  KEY_Hangul_EO* = 0x00000EC3
  KEY_Hangul_E* = 0x00000EC4
  KEY_Hangul_YEO* = 0x00000EC5
  KEY_Hangul_YE* = 0x00000EC6
  KEY_Hangul_O* = 0x00000EC7
  KEY_Hangul_WA* = 0x00000EC8
  KEY_Hangul_WAE* = 0x00000EC9
  KEY_Hangul_OE* = 0x00000ECA
  KEY_Hangul_YO* = 0x00000ECB
  KEY_Hangul_U* = 0x00000ECC
  KEY_Hangul_WEO* = 0x00000ECD
  KEY_Hangul_WE* = 0x00000ECE
  KEY_Hangul_WI* = 0x00000ECF
  KEY_Hangul_YU* = 0x00000ED0
  KEY_Hangul_EU* = 0x00000ED1
  KEY_Hangul_YI* = 0x00000ED2
  KEY_Hangul_I* = 0x00000ED3
  KEY_Hangul_J_Kiyeog* = 0x00000ED4
  KEY_Hangul_J_SsangKiyeog* = 0x00000ED5
  KEY_Hangul_J_KiyeogSios* = 0x00000ED6
  KEY_Hangul_J_Nieun* = 0x00000ED7
  KEY_Hangul_J_NieunJieuj* = 0x00000ED8
  KEY_Hangul_J_NieunHieuh* = 0x00000ED9
  KEY_Hangul_J_Dikeud* = 0x00000EDA
  KEY_Hangul_J_Rieul* = 0x00000EDB
  KEY_Hangul_J_RieulKiyeog* = 0x00000EDC
  KEY_Hangul_J_RieulMieum* = 0x00000EDD
  KEY_Hangul_J_RieulPieub* = 0x00000EDE
  KEY_Hangul_J_RieulSios* = 0x00000EDF
  KEY_Hangul_J_RieulTieut* = 0x00000EE0
  KEY_Hangul_J_RieulPhieuf* = 0x00000EE1
  KEY_Hangul_J_RieulHieuh* = 0x00000EE2
  KEY_Hangul_J_Mieum* = 0x00000EE3
  KEY_Hangul_J_Pieub* = 0x00000EE4
  KEY_Hangul_J_PieubSios* = 0x00000EE5
  KEY_Hangul_J_Sios* = 0x00000EE6
  KEY_Hangul_J_SsangSios* = 0x00000EE7
  KEY_Hangul_J_Ieung* = 0x00000EE8
  KEY_Hangul_J_Jieuj* = 0x00000EE9
  KEY_Hangul_J_Cieuc* = 0x00000EEA
  KEY_Hangul_J_Khieuq* = 0x00000EEB
  KEY_Hangul_J_Tieut* = 0x00000EEC
  KEY_Hangul_J_Phieuf* = 0x00000EED
  KEY_Hangul_J_Hieuh* = 0x00000EEE
  KEY_Hangul_RieulYeorinHieuh* = 0x00000EEF
  KEY_Hangul_SunkyeongeumMieum* = 0x00000EF0
  KEY_Hangul_SunkyeongeumPieub* = 0x00000EF1
  KEY_Hangul_PanSios* = 0x00000EF2
  KEY_Hangul_KkogjiDalrinIeung* = 0x00000EF3
  KEY_Hangul_SunkyeongeumPhieuf* = 0x00000EF4
  KEY_Hangul_YeorinHieuh* = 0x00000EF5
  KEY_Hangul_AraeA* = 0x00000EF6
  KEY_Hangul_AraeAE* = 0x00000EF7
  KEY_Hangul_J_PanSios* = 0x00000EF8
  KEY_Hangul_J_KkogjiDalrinIeung* = 0x00000EF9
  KEY_Hangul_J_YeorinHieuh* = 0x00000EFA
  KEY_Korean_Won* = 0x00000EFF
  KEY_EcuSign* = 0x000020A0
  KEY_ColonSign* = 0x000020A1
  KEY_CruzeiroSign* = 0x000020A2
  KEY_FFrancSign* = 0x000020A3
  KEY_LiraSign* = 0x000020A4
  KEY_MillSign* = 0x000020A5
  KEY_NairaSign* = 0x000020A6
  KEY_PesetaSign* = 0x000020A7
  KEY_RupeeSign* = 0x000020A8
  KEY_WonSign* = 0x000020A9
  KEY_NewSheqelSign* = 0x000020AA
  KEY_DongSign* = 0x000020AB
  KEY_EuroSign* = 0x000020AC

proc pango_context_get_for_screen*(screen: PScreen): PContext{.cdecl,
    dynlib: lib, importc: "gdk_pango_context_get_for_screen".}
proc pango_context_set_colormap*(context: PContext, colormap: PColormap){.
    cdecl, dynlib: lib, importc: "gdk_pango_context_set_colormap".}
proc pango_layout_line_get_clip_region*(line: PLayoutLine, x_origin: gint,
                                        y_origin: gint, index_ranges: Pgint,
                                        n_ranges: gint): PRegion{.cdecl,
    dynlib: lib, importc: "gdk_pango_layout_line_get_clip_region".}
proc pango_layout_get_clip_region*(layout: PLayout, x_origin: gint,
                                   y_origin: gint, index_ranges: Pgint,
                                   n_ranges: gint): PRegion{.cdecl, dynlib: lib,
    importc: "gdk_pango_layout_get_clip_region".}
proc pango_attr_stipple_new*(stipple: PBitmap): PAttribute{.cdecl,
    dynlib: lib, importc: "gdk_pango_attr_stipple_new".}
proc pango_attr_embossed_new*(embossed: gboolean): PAttribute{.cdecl,
    dynlib: lib, importc: "gdk_pango_attr_embossed_new".}
proc render_threshold_alpha*(pixbuf: PPixbuf, bitmap: PBitmap,
                                    src_x: int32, src_y: int32, dest_x: int32,
                                    dest_y: int32, width: int32, height: int32,
                                    alpha_threshold: int32){.cdecl, dynlib: lib,
    importc: "gdk_pixbuf_render_threshold_alpha".}
proc render_to_drawable*(pixbuf: PPixbuf, drawable: PDrawable, gc: PGC,
                                src_x: int32, src_y: int32, dest_x: int32,
                                dest_y: int32, width: int32, height: int32,
                                dither: TRgbDither, x_dither: int32,
                                y_dither: int32){.cdecl, dynlib: lib,
    importc: "gdk_pixbuf_render_to_drawable".}
proc render_to_drawable_alpha*(pixbuf: PPixbuf, drawable: PDrawable,
                                      src_x: int32, src_y: int32, dest_x: int32,
                                      dest_y: int32, width: int32,
                                      height: int32,
                                      alpha_mode: TPixbufAlphaMode,
                                      alpha_threshold: int32,
                                      dither: TRgbDither, x_dither: int32,
                                      y_dither: int32){.cdecl, dynlib: lib,
    importc: "gdk_pixbuf_render_to_drawable_alpha".}
proc render_pixmap_and_mask_for_colormap*(pixbuf: PPixbuf,
    colormap: PColormap, n: var PPixmap, nasdfdsafw4e: var PBitmap,
    alpha_threshold: int32){.cdecl, dynlib: lib, importc: "gdk_pixbuf_render_pixmap_and_mask_for_colormap".}
proc get_from_drawable*(dest: PPixbuf, src: PDrawable, cmap: PColormap,
                               src_x: int32, src_y: int32, dest_x: int32,
                               dest_y: int32, width: int32, height: int32): PPixbuf{.
    cdecl, dynlib: lib, importc: "gdk_pixbuf_get_from_drawable".}
proc get_from_image*(dest: PPixbuf, src: PImage, cmap: PColormap,
                            src_x: int32, src_y: int32, dest_x: int32,
                            dest_y: int32, width: int32, height: int32): PPixbuf{.
    cdecl, dynlib: lib, importc: "gdk_pixbuf_get_from_image".}
proc TYPE_PIXMAP*(): GType
proc PIXMAP*(anObject: Pointer): PPixmap
proc PIXMAP_CLASS*(klass: Pointer): PPixmapObjectClass
proc IS_PIXMAP*(anObject: Pointer): bool
proc IS_PIXMAP_CLASS*(klass: Pointer): bool
proc PIXMAP_GET_CLASS*(obj: Pointer): PPixmapObjectClass
proc PIXMAP_OBJECT*(anObject: Pointer): PPixmapObject
proc pixmap_get_type*(): GType{.cdecl, dynlib: lib,
                                importc: "gdk_pixmap_get_type".}
proc pixmap_new*(window: PWindow, width: gint, height: gint, depth: gint): PPixmap{.
    cdecl, dynlib: lib, importc: "gdk_pixmap_new".}
proc bitmap_create_from_data*(window: PWindow, data: cstring, width: gint,
                              height: gint): PBitmap{.cdecl, dynlib: lib,
    importc: "gdk_bitmap_create_from_data".}
proc pixmap_create_from_data*(window: PWindow, data: cstring, width: gint,
                              height: gint, depth: gint, fg: PColor, bg: PColor): PPixmap{.
    cdecl, dynlib: lib, importc: "gdk_pixmap_create_from_data".}
proc pixmap_create_from_xpm*(window: PWindow, k: var PBitmap,
                             transparent_color: PColor, filename: cstring): PPixmap{.
    cdecl, dynlib: lib, importc: "gdk_pixmap_create_from_xpm".}
proc pixmap_colormap_create_from_xpm*(window: PWindow, colormap: PColormap,
                                      k: var PBitmap, transparent_color: PColor,
                                      filename: cstring): PPixmap{.cdecl,
    dynlib: lib, importc: "gdk_pixmap_colormap_create_from_xpm".}
proc pixmap_create_from_xpm_d*(window: PWindow, k: var PBitmap,
                               transparent_color: PColor, data: PPgchar): PPixmap{.
    cdecl, dynlib: lib, importc: "gdk_pixmap_create_from_xpm_d".}
proc pixmap_colormap_create_from_xpm_d*(window: PWindow, colormap: PColormap,
                                        k: var PBitmap,
                                        transparent_color: PColor, data: PPgchar): PPixmap{.
    cdecl, dynlib: lib, importc: "gdk_pixmap_colormap_create_from_xpm_d".}
proc pixmap_foreign_new_for_display*(display: PDisplay, anid: TNativeWindow): PPixmap{.
    cdecl, dynlib: lib, importc: "gdk_pixmap_foreign_new_for_display".}
proc pixmap_lookup_for_display*(display: PDisplay, anid: TNativeWindow): PPixmap{.
    cdecl, dynlib: lib, importc: "gdk_pixmap_lookup_for_display".}
proc atom_intern*(atom_name: cstring, only_if_exists: gboolean): TAtom{.cdecl,
    dynlib: lib, importc: "gdk_atom_intern".}
proc atom_name*(atom: TAtom): cstring{.cdecl, dynlib: lib,
                                       importc: "gdk_atom_name".}
proc property_get*(window: PWindow, `property`: TAtom, `type`: TAtom,
                   offset: gulong, length: gulong, pdelete: gint,
                   actual_property_type: PAtom, actual_format: Pgint,
                   actual_length: Pgint, data: PPguchar): gboolean{.cdecl,
    dynlib: lib, importc: "gdk_property_get".}
proc property_change*(window: PWindow, `property`: TAtom, `type`: TAtom,
                      format: gint, mode: TPropMode, data: Pguchar,
                      nelements: gint){.cdecl, dynlib: lib,
                                        importc: "gdk_property_change".}
proc property_delete*(window: PWindow, `property`: TAtom){.cdecl, dynlib: lib,
    importc: "gdk_property_delete".}
proc text_property_to_text_list_for_display*(display: PDisplay, encoding: TAtom,
    format: gint, text: Pguchar, length: gint, t: var PPgchar): gint{.cdecl,
    dynlib: lib, importc: "gdk_text_property_to_text_list_for_display".}
proc text_property_to_utf8_list_for_display*(display: PDisplay, encoding: TAtom,
    format: gint, text: Pguchar, length: gint, t: var PPgchar): gint{.cdecl,
    dynlib: lib, importc: "gdk_text_property_to_utf8_list_for_display".}
proc utf8_to_string_target*(str: cstring): cstring{.cdecl, dynlib: lib,
    importc: "gdk_utf8_to_string_target".}
proc string_to_compound_text_for_display*(display: PDisplay, str: cstring,
    encoding: PAtom, format: Pgint, ctext: PPguchar, length: Pgint): gint{.
    cdecl, dynlib: lib, importc: "gdk_string_to_compound_text_for_display".}
proc utf8_to_compound_text_for_display*(display: PDisplay, str: cstring,
                                        encoding: PAtom, format: Pgint,
                                        ctext: PPguchar, length: Pgint): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_utf8_to_compound_text_for_display".}
proc free_text_list*(list: PPgchar){.cdecl, dynlib: lib,
                                     importc: "gdk_free_text_list".}
proc free_compound_text*(ctext: Pguchar){.cdecl, dynlib: lib,
    importc: "gdk_free_compound_text".}
proc region_new*(): PRegion{.cdecl, dynlib: lib, importc: "gdk_region_new".}
proc region_polygon*(points: PPoint, npoints: gint, fill_rule: TFillRule): PRegion{.
    cdecl, dynlib: lib, importc: "gdk_region_polygon".}
proc copy*(region: PRegion): PRegion{.cdecl, dynlib: lib,
    importc: "gdk_region_copy".}
proc region_rectangle*(rectangle: PRectangle): PRegion{.cdecl, dynlib: lib,
    importc: "gdk_region_rectangle".}
proc destroy*(region: PRegion){.cdecl, dynlib: lib,
                                       importc: "gdk_region_destroy".}
proc get_clipbox*(region: PRegion, rectangle: PRectangle){.cdecl,
    dynlib: lib, importc: "gdk_region_get_clipbox".}
proc get_rectangles*(region: PRegion, s: var PRectangle,
                            n_rectangles: Pgint){.cdecl, dynlib: lib,
    importc: "gdk_region_get_rectangles".}
proc empty*(region: PRegion): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_region_empty".}
proc equal*(region1: PRegion, region2: PRegion): gboolean{.cdecl,
    dynlib: lib, importc: "gdk_region_equal".}
proc point_in*(region: PRegion, x: int32, y: int32): gboolean{.cdecl,
    dynlib: lib, importc: "gdk_region_point_in".}
proc rect_in*(region: PRegion, rect: PRectangle): TOverlapType{.cdecl,
    dynlib: lib, importc: "gdk_region_rect_in".}
proc offset*(region: PRegion, dx: gint, dy: gint){.cdecl, dynlib: lib,
    importc: "gdk_region_offset".}
proc shrink*(region: PRegion, dx: gint, dy: gint){.cdecl, dynlib: lib,
    importc: "gdk_region_shrink".}
proc union*(region: PRegion, rect: PRectangle){.cdecl,
    dynlib: lib, importc: "gdk_region_union_with_rect".}
proc intersect*(source1: PRegion, source2: PRegion){.cdecl, dynlib: lib,
    importc: "gdk_region_intersect".}
proc union*(source1: PRegion, source2: PRegion){.cdecl, dynlib: lib,
    importc: "gdk_region_union".}
proc subtract*(source1: PRegion, source2: PRegion){.cdecl, dynlib: lib,
    importc: "gdk_region_subtract".}
proc `xor`*(source1: PRegion, source2: PRegion){.cdecl, dynlib: lib,
    importc: "gdk_region_xor".}
proc spans_intersect_foreach*(region: PRegion, spans: PSpan,
                                     n_spans: int32, sorted: gboolean,
                                     `function`: TSpanFunc, data: gpointer){.
    cdecl, dynlib: lib, importc: "gdk_region_spans_intersect_foreach".}
proc rgb_find_color*(colormap: PColormap, color: PColor){.cdecl, dynlib: lib,
    importc: "gdk_rgb_find_color".}
proc rgb_image*(drawable: PDrawable, gc: PGC, x: gint, y: gint,
                     width: gint, height: gint, dith: TRgbDither,
                     rgb_buf: Pguchar, rowstride: gint){.cdecl, dynlib: lib,
    importc: "gdk_draw_rgb_image".}
proc rgb_image_dithalign*(drawable: PDrawable, gc: PGC, x: gint, y: gint,
                               width: gint, height: gint, dith: TRgbDither,
                               rgb_buf: Pguchar, rowstride: gint, xdith: gint,
                               ydith: gint){.cdecl, dynlib: lib,
    importc: "gdk_draw_rgb_image_dithalign".}
proc rgb_32_image*(drawable: PDrawable, gc: PGC, x: gint, y: gint,
                        width: gint, height: gint, dith: TRgbDither,
                        buf: Pguchar, rowstride: gint){.cdecl, dynlib: lib,
    importc: "gdk_draw_rgb_32_image".}
proc rgb_32_image_dithalign*(drawable: PDrawable, gc: PGC, x: gint,
                                  y: gint, width: gint, height: gint,
                                  dith: TRgbDither, buf: Pguchar,
                                  rowstride: gint, xdith: gint, ydith: gint){.
    cdecl, dynlib: lib, importc: "gdk_draw_rgb_32_image_dithalign".}
proc gray_image*(drawable: PDrawable, gc: PGC, x: gint, y: gint,
                      width: gint, height: gint, dith: TRgbDither, buf: Pguchar,
                      rowstride: gint){.cdecl, dynlib: lib,
                                        importc: "gdk_draw_gray_image".}
proc indexed_image*(drawable: PDrawable, gc: PGC, x: gint, y: gint,
                         width: gint, height: gint, dith: TRgbDither,
                         buf: Pguchar, rowstride: gint, cmap: PRgbCmap){.cdecl,
    dynlib: lib, importc: "gdk_draw_indexed_image".}
proc rgb_cmap_new*(colors: Pguint32, n_colors: gint): PRgbCmap{.cdecl,
    dynlib: lib, importc: "gdk_rgb_cmap_new".}
proc free*(cmap: PRgbCmap){.cdecl, dynlib: lib,
                                     importc: "gdk_rgb_cmap_free".}
proc rgb_set_verbose*(verbose: gboolean){.cdecl, dynlib: lib,
    importc: "gdk_rgb_set_verbose".}
proc rgb_set_install*(install: gboolean){.cdecl, dynlib: lib,
    importc: "gdk_rgb_set_install".}
proc rgb_set_min_colors*(min_colors: gint){.cdecl, dynlib: lib,
    importc: "gdk_rgb_set_min_colors".}
proc TYPE_DISPLAY*(): GType
proc DISPLAY_OBJECT*(anObject: pointer): PDisplay
proc DISPLAY_CLASS*(klass: pointer): PDisplayClass
proc IS_DISPLAY*(anObject: pointer): bool
proc IS_DISPLAY_CLASS*(klass: pointer): bool
proc DISPLAY_GET_CLASS*(obj: pointer): PDisplayClass
proc display_open*(display_name: cstring): PDisplay{.cdecl, dynlib: lib,
    importc: "gdk_display_open".}
proc get_name*(display: PDisplay): cstring{.cdecl, dynlib: lib,
    importc: "gdk_display_get_name".}
proc get_n_screens*(display: PDisplay): gint{.cdecl, dynlib: lib,
    importc: "gdk_display_get_n_screens".}
proc get_screen*(display: PDisplay, screen_num: gint): PScreen{.cdecl,
    dynlib: lib, importc: "gdk_display_get_screen".}
proc get_default_screen*(display: PDisplay): PScreen{.cdecl,
    dynlib: lib, importc: "gdk_display_get_default_screen".}
proc pointer_ungrab*(display: PDisplay, time: guint32){.cdecl,
    dynlib: lib, importc: "gdk_display_pointer_ungrab".}
proc keyboard_ungrab*(display: PDisplay, time: guint32){.cdecl,
    dynlib: lib, importc: "gdk_display_keyboard_ungrab".}
proc pointer_is_grabbed*(display: PDisplay): gboolean{.cdecl,
    dynlib: lib, importc: "gdk_display_pointer_is_grabbed".}
proc beep*(display: PDisplay){.cdecl, dynlib: lib,
                                       importc: "gdk_display_beep".}
proc sync*(display: PDisplay){.cdecl, dynlib: lib,
                                       importc: "gdk_display_sync".}
proc close*(display: PDisplay){.cdecl, dynlib: lib,
                                        importc: "gdk_display_close".}
proc list_devices*(display: PDisplay): PGList{.cdecl, dynlib: lib,
    importc: "gdk_display_list_devices".}
proc get_event*(display: PDisplay): PEvent{.cdecl, dynlib: lib,
    importc: "gdk_display_get_event".}
proc peek_event*(display: PDisplay): PEvent{.cdecl, dynlib: lib,
    importc: "gdk_display_peek_event".}
proc put_event*(display: PDisplay, event: PEvent){.cdecl, dynlib: lib,
    importc: "gdk_display_put_event".}
proc add_client_message_filter*(display: PDisplay, message_type: TAtom,
                                        func: TFilterFunc, data: gpointer){.
    cdecl, dynlib: lib, importc: "gdk_display_add_client_message_filter".}
proc set_double_click_time*(display: PDisplay, msec: guint){.cdecl,
    dynlib: lib, importc: "gdk_display_set_double_click_time".}
proc set_sm_client_id*(display: PDisplay, sm_client_id: cstring){.cdecl,
    dynlib: lib, importc: "gdk_display_set_sm_client_id".}
proc set_default_display*(display: PDisplay){.cdecl, dynlib: lib,
    importc: "gdk_set_default_display".}
proc get_default_display*(): PDisplay{.cdecl, dynlib: lib,
                                       importc: "gdk_get_default_display".}
proc TYPE_SCREEN*(): GType
proc SCREEN*(anObject: Pointer): PScreen
proc SCREEN_CLASS*(klass: Pointer): PScreenClass
proc IS_SCREEN*(anObject: Pointer): bool
proc IS_SCREEN_CLASS*(klass: Pointer): bool
proc SCREEN_GET_CLASS*(obj: Pointer): PScreenClass
proc get_default_colormap*(screen: PScreen): PColormap{.cdecl,
    dynlib: lib, importc: "gdk_screen_get_default_colormap".}
proc set_default_colormap*(screen: PScreen, colormap: PColormap){.cdecl,
    dynlib: lib, importc: "gdk_screen_set_default_colormap".}
proc get_system_colormap*(screen: PScreen): PColormap{.cdecl,
    dynlib: lib, importc: "gdk_screen_get_system_colormap".}
proc get_system_visual*(screen: PScreen): PVisual{.cdecl, dynlib: lib,
    importc: "gdk_screen_get_system_visual".}
proc get_rgb_colormap*(screen: PScreen): PColormap{.cdecl, dynlib: lib,
    importc: "gdk_screen_get_rgb_colormap".}
proc get_rgb_visual*(screen: PScreen): PVisual{.cdecl, dynlib: lib,
    importc: "gdk_screen_get_rgb_visual".}
proc get_root_window*(screen: PScreen): PWindow{.cdecl, dynlib: lib,
    importc: "gdk_screen_get_root_window".}
proc get_display*(screen: PScreen): PDisplay{.cdecl, dynlib: lib,
    importc: "gdk_screen_get_display".}
proc get_number*(screen: PScreen): gint{.cdecl, dynlib: lib,
    importc: "gdk_screen_get_number".}
proc get_window_at_pointer*(screen: PScreen, win_x: Pgint, win_y: Pgint): PWindow{.
    cdecl, dynlib: lib, importc: "gdk_screen_get_window_at_pointer".}
proc get_width*(screen: PScreen): gint{.cdecl, dynlib: lib,
    importc: "gdk_screen_get_width".}
proc get_height*(screen: PScreen): gint{.cdecl, dynlib: lib,
    importc: "gdk_screen_get_height".}
proc get_width_mm*(screen: PScreen): gint{.cdecl, dynlib: lib,
    importc: "gdk_screen_get_width_mm".}
proc get_height_mm*(screen: PScreen): gint{.cdecl, dynlib: lib,
    importc: "gdk_screen_get_height_mm".}
proc close*(screen: PScreen){.cdecl, dynlib: lib,
                                     importc: "gdk_screen_close".}
proc list_visuals*(screen: PScreen): PGList{.cdecl, dynlib: lib,
    importc: "gdk_screen_list_visuals".}
proc get_toplevel_windows*(screen: PScreen): PGList{.cdecl, dynlib: lib,
    importc: "gdk_screen_get_toplevel_windows".}
proc get_n_monitors*(screen: PScreen): gint{.cdecl, dynlib: lib,
    importc: "gdk_screen_get_n_monitors".}
proc get_monitor_geometry*(screen: PScreen, monitor_num: gint,
                                  dest: PRectangle){.cdecl, dynlib: lib,
    importc: "gdk_screen_get_monitor_geometry".}
proc get_monitor_at_point*(screen: PScreen, x: gint, y: gint): gint{.
    cdecl, dynlib: lib, importc: "gdk_screen_get_monitor_at_point".}
proc get_monitor_at_window*(screen: PScreen, window: PWindow): gint{.
    cdecl, dynlib: lib, importc: "gdk_screen_get_monitor_at_window".}
proc broadcast_client_message*(screen: PScreen, event: PEvent){.cdecl,
    dynlib: lib, importc: "gdk_screen_broadcast_client_message".}
proc get_default_screen*(): PScreen{.cdecl, dynlib: lib,
                                     importc: "gdk_get_default_screen".}
proc get_setting*(screen: PScreen, name: cstring, value: PGValue): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_screen_get_setting".}
proc SELECTION_PRIMARY*(): TAtom
proc SELECTION_SECONDARY*(): TAtom
proc SELECTION_CLIPBOARD*(): TAtom
proc TARGET_BITMAP*(): TAtom
proc TARGET_COLORMAP*(): TAtom
proc TARGET_DRAWABLE*(): TAtom
proc TARGET_PIXMAP*(): TAtom
proc TARGET_STRING*(): TAtom
proc SELECTION_TYPE_ATOM*(): TAtom
proc SELECTION_TYPE_BITMAP*(): TAtom
proc SELECTION_TYPE_COLORMAP*(): TAtom
proc SELECTION_TYPE_DRAWABLE*(): TAtom
proc SELECTION_TYPE_INTEGER*(): TAtom
proc SELECTION_TYPE_PIXMAP*(): TAtom
proc SELECTION_TYPE_WINDOW*(): TAtom
proc SELECTION_TYPE_STRING*(): TAtom
proc selection_owner_set_for_display*(display: PDisplay, owner: PWindow,
                                      selection: TAtom, time: guint32,
                                      send_event: gboolean): gboolean{.cdecl,
    dynlib: lib, importc: "gdk_selection_owner_set_for_display".}
proc selection_owner_get_for_display*(display: PDisplay, selection: TAtom): PWindow{.
    cdecl, dynlib: lib, importc: "gdk_selection_owner_get_for_display".}
proc selection_convert*(requestor: PWindow, selection: TAtom, target: TAtom,
                        time: guint32){.cdecl, dynlib: lib,
                                        importc: "gdk_selection_convert".}
proc selection_property_get*(requestor: PWindow, data: PPguchar,
                             prop_type: PAtom, prop_format: Pgint): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_selection_property_get".}
proc selection_send_notify_for_display*(display: PDisplay, requestor: guint32,
                                        selection: TAtom, target: TAtom,
                                        `property`: TAtom, time: guint32){.
    cdecl, dynlib: lib, importc: "gdk_selection_send_notify_for_display".}
const
  CURRENT_TIME* = 0
  PARENT_RELATIVE* = 1
  OK* = 0
  ERROR* = - (1)
  ERROR_PARAM* = - (2)
  ERROR_FILE* = - (3)
  ERROR_MEM* = - (4)
  SHIFT_MASK* = 1 shl 0
  LOCK_MASK* = 1 shl 1
  CONTROL_MASK* = 1 shl 2
  MOD1_MASK* = 1 shl 3
  MOD2_MASK* = 1 shl 4
  MOD3_MASK* = 1 shl 5
  MOD4_MASK* = 1 shl 6
  MOD5_MASK* = 1 shl 7
  BUTTON1_MASK* = 1 shl 8
  BUTTON2_MASK* = 1 shl 9
  BUTTON3_MASK* = 1 shl 10
  BUTTON4_MASK* = 1 shl 11
  BUTTON5_MASK* = 1 shl 12
  RELEASE_MASK* = 1 shl 30
  MODIFIER_MASK* = ord(RELEASE_MASK) or 0x00001FFF
  INPUT_READ* = 1 shl 0
  INPUT_WRITE* = 1 shl 1
  INPUT_EXCEPTION* = 1 shl 2
  GRAB_SUCCESS* = 0
  GRAB_ALREADY_GRABBED* = 1
  GRAB_INVALID_TIME* = 2
  GRAB_NOT_VIEWABLE* = 3
  GRAB_FROZEN* = 4

proc ATOM_TO_POINTER*(atom: TAtom): Pointer
proc POINTER_TO_ATOM*(p: Pointer): TAtom
proc `MAKE_ATOM`*(val: guint): TAtom
proc NONE*(): TAtom
proc TYPE_VISUAL*(): GType
proc VISUAL*(anObject: Pointer): PVisual
proc VISUAL_CLASS*(klass: Pointer): PVisualClass
proc IS_VISUAL*(anObject: Pointer): bool
proc IS_VISUAL_CLASS*(klass: Pointer): bool
proc VISUAL_GET_CLASS*(obj: Pointer): PVisualClass
proc visual_get_type*(): GType{.cdecl, dynlib: lib,
                                importc: "gdk_visual_get_type".}
const
  WA_TITLE* = 1 shl 1
  WA_X* = 1 shl 2
  WA_Y* = 1 shl 3
  WA_CURSOR* = 1 shl 4
  WA_COLORMAP* = 1 shl 5
  WA_VISUAL* = 1 shl 6
  WA_WMCLASS* = 1 shl 7
  WA_NOREDIR* = 1 shl 8
  HINT_POS* = 1 shl 0
  HINT_MIN_SIZE* = 1 shl 1
  HINT_MAX_SIZE* = 1 shl 2
  HINT_BASE_SIZE* = 1 shl 3
  HINT_ASPECT* = 1 shl 4
  HINT_RESIZE_INC* = 1 shl 5
  HINT_WIN_GRAVITY* = 1 shl 6
  HINT_USER_POS* = 1 shl 7
  HINT_USER_SIZE* = 1 shl 8
  DECOR_ALL* = 1 shl 0
  DECOR_BORDER* = 1 shl 1
  DECOR_RESIZEH* = 1 shl 2
  DECOR_TITLE* = 1 shl 3
  DECOR_MENU* = 1 shl 4
  DECOR_MINIMIZE* = 1 shl 5
  DECOR_MAXIMIZE* = 1 shl 6
  FUNC_ALL* = 1 shl 0
  FUNC_RESIZE* = 1 shl 1
  FUNC_MOVE* = 1 shl 2
  FUNC_MINIMIZE* = 1 shl 3
  FUNC_MAXIMIZE* = 1 shl 4
  FUNC_CLOSE* = 1 shl 5
  GRAVITY_NORTH_WEST* = 1
  GRAVITY_NORTH* = 2
  GRAVITY_NORTH_EAST* = 3
  GRAVITY_WEST* = 4
  GRAVITY_CENTER* = 5
  GRAVITY_EAST* = 6
  GRAVITY_SOUTH_WEST* = 7
  GRAVITY_SOUTH* = 8
  GRAVITY_SOUTH_EAST* = 9
  GRAVITY_STATIC* = 10

proc TYPE_WINDOW*(): GType
proc WINDOW*(anObject: Pointer): PWindow
proc WINDOW_CLASS*(klass: Pointer): PWindowObjectClass
proc IS_WINDOW*(anObject: Pointer): bool
proc IS_WINDOW_CLASS*(klass: Pointer): bool
proc WINDOW_GET_CLASS*(obj: Pointer): PWindowObjectClass
proc WINDOW_OBJECT*(anObject: Pointer): PWindowObject
const
  bm_TWindowObject_guffaw_gravity* = 0x0001'i16
  bp_TWindowObject_guffaw_gravity* = 0'i16
  bm_TWindowObject_input_only* = 0x0002'i16
  bp_TWindowObject_input_only* = 1'i16
  bm_TWindowObject_modal_hint* = 0x0004'i16
  bp_TWindowObject_modal_hint* = 2'i16
  bm_TWindowObject_destroyed* = 0x0018'i16
  bp_TWindowObject_destroyed* = 3'i16

proc WindowObject_guffaw_gravity*(a: PWindowObject): guint
proc WindowObject_set_guffaw_gravity*(a: PWindowObject,
                                      `guffaw_gravity`: guint)
proc WindowObject_input_only*(a: PWindowObject): guint
proc WindowObject_set_input_only*(a: PWindowObject, `input_only`: guint)
proc WindowObject_modal_hint*(a: PWindowObject): guint
proc WindowObject_set_modal_hint*(a: PWindowObject, `modal_hint`: guint)
proc WindowObject_destroyed*(a: PWindowObject): guint
proc WindowObject_set_destroyed*(a: PWindowObject, `destroyed`: guint)
proc window_object_get_type*(): GType{.cdecl, dynlib: lib,
                                       importc: "gdk_window_object_get_type".}
proc new*(parent: PWindow, attributes: PWindowAttr, attributes_mask: gint): PWindow{.
    cdecl, dynlib: lib, importc: "gdk_window_new".}
proc destroy*(window: PWindow){.cdecl, dynlib: lib,
                                       importc: "gdk_window_destroy".}
proc get_window_type*(window: PWindow): TWindowType{.cdecl, dynlib: lib,
    importc: "gdk_window_get_window_type".}
proc window_at_pointer*(win_x: Pgint, win_y: Pgint): PWindow{.cdecl,
    dynlib: lib, importc: "gdk_window_at_pointer".}
proc show*(window: PWindow){.cdecl, dynlib: lib,
                                    importc: "gdk_window_show".}
proc hide*(window: PWindow){.cdecl, dynlib: lib,
                                    importc: "gdk_window_hide".}
proc withdraw*(window: PWindow){.cdecl, dynlib: lib,
                                        importc: "gdk_window_withdraw".}
proc show_unraised*(window: PWindow){.cdecl, dynlib: lib,
    importc: "gdk_window_show_unraised".}
proc move*(window: PWindow, x: gint, y: gint){.cdecl, dynlib: lib,
    importc: "gdk_window_move".}
proc resize*(window: PWindow, width: gint, height: gint){.cdecl,
    dynlib: lib, importc: "gdk_window_resize".}
proc move_resize*(window: PWindow, x: gint, y: gint, width: gint,
                         height: gint){.cdecl, dynlib: lib,
                                        importc: "gdk_window_move_resize".}
proc reparent*(window: PWindow, new_parent: PWindow, x: gint, y: gint){.
    cdecl, dynlib: lib, importc: "gdk_window_reparent".}
proc clear*(window: PWindow){.cdecl, dynlib: lib,
                                     importc: "gdk_window_clear".}
proc clear_area*(window: PWindow, x: gint, y: gint, width: gint,
                        height: gint){.cdecl, dynlib: lib,
                                       importc: "gdk_window_clear_area".}
proc clear_area_e*(window: PWindow, x: gint, y: gint, width: gint,
                          height: gint){.cdecl, dynlib: lib,
    importc: "gdk_window_clear_area_e".}
proc `raise`*(window: PWindow){.cdecl, dynlib: lib,
                                importc: "gdk_window_raise".}
proc lower*(window: PWindow){.cdecl, dynlib: lib,
                                     importc: "gdk_window_lower".}
proc focus*(window: PWindow, timestamp: guint32){.cdecl, dynlib: lib,
    importc: "gdk_window_focus".}
proc set_user_data*(window: PWindow, user_data: gpointer){.cdecl,
    dynlib: lib, importc: "gdk_window_set_user_data".}
proc set_override_redirect*(window: PWindow, override_redirect: gboolean){.
    cdecl, dynlib: lib, importc: "gdk_window_set_override_redirect".}
proc add_filter*(window: PWindow, `function`: TFilterFunc, data: gpointer){.
    cdecl, dynlib: lib, importc: "gdk_window_add_filter".}
proc remove_filter*(window: PWindow, `function`: TFilterFunc,
                           data: gpointer){.cdecl, dynlib: lib,
    importc: "gdk_window_remove_filter".}
proc scroll*(window: PWindow, dx: gint, dy: gint){.cdecl, dynlib: lib,
    importc: "gdk_window_scroll".}
proc shape_combine_mask*(window: PWindow, mask: PBitmap, x: gint, y: gint){.
    cdecl, dynlib: lib, importc: "gdk_window_shape_combine_mask".}
proc shape_combine_region*(window: PWindow, shape_region: PRegion,
                                  offset_x: gint, offset_y: gint){.cdecl,
    dynlib: lib, importc: "gdk_window_shape_combine_region".}
proc set_child_shapes*(window: PWindow){.cdecl, dynlib: lib,
    importc: "gdk_window_set_child_shapes".}
proc merge_child_shapes*(window: PWindow){.cdecl, dynlib: lib,
    importc: "gdk_window_merge_child_shapes".}
proc is_visible*(window: PWindow): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_window_is_visible".}
proc is_viewable*(window: PWindow): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_window_is_viewable".}
proc get_state*(window: PWindow): TWindowState{.cdecl, dynlib: lib,
    importc: "gdk_window_get_state".}
proc set_static_gravities*(window: PWindow, use_static: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_window_set_static_gravities".}
proc window_foreign_new_for_display*(display: PDisplay, anid: TNativeWindow): PWindow{.
    cdecl, dynlib: lib, importc: "gdk_window_foreign_new_for_display".}
proc window_lookup_for_display*(display: PDisplay, anid: TNativeWindow): PWindow{.
    cdecl, dynlib: lib, importc: "gdk_window_lookup_for_display".}
proc set_type_hint*(window: PWindow, hint: TWindowTypeHint){.cdecl,
    dynlib: lib, importc: "gdk_window_set_type_hint".}
proc set_modal_hint*(window: PWindow, modal: gboolean){.cdecl,
    dynlib: lib, importc: "gdk_window_set_modal_hint".}
proc set_geometry_hints*(window: PWindow, geometry: PGeometry,
                                geom_mask: TWindowHints){.cdecl, dynlib: lib,
    importc: "gdk_window_set_geometry_hints".}
proc set_sm_client_id*(sm_client_id: cstring){.cdecl, dynlib: lib,
    importc: "gdk_set_sm_client_id".}
proc begin_paint_rect*(window: PWindow, rectangle: PRectangle){.cdecl,
    dynlib: lib, importc: "gdk_window_begin_paint_rect".}
proc begin_paint_region*(window: PWindow, region: PRegion){.cdecl,
    dynlib: lib, importc: "gdk_window_begin_paint_region".}
proc end_paint*(window: PWindow){.cdecl, dynlib: lib,
    importc: "gdk_window_end_paint".}
proc set_title*(window: PWindow, title: cstring){.cdecl, dynlib: lib,
    importc: "gdk_window_set_title".}
proc set_role*(window: PWindow, role: cstring){.cdecl, dynlib: lib,
    importc: "gdk_window_set_role".}
proc set_transient_for*(window: PWindow, parent: PWindow){.cdecl,
    dynlib: lib, importc: "gdk_window_set_transient_for".}
proc set_background*(window: PWindow, color: PColor){.cdecl, dynlib: lib,
    importc: "gdk_window_set_background".}
proc set_back_pixmap*(window: PWindow, pixmap: PPixmap,
                             parent_relative: gboolean){.cdecl, dynlib: lib,
    importc: "gdk_window_set_back_pixmap".}
proc set_cursor*(window: PWindow, cursor: PCursor){.cdecl, dynlib: lib,
    importc: "gdk_window_set_cursor".}
proc get_user_data*(window: PWindow, data: gpointer){.cdecl, dynlib: lib,
    importc: "gdk_window_get_user_data".}
proc get_geometry*(window: PWindow, x: Pgint, y: Pgint, width: Pgint,
                          height: Pgint, depth: Pgint){.cdecl, dynlib: lib,
    importc: "gdk_window_get_geometry".}
proc get_position*(window: PWindow, x: Pgint, y: Pgint){.cdecl,
    dynlib: lib, importc: "gdk_window_get_position".}
proc get_origin*(window: PWindow, x: Pgint, y: Pgint): gint{.cdecl,
    dynlib: lib, importc: "gdk_window_get_origin".}
proc get_root_origin*(window: PWindow, x: Pgint, y: Pgint){.cdecl,
    dynlib: lib, importc: "gdk_window_get_root_origin".}
proc get_frame_extents*(window: PWindow, rect: PRectangle){.cdecl,
    dynlib: lib, importc: "gdk_window_get_frame_extents".}
proc get_pointer*(window: PWindow, x: Pgint, y: Pgint,
                         mask: PModifierType): PWindow{.cdecl, dynlib: lib,
    importc: "gdk_window_get_pointer".}
proc get_parent*(window: PWindow): PWindow{.cdecl, dynlib: lib,
    importc: "gdk_window_get_parent".}
proc get_toplevel*(window: PWindow): PWindow{.cdecl, dynlib: lib,
    importc: "gdk_window_get_toplevel".}
proc get_children*(window: PWindow): PGList{.cdecl, dynlib: lib,
    importc: "gdk_window_get_children".}
proc peek_children*(window: PWindow): PGList{.cdecl, dynlib: lib,
    importc: "gdk_window_peek_children".}
proc get_events*(window: PWindow): TEventMask{.cdecl, dynlib: lib,
    importc: "gdk_window_get_events".}
proc set_events*(window: PWindow, event_mask: TEventMask){.cdecl,
    dynlib: lib, importc: "gdk_window_set_events".}
proc set_icon_list*(window: PWindow, pixbufs: PGList){.cdecl,
    dynlib: lib, importc: "gdk_window_set_icon_list".}
proc set_icon*(window: PWindow, icon_window: PWindow, pixmap: PPixmap,
                      mask: PBitmap){.cdecl, dynlib: lib,
                                      importc: "gdk_window_set_icon".}
proc set_icon_name*(window: PWindow, name: cstring){.cdecl, dynlib: lib,
    importc: "gdk_window_set_icon_name".}
proc set_group*(window: PWindow, leader: PWindow){.cdecl, dynlib: lib,
    importc: "gdk_window_set_group".}
proc set_decorations*(window: PWindow, decorations: TWMDecoration){.
    cdecl, dynlib: lib, importc: "gdk_window_set_decorations".}
proc get_decorations*(window: PWindow, decorations: PWMDecoration): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_window_get_decorations".}
proc set_functions*(window: PWindow, functions: TWMFunction){.cdecl,
    dynlib: lib, importc: "gdk_window_set_functions".}
proc iconify*(window: PWindow){.cdecl, dynlib: lib,
                                       importc: "gdk_window_iconify".}
proc deiconify*(window: PWindow){.cdecl, dynlib: lib,
    importc: "gdk_window_deiconify".}
proc stick*(window: PWindow){.cdecl, dynlib: lib,
                                     importc: "gdk_window_stick".}
proc unstick*(window: PWindow){.cdecl, dynlib: lib,
                                       importc: "gdk_window_unstick".}
proc maximize*(window: PWindow){.cdecl, dynlib: lib,
                                        importc: "gdk_window_maximize".}
proc unmaximize*(window: PWindow){.cdecl, dynlib: lib,
    importc: "gdk_window_unmaximize".}
proc register_dnd*(window: PWindow){.cdecl, dynlib: lib,
    importc: "gdk_window_register_dnd".}
proc begin_resize_drag*(window: PWindow, edge: TWindowEdge, button: gint,
                               root_x: gint, root_y: gint, timestamp: guint32){.
    cdecl, dynlib: lib, importc: "gdk_window_begin_resize_drag".}
proc begin_move_drag*(window: PWindow, button: gint, root_x: gint,
                             root_y: gint, timestamp: guint32){.cdecl,
    dynlib: lib, importc: "gdk_window_begin_move_drag".}
proc invalidate_rect*(window: PWindow, rect: PRectangle,
                             invalidate_children: gboolean){.cdecl, dynlib: lib,
    importc: "gdk_window_invalidate_rect".}
proc invalidate_region*(window: PWindow, region: PRegion,
                               invalidate_children: gboolean){.cdecl,
    dynlib: lib, importc: "gdk_window_invalidate_region".}
proc invalidate_maybe_recurse*(window: PWindow, region: PRegion,
    child_func: window_invalidate_maybe_recurse_child_func, user_data: gpointer){.
    cdecl, dynlib: lib, importc: "gdk_window_invalidate_maybe_recurse".}
proc get_update_area*(window: PWindow): PRegion{.cdecl, dynlib: lib,
    importc: "gdk_window_get_update_area".}
proc freeze_updates*(window: PWindow){.cdecl, dynlib: lib,
    importc: "gdk_window_freeze_updates".}
proc thaw_updates*(window: PWindow){.cdecl, dynlib: lib,
    importc: "gdk_window_thaw_updates".}
proc window_process_all_updates*(){.cdecl, dynlib: lib,
                                    importc: "gdk_window_process_all_updates".}
proc process_updates*(window: PWindow, update_children: gboolean){.cdecl,
    dynlib: lib, importc: "gdk_window_process_updates".}
proc window_set_debug_updates*(setting: gboolean){.cdecl, dynlib: lib,
    importc: "gdk_window_set_debug_updates".}
proc window_constrain_size*(geometry: PGeometry, flags: guint, width: gint,
                            height: gint, new_width: Pgint, new_height: Pgint){.
    cdecl, dynlib: lib, importc: "gdk_window_constrain_size".}
proc get_internal_paint_info*(window: PWindow, e: var PDrawable,
                                     x_offset: Pgint, y_offset: Pgint){.cdecl,
    dynlib: lib, importc: "gdk_window_get_internal_paint_info".}
proc set_pointer_hooks*(new_hooks: PPointerHooks): PPointerHooks{.cdecl,
    dynlib: lib, importc: "gdk_set_pointer_hooks".}
proc get_default_root_window*(): PWindow{.cdecl, dynlib: lib,
    importc: "gdk_get_default_root_window".}
proc parse_args*(argc: Pgint, v: var PPgchar){.cdecl, dynlib: lib,
    importc: "gdk_parse_args".}
proc init*(argc: Pgint, v: var PPgchar){.cdecl, dynlib: lib, importc: "gdk_init".}
proc init_check*(argc: Pgint, v: var PPgchar): gboolean{.cdecl, dynlib: lib,
    importc: "gdk_init_check".}
when not defined(DISABLE_DEPRECATED):
  proc exit*(error_code: gint){.cdecl, dynlib: lib, importc: "gdk_exit".}
proc set_locale*(): cstring{.cdecl, dynlib: lib, importc: "gdk_set_locale".}
proc get_program_class*(): cstring{.cdecl, dynlib: lib,
                                    importc: "gdk_get_program_class".}
proc set_program_class*(program_class: cstring){.cdecl, dynlib: lib,
    importc: "gdk_set_program_class".}
proc error_trap_push*(){.cdecl, dynlib: lib, importc: "gdk_error_trap_push".}
proc error_trap_pop*(): gint{.cdecl, dynlib: lib, importc: "gdk_error_trap_pop".}
when not defined(DISABLE_DEPRECATED):
  proc set_use_xshm*(use_xshm: gboolean){.cdecl, dynlib: lib,
      importc: "gdk_set_use_xshm".}
  proc get_use_xshm*(): gboolean{.cdecl, dynlib: lib,
                                  importc: "gdk_get_use_xshm".}
proc get_display*(): cstring{.cdecl, dynlib: lib, importc: "gdk_get_display".}
proc get_display_arg_name*(): cstring{.cdecl, dynlib: lib,
                                       importc: "gdk_get_display_arg_name".}
when not defined(DISABLE_DEPRECATED):
  proc input_add_full*(source: gint, condition: TInputCondition,
                       `function`: TInputFunction, data: gpointer,
                       destroy: TDestroyNotify): gint{.cdecl, dynlib: lib,
      importc: "gdk_input_add_full".}
  proc input_add*(source: gint, condition: TInputCondition,
                  `function`: TInputFunction, data: gpointer): gint{.cdecl,
      dynlib: lib, importc: "gdk_input_add".}
  proc input_remove*(tag: gint){.cdecl, dynlib: lib, importc: "gdk_input_remove".}
proc pointer_grab*(window: PWindow, owner_events: gboolean,
                   event_mask: TEventMask, confine_to: PWindow, cursor: PCursor,
                   time: guint32): TGrabStatus{.cdecl, dynlib: lib,
    importc: "gdk_pointer_grab".}
proc keyboard_grab*(window: PWindow, owner_events: gboolean, time: guint32): TGrabStatus{.
    cdecl, dynlib: lib, importc: "gdk_keyboard_grab".}
when not defined(MULTIHEAD_SAFE):
  proc pointer_ungrab*(time: guint32){.cdecl, dynlib: lib,
                                       importc: "gdk_pointer_ungrab".}
  proc keyboard_ungrab*(time: guint32){.cdecl, dynlib: lib,
                                        importc: "gdk_keyboard_ungrab".}
  proc pointer_is_grabbed*(): gboolean{.cdecl, dynlib: lib,
                                        importc: "gdk_pointer_is_grabbed".}
  proc screen_width*(): gint{.cdecl, dynlib: lib, importc: "gdk_screen_width".}
  proc screen_height*(): gint{.cdecl, dynlib: lib, importc: "gdk_screen_height".}
  proc screen_width_mm*(): gint{.cdecl, dynlib: lib,
                                 importc: "gdk_screen_width_mm".}
  proc screen_height_mm*(): gint{.cdecl, dynlib: lib,
                                  importc: "gdk_screen_height_mm".}
  proc beep*(){.cdecl, dynlib: lib, importc: "gdk_beep".}
proc flush*(){.cdecl, dynlib: lib, importc: "gdk_flush".}
when not defined(MULTIHEAD_SAFE):
  proc set_double_click_time*(msec: guint){.cdecl, dynlib: lib,
      importc: "gdk_set_double_click_time".}
proc intersect*(src1: PRectangle, src2: PRectangle, dest: PRectangle): gboolean{.
    cdecl, dynlib: lib, importc: "gdk_rectangle_intersect".}
proc union*(src1: PRectangle, src2: PRectangle, dest: PRectangle){.
    cdecl, dynlib: lib, importc: "gdk_rectangle_union".}
proc rectangle_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "gdk_rectangle_get_type".}
proc TYPE_RECTANGLE*(): GType
proc wcstombs*(src: PWChar): cstring{.cdecl, dynlib: lib,
                                      importc: "gdk_wcstombs".}
proc mbstowcs*(dest: PWChar, src: cstring, dest_max: gint): gint{.cdecl,
    dynlib: lib, importc: "gdk_mbstowcs".}
when not defined(MULTIHEAD_SAFE):
  proc event_send_client_message*(event: PEvent, xid: guint32): gboolean{.cdecl,
      dynlib: lib, importc: "gdk_event_send_client_message".}
  proc event_send_clientmessage_toall*(event: PEvent){.cdecl, dynlib: lib,
      importc: "gdk_event_send_clientmessage_toall".}
proc event_send_client_message_for_display*(display: PDisplay, event: PEvent,
    xid: guint32): gboolean{.cdecl, dynlib: lib, importc: "gdk_event_send_client_message_for_display".}
proc threads_enter*(){.cdecl, dynlib: lib, importc: "gdk_threads_enter".}
proc threads_leave*(){.cdecl, dynlib: lib, importc: "gdk_threads_leave".}
proc threads_init*(){.cdecl, dynlib: lib, importc: "gdk_threads_init".}
proc TYPE_RECTANGLE*(): GType =
  result = rectangle_get_type()

proc TYPE_COLORMAP*(): GType =
  result = colormap_get_type()

proc COLORMAP*(anObject: pointer): PColormap =
  result = cast[PColormap](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_COLORMAP()))

proc COLORMAP_CLASS*(klass: pointer): PColormapClass =
  result = cast[PColormapClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_COLORMAP()))

proc IS_COLORMAP*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_COLORMAP())

proc IS_COLORMAP_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_COLORMAP())

proc COLORMAP_GET_CLASS*(obj: pointer): PColormapClass =
  result = cast[PColormapClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_COLORMAP()))

proc TYPE_COLOR*(): GType =
  result = gdk2.color_get_type()

proc destroy*(cursor: PCursor) =
  unref(cursor)

proc TYPE_CURSOR*(): GType =
  result = cursor_get_type()

proc TYPE_DRAG_CONTEXT*(): GType =
  result = drag_context_get_type()

proc DRAG_CONTEXT*(anObject: Pointer): PDragContext =
  result = cast[PDragContext](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      TYPE_DRAG_CONTEXT()))

proc DRAG_CONTEXT_CLASS*(klass: Pointer): PDragContextClass =
  result = cast[PDragContextClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_DRAG_CONTEXT()))

proc IS_DRAG_CONTEXT*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_DRAG_CONTEXT())

proc IS_DRAG_CONTEXT_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_DRAG_CONTEXT())

proc DRAG_CONTEXT_GET_CLASS*(obj: Pointer): PDragContextClass =
  result = cast[PDragContextClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_DRAG_CONTEXT()))

proc region_EXTENTCHECK*(r1, r2: PRegionBox): bool =
  result = ((r1.x2) > r2.x1) and ((r1.x1) < r2.x2) and ((r1.y2) > r2.y1) and
      ((r1.y1) < r2.y2)

proc EXTENTS*(r: PRegionBox, idRect: PRegion) =
  if ((r.x1) < idRect.extents.x1):
    idRect.extents.x1 = r.x1
  if (r.y1) < idRect.extents.y1:
    idRect.extents.y1 = r.y1
  if (r.x2) > idRect.extents.x2:
    idRect.extents.x2 = r.x2

proc MEMCHECK*(reg: PRegion, ARect, firstrect: var PRegionBox): bool =
  assert(false)               # to implement

proc CHECK_PREVIOUS*(Reg: PRegion, R: PRegionBox,
                            Rx1, Ry1, Rx2, Ry2: gint): bool =
  assert(false)               # to implement

proc ADDRECT*(reg: PRegion, r: PRegionBox, rx1, ry1, rx2, ry2: gint) =
  if (((rx1) < rx2) and ((ry1) < ry2) and
      CHECK_PREVIOUS(reg, r, rx1, ry1, rx2, ry2)):
    r.x1 = rx1
    r.y1 = ry1
    r.x2 = rx2
    r.y2 = ry2

proc ADDRECTNOX*(reg: PRegion, r: PRegionBox, rx1, ry1, rx2, ry2: gint) =
  if (((rx1) < rx2) and ((ry1) < ry2) and
      CHECK_PREVIOUS(reg, r, rx1, ry1, rx2, ry2)):
    r.x1 = rx1
    r.y1 = ry1
    r.x2 = rx2
    r.y2 = ry2
    inc(reg.numRects)

proc EMPTY_REGION*(pReg: PRegion): bool =
  result = pReg.numRects == 0'i32

proc REGION_NOT_EMPTY*(pReg: PRegion): bool =
  result = pReg.numRects != 0'i32

proc region_INBOX*(r: TRegionBox, x, y: gint): bool =
  result = ((((r.x2) > x) and ((r.x1) <= x)) and ((r.y2) > y)) and
      ((r.y1) <= y)

proc TYPE_DRAWABLE*(): GType =
  result = drawable_get_type()

proc DRAWABLE*(anObject: Pointer): PDrawable =
  result = cast[PDrawable](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_DRAWABLE()))

proc DRAWABLE_CLASS*(klass: Pointer): PDrawableClass =
  result = cast[PDrawableClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_DRAWABLE()))

proc IS_DRAWABLE*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_DRAWABLE())

proc IS_DRAWABLE_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_DRAWABLE())

proc DRAWABLE_GET_CLASS*(obj: Pointer): PDrawableClass =
  result = cast[PDrawableClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_DRAWABLE()))

proc pixmap*(drawable: PDrawable, gc: PGC, src: PDrawable, xsrc: gint,
                  ysrc: gint, xdest: gint, ydest: gint, width: gint,
                  height: gint) =
  drawable(drawable, gc, src, xsrc, ysrc, xdest, ydest, width, height)

proc bitmap*(drawable: PDrawable, gc: PGC, src: PDrawable, xsrc: gint,
                  ysrc: gint, xdest: gint, ydest: gint, width: gint,
                  height: gint) =
  drawable(drawable, gc, src, xsrc, ysrc, xdest, ydest, width, height)

proc TYPE_EVENT*(): GType =
  result = event_get_type()

proc TYPE_FONT*(): GType =
  result = gdk2.font_get_type()

proc TYPE_GC*(): GType =
  result = gc_get_type()

proc GC*(anObject: Pointer): PGC =
  result = cast[PGC](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_GC()))

proc GC_CLASS*(klass: Pointer): PGCClass =
  result = cast[PGCClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_GC()))

proc IS_GC*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_GC())

proc IS_GC_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_GC())

proc GC_GET_CLASS*(obj: Pointer): PGCClass =
  result = cast[PGCClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_GC()))

proc destroy*(gc: PGC) =
  g_object_unref(G_OBJECT(gc))

proc TYPE_IMAGE*(): GType =
  result = image_get_type()

proc IMAGE*(anObject: Pointer): PImage =
  result = cast[PImage](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_IMAGE()))

proc IMAGE_CLASS*(klass: Pointer): PImageClass =
  result = cast[PImageClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_IMAGE()))

proc IS_IMAGE*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_IMAGE())

proc IS_IMAGE_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_IMAGE())

proc IMAGE_GET_CLASS*(obj: Pointer): PImageClass =
  result = cast[PImageClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_IMAGE()))

proc destroy*(image: PImage) =
  g_object_unref(G_OBJECT(image))

proc TYPE_DEVICE*(): GType =
  result = device_get_type()

proc DEVICE*(anObject: Pointer): PDevice =
  result = cast[PDevice](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_DEVICE()))

proc DEVICE_CLASS*(klass: Pointer): PDeviceClass =
  result = cast[PDeviceClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_DEVICE()))

proc IS_DEVICE*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_DEVICE())

proc IS_DEVICE_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_DEVICE())

proc DEVICE_GET_CLASS*(obj: Pointer): PDeviceClass =
  result = cast[PDeviceClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_DEVICE()))

proc TYPE_KEYMAP*(): GType =
  result = keymap_get_type()

proc KEYMAP*(anObject: Pointer): PKeymap =
  result = cast[PKeymap](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_KEYMAP()))

proc KEYMAP_CLASS*(klass: Pointer): PKeymapClass =
  result = cast[PKeymapClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_KEYMAP()))

proc IS_KEYMAP*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_KEYMAP())

proc IS_KEYMAP_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_KEYMAP())

proc KEYMAP_GET_CLASS*(obj: Pointer): PKeymapClass =
  result = cast[PKeymapClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_KEYMAP()))

proc TYPE_PIXMAP*(): GType =
  result = pixmap_get_type()

proc PIXMAP*(anObject: Pointer): PPixmap =
  result = cast[PPixmap](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_PIXMAP()))

proc PIXMAP_CLASS*(klass: Pointer): PPixmapObjectClass =
  result = cast[PPixmapObjectClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_PIXMAP()))

proc IS_PIXMAP*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_PIXMAP())

proc IS_PIXMAP_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_PIXMAP())

proc PIXMAP_GET_CLASS*(obj: Pointer): PPixmapObjectClass =
  result = cast[PPixmapObjectClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_PIXMAP()))

proc PIXMAP_OBJECT*(anObject: Pointer): PPixmapObject =
  result = cast[PPixmapObject](PIXMAP(anObject))

proc bitmap_ref*(drawable: PDrawable): PDrawable =
  result = DRAWABLE(g_object_ref(G_OBJECT(drawable)))

proc bitmap_unref*(drawable: PDrawable) =
  g_object_unref(G_OBJECT(drawable))

proc pixmap_ref*(drawable: PDrawable): PDrawable =
  result = DRAWABLE(g_object_ref(G_OBJECT(drawable)))

proc pixmap_unref*(drawable: PDrawable) =
  g_object_unref(G_OBJECT(drawable))

proc rgb_get_cmap*(): PColormap =
  result = nil                #gdk_rgb_get_colormap()

proc TYPE_DISPLAY*(): GType =
  nil
  #result = nil

proc DISPLAY_OBJECT*(anObject: pointer): PDisplay =
  result = cast[PDisplay](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_DISPLAY()))

proc DISPLAY_CLASS*(klass: pointer): PDisplayClass =
  result = cast[PDisplayClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_DISPLAY()))

proc IS_DISPLAY*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_DISPLAY())

proc IS_DISPLAY_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_DISPLAY())

proc DISPLAY_GET_CLASS*(obj: pointer): PDisplayClass =
  result = cast[PDisplayClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_DISPLAY()))

proc TYPE_SCREEN*(): GType =
  nil

proc SCREEN*(anObject: Pointer): PScreen =
  result = cast[PScreen](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_SCREEN()))

proc SCREEN_CLASS*(klass: Pointer): PScreenClass =
  result = cast[PScreenClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_SCREEN()))

proc IS_SCREEN*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_SCREEN())

proc IS_SCREEN_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_SCREEN())

proc SCREEN_GET_CLASS*(obj: Pointer): PScreenClass =
  result = cast[PScreenClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_SCREEN()))

proc SELECTION_PRIMARY*(): TAtom =
  result = `MAKE_ATOM`(1)

proc SELECTION_SECONDARY*(): TAtom =
  result = `MAKE_ATOM`(2)

proc SELECTION_CLIPBOARD*(): TAtom =
  result = `MAKE_ATOM`(69)

proc TARGET_BITMAP*(): TAtom =
  result = `MAKE_ATOM`(5)

proc TARGET_COLORMAP*(): TAtom =
  result = `MAKE_ATOM`(7)

proc TARGET_DRAWABLE*(): TAtom =
  result = `MAKE_ATOM`(17)

proc TARGET_PIXMAP*(): TAtom =
  result = `MAKE_ATOM`(20)

proc TARGET_STRING*(): TAtom =
  result = `MAKE_ATOM`(31)

proc SELECTION_TYPE_ATOM*(): TAtom =
  result = `MAKE_ATOM`(4)

proc SELECTION_TYPE_BITMAP*(): TAtom =
  result = `MAKE_ATOM`(5)

proc SELECTION_TYPE_COLORMAP*(): TAtom =
  result = `MAKE_ATOM`(7)

proc SELECTION_TYPE_DRAWABLE*(): TAtom =
  result = `MAKE_ATOM`(17)

proc SELECTION_TYPE_INTEGER*(): TAtom =
  result = `MAKE_ATOM`(19)

proc SELECTION_TYPE_PIXMAP*(): TAtom =
  result = `MAKE_ATOM`(20)

proc SELECTION_TYPE_WINDOW*(): TAtom =
  result = `MAKE_ATOM`(33)

proc SELECTION_TYPE_STRING*(): TAtom =
  result = `MAKE_ATOM`(31)

proc ATOM_TO_POINTER*(atom: TAtom): pointer =
  result = cast[Pointer](atom)

proc POINTER_TO_ATOM*(p: Pointer): TAtom =
  result = cast[TAtom](p)

proc `MAKE_ATOM`*(val: guint): TAtom =
  result = cast[TAtom](val)

proc NONE*(): TAtom =
  result = `MAKE_ATOM`(0)

proc TYPE_VISUAL*(): GType =
  result = visual_get_type()

proc VISUAL*(anObject: Pointer): PVisual =
  result = cast[PVisual](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_VISUAL()))

proc VISUAL_CLASS*(klass: Pointer): PVisualClass =
  result = cast[PVisualClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_VISUAL()))

proc IS_VISUAL*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_VISUAL())

proc IS_VISUAL_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_VISUAL())

proc VISUAL_GET_CLASS*(obj: Pointer): PVisualClass =
  result = cast[PVisualClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_VISUAL()))

proc reference*(v: PVisual) =
  discard g_object_ref(v)

proc unref*(v: PVisual) =
  g_object_unref(v)

proc TYPE_WINDOW*(): GType =
  result = window_object_get_type()

proc WINDOW*(anObject: Pointer): PWindow =
  result = cast[PWindow](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_WINDOW()))

proc WINDOW_CLASS*(klass: Pointer): PWindowObjectClass =
  result = cast[PWindowObjectClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_WINDOW()))

proc IS_WINDOW*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_WINDOW())

proc IS_WINDOW_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_WINDOW())

proc WINDOW_GET_CLASS*(obj: Pointer): PWindowObjectClass =
  result = cast[PWindowObjectClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_WINDOW()))

proc WINDOW_OBJECT*(anObject: Pointer): PWindowObject =
  result = cast[PWindowObject](WINDOW(anObject))

proc WindowObject_guffaw_gravity*(a: PWindowObject): guint =
  result = (a.flag0 and bm_TWindowObject_guffaw_gravity) shr
      bp_TWindowObject_guffaw_gravity

proc WindowObject_set_guffaw_gravity*(a: PWindowObject,
                                      `guffaw_gravity`: guint) =
  a.flag0 = a.flag0 or
      (int16(`guffaw_gravity` shl bp_TWindowObject_guffaw_gravity) and
      bm_TWindowObject_guffaw_gravity)

proc WindowObject_input_only*(a: PWindowObject): guint =
  result = (a.flag0 and bm_TWindowObject_input_only) shr
      bp_TWindowObject_input_only

proc WindowObject_set_input_only*(a: PWindowObject, `input_only`: guint) =
  a.flag0 = a.flag0 or
      (int16(`input_only` shl bp_TWindowObject_input_only) and
      bm_TWindowObject_input_only)

proc WindowObject_modal_hint*(a: PWindowObject): guint =
  result = (a.flag0 and bm_TWindowObject_modal_hint) shr
      bp_TWindowObject_modal_hint

proc WindowObject_set_modal_hint*(a: PWindowObject, `modal_hint`: guint) =
  a.flag0 = a.flag0 or
      (int16(`modal_hint` shl bp_TWindowObject_modal_hint) and
      bm_TWindowObject_modal_hint)

proc WindowObject_destroyed*(a: PWindowObject): guint =
  result = (a.flag0 and bm_TWindowObject_destroyed) shr
      bp_TWindowObject_destroyed

proc WindowObject_set_destroyed*(a: PWindowObject, `destroyed`: guint) =
  a.flag0 = a.flag0 or
      (int16(`destroyed` shl bp_TWindowObject_destroyed) and
      bm_TWindowObject_destroyed)

proc ROOT_PARENT*(): PWindow =
  result = get_default_root_window()

proc window_get_size*(drawable: PDrawable, width: Pgint, height: Pgint) =
  get_size(drawable, width, height)

proc get_type*(window: PWindow): TWindowType =
  result = get_window_type(window)

proc window_get_colormap*(drawable: PDrawable): PColormap =
  result = get_colormap(drawable)

proc window_set_colormap*(drawable: PDrawable, colormap: PColormap) =
  set_colormap(drawable, colormap)

proc window_get_visual*(drawable: PDrawable): PVisual =
  result = get_visual(drawable)

proc window_ref*(drawable: PDrawable): PDrawable =
  result = DRAWABLE(g_object_ref(G_OBJECT(drawable)))

proc window_unref*(drawable: PDrawable) =
  g_object_unref(G_OBJECT(drawable))

proc window_copy_area*(drawable: PDrawable, gc: PGC, x, y: gint,
                       source_drawable: PDrawable, source_x, source_y: gint,
                       width, height: gint) =
  pixmap(drawable, gc, source_drawable, source_x, source_y, x, y, width,
         height)
