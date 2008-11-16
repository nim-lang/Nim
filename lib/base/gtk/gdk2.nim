import
  glib2, gdk2pixbuf, pango

when defined(win32):
  const
    gdklib = "libgdk-win32-2.0-0.dll"
    GDK_HAVE_WCHAR_H = 1
    GDK_HAVE_WCTYPE_H = 1
elif defined(darwin):
  #    linklib gtk-x11-2.0
  #    linklib gdk-x11-2.0
  #    linklib pango-1.0.0
  #    linklib glib-2.0.0
  #    linklib gobject-2.0.0
  #    linklib gdk_pixbuf-2.0.0
  #    linklib atk-1.0.0
  const
    gdklib = "gdk-x11-2.0"
else:
  const
    gdklib = "libgdk-x11-2.0.so"
const
  NUMPTSTOBUFFER* = 200
  GDK_MAX_TIMECOORD_AXES* = 128

type
  PGdkDeviceClass* = ptr TGdkDeviceClass
  TGdkDeviceClass* = object of TGObjectClass

  PGdkVisualClass* = ptr TGdkVisualClass
  TGdkVisualClass* = object of TGObjectClass

  PGdkColor* = ptr TGdkColor
  TGdkColor* {.final.} = object
    pixel*: guint32
    red*: guint16
    green*: guint16
    blue*: guint16

  PGdkColormap* = ptr TGdkColormap
  PGdkDrawable* = ptr TGdkDrawable
  TGdkDrawable* = object of TGObject

  PGdkWindow* = ptr TGdkWindow
  TGdkWindow* = TGdkDrawable
  PGdkPixmap* = ptr TGdkPixmap
  TGdkPixmap* = TGdkDrawable
  PGdkBitmap* = ptr TGdkBitmap
  TGdkBitmap* = TGdkDrawable
  PGdkFontType* = ptr TGdkFontType
  TGdkFontType* = enum
    GDK_FONT_FONT, GDK_FONT_FONTSET
  PGdkFont* = ptr TGdkFont
  TGdkFont* {.final.} = object
    `type`*: TGdkFontType
    ascent*: gint
    descent*: gint

  PGdkFunction* = ptr TGdkFunction
  TGdkFunction* = enum
    GDK_COPY, GDK_INVERT, GDK_XOR, GDK_CLEAR, GDK_AND, GDK_AND_REVERSE,
    GDK_AND_INVERT, GDK_NOOP, GDK_OR, GDK_EQUIV, GDK_OR_REVERSE,
    GDK_COPY_INVERT, GDK_OR_INVERT, GDK_NAND, GDK_NOR, GDK_SET
  PGdkCapStyle* = ptr TGdkCapStyle
  TGdkCapStyle* = enum
    GDK_CAP_NOT_LAST, GDK_CAP_BUTT, GDK_CAP_ROUND, GDK_CAP_PROJECTING
  PGdkFill* = ptr TGdkFill
  TGdkFill* = enum
    GDK_SOLID, GDK_TILED, GDK_STIPPLED, GDK_OPAQUE_STIPPLED
  PGdkJoinStyle* = ptr TGdkJoinStyle
  TGdkJoinStyle* = enum
    GDK_JOIN_MITER, GDK_JOIN_ROUND, GDK_JOIN_BEVEL
  PGdkLineStyle* = ptr TGdkLineStyle
  TGdkLineStyle* = enum
    GDK_LINE_SOLID, GDK_LINE_ON_OFF_DASH, GDK_LINE_DOUBLE_DASH
  PGdkSubwindowMode* = ptr TGdkSubwindowMode
  TGdkSubwindowMode* = int
  PGdkGCValuesMask* = ptr TGdkGCValuesMask
  TGdkGCValuesMask* = int32
  PGdkGCValues* = ptr TGdkGCValues
  TGdkGCValues* {.final.} = object
    foreground*: TGdkColor
    background*: TGdkColor
    font*: PGdkFont
    `function`*: TGdkFunction
    fill*: TGdkFill
    tile*: PGdkPixmap
    stipple*: PGdkPixmap
    clip_mask*: PGdkPixmap
    subwindow_mode*: TGdkSubwindowMode
    ts_x_origin*: gint
    ts_y_origin*: gint
    clip_x_origin*: gint
    clip_y_origin*: gint
    graphics_exposures*: gint
    line_width*: gint
    line_style*: TGdkLineStyle
    cap_style*: TGdkCapStyle
    join_style*: TGdkJoinStyle

  PGdkGC* = ptr TGdkGC
  TGdkGC* = object of TGObject
    clip_x_origin*: gint
    clip_y_origin*: gint
    ts_x_origin*: gint
    ts_y_origin*: gint
    colormap*: PGdkColormap

  PGdkImageType* = ptr TGdkImageType
  TGdkImageType* = enum
    GDK_IMAGE_NORMAL, GDK_IMAGE_SHARED, GDK_IMAGE_FASTEST
  PGdkImage* = ptr TGdkImage
  PGdkDevice* = ptr TGdkDevice
  PGdkTimeCoord* = ptr TGdkTimeCoord
  PPGdkTimeCoord* = ptr PGdkTimeCoord
  PGdkRgbDither* = ptr TGdkRgbDither
  TGdkRgbDither* = enum
    GDK_RGB_DITHER_NONE, GDK_RGB_DITHER_NORMAL, GDK_RGB_DITHER_MAX
  PGdkDisplay* = ptr TGdkDisplay
  PGdkScreen* = ptr TGdkScreen
  TGdkScreen* = object of TGObject

  PGdkInputCondition* = ptr TGdkInputCondition
  TGdkInputCondition* = int32
  PGdkStatus* = ptr TGdkStatus
  TGdkStatus* = int32
  TGdkPoint* {.final.} = object
    x*: gint
    y*: gint

  PGdkPoint* = ptr TGdkPoint
  PPGdkPoint* = ptr PGdkPoint
  PGdkSpan* = ptr TGdkSpan
  PGdkWChar* = ptr TGdkWChar
  TGdkWChar* = guint32
  PGdkSegment* = ptr TGdkSegment
  TGdkSegment* {.final.} = object
    x1*: gint
    y1*: gint
    x2*: gint
    y2*: gint

  PGdkRectangle* = ptr TGdkRectangle
  TGdkRectangle* {.final.} = object
    x*: gint
    y*: gint
    width*: gint
    height*: gint

  PGdkAtom* = ptr TGdkAtom
  TGdkAtom* = gulong
  PGdkByteOrder* = ptr TGdkByteOrder
  TGdkByteOrder* = enum
    GDK_LSB_FIRST, GDK_MSB_FIRST
  PGdkModifierType* = ptr TGdkModifierType
  TGdkModifierType* = gint
  PGdkVisualType* = ptr TGdkVisualType
  TGdkVisualType* = enum
    GDK_VISUAL_STATIC_GRAY, GDK_VISUAL_GRAYSCALE, GDK_VISUAL_STATIC_COLOR,
    GDK_VISUAL_PSEUDO_COLOR, GDK_VISUAL_TRUE_COLOR, GDK_VISUAL_DIRECT_COLOR
  PGdkVisual* = ptr TGdkVisual
  TGdkVisual* = object of TGObject
    TheType*: TGdkVisualType
    depth*: gint
    byte_order*: TGdkByteOrder
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
    screen*: PGdkScreen

  PGdkColormapClass* = ptr TGdkColormapClass
  TGdkColormapClass* = object of TGObjectClass

  TGdkColormap* = object of TGObject
    size*: gint
    colors*: PGdkColor
    visual*: PGdkVisual
    windowing_data*: gpointer
    screen*: PGdkScreen

  PGdkCursorType* = ptr TGdkCursorType
  TGdkCursorType* = gint
  PGdkCursor* = ptr TGdkCursor
  TGdkCursor* {.final.} = object
    `type`*: TGdkCursorType
    ref_count*: guint

  PGdkDragAction* = ptr TGdkDragAction
  TGdkDragAction* = int32
  PGdkDragProtocol* = ptr TGdkDragProtocol
  TGdkDragProtocol* = enum
    GDK_DRAG_PROTO_MOTIF, GDK_DRAG_PROTO_XDND, GDK_DRAG_PROTO_ROOTWIN,
    GDK_DRAG_PROTO_NONE, GDK_DRAG_PROTO_WIN32_DROPFILES, GDK_DRAG_PROTO_OLE2,
    GDK_DRAG_PROTO_LOCAL
  PGdkDragContext* = ptr TGdkDragContext
  TGdkDragContext* = object of TGObject
    protocol*: TGdkDragProtocol
    is_source*: gboolean
    source_window*: PGdkWindow
    dest_window*: PGdkWindow
    targets*: PGList
    actions*: TGdkDragAction
    suggested_action*: TGdkDragAction
    action*: TGdkDragAction
    start_time*: guint32
    windowing_data*: gpointer

  PGdkDragContextClass* = ptr TGdkDragContextClass
  TGdkDragContextClass* = object of TGObjectClass

  PGdkRegionBox* = ptr TGdkRegionBox
  TGdkRegionBox* = TGdkSegment
  PGdkRegion* = ptr TGdkRegion
  TGdkRegion* {.final.} = object
    size*: int32
    numRects*: int32
    rects*: PGdkRegionBox
    extents*: TGdkRegionBox

  PPOINTBLOCK* = ptr TPOINTBLOCK
  TPOINTBLOCK* {.final.} = object
    pts*: array[0..(NUMPTSTOBUFFER) - 1, TGdkPoint]
    next*: PPOINTBLOCK

  PGdkDrawableClass* = ptr TGdkDrawableClass
  TGdkDrawableClass* = object of TGObjectClass
    create_gc*: proc (drawable: PGdkDrawable, values: PGdkGCValues,
                      mask: TGdkGCValuesMask): PGdkGC{.cdecl.}
    draw_rectangle*: proc (drawable: PGdkDrawable, gc: PGdkGC, filled: gint,
                           x: gint, y: gint, width: gint, height: gint){.cdecl.}
    draw_arc*: proc (drawable: PGdkDrawable, gc: PGdkGC, filled: gint, x: gint,
                     y: gint, width: gint, height: gint, angle1: gint,
                     angle2: gint){.cdecl.}
    draw_polygon*: proc (drawable: PGdkDrawable, gc: PGdkGC, filled: gint,
                         points: PGdkPoint, npoints: gint){.cdecl.}
    draw_text*: proc (drawable: PGdkDrawable, font: PGdkFont, gc: PGdkGC,
                      x: gint, y: gint, text: cstring, text_length: gint){.cdecl.}
    draw_text_wc*: proc (drawable: PGdkDrawable, font: PGdkFont, gc: PGdkGC,
                         x: gint, y: gint, text: PGdkWChar, text_length: gint){.
        cdecl.}
    draw_drawable*: proc (drawable: PGdkDrawable, gc: PGdkGC, src: PGdkDrawable,
                          xsrc: gint, ysrc: gint, xdest: gint, ydest: gint,
                          width: gint, height: gint){.cdecl.}
    draw_points*: proc (drawable: PGdkDrawable, gc: PGdkGC, points: PGdkPoint,
                        npoints: gint){.cdecl.}
    draw_segments*: proc (drawable: PGdkDrawable, gc: PGdkGC, segs: PGdkSegment,
                          nsegs: gint){.cdecl.}
    draw_lines*: proc (drawable: PGdkDrawable, gc: PGdkGC, points: PGdkPoint,
                       npoints: gint){.cdecl.}
    draw_glyphs*: proc (drawable: PGdkDrawable, gc: PGdkGC, font: PPangoFont,
                        x: gint, y: gint, glyphs: PPangoGlyphString){.cdecl.}
    draw_image*: proc (drawable: PGdkDrawable, gc: PGdkGC, image: PGdkImage,
                       xsrc: gint, ysrc: gint, xdest: gint, ydest: gint,
                       width: gint, height: gint){.cdecl.}
    get_depth*: proc (drawable: PGdkDrawable): gint{.cdecl.}
    get_size*: proc (drawable: PGdkDrawable, width: Pgint, height: Pgint){.cdecl.}
    set_colormap*: proc (drawable: PGdkDrawable, cmap: PGdkColormap){.cdecl.}
    get_colormap*: proc (drawable: PGdkDrawable): PGdkColormap{.cdecl.}
    get_visual*: proc (drawable: PGdkDrawable): PGdkVisual{.cdecl.}
    get_screen*: proc (drawable: PGdkDrawable): PGdkScreen{.cdecl.}
    get_image*: proc (drawable: PGdkDrawable, x: gint, y: gint, width: gint,
                      height: gint): PGdkImage{.cdecl.}
    get_clip_region*: proc (drawable: PGdkDrawable): PGdkRegion{.cdecl.}
    get_visible_region*: proc (drawable: PGdkDrawable): PGdkRegion{.cdecl.}
    get_composite_drawable*: proc (drawable: PGdkDrawable, x: gint, y: gint,
                                   width: gint, height: gint,
                                   composite_x_offset: Pgint,
                                   composite_y_offset: Pgint): PGdkDrawable{.
        cdecl.}
    `draw_pixbuf`*: proc (drawable: PGdkDrawable, gc: PGdkGC,
                          pixbuf: PGdkPixbuf, src_x: gint, src_y: gint,
                          dest_x: gint, dest_y: gint, width: gint, height: gint,
                          dither: TGdkRgbDither, x_dither: gint, y_dither: gint){.
        cdecl.}
    `copy_to_image`*: proc (drawable: PGdkDrawable, image: PGdkImage,
                            src_x: gint, src_y: gint, dest_x: gint,
                            dest_y: gint, width: gint, height: gint): PGdkImage{.
        cdecl.}
    `gdk_reserved1`: proc (){.cdecl.}
    `gdk_reserved2`: proc (){.cdecl.}
    `gdk_reserved3`: proc (){.cdecl.}
    `gdk_reserved4`: proc (){.cdecl.}
    `gdk_reserved5`: proc (){.cdecl.}
    `gdk_reserved6`: proc (){.cdecl.}
    `gdk_reserved7`: proc (){.cdecl.}
    `gdk_reserved9`: proc (){.cdecl.}
    `gdk_reserved10`: proc (){.cdecl.}
    `gdk_reserved11`: proc (){.cdecl.}
    `gdk_reserved12`: proc (){.cdecl.}
    `gdk_reserved13`: proc (){.cdecl.}
    `gdk_reserved14`: proc (){.cdecl.}
    `gdk_reserved15`: proc (){.cdecl.}
    `gdk_reserved16`: proc (){.cdecl.}

  PGdkEvent* = ptr TGdkEvent
  TGdkEventFunc* = proc (event: PGdkEvent, data: gpointer){.cdecl.}
  PGdkXEvent* = ptr TGdkXEvent
  TGdkXEvent* = proc ()
  PGdkFilterReturn* = ptr TGdkFilterReturn
  TGdkFilterReturn* = enum
    GDK_FILTER_CONTINUE, GDK_FILTER_TRANSLATE, GDK_FILTER_REMOVE
  TGdkFilterFunc* = proc (xevent: PGdkXEvent, event: PGdkEvent, data: gpointer): TGdkFilterReturn{.
      cdecl.}
  PGdkEventType* = ptr TGdkEventType
  TGdkEventType* = gint
  PGdkEventMask* = ptr TGdkEventMask
  TGdkEventMask* = gint32
  PGdkVisibilityState* = ptr TGdkVisibilityState
  TGdkVisibilityState* = enum
    GDK_VISIBILITY_UNOBSCURED, GDK_VISIBILITY_PARTIAL,
    GDK_VISIBILITY_FULLY_OBSCURED
  PGdkScrollDirection* = ptr TGdkScrollDirection
  TGdkScrollDirection* = enum
    GDK_SCROLL_UP, GDK_SCROLL_DOWN, GDK_SCROLL_LEFT, GDK_SCROLL_RIGHT
  PGdkNotifyType* = ptr TGdkNotifyType
  TGdkNotifyType* = int
  PGdkCrossingMode* = ptr TGdkCrossingMode
  TGdkCrossingMode* = enum
    GDK_CROSSING_NORMAL, GDK_CROSSING_GRAB, GDK_CROSSING_UNGRAB
  PGdkPropertyState* = ptr TGdkPropertyState
  TGdkPropertyState* = enum
    GDK_PROPERTY_NEW_VALUE, GDK_PROPERTY_STATE_DELETE
  PGdkWindowState* = ptr TGdkWindowState
  TGdkWindowState* = gint
  PGdkSettingAction* = ptr TGdkSettingAction
  TGdkSettingAction* = enum
    GDK_SETTING_ACTION_NEW, GDK_SETTING_ACTION_CHANGED,
    GDK_SETTING_ACTION_DELETED
  PGdkEventAny* = ptr TGdkEventAny
  TGdkEventAny* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8

  PGdkEventExpose* = ptr TGdkEventExpose
  TGdkEventExpose* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    area*: TGdkRectangle
    region*: PGdkRegion
    count*: gint

  PGdkEventNoExpose* = ptr TGdkEventNoExpose
  TGdkEventNoExpose* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8

  PGdkEventVisibility* = ptr TGdkEventVisibility
  TGdkEventVisibility* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    state*: TGdkVisibilityState

  PGdkEventMotion* = ptr TGdkEventMotion
  TGdkEventMotion* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    time*: guint32
    x*: gdouble
    y*: gdouble
    axes*: Pgdouble
    state*: guint
    is_hint*: gint16
    device*: PGdkDevice
    x_root*: gdouble
    y_root*: gdouble

  PGdkEventButton* = ptr TGdkEventButton
  TGdkEventButton* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    time*: guint32
    x*: gdouble
    y*: gdouble
    axes*: Pgdouble
    state*: guint
    button*: guint
    device*: PGdkDevice
    x_root*: gdouble
    y_root*: gdouble

  PGdkEventScroll* = ptr TGdkEventScroll
  TGdkEventScroll* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    time*: guint32
    x*: gdouble
    y*: gdouble
    state*: guint
    direction*: TGdkScrollDirection
    device*: PGdkDevice
    x_root*: gdouble
    y_root*: gdouble

  PGdkEventKey* = ptr TGdkEventKey
  TGdkEventKey* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    time*: guint32
    state*: guint
    keyval*: guint
    length*: gint
    `string`*: cstring
    hardware_keycode*: guint16
    group*: guint8

  PGdkEventCrossing* = ptr TGdkEventCrossing
  TGdkEventCrossing* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    subwindow*: PGdkWindow
    time*: guint32
    x*: gdouble
    y*: gdouble
    x_root*: gdouble
    y_root*: gdouble
    mode*: TGdkCrossingMode
    detail*: TGdkNotifyType
    focus*: gboolean
    state*: guint

  PGdkEventFocus* = ptr TGdkEventFocus
  TGdkEventFocus* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    `in`*: gint16

  PGdkEventConfigure* = ptr TGdkEventConfigure
  TGdkEventConfigure* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    x*: gint
    y*: gint
    width*: gint
    height*: gint

  PGdkEventProperty* = ptr TGdkEventProperty
  TGdkEventProperty* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    atom*: TGdkAtom
    time*: guint32
    state*: guint

  TGdkNativeWindow* = pointer
  PGdkEventSelection* = ptr TGdkEventSelection
  TGdkEventSelection* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    selection*: TGdkAtom
    target*: TGdkAtom
    `property`*: TGdkAtom
    time*: guint32
    requestor*: TGdkNativeWindow

  PGdkEventProximity* = ptr TGdkEventProximity
  TGdkEventProximity* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    time*: guint32
    device*: PGdkDevice

  PmatDUMMY* = ptr TmatDUMMY
  TmatDUMMY* {.final.} = object
    b*: array[0..19, char]

  PGdkEventClient* = ptr TGdkEventClient
  TGdkEventClient* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    message_type*: TGdkAtom
    data_format*: gushort
    b*: array[0..19, char]

  PGdkEventSetting* = ptr TGdkEventSetting
  TGdkEventSetting* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    action*: TGdkSettingAction
    name*: cstring

  PGdkEventWindowState* = ptr TGdkEventWindowState
  TGdkEventWindowState* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    changed_mask*: TGdkWindowState
    new_window_state*: TGdkWindowState

  PGdkEventDND* = ptr TGdkEventDND
  TGdkEventDND* {.final.} = object
    `type`*: TGdkEventType
    window*: PGdkWindow
    send_event*: gint8
    context*: PGdkDragContext
    time*: guint32
    x_root*: gshort
    y_root*: gshort

  TGdkEvent* {.final.} = object
    data*: array[0..255, char] # union of
                               # `type`: TGdkEventType
                               #  any: TGdkEventAny
                               #  expose: TGdkEventExpose
                               #  no_expose: TGdkEventNoExpose
                               #  visibility: TGdkEventVisibility
                               #  motion: TGdkEventMotion
                               #  button: TGdkEventButton
                               #  scroll: TGdkEventScroll
                               #  key: TGdkEventKey
                               #  crossing: TGdkEventCrossing
                               #  focus_change: TGdkEventFocus
                               #  configure: TGdkEventConfigure
                               #  `property`: TGdkEventProperty
                               #  selection: TGdkEventSelection
                               #  proximity: TGdkEventProximity
                               #  client: TGdkEventClient
                               #  dnd: TGdkEventDND
                               #  window_state: TGdkEventWindowState
                               #  setting: TGdkEventSetting

  PGdkGCClass* = ptr TGdkGCClass
  TGdkGCClass* = object of TGObjectClass
    get_values*: proc (gc: PGdkGC, values: PGdkGCValues){.cdecl.}
    set_values*: proc (gc: PGdkGC, values: PGdkGCValues, mask: TGdkGCValuesMask){.
        cdecl.}
    set_dashes*: proc (gc: PGdkGC, dash_offset: gint,
                       dash_list: openarray[gint8]){.cdecl.}
    `gdk_reserved1`*: proc (){.cdecl.}
    `gdk_reserved2`*: proc (){.cdecl.}
    `gdk_reserved3`*: proc (){.cdecl.}
    `gdk_reserved4`*: proc (){.cdecl.}

  PGdkImageClass* = ptr TGdkImageClass
  TGdkImageClass* = object of TGObjectClass

  TGdkImage* = object of TGObject
    `type`*: TGdkImageType
    visual*: PGdkVisual
    byte_order*: TGdkByteOrder
    width*: gint
    height*: gint
    depth*: guint16
    bpp*: guint16
    bpl*: guint16
    bits_per_pixel*: guint16
    mem*: gpointer
    colormap*: PGdkColormap
    windowing_data*: gpointer

  PGdkExtensionMode* = ptr TGdkExtensionMode
  TGdkExtensionMode* = enum
    GDK_EXTENSION_EVENTS_NONE, GDK_EXTENSION_EVENTS_ALL,
    GDK_EXTENSION_EVENTS_CURSOR
  PGdkInputSource* = ptr TGdkInputSource
  TGdkInputSource* = enum
    GDK_SOURCE_MOUSE, GDK_SOURCE_PEN, GDK_SOURCE_ERASER, GDK_SOURCE_CURSOR
  PGdkInputMode* = ptr TGdkInputMode
  TGdkInputMode* = enum
    GDK_MODE_DISABLED, GDK_MODE_SCREEN, GDK_MODE_WINDOW
  PGdkAxisUse* = ptr TGdkAxisUse
  TGdkAxisUse* = int32
  PGdkDeviceKey* = ptr TGdkDeviceKey
  TGdkDeviceKey* {.final.} = object
    keyval*: guint
    modifiers*: TGdkModifierType

  PGdkDeviceAxis* = ptr TGdkDeviceAxis
  TGdkDeviceAxis* {.final.} = object
    use*: TGdkAxisUse
    min*: gdouble
    max*: gdouble

  TGdkDevice* = object of TGObject
    name*: cstring
    source*: TGdkInputSource
    mode*: TGdkInputMode
    has_cursor*: gboolean
    num_axes*: gint
    axes*: PGdkDeviceAxis
    num_keys*: gint
    keys*: PGdkDeviceKey

  TGdkTimeCoord* {.final.} = object
    time*: guint32
    axes*: array[0..(GDK_MAX_TIMECOORD_AXES) - 1, gdouble]

  PGdkKeymapKey* = ptr TGdkKeymapKey
  TGdkKeymapKey* {.final.} = object
    keycode*: guint
    group*: gint
    level*: gint

  PGdkKeymap* = ptr TGdkKeymap
  TGdkKeymap* = object of TGObject
    display*: PGdkDisplay

  PGdkKeymapClass* = ptr TGdkKeymapClass
  TGdkKeymapClass* = object of TGObjectClass
    direction_changed*: proc (keymap: PGdkKeymap){.cdecl.}

  PGdkPangoAttrStipple* = ptr TGdkPangoAttrStipple
  TGdkPangoAttrStipple* {.final.} = object
    attr*: TPangoAttribute
    stipple*: PGdkBitmap

  PGdkPangoAttrEmbossed* = ptr TGdkPangoAttrEmbossed
  TGdkPangoAttrEmbossed* {.final.} = object
    attr*: TPangoAttribute
    embossed*: gboolean

  PGdkPixmapObject* = ptr TGdkPixmapObject
  TGdkPixmapObject* = object of TGdkDrawable
    impl*: PGdkDrawable
    depth*: gint

  PGdkPixmapObjectClass* = ptr TGdkPixmapObjectClass
  TGdkPixmapObjectClass* = object of TGdkDrawableClass

  PGdkPropMode* = ptr TGdkPropMode
  TGdkPropMode* = enum
    GDK_PROP_MODE_REPLACE, GDK_PROP_MODE_PREPEND, GDK_PROP_MODE_APPEND
  PGdkFillRule* = ptr TGdkFillRule
  TGdkFillRule* = enum
    GDK_EVEN_ODD_RULE, GDK_WINDING_RULE
  PGdkOverlapType* = ptr TGdkOverlapType
  TGdkOverlapType* = enum
    GDK_OVERLAP_RECTANGLE_IN, GDK_OVERLAP_RECTANGLE_OUT,
    GDK_OVERLAP_RECTANGLE_PART
  TGdkSpanFunc* = proc (span: PGdkSpan, data: gpointer){.cdecl.}
  PGdkRgbCmap* = ptr TGdkRgbCmap
  TGdkRgbCmap* {.final.} = object
    colors*: array[0..255, guint32]
    n_colors*: gint
    info_list*: PGSList

  TGdkDisplay* = object of TGObject
    queued_events*: PGList
    queued_tail*: PGList
    button_click_time*: array[0..1, guint32]
    button_window*: array[0..1, PGdkWindow]
    button_number*: array[0..1, guint]
    double_click_time*: guint

  PGdkDisplayClass* = ptr TGdkDisplayClass
  TGdkDisplayClass* = object of TGObjectClass
    get_display_name*: proc (display: PGdkDisplay): cstring{.cdecl.}
    get_n_screens*: proc (display: PGdkDisplay): gint{.cdecl.}
    get_screen*: proc (display: PGdkDisplay, screen_num: gint): PGdkScreen{.
        cdecl.}
    get_default_screen*: proc (display: PGdkDisplay): PGdkScreen{.cdecl.}

  PGdkScreenClass* = ptr TGdkScreenClass
  TGdkScreenClass* = object of TGObjectClass
    get_display*: proc (screen: PGdkScreen): PGdkDisplay{.cdecl.}
    get_width*: proc (screen: PGdkScreen): gint{.cdecl.}
    get_height*: proc (screen: PGdkScreen): gint{.cdecl.}
    get_width_mm*: proc (screen: PGdkScreen): gint{.cdecl.}
    get_height_mm*: proc (screen: PGdkScreen): gint{.cdecl.}
    get_root_depth*: proc (screen: PGdkScreen): gint{.cdecl.}
    get_screen_num*: proc (screen: PGdkScreen): gint{.cdecl.}
    get_root_window*: proc (screen: PGdkScreen): PGdkWindow{.cdecl.}
    get_default_colormap*: proc (screen: PGdkScreen): PGdkColormap{.cdecl.}
    set_default_colormap*: proc (screen: PGdkScreen, colormap: PGdkColormap){.
        cdecl.}
    get_window_at_pointer*: proc (screen: PGdkScreen, win_x: Pgint, win_y: Pgint): PGdkWindow{.
        cdecl.}
    get_n_monitors*: proc (screen: PGdkScreen): gint{.cdecl.}
    get_monitor_geometry*: proc (screen: PGdkScreen, monitor_num: gint,
                                 dest: PGdkRectangle){.cdecl.}

  PGdkGrabStatus* = ptr TGdkGrabStatus
  TGdkGrabStatus* = int
  TGdkInputFunction* = proc (data: gpointer, source: gint,
                             condition: TGdkInputCondition){.cdecl.}
  TGdkDestroyNotify* = proc (data: gpointer){.cdecl.}
  TGdkSpan* {.final.} = object
    x*: gint
    y*: gint
    width*: gint

  PGdkWindowClass* = ptr TGdkWindowClass
  TGdkWindowClass* = enum
    GDK_INPUT_OUTPUT, GDK_INPUT_ONLY
  PGdkWindowType* = ptr TGdkWindowType
  TGdkWindowType* = enum
    GDK_WINDOW_ROOT, GDK_WINDOW_TOPLEVEL, GDK_WINDOW_CHILD, GDK_WINDOW_DIALOG,
    GDK_WINDOW_TEMP, GDK_WINDOW_FOREIGN
  PGdkWindowAttributesType* = ptr TGdkWindowAttributesType
  TGdkWindowAttributesType* = int32
  PGdkWindowHints* = ptr TGdkWindowHints
  TGdkWindowHints* = int32
  PGdkWindowTypeHint* = ptr TGdkWindowTypeHint
  TGdkWindowTypeHint* = enum
    GDK_WINDOW_TYPE_HINT_NORMAL, GDK_WINDOW_TYPE_HINT_DIALOG,
    GDK_WINDOW_TYPE_HINT_MENU, GDK_WINDOW_TYPE_HINT_TOOLBAR
  PGdkWMDecoration* = ptr TGdkWMDecoration
  TGdkWMDecoration* = int32
  PGdkWMFunction* = ptr TGdkWMFunction
  TGdkWMFunction* = int32
  PGdkGravity* = ptr TGdkGravity
  TGdkGravity* = int
  PGdkWindowEdge* = ptr TGdkWindowEdge
  TGdkWindowEdge* = enum
    GDK_WINDOW_EDGE_NORTH_WEST, GDK_WINDOW_EDGE_NORTH,
    GDK_WINDOW_EDGE_NORTH_EAST, GDK_WINDOW_EDGE_WEST, GDK_WINDOW_EDGE_EAST,
    GDK_WINDOW_EDGE_SOUTH_WEST, GDK_WINDOW_EDGE_SOUTH,
    GDK_WINDOW_EDGE_SOUTH_EAST
  PGdkWindowAttr* = ptr TGdkWindowAttr
  TGdkWindowAttr* {.final.} = object
    title*: cstring
    event_mask*: gint
    x*: gint
    y*: gint
    width*: gint
    height*: gint
    wclass*: TGdkWindowClass
    visual*: PGdkVisual
    colormap*: PGdkColormap
    window_type*: TGdkWindowType
    cursor*: PGdkCursor
    wmclass_name*: cstring
    wmclass_class*: cstring
    override_redirect*: gboolean

  PGdkGeometry* = ptr TGdkGeometry
  TGdkGeometry* {.final.} = object
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
    win_gravity*: TGdkGravity

  PGdkPointerHooks* = ptr TGdkPointerHooks
  TGdkPointerHooks* {.final.} = object
    get_pointer*: proc (window: PGdkWindow, x: Pgint, y: Pgint,
                        mask: PGdkModifierType): PGdkWindow{.cdecl.}
    window_at_pointer*: proc (screen: PGdkScreen, win_x: Pgint, win_y: Pgint): PGdkWindow{.
        cdecl.}

  PGdkWindowObject* = ptr TGdkWindowObject
  TGdkWindowObject* = object of TGdkDrawable
    impl*: PGdkDrawable
    parent*: PGdkWindowObject
    user_data*: gpointer
    x*: gint
    y*: gint
    extension_events*: gint
    filters*: PGList
    children*: PGList
    bg_color*: TGdkColor
    bg_pixmap*: PGdkPixmap
    paint_stack*: PGSList
    update_area*: PGdkRegion
    update_freeze_count*: guint
    window_type*: guint8
    depth*: guint8
    resize_count*: guint8
    state*: TGdkWindowState
    flag0*: guint16
    event_mask*: TGdkEventMask

  PGdkWindowObjectClass* = ptr TGdkWindowObjectClass
  TGdkWindowObjectClass* = object of TGdkDrawableClass

  gdk_window_invalidate_maybe_recurse_child_func* = proc (para1: PGdkWindow,
      para2: gpointer): gboolean

proc GDK_TYPE_COLORMAP*(): GType
proc GDK_COLORMAP*(anObject: pointer): PGdkColormap
proc GDK_COLORMAP_CLASS*(klass: pointer): PGdkColormapClass
proc GDK_IS_COLORMAP*(anObject: pointer): bool
proc GDK_IS_COLORMAP_CLASS*(klass: pointer): bool
proc GDK_COLORMAP_GET_CLASS*(obj: pointer): PGdkColormapClass
proc GDK_TYPE_COLOR*(): GType
proc gdk_colormap_get_type*(): GType{.cdecl, dynlib: gdklib,
                                      importc: "gdk_colormap_get_type".}
proc gdk_colormap_new*(visual: PGdkVisual, allocate: gboolean): PGdkColormap{.
    cdecl, dynlib: gdklib, importc: "gdk_colormap_new".}
proc gdk_colormap_alloc_colors*(colormap: PGdkColormap, colors: PGdkColor,
                                ncolors: gint, writeable: gboolean,
                                best_match: gboolean, success: Pgboolean): gint{.
    cdecl, dynlib: gdklib, importc: "gdk_colormap_alloc_colors".}
proc gdk_colormap_alloc_color*(colormap: PGdkColormap, color: PGdkColor,
                               writeable: gboolean, best_match: gboolean): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_colormap_alloc_color".}
proc gdk_colormap_free_colors*(colormap: PGdkColormap, colors: PGdkColor,
                               ncolors: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_colormap_free_colors".}
proc gdk_colormap_query_color*(colormap: PGdkColormap, pixel: gulong,
                               result: PGdkColor){.cdecl, dynlib: gdklib,
    importc: "gdk_colormap_query_color".}
proc gdk_colormap_get_visual*(colormap: PGdkColormap): PGdkVisual{.cdecl,
    dynlib: gdklib, importc: "gdk_colormap_get_visual".}
proc gdk_color_copy*(color: PGdkColor): PGdkColor{.cdecl, dynlib: gdklib,
    importc: "gdk_color_copy".}
proc gdk_color_free*(color: PGdkColor){.cdecl, dynlib: gdklib,
                                        importc: "gdk_color_free".}
proc gdk_color_parse*(spec: cstring, color: PGdkColor): gint{.cdecl,
    dynlib: gdklib, importc: "gdk_color_parse".}
proc gdk_color_hash*(colora: PGdkColor): guint{.cdecl, dynlib: gdklib,
    importc: "gdk_color_hash".}
proc gdk_color_equal*(colora: PGdkColor, colorb: PGdkColor): gboolean{.cdecl,
    dynlib: gdklib, importc: "gdk_color_equal".}
proc gdk_color_get_type*(): GType{.cdecl, dynlib: gdklib,
                                   importc: "gdk_color_get_type".}
const
  GDK_CURSOR_IS_PIXMAP* = - (1)
  GDK_X_CURSOR* = 0
  GDK_ARROW* = 2
  GDK_BASED_ARROW_DOWN* = 4
  GDK_BASED_ARROW_UP* = 6
  GDK_BOAT* = 8
  GDK_BOGOSITY* = 10
  GDK_BOTTOM_LEFT_CORNER* = 12
  GDK_BOTTOM_RIGHT_CORNER* = 14
  GDK_BOTTOM_SIDE* = 16
  GDK_BOTTOM_TEE* = 18
  GDK_BOX_SPIRAL* = 20
  GDK_CENTER_PTR* = 22
  GDK_CIRCLE* = 24
  GDK_CLOCK* = 26
  GDK_COFFEE_MUG* = 28
  GDK_CROSS* = 30
  GDK_CROSS_REVERSE* = 32
  GDK_CROSSHAIR* = 34
  GDK_DIAMOND_CROSS* = 36
  GDK_DOT* = 38
  GDK_DOTBOX* = 40
  GDK_DOUBLE_ARROW* = 42
  GDK_DRAFT_LARGE* = 44
  GDK_DRAFT_SMALL* = 46
  GDK_DRAPED_BOX* = 48
  GDK_EXCHANGE* = 50
  GDK_FLEUR* = 52
  GDK_GOBBLER* = 54
  GDK_GUMBY* = 56
  GDK_HAND1* = 58
  GDK_HAND2* = 60
  GDK_HEART* = 62
  GDK_ICON* = 64
  GDK_IRON_CROSS* = 66
  GDK_LEFT_PTR* = 68
  GDK_LEFT_SIDE* = 70
  GDK_LEFT_TEE* = 72
  GDK_LEFTBUTTON* = 74
  GDK_LL_ANGLE* = 76
  GDK_LR_ANGLE* = 78
  GDK_MAN* = 80
  GDK_MIDDLEBUTTON* = 82
  GDK_MOUSE* = 84
  GDK_PENCIL* = 86
  GDK_PIRATE* = 88
  GDK_PLUS* = 90
  GDK_QUESTION_ARROW* = 92
  GDK_RIGHT_PTR* = 94
  GDK_RIGHT_SIDE* = 96
  GDK_RIGHT_TEE* = 98
  GDK_RIGHTBUTTON* = 100
  GDK_RTL_LOGO* = 102
  GDK_SAILBOAT* = 104
  GDK_SB_DOWN_ARROW* = 106
  GDK_SB_H_DOUBLE_ARROW* = 108
  GDK_SB_LEFT_ARROW* = 110
  GDK_SB_RIGHT_ARROW* = 112
  GDK_SB_UP_ARROW* = 114
  GDK_SB_V_DOUBLE_ARROW* = 116
  GDK_SHUTTLE* = 118
  GDK_SIZING* = 120
  GDK_SPIDER* = 122
  GDK_SPRAYCAN* = 124
  GDK_STAR* = 126
  GDK_TARGET* = 128
  GDK_TCROSS* = 130
  GDK_TOP_LEFT_ARROW* = 132
  GDK_TOP_LEFT_CORNER* = 134
  GDK_TOP_RIGHT_CORNER* = 136
  GDK_TOP_SIDE* = 138
  GDK_TOP_TEE* = 140
  GDK_TREK* = 142
  GDK_UL_ANGLE* = 144
  GDK_UMBRELLA* = 146
  GDK_UR_ANGLE* = 148
  GDK_WATCH* = 150
  GDK_XTERM* = 152
  GDK_LAST_CURSOR* = GDK_XTERM + 1

proc GDK_TYPE_CURSOR*(): GType
proc gdk_cursor_get_type*(): GType{.cdecl, dynlib: gdklib,
                                    importc: "gdk_cursor_get_type".}
proc gdk_cursor_new_for_screen*(screen: PGdkScreen, cursor_type: TGdkCursorType): PGdkCursor{.
    cdecl, dynlib: gdklib, importc: "gdk_cursor_new_for_screen".}
proc gdk_cursor_new_from_pixmap*(source: PGdkPixmap, mask: PGdkPixmap,
                                 fg: PGdkColor, bg: PGdkColor, x: gint, y: gint): PGdkCursor{.
    cdecl, dynlib: gdklib, importc: "gdk_cursor_new_from_pixmap".}
proc gdk_cursor_get_screen*(cursor: PGdkCursor): PGdkScreen{.cdecl,
    dynlib: gdklib, importc: "gdk_cursor_get_screen".}
proc gdk_cursor_ref*(cursor: PGdkCursor): PGdkCursor{.cdecl, dynlib: gdklib,
    importc: "gdk_cursor_ref".}
proc gdk_cursor_unref*(cursor: PGdkCursor){.cdecl, dynlib: gdklib,
    importc: "gdk_cursor_unref".}
const
  GDK_ACTION_DEFAULT* = 1 shl 0
  GDK_ACTION_COPY* = 1 shl 1
  GDK_ACTION_MOVE* = 1 shl 2
  GDK_ACTION_LINK* = 1 shl 3
  GDK_ACTION_PRIVATE* = 1 shl 4
  GDK_ACTION_ASK* = 1 shl 5

proc GDK_TYPE_DRAG_CONTEXT*(): GType
proc GDK_DRAG_CONTEXT*(anObject: Pointer): PGdkDragContext
proc GDK_DRAG_CONTEXT_CLASS*(klass: Pointer): PGdkDragContextClass
proc GDK_IS_DRAG_CONTEXT*(anObject: Pointer): bool
proc GDK_IS_DRAG_CONTEXT_CLASS*(klass: Pointer): bool
proc GDK_DRAG_CONTEXT_GET_CLASS*(obj: Pointer): PGdkDragContextClass
proc gdk_drag_context_get_type*(): GType{.cdecl, dynlib: gdklib,
    importc: "gdk_drag_context_get_type".}
proc gdk_drag_context_new*(): PGdkDragContext{.cdecl, dynlib: gdklib,
    importc: "gdk_drag_context_new".}
proc gdk_drag_status*(context: PGdkDragContext, action: TGdkDragAction,
                      time: guint32){.cdecl, dynlib: gdklib,
                                      importc: "gdk_drag_status".}
proc gdk_drop_reply*(context: PGdkDragContext, ok: gboolean, time: guint32){.
    cdecl, dynlib: gdklib, importc: "gdk_drop_reply".}
proc gdk_drop_finish*(context: PGdkDragContext, success: gboolean, time: guint32){.
    cdecl, dynlib: gdklib, importc: "gdk_drop_finish".}
proc gdk_drag_get_selection*(context: PGdkDragContext): TGdkAtom{.cdecl,
    dynlib: gdklib, importc: "gdk_drag_get_selection".}
proc gdk_drag_begin*(window: PGdkWindow, targets: PGList): PGdkDragContext{.
    cdecl, dynlib: gdklib, importc: "gdk_drag_begin".}
proc gdk_drag_get_protocol_for_display*(display: PGdkDisplay, xid: guint32,
                                        protocol: PGdkDragProtocol): guint32{.
    cdecl, dynlib: gdklib, importc: "gdk_drag_get_protocol_for_display".}
proc gdk_drag_find_window*(context: PGdkDragContext, drag_window: PGdkWindow,
                           x_root: gint, y_root: gint, w: var PGdkWindow,
                           protocol: PGdkDragProtocol){.cdecl, dynlib: gdklib,
    importc: "gdk_drag_find_window".}
proc gdk_drag_motion*(context: PGdkDragContext, dest_window: PGdkWindow,
                      protocol: TGdkDragProtocol, x_root: gint, y_root: gint,
                      suggested_action: TGdkDragAction,
                      possible_actions: TGdkDragAction, time: guint32): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_drag_motion".}
proc gdk_drag_drop*(context: PGdkDragContext, time: guint32){.cdecl,
    dynlib: gdklib, importc: "gdk_drag_drop".}
proc gdk_drag_abort*(context: PGdkDragContext, time: guint32){.cdecl,
    dynlib: gdklib, importc: "gdk_drag_abort".}
proc gdkregion_EXTENTCHECK*(r1, r2: PGdkRegionBox): bool
proc gdkregion_EXTENTS*(r: PGdkRegionBox, idRect: PGdkRegion)
proc gdkregion_MEMCHECK*(reg: PGdkRegion, ARect, firstrect: var PGdkRegionBox): bool
proc gdkregion_CHECK_PREVIOUS*(Reg: PGdkRegion, R: PGdkRegionBox,
                               Rx1, Ry1, Rx2, Ry2: gint): bool
proc gdkregion_ADDRECT*(reg: PGdkRegion, r: PGdkRegionBox,
                        rx1, ry1, rx2, ry2: gint)
proc gdkregion_ADDRECTNOX*(reg: PGdkRegion, r: PGdkRegionBox,
                           rx1, ry1, rx2, ry2: gint)
proc gdkregion_EMPTY_REGION*(pReg: PGdkRegion): bool
proc gdkregion_REGION_NOT_EMPTY*(pReg: PGdkRegion): bool
proc gdkregion_INBOX*(r: TGdkRegionBox, x, y: gint): bool
proc GDK_TYPE_DRAWABLE*(): GType
proc GDK_DRAWABLE*(anObject: Pointer): PGdkDrawable
proc GDK_DRAWABLE_CLASS*(klass: Pointer): PGdkDrawableClass
proc GDK_IS_DRAWABLE*(anObject: Pointer): bool
proc GDK_IS_DRAWABLE_CLASS*(klass: Pointer): bool
proc GDK_DRAWABLE_GET_CLASS*(obj: Pointer): PGdkDrawableClass
proc gdk_drawable_get_type*(): GType{.cdecl, dynlib: gdklib,
                                      importc: "gdk_drawable_get_type".}
proc gdk_drawable_get_size*(drawable: PGdkDrawable, width: Pgint, height: Pgint){.
    cdecl, dynlib: gdklib, importc: "gdk_drawable_get_size".}
proc gdk_drawable_set_colormap*(drawable: PGdkDrawable, colormap: PGdkColormap){.
    cdecl, dynlib: gdklib, importc: "gdk_drawable_set_colormap".}
proc gdk_drawable_get_colormap*(drawable: PGdkDrawable): PGdkColormap{.cdecl,
    dynlib: gdklib, importc: "gdk_drawable_get_colormap".}
proc gdk_drawable_get_visual*(drawable: PGdkDrawable): PGdkVisual{.cdecl,
    dynlib: gdklib, importc: "gdk_drawable_get_visual".}
proc gdk_drawable_get_depth*(drawable: PGdkDrawable): gint{.cdecl,
    dynlib: gdklib, importc: "gdk_drawable_get_depth".}
proc gdk_drawable_get_screen*(drawable: PGdkDrawable): PGdkScreen{.cdecl,
    dynlib: gdklib, importc: "gdk_drawable_get_screen".}
proc gdk_drawable_get_display*(drawable: PGdkDrawable): PGdkDisplay{.cdecl,
    dynlib: gdklib, importc: "gdk_drawable_get_display".}
proc gdk_draw_point*(drawable: PGdkDrawable, gc: PGdkGC, x: gint, y: gint){.
    cdecl, dynlib: gdklib, importc: "gdk_draw_point".}
proc gdk_draw_line*(drawable: PGdkDrawable, gc: PGdkGC, x1: gint, y1: gint,
                    x2: gint, y2: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_draw_line".}
proc gdk_draw_rectangle*(drawable: PGdkDrawable, gc: PGdkGC, filled: gint,
                         x: gint, y: gint, width: gint, height: gint){.cdecl,
    dynlib: gdklib, importc: "gdk_draw_rectangle".}
proc gdk_draw_arc*(drawable: PGdkDrawable, gc: PGdkGC, filled: gint, x: gint,
                   y: gint, width: gint, height: gint, angle1: gint,
                   angle2: gint){.cdecl, dynlib: gdklib, importc: "gdk_draw_arc".}
proc gdk_draw_polygon*(drawable: PGdkDrawable, gc: PGdkGC, filled: gint,
                       points: PGdkPoint, npoints: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_draw_polygon".}
proc gdk_draw_drawable*(drawable: PGdkDrawable, gc: PGdkGC, src: PGdkDrawable,
                        xsrc: gint, ysrc: gint, xdest: gint, ydest: gint,
                        width: gint, height: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_draw_drawable".}
proc gdk_draw_image*(drawable: PGdkDrawable, gc: PGdkGC, image: PGdkImage,
                     xsrc: gint, ysrc: gint, xdest: gint, ydest: gint,
                     width: gint, height: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_draw_image".}
proc gdk_draw_points*(drawable: PGdkDrawable, gc: PGdkGC, points: PGdkPoint,
                      npoints: gint){.cdecl, dynlib: gdklib,
                                      importc: "gdk_draw_points".}
proc gdk_draw_segments*(drawable: PGdkDrawable, gc: PGdkGC, segs: PGdkSegment,
                        nsegs: gint){.cdecl, dynlib: gdklib,
                                      importc: "gdk_draw_segments".}
proc gdk_draw_lines*(drawable: PGdkDrawable, gc: PGdkGC, points: PGdkPoint,
                     npoints: gint){.cdecl, dynlib: gdklib,
                                     importc: "gdk_draw_lines".}
proc gdk_draw_glyphs*(drawable: PGdkDrawable, gc: PGdkGC, font: PPangoFont,
                      x: gint, y: gint, glyphs: PPangoGlyphString){.cdecl,
    dynlib: gdklib, importc: "gdk_draw_glyphs".}
proc gdk_draw_layout_line*(drawable: PGdkDrawable, gc: PGdkGC, x: gint, y: gint,
                           line: PPangoLayoutLine){.cdecl, dynlib: gdklib,
    importc: "gdk_draw_layout_line".}
proc gdk_draw_layout*(drawable: PGdkDrawable, gc: PGdkGC, x: gint, y: gint,
                      layout: PPangoLayout){.cdecl, dynlib: gdklib,
    importc: "gdk_draw_layout".}
proc gdk_draw_layout_line_with_colors*(drawable: PGdkDrawable, gc: PGdkGC,
                                       x: gint, y: gint, line: PPangoLayoutLine,
                                       foreground: PGdkColor,
                                       background: PGdkColor){.cdecl,
    dynlib: gdklib, importc: "gdk_draw_layout_line_with_colors".}
proc gdk_draw_layout_with_colors*(drawable: PGdkDrawable, gc: PGdkGC, x: gint,
                                  y: gint, layout: PPangoLayout,
                                  foreground: PGdkColor, background: PGdkColor){.
    cdecl, dynlib: gdklib, importc: "gdk_draw_layout_with_colors".}
proc gdk_drawable_get_image*(drawable: PGdkDrawable, x: gint, y: gint,
                             width: gint, height: gint): PGdkImage{.cdecl,
    dynlib: gdklib, importc: "gdk_drawable_get_image".}
proc gdk_drawable_get_clip_region*(drawable: PGdkDrawable): PGdkRegion{.cdecl,
    dynlib: gdklib, importc: "gdk_drawable_get_clip_region".}
proc gdk_drawable_get_visible_region*(drawable: PGdkDrawable): PGdkRegion{.
    cdecl, dynlib: gdklib, importc: "gdk_drawable_get_visible_region".}
const
  GDK_NOTHING* = - (1)
  GDK_DELETE* = 0
  GDK_DESTROY* = 1
  GDK_EXPOSE* = 2
  GDK_MOTION_NOTIFY* = 3
  GDK_BUTTON_PRESS* = 4
  GDK_2BUTTON_PRESS* = 5
  GDK_3BUTTON_PRESS* = 6
  GDK_BUTTON_RELEASE* = 7
  GDK_KEY_PRESS* = 8
  GDK_KEY_RELEASE* = 9
  GDK_ENTER_NOTIFY* = 10
  GDK_LEAVE_NOTIFY* = 11
  GDK_FOCUS_CHANGE* = 12
  GDK_CONFIGURE* = 13
  GDK_MAP* = 14
  GDK_UNMAP* = 15
  GDK_PROPERTY_NOTIFY* = 16
  GDK_SELECTION_CLEAR* = 17
  GDK_SELECTION_REQUEST* = 18
  GDK_SELECTION_NOTIFY* = 19
  GDK_PROXIMITY_IN* = 20
  GDK_PROXIMITY_OUT* = 21
  GDK_DRAG_ENTER* = 22
  GDK_DRAG_LEAVE* = 23
  GDK_DRAG_MOTION_EVENT* = 24
  GDK_DRAG_STATUS_EVENT* = 25
  GDK_DROP_START* = 26
  GDK_DROP_FINISHED* = 27
  GDK_CLIENT_EVENT* = 28
  GDK_VISIBILITY_NOTIFY* = 29
  GDK_NO_EXPOSE* = 30
  GDK_SCROLL* = 31
  GDK_WINDOW_STATE* = 32
  GDK_SETTING* = 33
  GDK_NOTIFY_ANCESTOR* = 0
  GDK_NOTIFY_VIRTUAL* = 1
  GDK_NOTIFY_INFERIOR* = 2
  GDK_NOTIFY_NONLINEAR* = 3
  GDK_NOTIFY_NONLINEAR_VIRTUAL* = 4
  GDK_NOTIFY_UNKNOWN* = 5

proc GDK_TYPE_EVENT*(): GType
const
  G_PRIORITY_DEFAULT* = 0
  GDK_PRIORITY_EVENTS* = G_PRIORITY_DEFAULT
    #GDK_PRIORITY_REDRAW* = G_PRIORITY_HIGH_IDLE + 20
  GDK_EXPOSURE_MASK* = 1 shl 1
  GDK_POINTER_MOTION_MASK* = 1 shl 2
  GDK_POINTER_MOTION_HINT_MASK* = 1 shl 3
  GDK_BUTTON_MOTION_MASK* = 1 shl 4
  GDK_BUTTON1_MOTION_MASK* = 1 shl 5
  GDK_BUTTON2_MOTION_MASK* = 1 shl 6
  GDK_BUTTON3_MOTION_MASK* = 1 shl 7
  GDK_BUTTON_PRESS_MASK* = 1 shl 8
  GDK_BUTTON_RELEASE_MASK* = 1 shl 9
  GDK_KEY_PRESS_MASK* = 1 shl 10
  GDK_KEY_RELEASE_MASK* = 1 shl 11
  GDK_ENTER_NOTIFY_MASK* = 1 shl 12
  GDK_LEAVE_NOTIFY_MASK* = 1 shl 13
  GDK_FOCUS_CHANGE_MASK* = 1 shl 14
  GDK_STRUCTURE_MASK* = 1 shl 15
  GDK_PROPERTY_CHANGE_MASK* = 1 shl 16
  GDK_VISIBILITY_NOTIFY_MASK* = 1 shl 17
  GDK_PROXIMITY_IN_MASK* = 1 shl 18
  GDK_PROXIMITY_OUT_MASK* = 1 shl 19
  GDK_SUBSTRUCTURE_MASK* = 1 shl 20
  GDK_SCROLL_MASK* = 1 shl 21
  GDK_ALL_EVENTS_MASK* = 0x003FFFFE
  GDK_WINDOW_STATE_WITHDRAWN* = 1 shl 0
  GDK_WINDOW_STATE_ICONIFIED* = 1 shl 1
  GDK_WINDOW_STATE_MAXIMIZED* = 1 shl 2
  GDK_WINDOW_STATE_STICKY* = 1 shl 3

proc gdk_event_get_type*(): GType{.cdecl, dynlib: gdklib,
                                   importc: "gdk_event_get_type".}
proc gdk_events_pending*(): gboolean{.cdecl, dynlib: gdklib,
                                      importc: "gdk_events_pending".}
proc gdk_event_get*(): PGdkEvent{.cdecl, dynlib: gdklib,
                                  importc: "gdk_event_get".}
proc gdk_event_peek*(): PGdkEvent{.cdecl, dynlib: gdklib,
                                   importc: "gdk_event_peek".}
proc gdk_event_get_graphics_expose*(window: PGdkWindow): PGdkEvent{.cdecl,
    dynlib: gdklib, importc: "gdk_event_get_graphics_expose".}
proc gdk_event_put*(event: PGdkEvent){.cdecl, dynlib: gdklib,
                                       importc: "gdk_event_put".}
proc gdk_event_copy*(event: PGdkEvent): PGdkEvent{.cdecl, dynlib: gdklib,
    importc: "gdk_event_copy".}
proc gdk_event_free*(event: PGdkEvent){.cdecl, dynlib: gdklib,
                                        importc: "gdk_event_free".}
proc gdk_event_get_time*(event: PGdkEvent): guint32{.cdecl, dynlib: gdklib,
    importc: "gdk_event_get_time".}
proc gdk_event_get_state*(event: PGdkEvent, state: PGdkModifierType): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_event_get_state".}
proc gdk_event_get_coords*(event: PGdkEvent, x_win: Pgdouble, y_win: Pgdouble): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_event_get_coords".}
proc gdk_event_get_root_coords*(event: PGdkEvent, x_root: Pgdouble,
                                y_root: Pgdouble): gboolean{.cdecl,
    dynlib: gdklib, importc: "gdk_event_get_root_coords".}
proc gdk_event_get_axis*(event: PGdkEvent, axis_use: TGdkAxisUse,
                         value: Pgdouble): gboolean{.cdecl, dynlib: gdklib,
    importc: "gdk_event_get_axis".}
proc gdk_event_handler_set*(func: TGdkEventFunc, data: gpointer,
                            notify: TGDestroyNotify){.cdecl, dynlib: gdklib,
    importc: "gdk_event_handler_set".}
proc gdk_set_show_events*(show_events: gboolean){.cdecl, dynlib: gdklib,
    importc: "gdk_set_show_events".}
proc gdk_get_show_events*(): gboolean{.cdecl, dynlib: gdklib,
                                       importc: "gdk_get_show_events".}
proc GDK_TYPE_FONT*(): GType
proc gdk_font_get_type*(): GType{.cdecl, dynlib: gdklib,
                                  importc: "gdk_font_get_type".}
proc gdk_font_load_for_display*(display: PGdkDisplay, font_name: cstring): PGdkFont{.
    cdecl, dynlib: gdklib, importc: "gdk_font_load_for_display".}
proc gdk_fontset_load_for_display*(display: PGdkDisplay, fontset_name: cstring): PGdkFont{.
    cdecl, dynlib: gdklib, importc: "gdk_fontset_load_for_display".}
proc gdk_font_from_description_for_display*(display: PGdkDisplay,
    font_desc: PPangoFontDescription): PGdkFont{.cdecl, dynlib: gdklib,
    importc: "gdk_font_from_description_for_display".}
proc gdk_font_ref*(font: PGdkFont): PGdkFont{.cdecl, dynlib: gdklib,
    importc: "gdk_font_ref".}
proc gdk_font_unref*(font: PGdkFont){.cdecl, dynlib: gdklib,
                                      importc: "gdk_font_unref".}
proc gdk_font_id*(font: PGdkFont): gint{.cdecl, dynlib: gdklib,
    importc: "gdk_font_id".}
proc gdk_font_equal*(fonta: PGdkFont, fontb: PGdkFont): gboolean{.cdecl,
    dynlib: gdklib, importc: "gdk_font_equal".}
proc gdk_string_width*(font: PGdkFont, `string`: cstring): gint{.cdecl,
    dynlib: gdklib, importc: "gdk_string_width".}
proc gdk_text_width*(font: PGdkFont, text: cstring, text_length: gint): gint{.
    cdecl, dynlib: gdklib, importc: "gdk_text_width".}
proc gdk_text_width_wc*(font: PGdkFont, text: PGdkWChar, text_length: gint): gint{.
    cdecl, dynlib: gdklib, importc: "gdk_text_width_wc".}
proc gdk_char_width*(font: PGdkFont, character: gchar): gint{.cdecl,
    dynlib: gdklib, importc: "gdk_char_width".}
proc gdk_char_width_wc*(font: PGdkFont, character: TGdkWChar): gint{.cdecl,
    dynlib: gdklib, importc: "gdk_char_width_wc".}
proc gdk_string_measure*(font: PGdkFont, `string`: cstring): gint{.cdecl,
    dynlib: gdklib, importc: "gdk_string_measure".}
proc gdk_text_measure*(font: PGdkFont, text: cstring, text_length: gint): gint{.
    cdecl, dynlib: gdklib, importc: "gdk_text_measure".}
proc gdk_char_measure*(font: PGdkFont, character: gchar): gint{.cdecl,
    dynlib: gdklib, importc: "gdk_char_measure".}
proc gdk_string_height*(font: PGdkFont, `string`: cstring): gint{.cdecl,
    dynlib: gdklib, importc: "gdk_string_height".}
proc gdk_text_height*(font: PGdkFont, text: cstring, text_length: gint): gint{.
    cdecl, dynlib: gdklib, importc: "gdk_text_height".}
proc gdk_char_height*(font: PGdkFont, character: gchar): gint{.cdecl,
    dynlib: gdklib, importc: "gdk_char_height".}
proc gdk_text_extents*(font: PGdkFont, text: cstring, text_length: gint,
                       lbearing: Pgint, rbearing: Pgint, width: Pgint,
                       ascent: Pgint, descent: Pgint){.cdecl, dynlib: gdklib,
    importc: "gdk_text_extents".}
proc gdk_text_extents_wc*(font: PGdkFont, text: PGdkWChar, text_length: gint,
                          lbearing: Pgint, rbearing: Pgint, width: Pgint,
                          ascent: Pgint, descent: Pgint){.cdecl, dynlib: gdklib,
    importc: "gdk_text_extents_wc".}
proc gdk_string_extents*(font: PGdkFont, `string`: cstring, lbearing: Pgint,
                         rbearing: Pgint, width: Pgint, ascent: Pgint,
                         descent: Pgint){.cdecl, dynlib: gdklib,
    importc: "gdk_string_extents".}
proc gdk_font_get_display*(font: PGdkFont): PGdkDisplay{.cdecl, dynlib: gdklib,
    importc: "gdk_font_get_display".}
const
  GDK_GC_FOREGROUND* = 1 shl 0
  GDK_GC_BACKGROUND* = 1 shl 1
  GDK_GC_FONT* = 1 shl 2
  GDK_GC_FUNCTION* = 1 shl 3
  GDK_GC_FILL* = 1 shl 4
  GDK_GC_TILE* = 1 shl 5
  GDK_GC_STIPPLE* = 1 shl 6
  GDK_GC_CLIP_MASK* = 1 shl 7
  GDK_GC_SUBWINDOW* = 1 shl 8
  GDK_GC_TS_X_ORIGIN* = 1 shl 9
  GDK_GC_TS_Y_ORIGIN* = 1 shl 10
  GDK_GC_CLIP_X_ORIGIN* = 1 shl 11
  GDK_GC_CLIP_Y_ORIGIN* = 1 shl 12
  GDK_GC_EXPOSURES* = 1 shl 13
  GDK_GC_LINE_WIDTH* = 1 shl 14
  GDK_GC_LINE_STYLE* = 1 shl 15
  GDK_GC_CAP_STYLE* = 1 shl 16
  GDK_GC_JOIN_STYLE* = 1 shl 17
  GDK_CLIP_BY_CHILDREN* = 0
  GDK_INCLUDE_INFERIORS* = 1

proc GDK_TYPE_GC*(): GType
proc GDK_GC*(anObject: Pointer): PGdkGC
proc GDK_GC_CLASS*(klass: Pointer): PGdkGCClass
proc GDK_IS_GC*(anObject: Pointer): bool
proc GDK_IS_GC_CLASS*(klass: Pointer): bool
proc GDK_GC_GET_CLASS*(obj: Pointer): PGdkGCClass
proc gdk_gc_get_type*(): GType{.cdecl, dynlib: gdklib,
                                importc: "gdk_gc_get_type".}
proc gdk_gc_new*(drawable: PGdkDrawable): PGdkGC{.cdecl, dynlib: gdklib,
    importc: "gdk_gc_new".}
proc gdk_gc_new_with_values*(drawable: PGdkDrawable, values: PGdkGCValues,
                             values_mask: TGdkGCValuesMask): PGdkGC{.cdecl,
    dynlib: gdklib, importc: "gdk_gc_new_with_values".}
proc gdk_gc_get_values*(gc: PGdkGC, values: PGdkGCValues){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_get_values".}
proc gdk_gc_set_values*(gc: PGdkGC, values: PGdkGCValues,
                        values_mask: TGdkGCValuesMask){.cdecl, dynlib: gdklib,
    importc: "gdk_gc_set_values".}
proc gdk_gc_set_foreground*(gc: PGdkGC, color: PGdkColor){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_foreground".}
proc gdk_gc_set_background*(gc: PGdkGC, color: PGdkColor){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_background".}
proc gdk_gc_set_function*(gc: PGdkGC, `function`: TGdkFunction){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_function".}
proc gdk_gc_set_fill*(gc: PGdkGC, fill: TGdkFill){.cdecl, dynlib: gdklib,
    importc: "gdk_gc_set_fill".}
proc gdk_gc_set_tile*(gc: PGdkGC, tile: PGdkPixmap){.cdecl, dynlib: gdklib,
    importc: "gdk_gc_set_tile".}
proc gdk_gc_set_stipple*(gc: PGdkGC, stipple: PGdkPixmap){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_stipple".}
proc gdk_gc_set_ts_origin*(gc: PGdkGC, x: gint, y: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_gc_set_ts_origin".}
proc gdk_gc_set_clip_origin*(gc: PGdkGC, x: gint, y: gint){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_clip_origin".}
proc gdk_gc_set_clip_mask*(gc: PGdkGC, mask: PGdkBitmap){.cdecl, dynlib: gdklib,
    importc: "gdk_gc_set_clip_mask".}
proc gdk_gc_set_clip_rectangle*(gc: PGdkGC, rectangle: PGdkRectangle){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_clip_rectangle".}
proc gdk_gc_set_clip_region*(gc: PGdkGC, region: PGdkRegion){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_clip_region".}
proc gdk_gc_set_subwindow*(gc: PGdkGC, mode: TGdkSubwindowMode){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_subwindow".}
proc gdk_gc_set_exposures*(gc: PGdkGC, exposures: gboolean){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_exposures".}
proc gdk_gc_set_line_attributes*(gc: PGdkGC, line_width: gint,
                                 line_style: TGdkLineStyle,
                                 cap_style: TGdkCapStyle,
                                 join_style: TGdkJoinStyle){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_line_attributes".}
proc gdk_gc_set_dashes*(gc: PGdkGC, dash_offset: gint,
                        dash_list: openarray[gint8]){.cdecl, dynlib: gdklib,
    importc: "gdk_gc_set_dashes".}
proc gdk_gc_offset*(gc: PGdkGC, x_offset: gint, y_offset: gint){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_offset".}
proc gdk_gc_copy*(dst_gc: PGdkGC, src_gc: PGdkGC){.cdecl, dynlib: gdklib,
    importc: "gdk_gc_copy".}
proc gdk_gc_set_colormap*(gc: PGdkGC, colormap: PGdkColormap){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_colormap".}
proc gdk_gc_get_colormap*(gc: PGdkGC): PGdkColormap{.cdecl, dynlib: gdklib,
    importc: "gdk_gc_get_colormap".}
proc gdk_gc_set_rgb_fg_color*(gc: PGdkGC, color: PGdkColor){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_rgb_fg_color".}
proc gdk_gc_set_rgb_bg_color*(gc: PGdkGC, color: PGdkColor){.cdecl,
    dynlib: gdklib, importc: "gdk_gc_set_rgb_bg_color".}
proc gdk_gc_get_screen*(gc: PGdkGC): PGdkScreen{.cdecl, dynlib: gdklib,
    importc: "gdk_gc_get_screen".}
proc GDK_TYPE_IMAGE*(): GType
proc GDK_IMAGE*(anObject: Pointer): PGdkImage
proc GDK_IMAGE_CLASS*(klass: Pointer): PGdkImageClass
proc GDK_IS_IMAGE*(anObject: Pointer): bool
proc GDK_IS_IMAGE_CLASS*(klass: Pointer): bool
proc GDK_IMAGE_GET_CLASS*(obj: Pointer): PGdkImageClass
proc gdk_image_get_type*(): GType{.cdecl, dynlib: gdklib,
                                   importc: "gdk_image_get_type".}
proc gdk_image_new*(`type`: TGdkImageType, visual: PGdkVisual, width: gint,
                    height: gint): PGdkImage{.cdecl, dynlib: gdklib,
    importc: "gdk_image_new".}
proc gdk_image_put_pixel*(image: PGdkImage, x: gint, y: gint, pixel: guint32){.
    cdecl, dynlib: gdklib, importc: "gdk_image_put_pixel".}
proc gdk_image_get_pixel*(image: PGdkImage, x: gint, y: gint): guint32{.cdecl,
    dynlib: gdklib, importc: "gdk_image_get_pixel".}
proc gdk_image_set_colormap*(image: PGdkImage, colormap: PGdkColormap){.cdecl,
    dynlib: gdklib, importc: "gdk_image_set_colormap".}
proc gdk_image_get_colormap*(image: PGdkImage): PGdkColormap{.cdecl,
    dynlib: gdklib, importc: "gdk_image_get_colormap".}
const
  GDK_AXIS_IGNORE* = 0
  GDK_AXIS_X* = 1
  GDK_AXIS_Y* = 2
  GDK_AXIS_PRESSURE* = 3
  GDK_AXIS_XTILT* = 4
  GDK_AXIS_YTILT* = 5
  GDK_AXIS_WHEEL* = 6
  GDK_AXIS_LAST* = 7

proc GDK_TYPE_DEVICE*(): GType
proc GDK_DEVICE*(anObject: Pointer): PGdkDevice
proc GDK_DEVICE_CLASS*(klass: Pointer): PGdkDeviceClass
proc GDK_IS_DEVICE*(anObject: Pointer): bool
proc GDK_IS_DEVICE_CLASS*(klass: Pointer): bool
proc GDK_DEVICE_GET_CLASS*(obj: Pointer): PGdkDeviceClass
proc gdk_device_get_type*(): GType{.cdecl, dynlib: gdklib,
                                    importc: "gdk_device_get_type".}
proc gdk_device_set_source*(device: PGdkDevice, source: TGdkInputSource){.cdecl,
    dynlib: gdklib, importc: "gdk_device_set_source".}
proc gdk_device_set_mode*(device: PGdkDevice, mode: TGdkInputMode): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_device_set_mode".}
proc gdk_device_set_key*(device: PGdkDevice, index: guint, keyval: guint,
                         modifiers: TGdkModifierType){.cdecl, dynlib: gdklib,
    importc: "gdk_device_set_key".}
proc gdk_device_set_axis_use*(device: PGdkDevice, index: guint, use: TGdkAxisUse){.
    cdecl, dynlib: gdklib, importc: "gdk_device_set_axis_use".}
proc gdk_device_get_state*(device: PGdkDevice, window: PGdkWindow,
                           axes: Pgdouble, mask: PGdkModifierType){.cdecl,
    dynlib: gdklib, importc: "gdk_device_get_state".}
proc gdk_device_get_history*(device: PGdkDevice, window: PGdkWindow,
                             start: guint32, stop: guint32,
                             s: var PPGdkTimeCoord, n_events: Pgint): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_device_get_history".}
proc gdk_device_free_history*(events: PPGdkTimeCoord, n_events: gint){.cdecl,
    dynlib: gdklib, importc: "gdk_device_free_history".}
proc gdk_device_get_axis*(device: PGdkDevice, axes: Pgdouble, use: TGdkAxisUse,
                          value: Pgdouble): gboolean{.cdecl, dynlib: gdklib,
    importc: "gdk_device_get_axis".}
proc gdk_input_set_extension_events*(window: PGdkWindow, mask: gint,
                                     mode: TGdkExtensionMode){.cdecl,
    dynlib: gdklib, importc: "gdk_input_set_extension_events".}
proc gdk_device_get_core_pointer*(): PGdkDevice{.cdecl, dynlib: gdklib,
    importc: "gdk_device_get_core_pointer".}
proc GDK_TYPE_KEYMAP*(): GType
proc GDK_KEYMAP*(anObject: Pointer): PGdkKeymap
proc GDK_KEYMAP_CLASS*(klass: Pointer): PGdkKeymapClass
proc GDK_IS_KEYMAP*(anObject: Pointer): bool
proc GDK_IS_KEYMAP_CLASS*(klass: Pointer): bool
proc GDK_KEYMAP_GET_CLASS*(obj: Pointer): PGdkKeymapClass
proc gdk_keymap_get_type*(): GType{.cdecl, dynlib: gdklib,
                                    importc: "gdk_keymap_get_type".}
proc gdk_keymap_get_for_display*(display: PGdkDisplay): PGdkKeymap{.cdecl,
    dynlib: gdklib, importc: "gdk_keymap_get_for_display".}
proc gdk_keymap_lookup_key*(keymap: PGdkKeymap, key: PGdkKeymapKey): guint{.
    cdecl, dynlib: gdklib, importc: "gdk_keymap_lookup_key".}
proc gdk_keymap_translate_keyboard_state*(keymap: PGdkKeymap,
    hardware_keycode: guint, state: TGdkModifierType, group: gint,
    keyval: Pguint, effective_group: Pgint, level: Pgint,
    consumed_modifiers: PGdkModifierType): gboolean{.cdecl, dynlib: gdklib,
    importc: "gdk_keymap_translate_keyboard_state".}
proc gdk_keymap_get_entries_for_keyval*(keymap: PGdkKeymap, keyval: guint,
                                        s: var PGdkKeymapKey, n_keys: Pgint): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_keymap_get_entries_for_keyval".}
proc gdk_keymap_get_entries_for_keycode*(keymap: PGdkKeymap,
    hardware_keycode: guint, s: var PGdkKeymapKey, sasdf: var Pguint,
    n_entries: Pgint): gboolean{.cdecl, dynlib: gdklib,
                                 importc: "gdk_keymap_get_entries_for_keycode".}
proc gdk_keymap_get_direction*(keymap: PGdkKeymap): TPangoDirection{.cdecl,
    dynlib: gdklib, importc: "gdk_keymap_get_direction".}
proc gdk_keyval_name*(keyval: guint): cstring{.cdecl, dynlib: gdklib,
    importc: "gdk_keyval_name".}
proc gdk_keyval_from_name*(keyval_name: cstring): guint{.cdecl, dynlib: gdklib,
    importc: "gdk_keyval_from_name".}
proc gdk_keyval_convert_case*(symbol: guint, lower: Pguint, upper: Pguint){.
    cdecl, dynlib: gdklib, importc: "gdk_keyval_convert_case".}
proc gdk_keyval_to_upper*(keyval: guint): guint{.cdecl, dynlib: gdklib,
    importc: "gdk_keyval_to_upper".}
proc gdk_keyval_to_lower*(keyval: guint): guint{.cdecl, dynlib: gdklib,
    importc: "gdk_keyval_to_lower".}
proc gdk_keyval_is_upper*(keyval: guint): gboolean{.cdecl, dynlib: gdklib,
    importc: "gdk_keyval_is_upper".}
proc gdk_keyval_is_lower*(keyval: guint): gboolean{.cdecl, dynlib: gdklib,
    importc: "gdk_keyval_is_lower".}
proc gdk_keyval_to_unicode*(keyval: guint): guint32{.cdecl, dynlib: gdklib,
    importc: "gdk_keyval_to_unicode".}
proc gdk_unicode_to_keyval*(wc: guint32): guint{.cdecl, dynlib: gdklib,
    importc: "gdk_unicode_to_keyval".}
const
  GDK_KEY_VoidSymbol* = 0x00FFFFFF
  GDK_KEY_BackSpace* = 0x0000FF08
  GDK_KEY_Tab* = 0x0000FF09
  GDK_KEY_Linefeed* = 0x0000FF0A
  GDK_KEY_Clear* = 0x0000FF0B
  GDK_KEY_Return* = 0x0000FF0D
  GDK_KEY_Pause* = 0x0000FF13
  GDK_KEY_Scroll_Lock* = 0x0000FF14
  GDK_KEY_Sys_Req* = 0x0000FF15
  GDK_KEY_Escape* = 0x0000FF1B
  GDK_KEY_Delete* = 0x0000FFFF
  GDK_KEY_Multi_key* = 0x0000FF20
  GDK_KEY_Codeinput* = 0x0000FF37
  GDK_KEY_SingleCandidate* = 0x0000FF3C
  GDK_KEY_MultipleCandidate* = 0x0000FF3D
  GDK_KEY_PreviousCandidate* = 0x0000FF3E
  GDK_KEY_Kanji* = 0x0000FF21
  GDK_KEY_Muhenkan* = 0x0000FF22
  GDK_KEY_Henkan_Mode* = 0x0000FF23
  GDK_KEY_Henkan* = 0x0000FF23
  GDK_KEY_Romaji* = 0x0000FF24
  GDK_KEY_Hiragana* = 0x0000FF25
  GDK_KEY_Katakana* = 0x0000FF26
  GDK_KEY_Hiragana_Katakana* = 0x0000FF27
  GDK_KEY_Zenkaku* = 0x0000FF28
  GDK_KEY_Hankaku* = 0x0000FF29
  GDK_KEY_Zenkaku_Hankaku* = 0x0000FF2A
  GDK_KEY_Touroku* = 0x0000FF2B
  GDK_KEY_Massyo* = 0x0000FF2C
  GDK_KEY_Kana_Lock* = 0x0000FF2D
  GDK_KEY_Kana_Shift* = 0x0000FF2E
  GDK_KEY_Eisu_Shift* = 0x0000FF2F
  GDK_KEY_Eisu_toggle* = 0x0000FF30
  GDK_KEY_Kanji_Bangou* = 0x0000FF37
  GDK_KEY_Zen_Koho* = 0x0000FF3D
  GDK_KEY_Mae_Koho* = 0x0000FF3E
  GDK_KEY_Home* = 0x0000FF50
  GDK_KEY_Left* = 0x0000FF51
  GDK_KEY_Up* = 0x0000FF52
  GDK_KEY_Right* = 0x0000FF53
  GDK_KEY_Down* = 0x0000FF54
  GDK_KEY_Prior* = 0x0000FF55
  GDK_KEY_Page_Up* = 0x0000FF55
  GDK_KEY_Next* = 0x0000FF56
  GDK_KEY_Page_Down* = 0x0000FF56
  GDK_KEY_End* = 0x0000FF57
  GDK_KEY_Begin* = 0x0000FF58
  GDK_KEY_Select* = 0x0000FF60
  GDK_KEY_Print* = 0x0000FF61
  GDK_KEY_Execute* = 0x0000FF62
  GDK_KEY_Insert* = 0x0000FF63
  GDK_KEY_Undo* = 0x0000FF65
  GDK_KEY_Redo* = 0x0000FF66
  GDK_KEY_Menu* = 0x0000FF67
  GDK_KEY_Find* = 0x0000FF68
  GDK_KEY_Cancel* = 0x0000FF69
  GDK_KEY_Help* = 0x0000FF6A
  GDK_KEY_Break* = 0x0000FF6B
  GDK_KEY_Mode_switch* = 0x0000FF7E
  GDK_KEY_script_switch* = 0x0000FF7E
  GDK_KEY_Num_Lock* = 0x0000FF7F
  GDK_KEY_KP_Space* = 0x0000FF80
  GDK_KEY_KP_Tab* = 0x0000FF89
  GDK_KEY_KP_Enter* = 0x0000FF8D
  GDK_KEY_KP_F1* = 0x0000FF91
  GDK_KEY_KP_F2* = 0x0000FF92
  GDK_KEY_KP_F3* = 0x0000FF93
  GDK_KEY_KP_F4* = 0x0000FF94
  GDK_KEY_KP_Home* = 0x0000FF95
  GDK_KEY_KP_Left* = 0x0000FF96
  GDK_KEY_KP_Up* = 0x0000FF97
  GDK_KEY_KP_Right* = 0x0000FF98
  GDK_KEY_KP_Down* = 0x0000FF99
  GDK_KEY_KP_Prior* = 0x0000FF9A
  GDK_KEY_KP_Page_Up* = 0x0000FF9A
  GDK_KEY_KP_Next* = 0x0000FF9B
  GDK_KEY_KP_Page_Down* = 0x0000FF9B
  GDK_KEY_KP_End* = 0x0000FF9C
  GDK_KEY_KP_Begin* = 0x0000FF9D
  GDK_KEY_KP_Insert* = 0x0000FF9E
  GDK_KEY_KP_Delete* = 0x0000FF9F
  GDK_KEY_KP_Equal* = 0x0000FFBD
  GDK_KEY_KP_Multiply* = 0x0000FFAA
  GDK_KEY_KP_Add* = 0x0000FFAB
  GDK_KEY_KP_Separator* = 0x0000FFAC
  GDK_KEY_KP_Subtract* = 0x0000FFAD
  GDK_KEY_KP_Decimal* = 0x0000FFAE
  GDK_KEY_KP_Divide* = 0x0000FFAF
  GDK_KEY_KP_0* = 0x0000FFB0
  GDK_KEY_KP_1* = 0x0000FFB1
  GDK_KEY_KP_2* = 0x0000FFB2
  GDK_KEY_KP_3* = 0x0000FFB3
  GDK_KEY_KP_4* = 0x0000FFB4
  GDK_KEY_KP_5* = 0x0000FFB5
  GDK_KEY_KP_6* = 0x0000FFB6
  GDK_KEY_KP_7* = 0x0000FFB7
  GDK_KEY_KP_8* = 0x0000FFB8
  GDK_KEY_KP_9* = 0x0000FFB9
  GDK_KEY_F1* = 0x0000FFBE
  GDK_KEY_F2* = 0x0000FFBF
  GDK_KEY_F3* = 0x0000FFC0
  GDK_KEY_F4* = 0x0000FFC1
  GDK_KEY_F5* = 0x0000FFC2
  GDK_KEY_F6* = 0x0000FFC3
  GDK_KEY_F7* = 0x0000FFC4
  GDK_KEY_F8* = 0x0000FFC5
  GDK_KEY_F9* = 0x0000FFC6
  GDK_KEY_F10* = 0x0000FFC7
  GDK_KEY_F11* = 0x0000FFC8
  GDK_KEY_L1* = 0x0000FFC8
  GDK_KEY_F12* = 0x0000FFC9
  GDK_KEY_L2* = 0x0000FFC9
  GDK_KEY_F13* = 0x0000FFCA
  GDK_KEY_L3* = 0x0000FFCA
  GDK_KEY_F14* = 0x0000FFCB
  GDK_KEY_L4* = 0x0000FFCB
  GDK_KEY_F15* = 0x0000FFCC
  GDK_KEY_L5* = 0x0000FFCC
  GDK_KEY_F16* = 0x0000FFCD
  GDK_KEY_L6* = 0x0000FFCD
  GDK_KEY_F17* = 0x0000FFCE
  GDK_KEY_L7* = 0x0000FFCE
  GDK_KEY_F18* = 0x0000FFCF
  GDK_KEY_L8* = 0x0000FFCF
  GDK_KEY_F19* = 0x0000FFD0
  GDK_KEY_L9* = 0x0000FFD0
  GDK_KEY_F20* = 0x0000FFD1
  GDK_KEY_L10* = 0x0000FFD1
  GDK_KEY_F21* = 0x0000FFD2
  GDK_KEY_R1* = 0x0000FFD2
  GDK_KEY_F22* = 0x0000FFD3
  GDK_KEY_R2* = 0x0000FFD3
  GDK_KEY_F23* = 0x0000FFD4
  GDK_KEY_R3* = 0x0000FFD4
  GDK_KEY_F24* = 0x0000FFD5
  GDK_KEY_R4* = 0x0000FFD5
  GDK_KEY_F25* = 0x0000FFD6
  GDK_KEY_R5* = 0x0000FFD6
  GDK_KEY_F26* = 0x0000FFD7
  GDK_KEY_R6* = 0x0000FFD7
  GDK_KEY_F27* = 0x0000FFD8
  GDK_KEY_R7* = 0x0000FFD8
  GDK_KEY_F28* = 0x0000FFD9
  GDK_KEY_R8* = 0x0000FFD9
  GDK_KEY_F29* = 0x0000FFDA
  GDK_KEY_R9* = 0x0000FFDA
  GDK_KEY_F30* = 0x0000FFDB
  GDK_KEY_R10* = 0x0000FFDB
  GDK_KEY_F31* = 0x0000FFDC
  GDK_KEY_R11* = 0x0000FFDC
  GDK_KEY_F32* = 0x0000FFDD
  GDK_KEY_R12* = 0x0000FFDD
  GDK_KEY_F33* = 0x0000FFDE
  GDK_KEY_R13* = 0x0000FFDE
  GDK_KEY_F34* = 0x0000FFDF
  GDK_KEY_R14* = 0x0000FFDF
  GDK_KEY_F35* = 0x0000FFE0
  GDK_KEY_R15* = 0x0000FFE0
  GDK_KEY_Shift_L* = 0x0000FFE1
  GDK_KEY_Shift_R* = 0x0000FFE2
  GDK_KEY_Control_L* = 0x0000FFE3
  GDK_KEY_Control_R* = 0x0000FFE4
  GDK_KEY_Caps_Lock* = 0x0000FFE5
  GDK_KEY_Shift_Lock* = 0x0000FFE6
  GDK_KEY_Meta_L* = 0x0000FFE7
  GDK_KEY_Meta_R* = 0x0000FFE8
  GDK_KEY_Alt_L* = 0x0000FFE9
  GDK_KEY_Alt_R* = 0x0000FFEA
  GDK_KEY_Super_L* = 0x0000FFEB
  GDK_KEY_Super_R* = 0x0000FFEC
  GDK_KEY_Hyper_L* = 0x0000FFED
  GDK_KEY_Hyper_R* = 0x0000FFEE
  GDK_KEY_ISO_Lock* = 0x0000FE01
  GDK_KEY_ISO_Level2_Latch* = 0x0000FE02
  GDK_KEY_ISO_Level3_Shift* = 0x0000FE03
  GDK_KEY_ISO_Level3_Latch* = 0x0000FE04
  GDK_KEY_ISO_Level3_Lock* = 0x0000FE05
  GDK_KEY_ISO_Group_Shift* = 0x0000FF7E
  GDK_KEY_ISO_Group_Latch* = 0x0000FE06
  GDK_KEY_ISO_Group_Lock* = 0x0000FE07
  GDK_KEY_ISO_Next_Group* = 0x0000FE08
  GDK_KEY_ISO_Next_Group_Lock* = 0x0000FE09
  GDK_KEY_ISO_Prev_Group* = 0x0000FE0A
  GDK_KEY_ISO_Prev_Group_Lock* = 0x0000FE0B
  GDK_KEY_ISO_First_Group* = 0x0000FE0C
  GDK_KEY_ISO_First_Group_Lock* = 0x0000FE0D
  GDK_KEY_ISO_Last_Group* = 0x0000FE0E
  GDK_KEY_ISO_Last_Group_Lock* = 0x0000FE0F
  GDK_KEY_ISO_Left_Tab* = 0x0000FE20
  GDK_KEY_ISO_Move_Line_Up* = 0x0000FE21
  GDK_KEY_ISO_Move_Line_Down* = 0x0000FE22
  GDK_KEY_ISO_Partial_Line_Up* = 0x0000FE23
  GDK_KEY_ISO_Partial_Line_Down* = 0x0000FE24
  GDK_KEY_ISO_Partial_Space_Left* = 0x0000FE25
  GDK_KEY_ISO_Partial_Space_Right* = 0x0000FE26
  GDK_KEY_ISO_Set_Margin_Left* = 0x0000FE27
  GDK_KEY_ISO_Set_Margin_Right* = 0x0000FE28
  GDK_KEY_ISO_Release_Margin_Left* = 0x0000FE29
  GDK_KEY_ISO_Release_Margin_Right* = 0x0000FE2A
  GDK_KEY_ISO_Release_Both_Margins* = 0x0000FE2B
  GDK_KEY_ISO_Fast_Cursor_Left* = 0x0000FE2C
  GDK_KEY_ISO_Fast_Cursor_Right* = 0x0000FE2D
  GDK_KEY_ISO_Fast_Cursor_Up* = 0x0000FE2E
  GDK_KEY_ISO_Fast_Cursor_Down* = 0x0000FE2F
  GDK_KEY_ISO_Continuous_Underline* = 0x0000FE30
  GDK_KEY_ISO_Discontinuous_Underline* = 0x0000FE31
  GDK_KEY_ISO_Emphasize* = 0x0000FE32
  GDK_KEY_ISO_Center_Object* = 0x0000FE33
  GDK_KEY_ISO_Enter* = 0x0000FE34
  GDK_KEY_dead_grave* = 0x0000FE50
  GDK_KEY_dead_acute* = 0x0000FE51
  GDK_KEY_dead_circumflex* = 0x0000FE52
  GDK_KEY_dead_tilde* = 0x0000FE53
  GDK_KEY_dead_macron* = 0x0000FE54
  GDK_KEY_dead_breve* = 0x0000FE55
  GDK_KEY_dead_abovedot* = 0x0000FE56
  GDK_KEY_dead_diaeresis* = 0x0000FE57
  GDK_KEY_dead_abovering* = 0x0000FE58
  GDK_KEY_dead_doubleacute* = 0x0000FE59
  GDK_KEY_dead_caron* = 0x0000FE5A
  GDK_KEY_dead_cedilla* = 0x0000FE5B
  GDK_KEY_dead_ogonek* = 0x0000FE5C
  GDK_KEY_dead_iota* = 0x0000FE5D
  GDK_KEY_dead_voiced_sound* = 0x0000FE5E
  GDK_KEY_dead_semivoiced_sound* = 0x0000FE5F
  GDK_KEY_dead_belowdot* = 0x0000FE60
  GDK_KEY_First_Virtual_Screen* = 0x0000FED0
  GDK_KEY_Prev_Virtual_Screen* = 0x0000FED1
  GDK_KEY_Next_Virtual_Screen* = 0x0000FED2
  GDK_KEY_Last_Virtual_Screen* = 0x0000FED4
  GDK_KEY_Terminate_Server* = 0x0000FED5
  GDK_KEY_AccessX_Enable* = 0x0000FE70
  GDK_KEY_AccessX_Feedback_Enable* = 0x0000FE71
  GDK_KEY_RepeatKeys_Enable* = 0x0000FE72
  GDK_KEY_SlowKeys_Enable* = 0x0000FE73
  GDK_KEY_BounceKeys_Enable* = 0x0000FE74
  GDK_KEY_StickyKeys_Enable* = 0x0000FE75
  GDK_KEY_MouseKeys_Enable* = 0x0000FE76
  GDK_KEY_MouseKeys_Accel_Enable* = 0x0000FE77
  GDK_KEY_Overlay1_Enable* = 0x0000FE78
  GDK_KEY_Overlay2_Enable* = 0x0000FE79
  GDK_KEY_AudibleBell_Enable* = 0x0000FE7A
  GDK_KEY_Pointer_Left* = 0x0000FEE0
  GDK_KEY_Pointer_Right* = 0x0000FEE1
  GDK_KEY_Pointer_Up* = 0x0000FEE2
  GDK_KEY_Pointer_Down* = 0x0000FEE3
  GDK_KEY_Pointer_UpLeft* = 0x0000FEE4
  GDK_KEY_Pointer_UpRight* = 0x0000FEE5
  GDK_KEY_Pointer_DownLeft* = 0x0000FEE6
  GDK_KEY_Pointer_DownRight* = 0x0000FEE7
  GDK_KEY_Pointer_Button_Dflt* = 0x0000FEE8
  GDK_KEY_Pointer_Button1* = 0x0000FEE9
  GDK_KEY_Pointer_Button2* = 0x0000FEEA
  GDK_KEY_Pointer_Button3* = 0x0000FEEB
  GDK_KEY_Pointer_Button4* = 0x0000FEEC
  GDK_KEY_Pointer_Button5* = 0x0000FEED
  GDK_KEY_Pointer_DblClick_Dflt* = 0x0000FEEE
  GDK_KEY_Pointer_DblClick1* = 0x0000FEEF
  GDK_KEY_Pointer_DblClick2* = 0x0000FEF0
  GDK_KEY_Pointer_DblClick3* = 0x0000FEF1
  GDK_KEY_Pointer_DblClick4* = 0x0000FEF2
  GDK_KEY_Pointer_DblClick5* = 0x0000FEF3
  GDK_KEY_Pointer_Drag_Dflt* = 0x0000FEF4
  GDK_KEY_Pointer_Drag1* = 0x0000FEF5
  GDK_KEY_Pointer_Drag2* = 0x0000FEF6
  GDK_KEY_Pointer_Drag3* = 0x0000FEF7
  GDK_KEY_Pointer_Drag4* = 0x0000FEF8
  GDK_KEY_Pointer_Drag5* = 0x0000FEFD
  GDK_KEY_Pointer_EnableKeys* = 0x0000FEF9
  GDK_KEY_Pointer_Accelerate* = 0x0000FEFA
  GDK_KEY_Pointer_DfltBtnNext* = 0x0000FEFB
  GDK_KEY_Pointer_DfltBtnPrev* = 0x0000FEFC
  GDK_KEY_3270_Duplicate* = 0x0000FD01
  GDK_KEY_3270_FieldMark* = 0x0000FD02
  GDK_KEY_3270_Right2* = 0x0000FD03
  GDK_KEY_3270_Left2* = 0x0000FD04
  GDK_KEY_3270_BackTab* = 0x0000FD05
  GDK_KEY_3270_EraseEOF* = 0x0000FD06
  GDK_KEY_3270_EraseInput* = 0x0000FD07
  GDK_KEY_3270_Reset* = 0x0000FD08
  GDK_KEY_3270_Quit* = 0x0000FD09
  GDK_KEY_3270_PA1* = 0x0000FD0A
  GDK_KEY_3270_PA2* = 0x0000FD0B
  GDK_KEY_3270_PA3* = 0x0000FD0C
  GDK_KEY_3270_Test* = 0x0000FD0D
  GDK_KEY_3270_Attn* = 0x0000FD0E
  GDK_KEY_3270_CursorBlink* = 0x0000FD0F
  GDK_KEY_3270_AltCursor* = 0x0000FD10
  GDK_KEY_3270_KeyClick* = 0x0000FD11
  GDK_KEY_3270_Jump* = 0x0000FD12
  GDK_KEY_3270_Ident* = 0x0000FD13
  GDK_KEY_3270_Rule* = 0x0000FD14
  GDK_KEY_3270_Copy* = 0x0000FD15
  GDK_KEY_3270_Play* = 0x0000FD16
  GDK_KEY_3270_Setup* = 0x0000FD17
  GDK_KEY_3270_Record* = 0x0000FD18
  GDK_KEY_3270_ChangeScreen* = 0x0000FD19
  GDK_KEY_3270_DeleteWord* = 0x0000FD1A
  GDK_KEY_3270_ExSelect* = 0x0000FD1B
  GDK_KEY_3270_CursorSelect* = 0x0000FD1C
  GDK_KEY_3270_PrintScreen* = 0x0000FD1D
  GDK_KEY_3270_Enter* = 0x0000FD1E
  GDK_KEY_space* = 0x00000020
  GDK_KEY_exclam* = 0x00000021
  GDK_KEY_quotedbl* = 0x00000022
  GDK_KEY_numbersign* = 0x00000023
  GDK_KEY_dollar* = 0x00000024
  GDK_KEY_percent* = 0x00000025
  GDK_KEY_ampersand* = 0x00000026
  GDK_KEY_apostrophe* = 0x00000027
  GDK_KEY_quoteright* = 0x00000027
  GDK_KEY_parenleft* = 0x00000028
  GDK_KEY_parenright* = 0x00000029
  GDK_KEY_asterisk* = 0x0000002A
  GDK_KEY_plus* = 0x0000002B
  GDK_KEY_comma* = 0x0000002C
  GDK_KEY_minus* = 0x0000002D
  GDK_KEY_period* = 0x0000002E
  GDK_KEY_slash* = 0x0000002F
  GDK_KEY_0* = 0x00000030
  GDK_KEY_1* = 0x00000031
  GDK_KEY_2* = 0x00000032
  GDK_KEY_3* = 0x00000033
  GDK_KEY_4* = 0x00000034
  GDK_KEY_5* = 0x00000035
  GDK_KEY_6* = 0x00000036
  GDK_KEY_7* = 0x00000037
  GDK_KEY_8* = 0x00000038
  GDK_KEY_9* = 0x00000039
  GDK_KEY_colon* = 0x0000003A
  GDK_KEY_semicolon* = 0x0000003B
  GDK_KEY_less* = 0x0000003C
  GDK_KEY_equal* = 0x0000003D
  GDK_KEY_greater* = 0x0000003E
  GDK_KEY_question* = 0x0000003F
  GDK_KEY_at* = 0x00000040
  GDK_KEY_CAPITAL_A* = 0x00000041
  GDK_KEY_CAPITAL_B* = 0x00000042
  GDK_KEY_CAPITAL_C* = 0x00000043
  GDK_KEY_CAPITAL_D* = 0x00000044
  GDK_KEY_CAPITAL_E* = 0x00000045
  GDK_KEY_CAPITAL_F* = 0x00000046
  GDK_KEY_CAPITAL_G* = 0x00000047
  GDK_KEY_CAPITAL_H* = 0x00000048
  GDK_KEY_CAPITAL_I* = 0x00000049
  GDK_KEY_CAPITAL_J* = 0x0000004A
  GDK_KEY_CAPITAL_K* = 0x0000004B
  GDK_KEY_CAPITAL_L* = 0x0000004C
  GDK_KEY_CAPITAL_M* = 0x0000004D
  GDK_KEY_CAPITAL_N* = 0x0000004E
  GDK_KEY_CAPITAL_O* = 0x0000004F
  GDK_KEY_CAPITAL_P* = 0x00000050
  GDK_KEY_CAPITAL_Q* = 0x00000051
  GDK_KEY_CAPITAL_R* = 0x00000052
  GDK_KEY_CAPITAL_S* = 0x00000053
  GDK_KEY_CAPITAL_T* = 0x00000054
  GDK_KEY_CAPITAL_U* = 0x00000055
  GDK_KEY_CAPITAL_V* = 0x00000056
  GDK_KEY_CAPITAL_W* = 0x00000057
  GDK_KEY_CAPITAL_X* = 0x00000058
  GDK_KEY_CAPITAL_Y* = 0x00000059
  GDK_KEY_CAPITAL_Z* = 0x0000005A
  GDK_KEY_bracketleft* = 0x0000005B
  GDK_KEY_backslash* = 0x0000005C
  GDK_KEY_bracketright* = 0x0000005D
  GDK_KEY_asciicircum* = 0x0000005E
  GDK_KEY_underscore* = 0x0000005F
  GDK_KEY_grave* = 0x00000060
  GDK_KEY_quoteleft* = 0x00000060
  GDK_KEY_a* = 0x00000061
  GDK_KEY_b* = 0x00000062
  GDK_KEY_c* = 0x00000063
  GDK_KEY_d* = 0x00000064
  GDK_KEY_e* = 0x00000065
  GDK_KEY_f* = 0x00000066
  GDK_KEY_g* = 0x00000067
  GDK_KEY_h* = 0x00000068
  GDK_KEY_i* = 0x00000069
  GDK_KEY_j* = 0x0000006A
  GDK_KEY_k* = 0x0000006B
  GDK_KEY_l* = 0x0000006C
  GDK_KEY_m* = 0x0000006D
  GDK_KEY_n* = 0x0000006E
  GDK_KEY_o* = 0x0000006F
  GDK_KEY_p* = 0x00000070
  GDK_KEY_q* = 0x00000071
  GDK_KEY_r* = 0x00000072
  GDK_KEY_s* = 0x00000073
  GDK_KEY_t* = 0x00000074
  GDK_KEY_u* = 0x00000075
  GDK_KEY_v* = 0x00000076
  GDK_KEY_w* = 0x00000077
  GDK_KEY_x* = 0x00000078
  GDK_KEY_y* = 0x00000079
  GDK_KEY_z* = 0x0000007A
  GDK_KEY_braceleft* = 0x0000007B
  GDK_KEY_bar* = 0x0000007C
  GDK_KEY_braceright* = 0x0000007D
  GDK_KEY_asciitilde* = 0x0000007E
  GDK_KEY_nobreakspace* = 0x000000A0
  GDK_KEY_exclamdown* = 0x000000A1
  GDK_KEY_cent* = 0x000000A2
  GDK_KEY_sterling* = 0x000000A3
  GDK_KEY_currency* = 0x000000A4
  GDK_KEY_yen* = 0x000000A5
  GDK_KEY_brokenbar* = 0x000000A6
  GDK_KEY_section* = 0x000000A7
  GDK_KEY_diaeresis* = 0x000000A8
  GDK_KEY_copyright* = 0x000000A9
  GDK_KEY_ordfeminine* = 0x000000AA
  GDK_KEY_guillemotleft* = 0x000000AB
  GDK_KEY_notsign* = 0x000000AC
  GDK_KEY_hyphen* = 0x000000AD
  GDK_KEY_registered* = 0x000000AE
  GDK_KEY_macron* = 0x000000AF
  GDK_KEY_degree* = 0x000000B0
  GDK_KEY_plusminus* = 0x000000B1
  GDK_KEY_twosuperior* = 0x000000B2
  GDK_KEY_threesuperior* = 0x000000B3
  GDK_KEY_acute* = 0x000000B4
  GDK_KEY_mu* = 0x000000B5
  GDK_KEY_paragraph* = 0x000000B6
  GDK_KEY_periodcentered* = 0x000000B7
  GDK_KEY_cedilla* = 0x000000B8
  GDK_KEY_onesuperior* = 0x000000B9
  GDK_KEY_masculine* = 0x000000BA
  GDK_KEY_guillemotright* = 0x000000BB
  GDK_KEY_onequarter* = 0x000000BC
  GDK_KEY_onehalf* = 0x000000BD
  GDK_KEY_threequarters* = 0x000000BE
  GDK_KEY_questiondown* = 0x000000BF
  GDK_KEY_CAPITAL_Agrave* = 0x000000C0
  GDK_KEY_CAPITAL_Aacute* = 0x000000C1
  GDK_KEY_CAPITAL_Acircumflex* = 0x000000C2
  GDK_KEY_CAPITAL_Atilde* = 0x000000C3
  GDK_KEY_CAPITAL_Adiaeresis* = 0x000000C4
  GDK_KEY_CAPITAL_Aring* = 0x000000C5
  GDK_KEY_CAPITAL_AE* = 0x000000C6
  GDK_KEY_CAPITAL_Ccedilla* = 0x000000C7
  GDK_KEY_CAPITAL_Egrave* = 0x000000C8
  GDK_KEY_CAPITAL_Eacute* = 0x000000C9
  GDK_KEY_CAPITAL_Ecircumflex* = 0x000000CA
  GDK_KEY_CAPITAL_Ediaeresis* = 0x000000CB
  GDK_KEY_CAPITAL_Igrave* = 0x000000CC
  GDK_KEY_CAPITAL_Iacute* = 0x000000CD
  GDK_KEY_CAPITAL_Icircumflex* = 0x000000CE
  GDK_KEY_CAPITAL_Idiaeresis* = 0x000000CF
  GDK_KEY_CAPITAL_ETH* = 0x000000D0
  GDK_KEY_CAPITAL_Ntilde* = 0x000000D1
  GDK_KEY_CAPITAL_Ograve* = 0x000000D2
  GDK_KEY_CAPITAL_Oacute* = 0x000000D3
  GDK_KEY_CAPITAL_Ocircumflex* = 0x000000D4
  GDK_KEY_CAPITAL_Otilde* = 0x000000D5
  GDK_KEY_CAPITAL_Odiaeresis* = 0x000000D6
  GDK_KEY_multiply* = 0x000000D7
  GDK_KEY_Ooblique* = 0x000000D8
  GDK_KEY_CAPITAL_Ugrave* = 0x000000D9
  GDK_KEY_CAPITAL_Uacute* = 0x000000DA
  GDK_KEY_CAPITAL_Ucircumflex* = 0x000000DB
  GDK_KEY_CAPITAL_Udiaeresis* = 0x000000DC
  GDK_KEY_CAPITAL_Yacute* = 0x000000DD
  GDK_KEY_CAPITAL_THORN* = 0x000000DE
  GDK_KEY_ssharp* = 0x000000DF
  GDK_KEY_agrave* = 0x000000E0
  GDK_KEY_aacute* = 0x000000E1
  GDK_KEY_acircumflex* = 0x000000E2
  GDK_KEY_atilde* = 0x000000E3
  GDK_KEY_adiaeresis* = 0x000000E4
  GDK_KEY_aring* = 0x000000E5
  GDK_KEY_ae* = 0x000000E6
  GDK_KEY_ccedilla* = 0x000000E7
  GDK_KEY_egrave* = 0x000000E8
  GDK_KEY_eacute* = 0x000000E9
  GDK_KEY_ecircumflex* = 0x000000EA
  GDK_KEY_ediaeresis* = 0x000000EB
  GDK_KEY_igrave* = 0x000000EC
  GDK_KEY_iacute* = 0x000000ED
  GDK_KEY_icircumflex* = 0x000000EE
  GDK_KEY_idiaeresis* = 0x000000EF
  GDK_KEY_eth* = 0x000000F0
  GDK_KEY_ntilde* = 0x000000F1
  GDK_KEY_ograve* = 0x000000F2
  GDK_KEY_oacute* = 0x000000F3
  GDK_KEY_ocircumflex* = 0x000000F4
  GDK_KEY_otilde* = 0x000000F5
  GDK_KEY_odiaeresis* = 0x000000F6
  GDK_KEY_division* = 0x000000F7
  GDK_KEY_oslash* = 0x000000F8
  GDK_KEY_ugrave* = 0x000000F9
  GDK_KEY_uacute* = 0x000000FA
  GDK_KEY_ucircumflex* = 0x000000FB
  GDK_KEY_udiaeresis* = 0x000000FC
  GDK_KEY_yacute* = 0x000000FD
  GDK_KEY_thorn* = 0x000000FE
  GDK_KEY_ydiaeresis* = 0x000000FF
  GDK_KEY_CAPITAL_Aogonek* = 0x000001A1
  GDK_KEY_breve* = 0x000001A2
  GDK_KEY_CAPITAL_Lstroke* = 0x000001A3
  GDK_KEY_CAPITAL_Lcaron* = 0x000001A5
  GDK_KEY_CAPITAL_Sacute* = 0x000001A6
  GDK_KEY_CAPITAL_Scaron* = 0x000001A9
  GDK_KEY_CAPITAL_Scedilla* = 0x000001AA
  GDK_KEY_CAPITAL_Tcaron* = 0x000001AB
  GDK_KEY_CAPITAL_Zacute* = 0x000001AC
  GDK_KEY_CAPITAL_Zcaron* = 0x000001AE
  GDK_KEY_CAPITAL_Zabovedot* = 0x000001AF
  GDK_KEY_aogonek* = 0x000001B1
  GDK_KEY_ogonek* = 0x000001B2
  GDK_KEY_lstroke* = 0x000001B3
  GDK_KEY_lcaron* = 0x000001B5
  GDK_KEY_sacute* = 0x000001B6
  GDK_KEY_caron* = 0x000001B7
  GDK_KEY_scaron* = 0x000001B9
  GDK_KEY_scedilla* = 0x000001BA
  GDK_KEY_tcaron* = 0x000001BB
  GDK_KEY_zacute* = 0x000001BC
  GDK_KEY_doubleacute* = 0x000001BD
  GDK_KEY_zcaron* = 0x000001BE
  GDK_KEY_zabovedot* = 0x000001BF
  GDK_KEY_CAPITAL_Racute* = 0x000001C0
  GDK_KEY_CAPITAL_Abreve* = 0x000001C3
  GDK_KEY_CAPITAL_Lacute* = 0x000001C5
  GDK_KEY_CAPITAL_Cacute* = 0x000001C6
  GDK_KEY_CAPITAL_Ccaron* = 0x000001C8
  GDK_KEY_CAPITAL_Eogonek* = 0x000001CA
  GDK_KEY_CAPITAL_Ecaron* = 0x000001CC
  GDK_KEY_CAPITAL_Dcaron* = 0x000001CF
  GDK_KEY_CAPITAL_Dstroke* = 0x000001D0
  GDK_KEY_CAPITAL_Nacute* = 0x000001D1
  GDK_KEY_CAPITAL_Ncaron* = 0x000001D2
  GDK_KEY_CAPITAL_Odoubleacute* = 0x000001D5
  GDK_KEY_CAPITAL_Rcaron* = 0x000001D8
  GDK_KEY_CAPITAL_Uring* = 0x000001D9
  GDK_KEY_CAPITAL_Udoubleacute* = 0x000001DB
  GDK_KEY_CAPITAL_Tcedilla* = 0x000001DE
  GDK_KEY_racute* = 0x000001E0
  GDK_KEY_abreve* = 0x000001E3
  GDK_KEY_lacute* = 0x000001E5
  GDK_KEY_cacute* = 0x000001E6
  GDK_KEY_ccaron* = 0x000001E8
  GDK_KEY_eogonek* = 0x000001EA
  GDK_KEY_ecaron* = 0x000001EC
  GDK_KEY_dcaron* = 0x000001EF
  GDK_KEY_dstroke* = 0x000001F0
  GDK_KEY_nacute* = 0x000001F1
  GDK_KEY_ncaron* = 0x000001F2
  GDK_KEY_odoubleacute* = 0x000001F5
  GDK_KEY_udoubleacute* = 0x000001FB
  GDK_KEY_rcaron* = 0x000001F8
  GDK_KEY_uring* = 0x000001F9
  GDK_KEY_tcedilla* = 0x000001FE
  GDK_KEY_abovedot* = 0x000001FF
  GDK_KEY_CAPITAL_Hstroke* = 0x000002A1
  GDK_KEY_CAPITAL_Hcircumflex* = 0x000002A6
  GDK_KEY_CAPITAL_Iabovedot* = 0x000002A9
  GDK_KEY_CAPITAL_Gbreve* = 0x000002AB
  GDK_KEY_CAPITAL_Jcircumflex* = 0x000002AC
  GDK_KEY_hstroke* = 0x000002B1
  GDK_KEY_hcircumflex* = 0x000002B6
  GDK_KEY_idotless* = 0x000002B9
  GDK_KEY_gbreve* = 0x000002BB
  GDK_KEY_jcircumflex* = 0x000002BC
  GDK_KEY_CAPITAL_Cabovedot* = 0x000002C5
  GDK_KEY_CAPITAL_Ccircumflex* = 0x000002C6
  GDK_KEY_CAPITAL_Gabovedot* = 0x000002D5
  GDK_KEY_CAPITAL_Gcircumflex* = 0x000002D8
  GDK_KEY_CAPITAL_Ubreve* = 0x000002DD
  GDK_KEY_CAPITAL_Scircumflex* = 0x000002DE
  GDK_KEY_cabovedot* = 0x000002E5
  GDK_KEY_ccircumflex* = 0x000002E6
  GDK_KEY_gabovedot* = 0x000002F5
  GDK_KEY_gcircumflex* = 0x000002F8
  GDK_KEY_ubreve* = 0x000002FD
  GDK_KEY_scircumflex* = 0x000002FE
  GDK_KEY_kra* = 0x000003A2
  GDK_KEY_kappa* = 0x000003A2
  GDK_KEY_CAPITAL_Rcedilla* = 0x000003A3
  GDK_KEY_CAPITAL_Itilde* = 0x000003A5
  GDK_KEY_CAPITAL_Lcedilla* = 0x000003A6
  GDK_KEY_CAPITAL_Emacron* = 0x000003AA
  GDK_KEY_CAPITAL_Gcedilla* = 0x000003AB
  GDK_KEY_CAPITAL_Tslash* = 0x000003AC
  GDK_KEY_rcedilla* = 0x000003B3
  GDK_KEY_itilde* = 0x000003B5
  GDK_KEY_lcedilla* = 0x000003B6
  GDK_KEY_emacron* = 0x000003BA
  GDK_KEY_gcedilla* = 0x000003BB
  GDK_KEY_tslash* = 0x000003BC
  GDK_KEY_CAPITAL_ENG* = 0x000003BD
  GDK_KEY_eng* = 0x000003BF
  GDK_KEY_CAPITAL_Amacron* = 0x000003C0
  GDK_KEY_CAPITAL_Iogonek* = 0x000003C7
  GDK_KEY_CAPITAL_Eabovedot* = 0x000003CC
  GDK_KEY_CAPITAL_Imacron* = 0x000003CF
  GDK_KEY_CAPITAL_Ncedilla* = 0x000003D1
  GDK_KEY_CAPITAL_Omacron* = 0x000003D2
  GDK_KEY_CAPITAL_Kcedilla* = 0x000003D3
  GDK_KEY_CAPITAL_Uogonek* = 0x000003D9
  GDK_KEY_CAPITAL_Utilde* = 0x000003DD
  GDK_KEY_CAPITAL_Umacron* = 0x000003DE
  GDK_KEY_amacron* = 0x000003E0
  GDK_KEY_iogonek* = 0x000003E7
  GDK_KEY_eabovedot* = 0x000003EC
  GDK_KEY_imacron* = 0x000003EF
  GDK_KEY_ncedilla* = 0x000003F1
  GDK_KEY_omacron* = 0x000003F2
  GDK_KEY_kcedilla* = 0x000003F3
  GDK_KEY_uogonek* = 0x000003F9
  GDK_KEY_utilde* = 0x000003FD
  GDK_KEY_umacron* = 0x000003FE
  GDK_KEY_CAPITAL_OE* = 0x000013BC
  GDK_KEY_oe* = 0x000013BD
  GDK_KEY_CAPITAL_Ydiaeresis* = 0x000013BE
  GDK_KEY_overline* = 0x0000047E
  GDK_KEY_kana_fullstop* = 0x000004A1
  GDK_KEY_kana_openingbracket* = 0x000004A2
  GDK_KEY_kana_closingbracket* = 0x000004A3
  GDK_KEY_kana_comma* = 0x000004A4
  GDK_KEY_kana_conjunctive* = 0x000004A5
  GDK_KEY_kana_middledot* = 0x000004A5
  GDK_KEY_kana_WO* = 0x000004A6
  GDK_KEY_kana_a* = 0x000004A7
  GDK_KEY_kana_i* = 0x000004A8
  GDK_KEY_kana_u* = 0x000004A9
  GDK_KEY_kana_e* = 0x000004AA
  GDK_KEY_kana_o* = 0x000004AB
  GDK_KEY_kana_ya* = 0x000004AC
  GDK_KEY_kana_yu* = 0x000004AD
  GDK_KEY_kana_yo* = 0x000004AE
  GDK_KEY_kana_tsu* = 0x000004AF
  GDK_KEY_kana_tu* = 0x000004AF
  GDK_KEY_prolongedsound* = 0x000004B0
  GDK_KEY_kana_CAPITAL_A* = 0x000004B1
  GDK_KEY_kana_CAPITAL_I* = 0x000004B2
  GDK_KEY_kana_CAPITAL_U* = 0x000004B3
  GDK_KEY_kana_CAPITAL_E* = 0x000004B4
  GDK_KEY_kana_CAPITAL_O* = 0x000004B5
  GDK_KEY_kana_KA* = 0x000004B6
  GDK_KEY_kana_KI* = 0x000004B7
  GDK_KEY_kana_KU* = 0x000004B8
  GDK_KEY_kana_KE* = 0x000004B9
  GDK_KEY_kana_KO* = 0x000004BA
  GDK_KEY_kana_SA* = 0x000004BB
  GDK_KEY_kana_SHI* = 0x000004BC
  GDK_KEY_kana_SU* = 0x000004BD
  GDK_KEY_kana_SE* = 0x000004BE
  GDK_KEY_kana_SO* = 0x000004BF
  GDK_KEY_kana_TA* = 0x000004C0
  GDK_KEY_kana_CHI* = 0x000004C1
  GDK_KEY_kana_TI* = 0x000004C1
  GDK_KEY_kana_CAPITAL_TSU* = 0x000004C2
  GDK_KEY_kana_CAPITAL_TU* = 0x000004C2
  GDK_KEY_kana_TE* = 0x000004C3
  GDK_KEY_kana_TO* = 0x000004C4
  GDK_KEY_kana_NA* = 0x000004C5
  GDK_KEY_kana_NI* = 0x000004C6
  GDK_KEY_kana_NU* = 0x000004C7
  GDK_KEY_kana_NE* = 0x000004C8
  GDK_KEY_kana_NO* = 0x000004C9
  GDK_KEY_kana_HA* = 0x000004CA
  GDK_KEY_kana_HI* = 0x000004CB
  GDK_KEY_kana_FU* = 0x000004CC
  GDK_KEY_kana_HU* = 0x000004CC
  GDK_KEY_kana_HE* = 0x000004CD
  GDK_KEY_kana_HO* = 0x000004CE
  GDK_KEY_kana_MA* = 0x000004CF
  GDK_KEY_kana_MI* = 0x000004D0
  GDK_KEY_kana_MU* = 0x000004D1
  GDK_KEY_kana_ME* = 0x000004D2
  GDK_KEY_kana_MO* = 0x000004D3
  GDK_KEY_kana_CAPITAL_YA* = 0x000004D4
  GDK_KEY_kana_CAPITAL_YU* = 0x000004D5
  GDK_KEY_kana_CAPITAL_YO* = 0x000004D6
  GDK_KEY_kana_RA* = 0x000004D7
  GDK_KEY_kana_RI* = 0x000004D8
  GDK_KEY_kana_RU* = 0x000004D9
  GDK_KEY_kana_RE* = 0x000004DA
  GDK_KEY_kana_RO* = 0x000004DB
  GDK_KEY_kana_WA* = 0x000004DC
  GDK_KEY_kana_N* = 0x000004DD
  GDK_KEY_voicedsound* = 0x000004DE
  GDK_KEY_semivoicedsound* = 0x000004DF
  GDK_KEY_kana_switch* = 0x0000FF7E
  GDK_KEY_Arabic_comma* = 0x000005AC
  GDK_KEY_Arabic_semicolon* = 0x000005BB
  GDK_KEY_Arabic_question_mark* = 0x000005BF
  GDK_KEY_Arabic_hamza* = 0x000005C1
  GDK_KEY_Arabic_maddaonalef* = 0x000005C2
  GDK_KEY_Arabic_hamzaonalef* = 0x000005C3
  GDK_KEY_Arabic_hamzaonwaw* = 0x000005C4
  GDK_KEY_Arabic_hamzaunderalef* = 0x000005C5
  GDK_KEY_Arabic_hamzaonyeh* = 0x000005C6
  GDK_KEY_Arabic_alef* = 0x000005C7
  GDK_KEY_Arabic_beh* = 0x000005C8
  GDK_KEY_Arabic_tehmarbuta* = 0x000005C9
  GDK_KEY_Arabic_teh* = 0x000005CA
  GDK_KEY_Arabic_theh* = 0x000005CB
  GDK_KEY_Arabic_jeem* = 0x000005CC
  GDK_KEY_Arabic_hah* = 0x000005CD
  GDK_KEY_Arabic_khah* = 0x000005CE
  GDK_KEY_Arabic_dal* = 0x000005CF
  GDK_KEY_Arabic_thal* = 0x000005D0
  GDK_KEY_Arabic_ra* = 0x000005D1
  GDK_KEY_Arabic_zain* = 0x000005D2
  GDK_KEY_Arabic_seen* = 0x000005D3
  GDK_KEY_Arabic_sheen* = 0x000005D4
  GDK_KEY_Arabic_sad* = 0x000005D5
  GDK_KEY_Arabic_dad* = 0x000005D6
  GDK_KEY_Arabic_tah* = 0x000005D7
  GDK_KEY_Arabic_zah* = 0x000005D8
  GDK_KEY_Arabic_ain* = 0x000005D9
  GDK_KEY_Arabic_ghain* = 0x000005DA
  GDK_KEY_Arabic_tatweel* = 0x000005E0
  GDK_KEY_Arabic_feh* = 0x000005E1
  GDK_KEY_Arabic_qaf* = 0x000005E2
  GDK_KEY_Arabic_kaf* = 0x000005E3
  GDK_KEY_Arabic_lam* = 0x000005E4
  GDK_KEY_Arabic_meem* = 0x000005E5
  GDK_KEY_Arabic_noon* = 0x000005E6
  GDK_KEY_Arabic_ha* = 0x000005E7
  GDK_KEY_Arabic_heh* = 0x000005E7
  GDK_KEY_Arabic_waw* = 0x000005E8
  GDK_KEY_Arabic_alefmaksura* = 0x000005E9
  GDK_KEY_Arabic_yeh* = 0x000005EA
  GDK_KEY_Arabic_fathatan* = 0x000005EB
  GDK_KEY_Arabic_dammatan* = 0x000005EC
  GDK_KEY_Arabic_kasratan* = 0x000005ED
  GDK_KEY_Arabic_fatha* = 0x000005EE
  GDK_KEY_Arabic_damma* = 0x000005EF
  GDK_KEY_Arabic_kasra* = 0x000005F0
  GDK_KEY_Arabic_shadda* = 0x000005F1
  GDK_KEY_Arabic_sukun* = 0x000005F2
  GDK_KEY_Arabic_switch* = 0x0000FF7E
  GDK_KEY_Serbian_dje* = 0x000006A1
  GDK_KEY_Macedonia_gje* = 0x000006A2
  GDK_KEY_Cyrillic_io* = 0x000006A3
  GDK_KEY_Ukrainian_ie* = 0x000006A4
  GDK_KEY_Ukranian_je* = 0x000006A4
  GDK_KEY_Macedonia_dse* = 0x000006A5
  GDK_KEY_Ukrainian_i* = 0x000006A6
  GDK_KEY_Ukranian_i* = 0x000006A6
  GDK_KEY_Ukrainian_yi* = 0x000006A7
  GDK_KEY_Ukranian_yi* = 0x000006A7
  GDK_KEY_Cyrillic_je* = 0x000006A8
  GDK_KEY_Serbian_je* = 0x000006A8
  GDK_KEY_Cyrillic_lje* = 0x000006A9
  GDK_KEY_Serbian_lje* = 0x000006A9
  GDK_KEY_Cyrillic_nje* = 0x000006AA
  GDK_KEY_Serbian_nje* = 0x000006AA
  GDK_KEY_Serbian_tshe* = 0x000006AB
  GDK_KEY_Macedonia_kje* = 0x000006AC
  GDK_KEY_Byelorussian_shortu* = 0x000006AE
  GDK_KEY_Cyrillic_dzhe* = 0x000006AF
  GDK_KEY_Serbian_dze* = 0x000006AF
  GDK_KEY_numerosign* = 0x000006B0
  GDK_KEY_Serbian_CAPITAL_DJE* = 0x000006B1
  GDK_KEY_Macedonia_CAPITAL_GJE* = 0x000006B2
  GDK_KEY_Cyrillic_CAPITAL_IO* = 0x000006B3
  GDK_KEY_Ukrainian_CAPITAL_IE* = 0x000006B4
  GDK_KEY_Ukranian_CAPITAL_JE* = 0x000006B4
  GDK_KEY_Macedonia_CAPITAL_DSE* = 0x000006B5
  GDK_KEY_Ukrainian_CAPITAL_I* = 0x000006B6
  GDK_KEY_Ukranian_CAPITAL_I* = 0x000006B6
  GDK_KEY_Ukrainian_CAPITAL_YI* = 0x000006B7
  GDK_KEY_Ukranian_CAPITAL_YI* = 0x000006B7
  GDK_KEY_Cyrillic_CAPITAL_JE* = 0x000006B8
  GDK_KEY_Serbian_CAPITAL_JE* = 0x000006B8
  GDK_KEY_Cyrillic_CAPITAL_LJE* = 0x000006B9
  GDK_KEY_Serbian_CAPITAL_LJE* = 0x000006B9
  GDK_KEY_Cyrillic_CAPITAL_NJE* = 0x000006BA
  GDK_KEY_Serbian_CAPITAL_NJE* = 0x000006BA
  GDK_KEY_Serbian_CAPITAL_TSHE* = 0x000006BB
  GDK_KEY_Macedonia_CAPITAL_KJE* = 0x000006BC
  GDK_KEY_Byelorussian_CAPITAL_SHORTU* = 0x000006BE
  GDK_KEY_Cyrillic_CAPITAL_DZHE* = 0x000006BF
  GDK_KEY_Serbian_CAPITAL_DZE* = 0x000006BF
  GDK_KEY_Cyrillic_yu* = 0x000006C0
  GDK_KEY_Cyrillic_a* = 0x000006C1
  GDK_KEY_Cyrillic_be* = 0x000006C2
  GDK_KEY_Cyrillic_tse* = 0x000006C3
  GDK_KEY_Cyrillic_de* = 0x000006C4
  GDK_KEY_Cyrillic_ie* = 0x000006C5
  GDK_KEY_Cyrillic_ef* = 0x000006C6
  GDK_KEY_Cyrillic_ghe* = 0x000006C7
  GDK_KEY_Cyrillic_ha* = 0x000006C8
  GDK_KEY_Cyrillic_i* = 0x000006C9
  GDK_KEY_Cyrillic_shorti* = 0x000006CA
  GDK_KEY_Cyrillic_ka* = 0x000006CB
  GDK_KEY_Cyrillic_el* = 0x000006CC
  GDK_KEY_Cyrillic_em* = 0x000006CD
  GDK_KEY_Cyrillic_en* = 0x000006CE
  GDK_KEY_Cyrillic_o* = 0x000006CF
  GDK_KEY_Cyrillic_pe* = 0x000006D0
  GDK_KEY_Cyrillic_ya* = 0x000006D1
  GDK_KEY_Cyrillic_er* = 0x000006D2
  GDK_KEY_Cyrillic_es* = 0x000006D3
  GDK_KEY_Cyrillic_te* = 0x000006D4
  GDK_KEY_Cyrillic_u* = 0x000006D5
  GDK_KEY_Cyrillic_zhe* = 0x000006D6
  GDK_KEY_Cyrillic_ve* = 0x000006D7
  GDK_KEY_Cyrillic_softsign* = 0x000006D8
  GDK_KEY_Cyrillic_yeru* = 0x000006D9
  GDK_KEY_Cyrillic_ze* = 0x000006DA
  GDK_KEY_Cyrillic_sha* = 0x000006DB
  GDK_KEY_Cyrillic_e* = 0x000006DC
  GDK_KEY_Cyrillic_shcha* = 0x000006DD
  GDK_KEY_Cyrillic_che* = 0x000006DE
  GDK_KEY_Cyrillic_hardsign* = 0x000006DF
  GDK_KEY_Cyrillic_CAPITAL_YU* = 0x000006E0
  GDK_KEY_Cyrillic_CAPITAL_A* = 0x000006E1
  GDK_KEY_Cyrillic_CAPITAL_BE* = 0x000006E2
  GDK_KEY_Cyrillic_CAPITAL_TSE* = 0x000006E3
  GDK_KEY_Cyrillic_CAPITAL_DE* = 0x000006E4
  GDK_KEY_Cyrillic_CAPITAL_IE* = 0x000006E5
  GDK_KEY_Cyrillic_CAPITAL_EF* = 0x000006E6
  GDK_KEY_Cyrillic_CAPITAL_GHE* = 0x000006E7
  GDK_KEY_Cyrillic_CAPITAL_HA* = 0x000006E8
  GDK_KEY_Cyrillic_CAPITAL_I* = 0x000006E9
  GDK_KEY_Cyrillic_CAPITAL_SHORTI* = 0x000006EA
  GDK_KEY_Cyrillic_CAPITAL_KA* = 0x000006EB
  GDK_KEY_Cyrillic_CAPITAL_EL* = 0x000006EC
  GDK_KEY_Cyrillic_CAPITAL_EM* = 0x000006ED
  GDK_KEY_Cyrillic_CAPITAL_EN* = 0x000006EE
  GDK_KEY_Cyrillic_CAPITAL_O* = 0x000006EF
  GDK_KEY_Cyrillic_CAPITAL_PE* = 0x000006F0
  GDK_KEY_Cyrillic_CAPITAL_YA* = 0x000006F1
  GDK_KEY_Cyrillic_CAPITAL_ER* = 0x000006F2
  GDK_KEY_Cyrillic_CAPITAL_ES* = 0x000006F3
  GDK_KEY_Cyrillic_CAPITAL_TE* = 0x000006F4
  GDK_KEY_Cyrillic_CAPITAL_U* = 0x000006F5
  GDK_KEY_Cyrillic_CAPITAL_ZHE* = 0x000006F6
  GDK_KEY_Cyrillic_CAPITAL_VE* = 0x000006F7
  GDK_KEY_Cyrillic_CAPITAL_SOFTSIGN* = 0x000006F8
  GDK_KEY_Cyrillic_CAPITAL_YERU* = 0x000006F9
  GDK_KEY_Cyrillic_CAPITAL_ZE* = 0x000006FA
  GDK_KEY_Cyrillic_CAPITAL_SHA* = 0x000006FB
  GDK_KEY_Cyrillic_CAPITAL_E* = 0x000006FC
  GDK_KEY_Cyrillic_CAPITAL_SHCHA* = 0x000006FD
  GDK_KEY_Cyrillic_CAPITAL_CHE* = 0x000006FE
  GDK_KEY_Cyrillic_CAPITAL_HARDSIGN* = 0x000006FF
  GDK_KEY_Greek_CAPITAL_ALPHAaccent* = 0x000007A1
  GDK_KEY_Greek_CAPITAL_EPSILONaccent* = 0x000007A2
  GDK_KEY_Greek_CAPITAL_ETAaccent* = 0x000007A3
  GDK_KEY_Greek_CAPITAL_IOTAaccent* = 0x000007A4
  GDK_KEY_Greek_CAPITAL_IOTAdiaeresis* = 0x000007A5
  GDK_KEY_Greek_CAPITAL_OMICRONaccent* = 0x000007A7
  GDK_KEY_Greek_CAPITAL_UPSILONaccent* = 0x000007A8
  GDK_KEY_Greek_CAPITAL_UPSILONdieresis* = 0x000007A9
  GDK_KEY_Greek_CAPITAL_OMEGAaccent* = 0x000007AB
  GDK_KEY_Greek_accentdieresis* = 0x000007AE
  GDK_KEY_Greek_horizbar* = 0x000007AF
  GDK_KEY_Greek_alphaaccent* = 0x000007B1
  GDK_KEY_Greek_epsilonaccent* = 0x000007B2
  GDK_KEY_Greek_etaaccent* = 0x000007B3
  GDK_KEY_Greek_iotaaccent* = 0x000007B4
  GDK_KEY_Greek_iotadieresis* = 0x000007B5
  GDK_KEY_Greek_iotaaccentdieresis* = 0x000007B6
  GDK_KEY_Greek_omicronaccent* = 0x000007B7
  GDK_KEY_Greek_upsilonaccent* = 0x000007B8
  GDK_KEY_Greek_upsilondieresis* = 0x000007B9
  GDK_KEY_Greek_upsilonaccentdieresis* = 0x000007BA
  GDK_KEY_Greek_omegaaccent* = 0x000007BB
  GDK_KEY_Greek_CAPITAL_ALPHA* = 0x000007C1
  GDK_KEY_Greek_CAPITAL_BETA* = 0x000007C2
  GDK_KEY_Greek_CAPITAL_GAMMA* = 0x000007C3
  GDK_KEY_Greek_CAPITAL_DELTA* = 0x000007C4
  GDK_KEY_Greek_CAPITAL_EPSILON* = 0x000007C5
  GDK_KEY_Greek_CAPITAL_ZETA* = 0x000007C6
  GDK_KEY_Greek_CAPITAL_ETA* = 0x000007C7
  GDK_KEY_Greek_CAPITAL_THETA* = 0x000007C8
  GDK_KEY_Greek_CAPITAL_IOTA* = 0x000007C9
  GDK_KEY_Greek_CAPITAL_KAPPA* = 0x000007CA
  GDK_KEY_Greek_CAPITAL_LAMDA* = 0x000007CB
  GDK_KEY_Greek_CAPITAL_LAMBDA* = 0x000007CB
  GDK_KEY_Greek_CAPITAL_MU* = 0x000007CC
  GDK_KEY_Greek_CAPITAL_NU* = 0x000007CD
  GDK_KEY_Greek_CAPITAL_XI* = 0x000007CE
  GDK_KEY_Greek_CAPITAL_OMICRON* = 0x000007CF
  GDK_KEY_Greek_CAPITAL_PI* = 0x000007D0
  GDK_KEY_Greek_CAPITAL_RHO* = 0x000007D1
  GDK_KEY_Greek_CAPITAL_SIGMA* = 0x000007D2
  GDK_KEY_Greek_CAPITAL_TAU* = 0x000007D4
  GDK_KEY_Greek_CAPITAL_UPSILON* = 0x000007D5
  GDK_KEY_Greek_CAPITAL_PHI* = 0x000007D6
  GDK_KEY_Greek_CAPITAL_CHI* = 0x000007D7
  GDK_KEY_Greek_CAPITAL_PSI* = 0x000007D8
  GDK_KEY_Greek_CAPITAL_OMEGA* = 0x000007D9
  GDK_KEY_Greek_alpha* = 0x000007E1
  GDK_KEY_Greek_beta* = 0x000007E2
  GDK_KEY_Greek_gamma* = 0x000007E3
  GDK_KEY_Greek_delta* = 0x000007E4
  GDK_KEY_Greek_epsilon* = 0x000007E5
  GDK_KEY_Greek_zeta* = 0x000007E6
  GDK_KEY_Greek_eta* = 0x000007E7
  GDK_KEY_Greek_theta* = 0x000007E8
  GDK_KEY_Greek_iota* = 0x000007E9
  GDK_KEY_Greek_kappa* = 0x000007EA
  GDK_KEY_Greek_lamda* = 0x000007EB
  GDK_KEY_Greek_lambda* = 0x000007EB
  GDK_KEY_Greek_mu* = 0x000007EC
  GDK_KEY_Greek_nu* = 0x000007ED
  GDK_KEY_Greek_xi* = 0x000007EE
  GDK_KEY_Greek_omicron* = 0x000007EF
  GDK_KEY_Greek_pi* = 0x000007F0
  GDK_KEY_Greek_rho* = 0x000007F1
  GDK_KEY_Greek_sigma* = 0x000007F2
  GDK_KEY_Greek_finalsmallsigma* = 0x000007F3
  GDK_KEY_Greek_tau* = 0x000007F4
  GDK_KEY_Greek_upsilon* = 0x000007F5
  GDK_KEY_Greek_phi* = 0x000007F6
  GDK_KEY_Greek_chi* = 0x000007F7
  GDK_KEY_Greek_psi* = 0x000007F8
  GDK_KEY_Greek_omega* = 0x000007F9
  GDK_KEY_Greek_switch* = 0x0000FF7E
  GDK_KEY_leftradical* = 0x000008A1
  GDK_KEY_topleftradical* = 0x000008A2
  GDK_KEY_horizconnector* = 0x000008A3
  GDK_KEY_topintegral* = 0x000008A4
  GDK_KEY_botintegral* = 0x000008A5
  GDK_KEY_vertconnector* = 0x000008A6
  GDK_KEY_topleftsqbracket* = 0x000008A7
  GDK_KEY_botleftsqbracket* = 0x000008A8
  GDK_KEY_toprightsqbracket* = 0x000008A9
  GDK_KEY_botrightsqbracket* = 0x000008AA
  GDK_KEY_topleftparens* = 0x000008AB
  GDK_KEY_botleftparens* = 0x000008AC
  GDK_KEY_toprightparens* = 0x000008AD
  GDK_KEY_botrightparens* = 0x000008AE
  GDK_KEY_leftmiddlecurlybrace* = 0x000008AF
  GDK_KEY_rightmiddlecurlybrace* = 0x000008B0
  GDK_KEY_topleftsummation* = 0x000008B1
  GDK_KEY_botleftsummation* = 0x000008B2
  GDK_KEY_topvertsummationconnector* = 0x000008B3
  GDK_KEY_botvertsummationconnector* = 0x000008B4
  GDK_KEY_toprightsummation* = 0x000008B5
  GDK_KEY_botrightsummation* = 0x000008B6
  GDK_KEY_rightmiddlesummation* = 0x000008B7
  GDK_KEY_lessthanequal* = 0x000008BC
  GDK_KEY_notequal* = 0x000008BD
  GDK_KEY_greaterthanequal* = 0x000008BE
  GDK_KEY_integral* = 0x000008BF
  GDK_KEY_therefore* = 0x000008C0
  GDK_KEY_variation* = 0x000008C1
  GDK_KEY_infinity* = 0x000008C2
  GDK_KEY_nabla* = 0x000008C5
  GDK_KEY_approximate* = 0x000008C8
  GDK_KEY_similarequal* = 0x000008C9
  GDK_KEY_ifonlyif* = 0x000008CD
  GDK_KEY_implies* = 0x000008CE
  GDK_KEY_identical* = 0x000008CF
  GDK_KEY_radical* = 0x000008D6
  GDK_KEY_includedin* = 0x000008DA
  GDK_KEY_includes* = 0x000008DB
  GDK_KEY_intersection* = 0x000008DC
  GDK_KEY_union* = 0x000008DD
  GDK_KEY_logicaland* = 0x000008DE
  GDK_KEY_logicalor* = 0x000008DF
  GDK_KEY_partialderivative* = 0x000008EF
  GDK_KEY_function* = 0x000008F6
  GDK_KEY_leftarrow* = 0x000008FB
  GDK_KEY_uparrow* = 0x000008FC
  GDK_KEY_rightarrow* = 0x000008FD
  GDK_KEY_downarrow* = 0x000008FE
  GDK_KEY_blank* = 0x000009DF
  GDK_KEY_soliddiamond* = 0x000009E0
  GDK_KEY_checkerboard* = 0x000009E1
  GDK_KEY_ht* = 0x000009E2
  GDK_KEY_ff* = 0x000009E3
  GDK_KEY_cr* = 0x000009E4
  GDK_KEY_lf* = 0x000009E5
  GDK_KEY_nl* = 0x000009E8
  GDK_KEY_vt* = 0x000009E9
  GDK_KEY_lowrightcorner* = 0x000009EA
  GDK_KEY_uprightcorner* = 0x000009EB
  GDK_KEY_upleftcorner* = 0x000009EC
  GDK_KEY_lowleftcorner* = 0x000009ED
  GDK_KEY_crossinglines* = 0x000009EE
  GDK_KEY_horizlinescan1* = 0x000009EF
  GDK_KEY_horizlinescan3* = 0x000009F0
  GDK_KEY_horizlinescan5* = 0x000009F1
  GDK_KEY_horizlinescan7* = 0x000009F2
  GDK_KEY_horizlinescan9* = 0x000009F3
  GDK_KEY_leftt* = 0x000009F4
  GDK_KEY_rightt* = 0x000009F5
  GDK_KEY_bott* = 0x000009F6
  GDK_KEY_topt* = 0x000009F7
  GDK_KEY_vertbar* = 0x000009F8
  GDK_KEY_emspace* = 0x00000AA1
  GDK_KEY_enspace* = 0x00000AA2
  GDK_KEY_em3space* = 0x00000AA3
  GDK_KEY_em4space* = 0x00000AA4
  GDK_KEY_digitspace* = 0x00000AA5
  GDK_KEY_punctspace* = 0x00000AA6
  GDK_KEY_thinspace* = 0x00000AA7
  GDK_KEY_hairspace* = 0x00000AA8
  GDK_KEY_emdash* = 0x00000AA9
  GDK_KEY_endash* = 0x00000AAA
  GDK_KEY_signifblank* = 0x00000AAC
  GDK_KEY_ellipsis* = 0x00000AAE
  GDK_KEY_doubbaselinedot* = 0x00000AAF
  GDK_KEY_onethird* = 0x00000AB0
  GDK_KEY_twothirds* = 0x00000AB1
  GDK_KEY_onefifth* = 0x00000AB2
  GDK_KEY_twofifths* = 0x00000AB3
  GDK_KEY_threefifths* = 0x00000AB4
  GDK_KEY_fourfifths* = 0x00000AB5
  GDK_KEY_onesixth* = 0x00000AB6
  GDK_KEY_fivesixths* = 0x00000AB7
  GDK_KEY_careof* = 0x00000AB8
  GDK_KEY_figdash* = 0x00000ABB
  GDK_KEY_leftanglebracket* = 0x00000ABC
  GDK_KEY_decimalpoint* = 0x00000ABD
  GDK_KEY_rightanglebracket* = 0x00000ABE
  GDK_KEY_marker* = 0x00000ABF
  GDK_KEY_oneeighth* = 0x00000AC3
  GDK_KEY_threeeighths* = 0x00000AC4
  GDK_KEY_fiveeighths* = 0x00000AC5
  GDK_KEY_seveneighths* = 0x00000AC6
  GDK_KEY_trademark* = 0x00000AC9
  GDK_KEY_signaturemark* = 0x00000ACA
  GDK_KEY_trademarkincircle* = 0x00000ACB
  GDK_KEY_leftopentriangle* = 0x00000ACC
  GDK_KEY_rightopentriangle* = 0x00000ACD
  GDK_KEY_emopencircle* = 0x00000ACE
  GDK_KEY_emopenrectangle* = 0x00000ACF
  GDK_KEY_leftsinglequotemark* = 0x00000AD0
  GDK_KEY_rightsinglequotemark* = 0x00000AD1
  GDK_KEY_leftdoublequotemark* = 0x00000AD2
  GDK_KEY_rightdoublequotemark* = 0x00000AD3
  GDK_KEY_prescription* = 0x00000AD4
  GDK_KEY_minutes* = 0x00000AD6
  GDK_KEY_seconds* = 0x00000AD7
  GDK_KEY_latincross* = 0x00000AD9
  GDK_KEY_hexagram* = 0x00000ADA
  GDK_KEY_filledrectbullet* = 0x00000ADB
  GDK_KEY_filledlefttribullet* = 0x00000ADC
  GDK_KEY_filledrighttribullet* = 0x00000ADD
  GDK_KEY_emfilledcircle* = 0x00000ADE
  GDK_KEY_emfilledrect* = 0x00000ADF
  GDK_KEY_enopencircbullet* = 0x00000AE0
  GDK_KEY_enopensquarebullet* = 0x00000AE1
  GDK_KEY_openrectbullet* = 0x00000AE2
  GDK_KEY_opentribulletup* = 0x00000AE3
  GDK_KEY_opentribulletdown* = 0x00000AE4
  GDK_KEY_openstar* = 0x00000AE5
  GDK_KEY_enfilledcircbullet* = 0x00000AE6
  GDK_KEY_enfilledsqbullet* = 0x00000AE7
  GDK_KEY_filledtribulletup* = 0x00000AE8
  GDK_KEY_filledtribulletdown* = 0x00000AE9
  GDK_KEY_leftpointer* = 0x00000AEA
  GDK_KEY_rightpointer* = 0x00000AEB
  GDK_KEY_club* = 0x00000AEC
  GDK_KEY_diamond* = 0x00000AED
  GDK_KEY_heart* = 0x00000AEE
  GDK_KEY_maltesecross* = 0x00000AF0
  GDK_KEY_dagger* = 0x00000AF1
  GDK_KEY_doubledagger* = 0x00000AF2
  GDK_KEY_checkmark* = 0x00000AF3
  GDK_KEY_ballotcross* = 0x00000AF4
  GDK_KEY_musicalsharp* = 0x00000AF5
  GDK_KEY_musicalflat* = 0x00000AF6
  GDK_KEY_malesymbol* = 0x00000AF7
  GDK_KEY_femalesymbol* = 0x00000AF8
  GDK_KEY_telephone* = 0x00000AF9
  GDK_KEY_telephonerecorder* = 0x00000AFA
  GDK_KEY_phonographcopyright* = 0x00000AFB
  GDK_KEY_caret* = 0x00000AFC
  GDK_KEY_singlelowquotemark* = 0x00000AFD
  GDK_KEY_doublelowquotemark* = 0x00000AFE
  GDK_KEY_cursor* = 0x00000AFF
  GDK_KEY_leftcaret* = 0x00000BA3
  GDK_KEY_rightcaret* = 0x00000BA6
  GDK_KEY_downcaret* = 0x00000BA8
  GDK_KEY_upcaret* = 0x00000BA9
  GDK_KEY_overbar* = 0x00000BC0
  GDK_KEY_downtack* = 0x00000BC2
  GDK_KEY_upshoe* = 0x00000BC3
  GDK_KEY_downstile* = 0x00000BC4
  GDK_KEY_underbar* = 0x00000BC6
  GDK_KEY_jot* = 0x00000BCA
  GDK_KEY_quad* = 0x00000BCC
  GDK_KEY_uptack* = 0x00000BCE
  GDK_KEY_circle* = 0x00000BCF
  GDK_KEY_upstile* = 0x00000BD3
  GDK_KEY_downshoe* = 0x00000BD6
  GDK_KEY_rightshoe* = 0x00000BD8
  GDK_KEY_leftshoe* = 0x00000BDA
  GDK_KEY_lefttack* = 0x00000BDC
  GDK_KEY_righttack* = 0x00000BFC
  GDK_KEY_hebrew_doublelowline* = 0x00000CDF
  GDK_KEY_hebrew_aleph* = 0x00000CE0
  GDK_KEY_hebrew_bet* = 0x00000CE1
  GDK_KEY_hebrew_beth* = 0x00000CE1
  GDK_KEY_hebrew_gimel* = 0x00000CE2
  GDK_KEY_hebrew_gimmel* = 0x00000CE2
  GDK_KEY_hebrew_dalet* = 0x00000CE3
  GDK_KEY_hebrew_daleth* = 0x00000CE3
  GDK_KEY_hebrew_he* = 0x00000CE4
  GDK_KEY_hebrew_waw* = 0x00000CE5
  GDK_KEY_hebrew_zain* = 0x00000CE6
  GDK_KEY_hebrew_zayin* = 0x00000CE6
  GDK_KEY_hebrew_chet* = 0x00000CE7
  GDK_KEY_hebrew_het* = 0x00000CE7
  GDK_KEY_hebrew_tet* = 0x00000CE8
  GDK_KEY_hebrew_teth* = 0x00000CE8
  GDK_KEY_hebrew_yod* = 0x00000CE9
  GDK_KEY_hebrew_finalkaph* = 0x00000CEA
  GDK_KEY_hebrew_kaph* = 0x00000CEB
  GDK_KEY_hebrew_lamed* = 0x00000CEC
  GDK_KEY_hebrew_finalmem* = 0x00000CED
  GDK_KEY_hebrew_mem* = 0x00000CEE
  GDK_KEY_hebrew_finalnun* = 0x00000CEF
  GDK_KEY_hebrew_nun* = 0x00000CF0
  GDK_KEY_hebrew_samech* = 0x00000CF1
  GDK_KEY_hebrew_samekh* = 0x00000CF1
  GDK_KEY_hebrew_ayin* = 0x00000CF2
  GDK_KEY_hebrew_finalpe* = 0x00000CF3
  GDK_KEY_hebrew_pe* = 0x00000CF4
  GDK_KEY_hebrew_finalzade* = 0x00000CF5
  GDK_KEY_hebrew_finalzadi* = 0x00000CF5
  GDK_KEY_hebrew_zade* = 0x00000CF6
  GDK_KEY_hebrew_zadi* = 0x00000CF6
  GDK_KEY_hebrew_qoph* = 0x00000CF7
  GDK_KEY_hebrew_kuf* = 0x00000CF7
  GDK_KEY_hebrew_resh* = 0x00000CF8
  GDK_KEY_hebrew_shin* = 0x00000CF9
  GDK_KEY_hebrew_taw* = 0x00000CFA
  GDK_KEY_hebrew_taf* = 0x00000CFA
  GDK_KEY_Hebrew_switch* = 0x0000FF7E
  GDK_KEY_Thai_kokai* = 0x00000DA1
  GDK_KEY_Thai_khokhai* = 0x00000DA2
  GDK_KEY_Thai_khokhuat* = 0x00000DA3
  GDK_KEY_Thai_khokhwai* = 0x00000DA4
  GDK_KEY_Thai_khokhon* = 0x00000DA5
  GDK_KEY_Thai_khorakhang* = 0x00000DA6
  GDK_KEY_Thai_ngongu* = 0x00000DA7
  GDK_KEY_Thai_chochan* = 0x00000DA8
  GDK_KEY_Thai_choching* = 0x00000DA9
  GDK_KEY_Thai_chochang* = 0x00000DAA
  GDK_KEY_Thai_soso* = 0x00000DAB
  GDK_KEY_Thai_chochoe* = 0x00000DAC
  GDK_KEY_Thai_yoying* = 0x00000DAD
  GDK_KEY_Thai_dochada* = 0x00000DAE
  GDK_KEY_Thai_topatak* = 0x00000DAF
  GDK_KEY_Thai_thothan* = 0x00000DB0
  GDK_KEY_Thai_thonangmontho* = 0x00000DB1
  GDK_KEY_Thai_thophuthao* = 0x00000DB2
  GDK_KEY_Thai_nonen* = 0x00000DB3
  GDK_KEY_Thai_dodek* = 0x00000DB4
  GDK_KEY_Thai_totao* = 0x00000DB5
  GDK_KEY_Thai_thothung* = 0x00000DB6
  GDK_KEY_Thai_thothahan* = 0x00000DB7
  GDK_KEY_Thai_thothong* = 0x00000DB8
  GDK_KEY_Thai_nonu* = 0x00000DB9
  GDK_KEY_Thai_bobaimai* = 0x00000DBA
  GDK_KEY_Thai_popla* = 0x00000DBB
  GDK_KEY_Thai_phophung* = 0x00000DBC
  GDK_KEY_Thai_fofa* = 0x00000DBD
  GDK_KEY_Thai_phophan* = 0x00000DBE
  GDK_KEY_Thai_fofan* = 0x00000DBF
  GDK_KEY_Thai_phosamphao* = 0x00000DC0
  GDK_KEY_Thai_moma* = 0x00000DC1
  GDK_KEY_Thai_yoyak* = 0x00000DC2
  GDK_KEY_Thai_rorua* = 0x00000DC3
  GDK_KEY_Thai_ru* = 0x00000DC4
  GDK_KEY_Thai_loling* = 0x00000DC5
  GDK_KEY_Thai_lu* = 0x00000DC6
  GDK_KEY_Thai_wowaen* = 0x00000DC7
  GDK_KEY_Thai_sosala* = 0x00000DC8
  GDK_KEY_Thai_sorusi* = 0x00000DC9
  GDK_KEY_Thai_sosua* = 0x00000DCA
  GDK_KEY_Thai_hohip* = 0x00000DCB
  GDK_KEY_Thai_lochula* = 0x00000DCC
  GDK_KEY_Thai_oang* = 0x00000DCD
  GDK_KEY_Thai_honokhuk* = 0x00000DCE
  GDK_KEY_Thai_paiyannoi* = 0x00000DCF
  GDK_KEY_Thai_saraa* = 0x00000DD0
  GDK_KEY_Thai_maihanakat* = 0x00000DD1
  GDK_KEY_Thai_saraaa* = 0x00000DD2
  GDK_KEY_Thai_saraam* = 0x00000DD3
  GDK_KEY_Thai_sarai* = 0x00000DD4
  GDK_KEY_Thai_saraii* = 0x00000DD5
  GDK_KEY_Thai_saraue* = 0x00000DD6
  GDK_KEY_Thai_sarauee* = 0x00000DD7
  GDK_KEY_Thai_sarau* = 0x00000DD8
  GDK_KEY_Thai_sarauu* = 0x00000DD9
  GDK_KEY_Thai_phinthu* = 0x00000DDA
  GDK_KEY_Thai_maihanakat_maitho* = 0x00000DDE
  GDK_KEY_Thai_baht* = 0x00000DDF
  GDK_KEY_Thai_sarae* = 0x00000DE0
  GDK_KEY_Thai_saraae* = 0x00000DE1
  GDK_KEY_Thai_sarao* = 0x00000DE2
  GDK_KEY_Thai_saraaimaimuan* = 0x00000DE3
  GDK_KEY_Thai_saraaimaimalai* = 0x00000DE4
  GDK_KEY_Thai_lakkhangyao* = 0x00000DE5
  GDK_KEY_Thai_maiyamok* = 0x00000DE6
  GDK_KEY_Thai_maitaikhu* = 0x00000DE7
  GDK_KEY_Thai_maiek* = 0x00000DE8
  GDK_KEY_Thai_maitho* = 0x00000DE9
  GDK_KEY_Thai_maitri* = 0x00000DEA
  GDK_KEY_Thai_maichattawa* = 0x00000DEB
  GDK_KEY_Thai_thanthakhat* = 0x00000DEC
  GDK_KEY_Thai_nikhahit* = 0x00000DED
  GDK_KEY_Thai_leksun* = 0x00000DF0
  GDK_KEY_Thai_leknung* = 0x00000DF1
  GDK_KEY_Thai_leksong* = 0x00000DF2
  GDK_KEY_Thai_leksam* = 0x00000DF3
  GDK_KEY_Thai_leksi* = 0x00000DF4
  GDK_KEY_Thai_lekha* = 0x00000DF5
  GDK_KEY_Thai_lekhok* = 0x00000DF6
  GDK_KEY_Thai_lekchet* = 0x00000DF7
  GDK_KEY_Thai_lekpaet* = 0x00000DF8
  GDK_KEY_Thai_lekkao* = 0x00000DF9
  GDK_KEY_Hangul* = 0x0000FF31
  GDK_KEY_Hangul_Start* = 0x0000FF32
  GDK_KEY_Hangul_End* = 0x0000FF33
  GDK_KEY_Hangul_Hanja* = 0x0000FF34
  GDK_KEY_Hangul_Jamo* = 0x0000FF35
  GDK_KEY_Hangul_Romaja* = 0x0000FF36
  GDK_KEY_Hangul_Codeinput* = 0x0000FF37
  GDK_KEY_Hangul_Jeonja* = 0x0000FF38
  GDK_KEY_Hangul_Banja* = 0x0000FF39
  GDK_KEY_Hangul_PreHanja* = 0x0000FF3A
  GDK_KEY_Hangul_PostHanja* = 0x0000FF3B
  GDK_KEY_Hangul_SingleCandidate* = 0x0000FF3C
  GDK_KEY_Hangul_MultipleCandidate* = 0x0000FF3D
  GDK_KEY_Hangul_PreviousCandidate* = 0x0000FF3E
  GDK_KEY_Hangul_Special* = 0x0000FF3F
  GDK_KEY_Hangul_switch* = 0x0000FF7E
  GDK_KEY_Hangul_Kiyeog* = 0x00000EA1
  GDK_KEY_Hangul_SsangKiyeog* = 0x00000EA2
  GDK_KEY_Hangul_KiyeogSios* = 0x00000EA3
  GDK_KEY_Hangul_Nieun* = 0x00000EA4
  GDK_KEY_Hangul_NieunJieuj* = 0x00000EA5
  GDK_KEY_Hangul_NieunHieuh* = 0x00000EA6
  GDK_KEY_Hangul_Dikeud* = 0x00000EA7
  GDK_KEY_Hangul_SsangDikeud* = 0x00000EA8
  GDK_KEY_Hangul_Rieul* = 0x00000EA9
  GDK_KEY_Hangul_RieulKiyeog* = 0x00000EAA
  GDK_KEY_Hangul_RieulMieum* = 0x00000EAB
  GDK_KEY_Hangul_RieulPieub* = 0x00000EAC
  GDK_KEY_Hangul_RieulSios* = 0x00000EAD
  GDK_KEY_Hangul_RieulTieut* = 0x00000EAE
  GDK_KEY_Hangul_RieulPhieuf* = 0x00000EAF
  GDK_KEY_Hangul_RieulHieuh* = 0x00000EB0
  GDK_KEY_Hangul_Mieum* = 0x00000EB1
  GDK_KEY_Hangul_Pieub* = 0x00000EB2
  GDK_KEY_Hangul_SsangPieub* = 0x00000EB3
  GDK_KEY_Hangul_PieubSios* = 0x00000EB4
  GDK_KEY_Hangul_Sios* = 0x00000EB5
  GDK_KEY_Hangul_SsangSios* = 0x00000EB6
  GDK_KEY_Hangul_Ieung* = 0x00000EB7
  GDK_KEY_Hangul_Jieuj* = 0x00000EB8
  GDK_KEY_Hangul_SsangJieuj* = 0x00000EB9
  GDK_KEY_Hangul_Cieuc* = 0x00000EBA
  GDK_KEY_Hangul_Khieuq* = 0x00000EBB
  GDK_KEY_Hangul_Tieut* = 0x00000EBC
  GDK_KEY_Hangul_Phieuf* = 0x00000EBD
  GDK_KEY_Hangul_Hieuh* = 0x00000EBE
  GDK_KEY_Hangul_A* = 0x00000EBF
  GDK_KEY_Hangul_AE* = 0x00000EC0
  GDK_KEY_Hangul_YA* = 0x00000EC1
  GDK_KEY_Hangul_YAE* = 0x00000EC2
  GDK_KEY_Hangul_EO* = 0x00000EC3
  GDK_KEY_Hangul_E* = 0x00000EC4
  GDK_KEY_Hangul_YEO* = 0x00000EC5
  GDK_KEY_Hangul_YE* = 0x00000EC6
  GDK_KEY_Hangul_O* = 0x00000EC7
  GDK_KEY_Hangul_WA* = 0x00000EC8
  GDK_KEY_Hangul_WAE* = 0x00000EC9
  GDK_KEY_Hangul_OE* = 0x00000ECA
  GDK_KEY_Hangul_YO* = 0x00000ECB
  GDK_KEY_Hangul_U* = 0x00000ECC
  GDK_KEY_Hangul_WEO* = 0x00000ECD
  GDK_KEY_Hangul_WE* = 0x00000ECE
  GDK_KEY_Hangul_WI* = 0x00000ECF
  GDK_KEY_Hangul_YU* = 0x00000ED0
  GDK_KEY_Hangul_EU* = 0x00000ED1
  GDK_KEY_Hangul_YI* = 0x00000ED2
  GDK_KEY_Hangul_I* = 0x00000ED3
  GDK_KEY_Hangul_J_Kiyeog* = 0x00000ED4
  GDK_KEY_Hangul_J_SsangKiyeog* = 0x00000ED5
  GDK_KEY_Hangul_J_KiyeogSios* = 0x00000ED6
  GDK_KEY_Hangul_J_Nieun* = 0x00000ED7
  GDK_KEY_Hangul_J_NieunJieuj* = 0x00000ED8
  GDK_KEY_Hangul_J_NieunHieuh* = 0x00000ED9
  GDK_KEY_Hangul_J_Dikeud* = 0x00000EDA
  GDK_KEY_Hangul_J_Rieul* = 0x00000EDB
  GDK_KEY_Hangul_J_RieulKiyeog* = 0x00000EDC
  GDK_KEY_Hangul_J_RieulMieum* = 0x00000EDD
  GDK_KEY_Hangul_J_RieulPieub* = 0x00000EDE
  GDK_KEY_Hangul_J_RieulSios* = 0x00000EDF
  GDK_KEY_Hangul_J_RieulTieut* = 0x00000EE0
  GDK_KEY_Hangul_J_RieulPhieuf* = 0x00000EE1
  GDK_KEY_Hangul_J_RieulHieuh* = 0x00000EE2
  GDK_KEY_Hangul_J_Mieum* = 0x00000EE3
  GDK_KEY_Hangul_J_Pieub* = 0x00000EE4
  GDK_KEY_Hangul_J_PieubSios* = 0x00000EE5
  GDK_KEY_Hangul_J_Sios* = 0x00000EE6
  GDK_KEY_Hangul_J_SsangSios* = 0x00000EE7
  GDK_KEY_Hangul_J_Ieung* = 0x00000EE8
  GDK_KEY_Hangul_J_Jieuj* = 0x00000EE9
  GDK_KEY_Hangul_J_Cieuc* = 0x00000EEA
  GDK_KEY_Hangul_J_Khieuq* = 0x00000EEB
  GDK_KEY_Hangul_J_Tieut* = 0x00000EEC
  GDK_KEY_Hangul_J_Phieuf* = 0x00000EED
  GDK_KEY_Hangul_J_Hieuh* = 0x00000EEE
  GDK_KEY_Hangul_RieulYeorinHieuh* = 0x00000EEF
  GDK_KEY_Hangul_SunkyeongeumMieum* = 0x00000EF0
  GDK_KEY_Hangul_SunkyeongeumPieub* = 0x00000EF1
  GDK_KEY_Hangul_PanSios* = 0x00000EF2
  GDK_KEY_Hangul_KkogjiDalrinIeung* = 0x00000EF3
  GDK_KEY_Hangul_SunkyeongeumPhieuf* = 0x00000EF4
  GDK_KEY_Hangul_YeorinHieuh* = 0x00000EF5
  GDK_KEY_Hangul_AraeA* = 0x00000EF6
  GDK_KEY_Hangul_AraeAE* = 0x00000EF7
  GDK_KEY_Hangul_J_PanSios* = 0x00000EF8
  GDK_KEY_Hangul_J_KkogjiDalrinIeung* = 0x00000EF9
  GDK_KEY_Hangul_J_YeorinHieuh* = 0x00000EFA
  GDK_KEY_Korean_Won* = 0x00000EFF
  GDK_KEY_EcuSign* = 0x000020A0
  GDK_KEY_ColonSign* = 0x000020A1
  GDK_KEY_CruzeiroSign* = 0x000020A2
  GDK_KEY_FFrancSign* = 0x000020A3
  GDK_KEY_LiraSign* = 0x000020A4
  GDK_KEY_MillSign* = 0x000020A5
  GDK_KEY_NairaSign* = 0x000020A6
  GDK_KEY_PesetaSign* = 0x000020A7
  GDK_KEY_RupeeSign* = 0x000020A8
  GDK_KEY_WonSign* = 0x000020A9
  GDK_KEY_NewSheqelSign* = 0x000020AA
  GDK_KEY_DongSign* = 0x000020AB
  GDK_KEY_EuroSign* = 0x000020AC

proc gdk_pango_context_get_for_screen*(screen: PGdkScreen): PPangoContext{.
    cdecl, dynlib: gdklib, importc: "gdk_pango_context_get_for_screen".}
proc gdk_pango_context_set_colormap*(context: PPangoContext,
                                     colormap: PGdkColormap){.cdecl,
    dynlib: gdklib, importc: "gdk_pango_context_set_colormap".}
proc gdk_pango_layout_line_get_clip_region*(line: PPangoLayoutLine,
    x_origin: gint, y_origin: gint, index_ranges: Pgint, n_ranges: gint): PGdkRegion{.
    cdecl, dynlib: gdklib, importc: "gdk_pango_layout_line_get_clip_region".}
proc gdk_pango_layout_get_clip_region*(layout: PPangoLayout, x_origin: gint,
                                       y_origin: gint, index_ranges: Pgint,
                                       n_ranges: gint): PGdkRegion{.cdecl,
    dynlib: gdklib, importc: "gdk_pango_layout_get_clip_region".}
proc gdk_pango_attr_stipple_new*(stipple: PGdkBitmap): PPangoAttribute{.cdecl,
    dynlib: gdklib, importc: "gdk_pango_attr_stipple_new".}
proc gdk_pango_attr_embossed_new*(embossed: gboolean): PPangoAttribute{.cdecl,
    dynlib: gdklib, importc: "gdk_pango_attr_embossed_new".}
proc gdk_pixbuf_render_threshold_alpha*(pixbuf: PGdkPixbuf, bitmap: PGdkBitmap,
                                        src_x: int32, src_y: int32,
                                        dest_x: int32, dest_y: int32,
                                        width: int32, height: int32,
                                        alpha_threshold: int32){.cdecl,
    dynlib: gdklib, importc: "gdk_pixbuf_render_threshold_alpha".}
proc gdk_pixbuf_render_to_drawable*(pixbuf: PGdkPixbuf, drawable: PGdkDrawable,
                                    gc: PGdkGC, src_x: int32, src_y: int32,
                                    dest_x: int32, dest_y: int32, width: int32,
                                    height: int32, dither: TGdkRgbDither,
                                    x_dither: int32, y_dither: int32){.cdecl,
    dynlib: gdklib, importc: "gdk_pixbuf_render_to_drawable".}
proc gdk_pixbuf_render_to_drawable_alpha*(pixbuf: PGdkPixbuf,
    drawable: PGdkDrawable, src_x: int32, src_y: int32, dest_x: int32,
    dest_y: int32, width: int32, height: int32, alpha_mode: TGdkPixbufAlphaMode,
    alpha_threshold: int32, dither: TGdkRgbDither, x_dither: int32,
    y_dither: int32){.cdecl, dynlib: gdklib,
                      importc: "gdk_pixbuf_render_to_drawable_alpha".}
proc gdk_pixbuf_render_pixmap_and_mask_for_colormap*(pixbuf: PGdkPixbuf,
    colormap: PGdkColormap, n: var PGdkPixmap, nasdfdsafw4e: var PGdkBitmap,
    alpha_threshold: int32){.cdecl, dynlib: gdklib, importc: "gdk_pixbuf_render_pixmap_and_mask_for_colormap".}
proc gdk_pixbuf_get_from_drawable*(dest: PGdkPixbuf, src: PGdkDrawable,
                                   cmap: PGdkColormap, src_x: int32,
                                   src_y: int32, dest_x: int32, dest_y: int32,
                                   width: int32, height: int32): PGdkPixbuf{.
    cdecl, dynlib: gdklib, importc: "gdk_pixbuf_get_from_drawable".}
proc gdk_pixbuf_get_from_image*(dest: PGdkPixbuf, src: PGdkImage,
                                cmap: PGdkColormap, src_x: int32, src_y: int32,
                                dest_x: int32, dest_y: int32, width: int32,
                                height: int32): PGdkPixbuf{.cdecl,
    dynlib: gdklib, importc: "gdk_pixbuf_get_from_image".}
proc GDK_TYPE_PIXMAP*(): GType
proc GDK_PIXMAP*(anObject: Pointer): PGdkPixmap
proc GDK_PIXMAP_CLASS*(klass: Pointer): PGdkPixmapObjectClass
proc GDK_IS_PIXMAP*(anObject: Pointer): bool
proc GDK_IS_PIXMAP_CLASS*(klass: Pointer): bool
proc GDK_PIXMAP_GET_CLASS*(obj: Pointer): PGdkPixmapObjectClass
proc GDK_PIXMAP_OBJECT*(anObject: Pointer): PGdkPixmapObject
proc gdk_pixmap_get_type*(): GType{.cdecl, dynlib: gdklib,
                                    importc: "gdk_pixmap_get_type".}
proc gdk_pixmap_new*(window: PGdkWindow, width: gint, height: gint, depth: gint): PGdkPixmap{.
    cdecl, dynlib: gdklib, importc: "gdk_pixmap_new".}
proc gdk_bitmap_create_from_data*(window: PGdkWindow, data: cstring, width: gint,
                                  height: gint): PGdkBitmap{.cdecl,
    dynlib: gdklib, importc: "gdk_bitmap_create_from_data".}
proc gdk_pixmap_create_from_data*(window: PGdkWindow, data: cstring, width: gint,
                                  height: gint, depth: gint, fg: PGdkColor,
                                  bg: PGdkColor): PGdkPixmap{.cdecl,
    dynlib: gdklib, importc: "gdk_pixmap_create_from_data".}
proc gdk_pixmap_create_from_xpm*(window: PGdkWindow, k: var PGdkBitmap,
                                 transparent_color: PGdkColor, filename: cstring): PGdkPixmap{.
    cdecl, dynlib: gdklib, importc: "gdk_pixmap_create_from_xpm".}
proc gdk_pixmap_colormap_create_from_xpm*(window: PGdkWindow,
    colormap: PGdkColormap, k: var PGdkBitmap, transparent_color: PGdkColor,
    filename: cstring): PGdkPixmap{.cdecl, dynlib: gdklib, importc: "gdk_pixmap_colormap_create_from_xpm".}
proc gdk_pixmap_create_from_xpm_d*(window: PGdkWindow, k: var PGdkBitmap,
                                   transparent_color: PGdkColor, data: PPgchar): PGdkPixmap{.
    cdecl, dynlib: gdklib, importc: "gdk_pixmap_create_from_xpm_d".}
proc gdk_pixmap_colormap_create_from_xpm_d*(window: PGdkWindow,
    colormap: PGdkColormap, k: var PGdkBitmap, transparent_color: PGdkColor,
    data: PPgchar): PGdkPixmap{.cdecl, dynlib: gdklib, importc: "gdk_pixmap_colormap_create_from_xpm_d".}
proc gdk_pixmap_foreign_new_for_display*(display: PGdkDisplay,
    anid: TGdkNativeWindow): PGdkPixmap{.cdecl, dynlib: gdklib,
    importc: "gdk_pixmap_foreign_new_for_display".}
proc gdk_pixmap_lookup_for_display*(display: PGdkDisplay, anid: TGdkNativeWindow): PGdkPixmap{.
    cdecl, dynlib: gdklib, importc: "gdk_pixmap_lookup_for_display".}
proc gdk_atom_intern*(atom_name: cstring, only_if_exists: gboolean): TGdkAtom{.
    cdecl, dynlib: gdklib, importc: "gdk_atom_intern".}
proc gdk_atom_name*(atom: TGdkAtom): cstring{.cdecl, dynlib: gdklib,
    importc: "gdk_atom_name".}
proc gdk_property_get*(window: PGdkWindow, `property`: TGdkAtom,
                       `type`: TGdkAtom, offset: gulong, length: gulong,
                       pdelete: gint, actual_property_type: PGdkAtom,
                       actual_format: Pgint, actual_length: Pgint,
                       data: PPguchar): gboolean{.cdecl, dynlib: gdklib,
    importc: "gdk_property_get".}
proc gdk_property_change*(window: PGdkWindow, `property`: TGdkAtom,
                          `type`: TGdkAtom, format: gint, mode: TGdkPropMode,
                          data: Pguchar, nelements: gint){.cdecl,
    dynlib: gdklib, importc: "gdk_property_change".}
proc gdk_property_delete*(window: PGdkWindow, `property`: TGdkAtom){.cdecl,
    dynlib: gdklib, importc: "gdk_property_delete".}
proc gdk_text_property_to_text_list_for_display*(display: PGdkDisplay,
    encoding: TGdkAtom, format: gint, text: Pguchar, length: gint,
    t: var PPgchar): gint{.cdecl, dynlib: gdklib, importc: "gdk_text_property_to_text_list_for_display".}
proc gdk_text_property_to_utf8_list_for_display*(display: PGdkDisplay,
    encoding: TGdkAtom, format: gint, text: Pguchar, length: gint,
    t: var PPgchar): gint{.cdecl, dynlib: gdklib, importc: "gdk_text_property_to_utf8_list_for_display".}
proc gdk_utf8_to_string_target*(str: cstring): cstring{.cdecl, dynlib: gdklib,
    importc: "gdk_utf8_to_string_target".}
proc gdk_string_to_compound_text_for_display*(display: PGdkDisplay, str: cstring,
    encoding: PGdkAtom, format: Pgint, ctext: PPguchar, length: Pgint): gint{.
    cdecl, dynlib: gdklib, importc: "gdk_string_to_compound_text_for_display".}
proc gdk_utf8_to_compound_text_for_display*(display: PGdkDisplay, str: cstring,
    encoding: PGdkAtom, format: Pgint, ctext: PPguchar, length: Pgint): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_utf8_to_compound_text_for_display".}
proc gdk_free_text_list*(list: PPgchar){.cdecl, dynlib: gdklib,
    importc: "gdk_free_text_list".}
proc gdk_free_compound_text*(ctext: Pguchar){.cdecl, dynlib: gdklib,
    importc: "gdk_free_compound_text".}
proc gdk_region_new*(): PGdkRegion{.cdecl, dynlib: gdklib,
                                    importc: "gdk_region_new".}
proc gdk_region_polygon*(points: PGdkPoint, npoints: gint,
                         fill_rule: TGdkFillRule): PGdkRegion{.cdecl,
    dynlib: gdklib, importc: "gdk_region_polygon".}
proc gdk_region_copy*(region: PGdkRegion): PGdkRegion{.cdecl, dynlib: gdklib,
    importc: "gdk_region_copy".}
proc gdk_region_rectangle*(rectangle: PGdkRectangle): PGdkRegion{.cdecl,
    dynlib: gdklib, importc: "gdk_region_rectangle".}
proc gdk_region_destroy*(region: PGdkRegion){.cdecl, dynlib: gdklib,
    importc: "gdk_region_destroy".}
proc gdk_region_get_clipbox*(region: PGdkRegion, rectangle: PGdkRectangle){.
    cdecl, dynlib: gdklib, importc: "gdk_region_get_clipbox".}
proc gdk_region_get_rectangles*(region: PGdkRegion, s: var PGdkRectangle,
                                n_rectangles: Pgint){.cdecl, dynlib: gdklib,
    importc: "gdk_region_get_rectangles".}
proc gdk_region_empty*(region: PGdkRegion): gboolean{.cdecl, dynlib: gdklib,
    importc: "gdk_region_empty".}
proc gdk_region_equal*(region1: PGdkRegion, region2: PGdkRegion): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_region_equal".}
proc gdk_region_point_in*(region: PGdkRegion, x: int32, y: int32): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_region_point_in".}
proc gdk_region_rect_in*(region: PGdkRegion, rect: PGdkRectangle): TGdkOverlapType{.
    cdecl, dynlib: gdklib, importc: "gdk_region_rect_in".}
proc gdk_region_offset*(region: PGdkRegion, dx: gint, dy: gint){.cdecl,
    dynlib: gdklib, importc: "gdk_region_offset".}
proc gdk_region_shrink*(region: PGdkRegion, dx: gint, dy: gint){.cdecl,
    dynlib: gdklib, importc: "gdk_region_shrink".}
proc gdk_region_union_with_rect*(region: PGdkRegion, rect: PGdkRectangle){.
    cdecl, dynlib: gdklib, importc: "gdk_region_union_with_rect".}
proc gdk_region_intersect*(source1: PGdkRegion, source2: PGdkRegion){.cdecl,
    dynlib: gdklib, importc: "gdk_region_intersect".}
proc gdk_region_union*(source1: PGdkRegion, source2: PGdkRegion){.cdecl,
    dynlib: gdklib, importc: "gdk_region_union".}
proc gdk_region_subtract*(source1: PGdkRegion, source2: PGdkRegion){.cdecl,
    dynlib: gdklib, importc: "gdk_region_subtract".}
proc gdk_region_xor*(source1: PGdkRegion, source2: PGdkRegion){.cdecl,
    dynlib: gdklib, importc: "gdk_region_xor".}
proc gdk_region_spans_intersect_foreach*(region: PGdkRegion, spans: PGdkSpan,
    n_spans: int32, sorted: gboolean, `function`: TGdkSpanFunc, data: gpointer){.
    cdecl, dynlib: gdklib, importc: "gdk_region_spans_intersect_foreach".}
proc gdk_rgb_find_color*(colormap: PGdkColormap, color: PGdkColor){.cdecl,
    dynlib: gdklib, importc: "gdk_rgb_find_color".}
proc gdk_draw_rgb_image*(drawable: PGdkDrawable, gc: PGdkGC, x: gint, y: gint,
                         width: gint, height: gint, dith: TGdkRgbDither,
                         rgb_buf: Pguchar, rowstride: gint){.cdecl,
    dynlib: gdklib, importc: "gdk_draw_rgb_image".}
proc gdk_draw_rgb_image_dithalign*(drawable: PGdkDrawable, gc: PGdkGC, x: gint,
                                   y: gint, width: gint, height: gint,
                                   dith: TGdkRgbDither, rgb_buf: Pguchar,
                                   rowstride: gint, xdith: gint, ydith: gint){.
    cdecl, dynlib: gdklib, importc: "gdk_draw_rgb_image_dithalign".}
proc gdk_draw_rgb_32_image*(drawable: PGdkDrawable, gc: PGdkGC, x: gint,
                            y: gint, width: gint, height: gint,
                            dith: TGdkRgbDither, buf: Pguchar, rowstride: gint){.
    cdecl, dynlib: gdklib, importc: "gdk_draw_rgb_32_image".}
proc gdk_draw_rgb_32_image_dithalign*(drawable: PGdkDrawable, gc: PGdkGC,
                                      x: gint, y: gint, width: gint,
                                      height: gint, dith: TGdkRgbDither,
                                      buf: Pguchar, rowstride: gint,
                                      xdith: gint, ydith: gint){.cdecl,
    dynlib: gdklib, importc: "gdk_draw_rgb_32_image_dithalign".}
proc gdk_draw_gray_image*(drawable: PGdkDrawable, gc: PGdkGC, x: gint, y: gint,
                          width: gint, height: gint, dith: TGdkRgbDither,
                          buf: Pguchar, rowstride: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_draw_gray_image".}
proc gdk_draw_indexed_image*(drawable: PGdkDrawable, gc: PGdkGC, x: gint,
                             y: gint, width: gint, height: gint,
                             dith: TGdkRgbDither, buf: Pguchar, rowstride: gint,
                             cmap: PGdkRgbCmap){.cdecl, dynlib: gdklib,
    importc: "gdk_draw_indexed_image".}
proc gdk_rgb_cmap_new*(colors: Pguint32, n_colors: gint): PGdkRgbCmap{.cdecl,
    dynlib: gdklib, importc: "gdk_rgb_cmap_new".}
proc gdk_rgb_cmap_free*(cmap: PGdkRgbCmap){.cdecl, dynlib: gdklib,
    importc: "gdk_rgb_cmap_free".}
proc gdk_rgb_set_verbose*(verbose: gboolean){.cdecl, dynlib: gdklib,
    importc: "gdk_rgb_set_verbose".}
proc gdk_rgb_set_install*(install: gboolean){.cdecl, dynlib: gdklib,
    importc: "gdk_rgb_set_install".}
proc gdk_rgb_set_min_colors*(min_colors: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_rgb_set_min_colors".}
proc GDK_TYPE_DISPLAY*(): GType
proc GDK_DISPLAY_OBJECT*(anObject: pointer): PGdkDisplay
proc GDK_DISPLAY_CLASS*(klass: pointer): PGdkDisplayClass
proc GDK_IS_DISPLAY*(anObject: pointer): bool
proc GDK_IS_DISPLAY_CLASS*(klass: pointer): bool
proc GDK_DISPLAY_GET_CLASS*(obj: pointer): PGdkDisplayClass
proc gdk_display_open*(display_name: cstring): PGdkDisplay{.cdecl,
    dynlib: gdklib, importc: "gdk_display_open".}
proc gdk_display_get_name*(display: PGdkDisplay): cstring{.cdecl, dynlib: gdklib,
    importc: "gdk_display_get_name".}
proc gdk_display_get_n_screens*(display: PGdkDisplay): gint{.cdecl,
    dynlib: gdklib, importc: "gdk_display_get_n_screens".}
proc gdk_display_get_screen*(display: PGdkDisplay, screen_num: gint): PGdkScreen{.
    cdecl, dynlib: gdklib, importc: "gdk_display_get_screen".}
proc gdk_display_get_default_screen*(display: PGdkDisplay): PGdkScreen{.cdecl,
    dynlib: gdklib, importc: "gdk_display_get_default_screen".}
proc gdk_display_pointer_ungrab*(display: PGdkDisplay, time: guint32){.cdecl,
    dynlib: gdklib, importc: "gdk_display_pointer_ungrab".}
proc gdk_display_keyboard_ungrab*(display: PGdkDisplay, time: guint32){.cdecl,
    dynlib: gdklib, importc: "gdk_display_keyboard_ungrab".}
proc gdk_display_pointer_is_grabbed*(display: PGdkDisplay): gboolean{.cdecl,
    dynlib: gdklib, importc: "gdk_display_pointer_is_grabbed".}
proc gdk_display_beep*(display: PGdkDisplay){.cdecl, dynlib: gdklib,
    importc: "gdk_display_beep".}
proc gdk_display_sync*(display: PGdkDisplay){.cdecl, dynlib: gdklib,
    importc: "gdk_display_sync".}
proc gdk_display_close*(display: PGdkDisplay){.cdecl, dynlib: gdklib,
    importc: "gdk_display_close".}
proc gdk_display_list_devices*(display: PGdkDisplay): PGList{.cdecl,
    dynlib: gdklib, importc: "gdk_display_list_devices".}
proc gdk_display_get_event*(display: PGdkDisplay): PGdkEvent{.cdecl,
    dynlib: gdklib, importc: "gdk_display_get_event".}
proc gdk_display_peek_event*(display: PGdkDisplay): PGdkEvent{.cdecl,
    dynlib: gdklib, importc: "gdk_display_peek_event".}
proc gdk_display_put_event*(display: PGdkDisplay, event: PGdkEvent){.cdecl,
    dynlib: gdklib, importc: "gdk_display_put_event".}
proc gdk_display_add_client_message_filter*(display: PGdkDisplay,
    message_type: TGdkAtom, func: TGdkFilterFunc, data: gpointer){.cdecl,
    dynlib: gdklib, importc: "gdk_display_add_client_message_filter".}
proc gdk_display_set_double_click_time*(display: PGdkDisplay, msec: guint){.
    cdecl, dynlib: gdklib, importc: "gdk_display_set_double_click_time".}
proc gdk_display_set_sm_client_id*(display: PGdkDisplay, sm_client_id: cstring){.
    cdecl, dynlib: gdklib, importc: "gdk_display_set_sm_client_id".}
proc gdk_set_default_display*(display: PGdkDisplay){.cdecl, dynlib: gdklib,
    importc: "gdk_set_default_display".}
proc gdk_get_default_display*(): PGdkDisplay{.cdecl, dynlib: gdklib,
    importc: "gdk_get_default_display".}
proc GDK_TYPE_SCREEN*(): GType
proc GDK_SCREEN*(anObject: Pointer): PGdkScreen
proc GDK_SCREEN_CLASS*(klass: Pointer): PGdkScreenClass
proc GDK_IS_SCREEN*(anObject: Pointer): bool
proc GDK_IS_SCREEN_CLASS*(klass: Pointer): bool
proc GDK_SCREEN_GET_CLASS*(obj: Pointer): PGdkScreenClass
proc gdk_screen_get_default_colormap*(screen: PGdkScreen): PGdkColormap{.cdecl,
    dynlib: gdklib, importc: "gdk_screen_get_default_colormap".}
proc gdk_screen_set_default_colormap*(screen: PGdkScreen, colormap: PGdkColormap){.
    cdecl, dynlib: gdklib, importc: "gdk_screen_set_default_colormap".}
proc gdk_screen_get_system_colormap*(screen: PGdkScreen): PGdkColormap{.cdecl,
    dynlib: gdklib, importc: "gdk_screen_get_system_colormap".}
proc gdk_screen_get_system_visual*(screen: PGdkScreen): PGdkVisual{.cdecl,
    dynlib: gdklib, importc: "gdk_screen_get_system_visual".}
proc gdk_screen_get_rgb_colormap*(screen: PGdkScreen): PGdkColormap{.cdecl,
    dynlib: gdklib, importc: "gdk_screen_get_rgb_colormap".}
proc gdk_screen_get_rgb_visual*(screen: PGdkScreen): PGdkVisual{.cdecl,
    dynlib: gdklib, importc: "gdk_screen_get_rgb_visual".}
proc gdk_screen_get_root_window*(screen: PGdkScreen): PGdkWindow{.cdecl,
    dynlib: gdklib, importc: "gdk_screen_get_root_window".}
proc gdk_screen_get_display*(screen: PGdkScreen): PGdkDisplay{.cdecl,
    dynlib: gdklib, importc: "gdk_screen_get_display".}
proc gdk_screen_get_number*(screen: PGdkScreen): gint{.cdecl, dynlib: gdklib,
    importc: "gdk_screen_get_number".}
proc gdk_screen_get_window_at_pointer*(screen: PGdkScreen, win_x: Pgint,
                                       win_y: Pgint): PGdkWindow{.cdecl,
    dynlib: gdklib, importc: "gdk_screen_get_window_at_pointer".}
proc gdk_screen_get_width*(screen: PGdkScreen): gint{.cdecl, dynlib: gdklib,
    importc: "gdk_screen_get_width".}
proc gdk_screen_get_height*(screen: PGdkScreen): gint{.cdecl, dynlib: gdklib,
    importc: "gdk_screen_get_height".}
proc gdk_screen_get_width_mm*(screen: PGdkScreen): gint{.cdecl, dynlib: gdklib,
    importc: "gdk_screen_get_width_mm".}
proc gdk_screen_get_height_mm*(screen: PGdkScreen): gint{.cdecl, dynlib: gdklib,
    importc: "gdk_screen_get_height_mm".}
proc gdk_screen_close*(screen: PGdkScreen){.cdecl, dynlib: gdklib,
    importc: "gdk_screen_close".}
proc gdk_screen_list_visuals*(screen: PGdkScreen): PGList{.cdecl,
    dynlib: gdklib, importc: "gdk_screen_list_visuals".}
proc gdk_screen_get_toplevel_windows*(screen: PGdkScreen): PGList{.cdecl,
    dynlib: gdklib, importc: "gdk_screen_get_toplevel_windows".}
proc gdk_screen_get_n_monitors*(screen: PGdkScreen): gint{.cdecl,
    dynlib: gdklib, importc: "gdk_screen_get_n_monitors".}
proc gdk_screen_get_monitor_geometry*(screen: PGdkScreen, monitor_num: gint,
                                      dest: PGdkRectangle){.cdecl,
    dynlib: gdklib, importc: "gdk_screen_get_monitor_geometry".}
proc gdk_screen_get_monitor_at_point*(screen: PGdkScreen, x: gint, y: gint): gint{.
    cdecl, dynlib: gdklib, importc: "gdk_screen_get_monitor_at_point".}
proc gdk_screen_get_monitor_at_window*(screen: PGdkScreen, window: PGdkWindow): gint{.
    cdecl, dynlib: gdklib, importc: "gdk_screen_get_monitor_at_window".}
proc gdk_screen_broadcast_client_message*(screen: PGdkScreen, event: PGdkEvent){.
    cdecl, dynlib: gdklib, importc: "gdk_screen_broadcast_client_message".}
proc gdk_get_default_screen*(): PGdkScreen{.cdecl, dynlib: gdklib,
    importc: "gdk_get_default_screen".}
proc gdk_screen_get_setting*(screen: PGdkScreen, name: cstring, value: PGValue): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_screen_get_setting".}
proc GDK_SELECTION_PRIMARY*(): TGdkAtom
proc GDK_SELECTION_SECONDARY*(): TGdkAtom
proc GDK_SELECTION_CLIPBOARD*(): TGdkAtom
proc GDK_TARGET_BITMAP*(): TGdkAtom
proc GDK_TARGET_COLORMAP*(): TGdkAtom
proc GDK_TARGET_DRAWABLE*(): TGdkAtom
proc GDK_TARGET_PIXMAP*(): TGdkAtom
proc GDK_TARGET_STRING*(): TGdkAtom
proc GDK_SELECTION_TYPE_ATOM*(): TGdkAtom
proc GDK_SELECTION_TYPE_BITMAP*(): TGdkAtom
proc GDK_SELECTION_TYPE_COLORMAP*(): TGdkAtom
proc GDK_SELECTION_TYPE_DRAWABLE*(): TGdkAtom
proc GDK_SELECTION_TYPE_INTEGER*(): TGdkAtom
proc GDK_SELECTION_TYPE_PIXMAP*(): TGdkAtom
proc GDK_SELECTION_TYPE_WINDOW*(): TGdkAtom
proc GDK_SELECTION_TYPE_STRING*(): TGdkAtom
proc gdk_selection_owner_set_for_display*(display: PGdkDisplay,
    owner: PGdkWindow, selection: TGdkAtom, time: guint32, send_event: gboolean): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_selection_owner_set_for_display".}
proc gdk_selection_owner_get_for_display*(display: PGdkDisplay,
    selection: TGdkAtom): PGdkWindow{.cdecl, dynlib: gdklib, importc: "gdk_selection_owner_get_for_display".}
proc gdk_selection_convert*(requestor: PGdkWindow, selection: TGdkAtom,
                            target: TGdkAtom, time: guint32){.cdecl,
    dynlib: gdklib, importc: "gdk_selection_convert".}
proc gdk_selection_property_get*(requestor: PGdkWindow, data: PPguchar,
                                 prop_type: PGdkAtom, prop_format: Pgint): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_selection_property_get".}
proc gdk_selection_send_notify_for_display*(display: PGdkDisplay,
    requestor: guint32, selection: TGdkAtom, target: TGdkAtom,
    `property`: TGdkAtom, time: guint32){.cdecl, dynlib: gdklib,
    importc: "gdk_selection_send_notify_for_display".}
const
  GDK_CURRENT_TIME* = 0
  GDK_PARENT_RELATIVE* = 1
  GDK_OK* = 0
  GDK_ERROR* = - (1)
  GDK_ERROR_PARAM* = - (2)
  GDK_ERROR_FILE* = - (3)
  GDK_ERROR_MEM* = - (4)
  GDK_SHIFT_MASK* = 1 shl 0
  GDK_LOCK_MASK* = 1 shl 1
  GDK_CONTROL_MASK* = 1 shl 2
  GDK_MOD1_MASK* = 1 shl 3
  GDK_MOD2_MASK* = 1 shl 4
  GDK_MOD3_MASK* = 1 shl 5
  GDK_MOD4_MASK* = 1 shl 6
  GDK_MOD5_MASK* = 1 shl 7
  GDK_BUTTON1_MASK* = 1 shl 8
  GDK_BUTTON2_MASK* = 1 shl 9
  GDK_BUTTON3_MASK* = 1 shl 10
  GDK_BUTTON4_MASK* = 1 shl 11
  GDK_BUTTON5_MASK* = 1 shl 12
  GDK_RELEASE_MASK* = 1 shl 30
  GDK_MODIFIER_MASK* = ord(GDK_RELEASE_MASK) or 0x00001FFF
  GDK_INPUT_READ* = 1 shl 0
  GDK_INPUT_WRITE* = 1 shl 1
  GDK_INPUT_EXCEPTION* = 1 shl 2
  GDK_GRAB_SUCCESS* = 0
  GDK_GRAB_ALREADY_GRABBED* = 1
  GDK_GRAB_INVALID_TIME* = 2
  GDK_GRAB_NOT_VIEWABLE* = 3
  GDK_GRAB_FROZEN* = 4

proc GDK_ATOM_TO_POINTER*(atom: TGdkAtom): Pointer
proc GDK_POINTER_TO_ATOM*(p: Pointer): TGdkAtom
proc `GDK_MAKE_ATOM`*(val: guint): TGdkAtom
proc GDK_NONE*(): TGdkAtom
proc GDK_TYPE_VISUAL*(): GType
proc GDK_VISUAL*(anObject: Pointer): PGdkVisual
proc GDK_VISUAL_CLASS*(klass: Pointer): PGdkVisualClass
proc GDK_IS_VISUAL*(anObject: Pointer): bool
proc GDK_IS_VISUAL_CLASS*(klass: Pointer): bool
proc GDK_VISUAL_GET_CLASS*(obj: Pointer): PGdkVisualClass
proc gdk_visual_get_type*(): GType{.cdecl, dynlib: gdklib,
                                    importc: "gdk_visual_get_type".}
const
  GDK_WA_TITLE* = 1 shl 1
  GDK_WA_X* = 1 shl 2
  GDK_WA_Y* = 1 shl 3
  GDK_WA_CURSOR* = 1 shl 4
  GDK_WA_COLORMAP* = 1 shl 5
  GDK_WA_VISUAL* = 1 shl 6
  GDK_WA_WMCLASS* = 1 shl 7
  GDK_WA_NOREDIR* = 1 shl 8
  GDK_HINT_POS* = 1 shl 0
  GDK_HINT_MIN_SIZE* = 1 shl 1
  GDK_HINT_MAX_SIZE* = 1 shl 2
  GDK_HINT_BASE_SIZE* = 1 shl 3
  GDK_HINT_ASPECT* = 1 shl 4
  GDK_HINT_RESIZE_INC* = 1 shl 5
  GDK_HINT_WIN_GRAVITY* = 1 shl 6
  GDK_HINT_USER_POS* = 1 shl 7
  GDK_HINT_USER_SIZE* = 1 shl 8
  GDK_DECOR_ALL* = 1 shl 0
  GDK_DECOR_BORDER* = 1 shl 1
  GDK_DECOR_RESIZEH* = 1 shl 2
  GDK_DECOR_TITLE* = 1 shl 3
  GDK_DECOR_MENU* = 1 shl 4
  GDK_DECOR_MINIMIZE* = 1 shl 5
  GDK_DECOR_MAXIMIZE* = 1 shl 6
  GDK_FUNC_ALL* = 1 shl 0
  GDK_FUNC_RESIZE* = 1 shl 1
  GDK_FUNC_MOVE* = 1 shl 2
  GDK_FUNC_MINIMIZE* = 1 shl 3
  GDK_FUNC_MAXIMIZE* = 1 shl 4
  GDK_FUNC_CLOSE* = 1 shl 5
  GDK_GRAVITY_NORTH_WEST* = 1
  GDK_GRAVITY_NORTH* = 2
  GDK_GRAVITY_NORTH_EAST* = 3
  GDK_GRAVITY_WEST* = 4
  GDK_GRAVITY_CENTER* = 5
  GDK_GRAVITY_EAST* = 6
  GDK_GRAVITY_SOUTH_WEST* = 7
  GDK_GRAVITY_SOUTH* = 8
  GDK_GRAVITY_SOUTH_EAST* = 9
  GDK_GRAVITY_STATIC* = 10

proc GDK_TYPE_WINDOW*(): GType
proc GDK_WINDOW*(anObject: Pointer): PGdkWindow
proc GDK_WINDOW_CLASS*(klass: Pointer): PGdkWindowObjectClass
proc GDK_IS_WINDOW*(anObject: Pointer): bool
proc GDK_IS_WINDOW_CLASS*(klass: Pointer): bool
proc GDK_WINDOW_GET_CLASS*(obj: Pointer): PGdkWindowObjectClass
proc GDK_WINDOW_OBJECT*(anObject: Pointer): PGdkWindowObject
const
  bm_TGdkWindowObject_guffaw_gravity* = 0x00000001'i16
  bp_TGdkWindowObject_guffaw_gravity* = 0'i16
  bm_TGdkWindowObject_input_only* = 0x00000002'i16
  bp_TGdkWindowObject_input_only* = 1'i16
  bm_TGdkWindowObject_modal_hint* = 0x00000004'i16
  bp_TGdkWindowObject_modal_hint* = 2'i16
  bm_TGdkWindowObject_destroyed* = 0x00000018'i16
  bp_TGdkWindowObject_destroyed* = 3'i16

proc GdkWindowObject_guffaw_gravity*(a: var TGdkWindowObject): guint
proc GdkWindowObject_set_guffaw_gravity*(a: var TGdkWindowObject,
    `guffaw_gravity`: guint)
proc GdkWindowObject_input_only*(a: var TGdkWindowObject): guint
proc GdkWindowObject_set_input_only*(a: var TGdkWindowObject,
                                     `input_only`: guint)
proc GdkWindowObject_modal_hint*(a: var TGdkWindowObject): guint
proc GdkWindowObject_set_modal_hint*(a: var TGdkWindowObject,
                                     `modal_hint`: guint)
proc GdkWindowObject_destroyed*(a: var TGdkWindowObject): guint
proc GdkWindowObject_set_destroyed*(a: var TGdkWindowObject, `destroyed`: guint)
proc gdk_window_object_get_type*(): GType{.cdecl, dynlib: gdklib,
    importc: "gdk_window_object_get_type".}
proc gdk_window_new*(parent: PGdkWindow, attributes: PGdkWindowAttr,
                     attributes_mask: gint): PGdkWindow{.cdecl, dynlib: gdklib,
    importc: "gdk_window_new".}
proc gdk_window_destroy*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_destroy".}
proc gdk_window_get_window_type*(window: PGdkWindow): TGdkWindowType{.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_window_type".}
proc gdk_window_at_pointer*(win_x: Pgint, win_y: Pgint): PGdkWindow{.cdecl,
    dynlib: gdklib, importc: "gdk_window_at_pointer".}
proc gdk_window_show*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_show".}
proc gdk_window_hide*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_hide".}
proc gdk_window_withdraw*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_withdraw".}
proc gdk_window_show_unraised*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_show_unraised".}
proc gdk_window_move*(window: PGdkWindow, x: gint, y: gint){.cdecl,
    dynlib: gdklib, importc: "gdk_window_move".}
proc gdk_window_resize*(window: PGdkWindow, width: gint, height: gint){.cdecl,
    dynlib: gdklib, importc: "gdk_window_resize".}
proc gdk_window_move_resize*(window: PGdkWindow, x: gint, y: gint, width: gint,
                             height: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_window_move_resize".}
proc gdk_window_reparent*(window: PGdkWindow, new_parent: PGdkWindow, x: gint,
                          y: gint){.cdecl, dynlib: gdklib,
                                    importc: "gdk_window_reparent".}
proc gdk_window_clear*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_clear".}
proc gdk_window_clear_area*(window: PGdkWindow, x: gint, y: gint, width: gint,
                            height: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_window_clear_area".}
proc gdk_window_clear_area_e*(window: PGdkWindow, x: gint, y: gint, width: gint,
                              height: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_window_clear_area_e".}
proc gdk_window_raise*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_raise".}
proc gdk_window_lower*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_lower".}
proc gdk_window_focus*(window: PGdkWindow, timestamp: guint32){.cdecl,
    dynlib: gdklib, importc: "gdk_window_focus".}
proc gdk_window_set_user_data*(window: PGdkWindow, user_data: gpointer){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_user_data".}
proc gdk_window_set_override_redirect*(window: PGdkWindow,
                                       override_redirect: gboolean){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_override_redirect".}
proc gdk_window_add_filter*(window: PGdkWindow, `function`: TGdkFilterFunc,
                            data: gpointer){.cdecl, dynlib: gdklib,
    importc: "gdk_window_add_filter".}
proc gdk_window_remove_filter*(window: PGdkWindow, `function`: TGdkFilterFunc,
                               data: gpointer){.cdecl, dynlib: gdklib,
    importc: "gdk_window_remove_filter".}
proc gdk_window_scroll*(window: PGdkWindow, dx: gint, dy: gint){.cdecl,
    dynlib: gdklib, importc: "gdk_window_scroll".}
proc gdk_window_shape_combine_mask*(window: PGdkWindow, mask: PGdkBitmap,
                                    x: gint, y: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_window_shape_combine_mask".}
proc gdk_window_shape_combine_region*(window: PGdkWindow,
                                      shape_region: PGdkRegion, offset_x: gint,
                                      offset_y: gint){.cdecl, dynlib: gdklib,
    importc: "gdk_window_shape_combine_region".}
proc gdk_window_set_child_shapes*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_set_child_shapes".}
proc gdk_window_merge_child_shapes*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_merge_child_shapes".}
proc gdk_window_is_visible*(window: PGdkWindow): gboolean{.cdecl,
    dynlib: gdklib, importc: "gdk_window_is_visible".}
proc gdk_window_is_viewable*(window: PGdkWindow): gboolean{.cdecl,
    dynlib: gdklib, importc: "gdk_window_is_viewable".}
proc gdk_window_get_state*(window: PGdkWindow): TGdkWindowState{.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_state".}
proc gdk_window_set_static_gravities*(window: PGdkWindow, use_static: gboolean): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_window_set_static_gravities".}
proc gdk_window_foreign_new_for_display*(display: PGdkDisplay,
    anid: TGdkNativeWindow): PGdkWindow{.cdecl, dynlib: gdklib,
    importc: "gdk_window_foreign_new_for_display".}
proc gdk_window_lookup_for_display*(display: PGdkDisplay, anid: TGdkNativeWindow): PGdkWindow{.
    cdecl, dynlib: gdklib, importc: "gdk_window_lookup_for_display".}
proc gdk_window_set_type_hint*(window: PGdkWindow, hint: TGdkWindowTypeHint){.
    cdecl, dynlib: gdklib, importc: "gdk_window_set_type_hint".}
proc gdk_window_set_modal_hint*(window: PGdkWindow, modal: gboolean){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_modal_hint".}
proc gdk_window_set_geometry_hints*(window: PGdkWindow, geometry: PGdkGeometry,
                                    geom_mask: TGdkWindowHints){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_geometry_hints".}
proc gdk_set_sm_client_id*(sm_client_id: cstring){.cdecl, dynlib: gdklib,
    importc: "gdk_set_sm_client_id".}
proc gdk_window_begin_paint_rect*(window: PGdkWindow, rectangle: PGdkRectangle){.
    cdecl, dynlib: gdklib, importc: "gdk_window_begin_paint_rect".}
proc gdk_window_begin_paint_region*(window: PGdkWindow, region: PGdkRegion){.
    cdecl, dynlib: gdklib, importc: "gdk_window_begin_paint_region".}
proc gdk_window_end_paint*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_end_paint".}
proc gdk_window_set_title*(window: PGdkWindow, title: cstring){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_title".}
proc gdk_window_set_role*(window: PGdkWindow, role: cstring){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_role".}
proc gdk_window_set_transient_for*(window: PGdkWindow, parent: PGdkWindow){.
    cdecl, dynlib: gdklib, importc: "gdk_window_set_transient_for".}
proc gdk_window_set_background*(window: PGdkWindow, color: PGdkColor){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_background".}
proc gdk_window_set_back_pixmap*(window: PGdkWindow, pixmap: PGdkPixmap,
                                 parent_relative: gboolean){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_back_pixmap".}
proc gdk_window_set_cursor*(window: PGdkWindow, cursor: PGdkCursor){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_cursor".}
proc gdk_window_get_user_data*(window: PGdkWindow, data: gpointer){.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_user_data".}
proc gdk_window_get_geometry*(window: PGdkWindow, x: Pgint, y: Pgint,
                              width: Pgint, height: Pgint, depth: Pgint){.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_geometry".}
proc gdk_window_get_position*(window: PGdkWindow, x: Pgint, y: Pgint){.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_position".}
proc gdk_window_get_origin*(window: PGdkWindow, x: Pgint, y: Pgint): gint{.
    cdecl, dynlib: gdklib, importc: "gdk_window_get_origin".}
proc gdk_window_get_root_origin*(window: PGdkWindow, x: Pgint, y: Pgint){.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_root_origin".}
proc gdk_window_get_frame_extents*(window: PGdkWindow, rect: PGdkRectangle){.
    cdecl, dynlib: gdklib, importc: "gdk_window_get_frame_extents".}
proc gdk_window_get_pointer*(window: PGdkWindow, x: Pgint, y: Pgint,
                             mask: PGdkModifierType): PGdkWindow{.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_pointer".}
proc gdk_window_get_parent*(window: PGdkWindow): PGdkWindow{.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_parent".}
proc gdk_window_get_toplevel*(window: PGdkWindow): PGdkWindow{.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_toplevel".}
proc gdk_window_get_children*(window: PGdkWindow): PGList{.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_children".}
proc gdk_window_peek_children*(window: PGdkWindow): PGList{.cdecl,
    dynlib: gdklib, importc: "gdk_window_peek_children".}
proc gdk_window_get_events*(window: PGdkWindow): TGdkEventMask{.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_events".}
proc gdk_window_set_events*(window: PGdkWindow, event_mask: TGdkEventMask){.
    cdecl, dynlib: gdklib, importc: "gdk_window_set_events".}
proc gdk_window_set_icon_list*(window: PGdkWindow, pixbufs: PGList){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_icon_list".}
proc gdk_window_set_icon*(window: PGdkWindow, icon_window: PGdkWindow,
                          pixmap: PGdkPixmap, mask: PGdkBitmap){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_icon".}
proc gdk_window_set_icon_name*(window: PGdkWindow, name: cstring){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_icon_name".}
proc gdk_window_set_group*(window: PGdkWindow, leader: PGdkWindow){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_group".}
proc gdk_window_set_decorations*(window: PGdkWindow,
                                 decorations: TGdkWMDecoration){.cdecl,
    dynlib: gdklib, importc: "gdk_window_set_decorations".}
proc gdk_window_get_decorations*(window: PGdkWindow,
                                 decorations: PGdkWMDecoration): gboolean{.
    cdecl, dynlib: gdklib, importc: "gdk_window_get_decorations".}
proc gdk_window_set_functions*(window: PGdkWindow, functions: TGdkWMFunction){.
    cdecl, dynlib: gdklib, importc: "gdk_window_set_functions".}
proc gdk_window_iconify*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_iconify".}
proc gdk_window_deiconify*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_deiconify".}
proc gdk_window_stick*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_stick".}
proc gdk_window_unstick*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_unstick".}
proc gdk_window_maximize*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_maximize".}
proc gdk_window_unmaximize*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_unmaximize".}
proc gdk_window_register_dnd*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_register_dnd".}
proc gdk_window_begin_resize_drag*(window: PGdkWindow, edge: TGdkWindowEdge,
                                   button: gint, root_x: gint, root_y: gint,
                                   timestamp: guint32){.cdecl, dynlib: gdklib,
    importc: "gdk_window_begin_resize_drag".}
proc gdk_window_begin_move_drag*(window: PGdkWindow, button: gint, root_x: gint,
                                 root_y: gint, timestamp: guint32){.cdecl,
    dynlib: gdklib, importc: "gdk_window_begin_move_drag".}
proc gdk_window_invalidate_rect*(window: PGdkWindow, rect: PGdkRectangle,
                                 invalidate_children: gboolean){.cdecl,
    dynlib: gdklib, importc: "gdk_window_invalidate_rect".}
proc gdk_window_invalidate_region*(window: PGdkWindow, region: PGdkRegion,
                                   invalidate_children: gboolean){.cdecl,
    dynlib: gdklib, importc: "gdk_window_invalidate_region".}
proc gdk_window_invalidate_maybe_recurse*(window: PGdkWindow,
    region: PGdkRegion,
    child_func: gdk_window_invalidate_maybe_recurse_child_func,
    user_data: gpointer){.cdecl, dynlib: gdklib,
                          importc: "gdk_window_invalidate_maybe_recurse".}
proc gdk_window_get_update_area*(window: PGdkWindow): PGdkRegion{.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_update_area".}
proc gdk_window_freeze_updates*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_freeze_updates".}
proc gdk_window_thaw_updates*(window: PGdkWindow){.cdecl, dynlib: gdklib,
    importc: "gdk_window_thaw_updates".}
proc gdk_window_process_all_updates*(){.cdecl, dynlib: gdklib, importc: "gdk_window_process_all_updates".}
proc gdk_window_process_updates*(window: PGdkWindow, update_children: gboolean){.
    cdecl, dynlib: gdklib, importc: "gdk_window_process_updates".}
proc gdk_window_set_debug_updates*(setting: gboolean){.cdecl, dynlib: gdklib,
    importc: "gdk_window_set_debug_updates".}
proc gdk_window_constrain_size*(geometry: PGdkGeometry, flags: guint,
                                width: gint, height: gint, new_width: Pgint,
                                new_height: Pgint){.cdecl, dynlib: gdklib,
    importc: "gdk_window_constrain_size".}
proc gdk_window_get_internal_paint_info*(window: PGdkWindow,
    e: var PGdkDrawable, x_offset: Pgint, y_offset: Pgint){.cdecl,
    dynlib: gdklib, importc: "gdk_window_get_internal_paint_info".}
proc gdk_set_pointer_hooks*(new_hooks: PGdkPointerHooks): PGdkPointerHooks{.
    cdecl, dynlib: gdklib, importc: "gdk_set_pointer_hooks".}
proc gdk_get_default_root_window*(): PGdkWindow{.cdecl, dynlib: gdklib,
    importc: "gdk_get_default_root_window".}
proc gdk_parse_args*(argc: Pgint, v: var PPgchar){.cdecl, dynlib: gdklib,
    importc: "gdk_parse_args".}
proc gdk_init*(argc: Pgint, v: var PPgchar){.cdecl, dynlib: gdklib,
    importc: "gdk_init".}
proc gdk_init_check*(argc: Pgint, v: var PPgchar): gboolean{.cdecl,
    dynlib: gdklib, importc: "gdk_init_check".}
when not defined(GDK_DISABLE_DEPRECATED):
  proc gdk_exit*(error_code: gint){.cdecl, dynlib: gdklib, importc: "gdk_exit".}
proc gdk_set_locale*(): cstring{.cdecl, dynlib: gdklib, importc: "gdk_set_locale".}
proc gdk_get_program_class*(): cstring{.cdecl, dynlib: gdklib,
                                        importc: "gdk_get_program_class".}
proc gdk_set_program_class*(program_class: cstring){.cdecl, dynlib: gdklib,
    importc: "gdk_set_program_class".}
proc gdk_error_trap_push*(){.cdecl, dynlib: gdklib,
                             importc: "gdk_error_trap_push".}
proc gdk_error_trap_pop*(): gint{.cdecl, dynlib: gdklib,
                                  importc: "gdk_error_trap_pop".}
when not defined(GDK_DISABLE_DEPRECATED):
  proc gdk_set_use_xshm*(use_xshm: gboolean){.cdecl, dynlib: gdklib,
      importc: "gdk_set_use_xshm".}
  proc gdk_get_use_xshm*(): gboolean{.cdecl, dynlib: gdklib,
                                     importc: "gdk_get_use_xshm".}
proc gdk_get_display*(): cstring{.cdecl, dynlib: gdklib,
                                 importc: "gdk_get_display".}
proc gdk_get_display_arg_name*(): cstring{.cdecl, dynlib: gdklib,
    importc: "gdk_get_display_arg_name".}
when not defined(GDK_DISABLE_DEPRECATED):
  proc gdk_input_add_full*(source: gint, condition: TGdkInputCondition,
                          `function`: TGdkInputFunction, data: gpointer,
                          destroy: TGdkDestroyNotify): gint{.cdecl,
      dynlib: gdklib, importc: "gdk_input_add_full".}
  proc gdk_input_add*(source: gint, condition: TGdkInputCondition,
                     `function`: TGdkInputFunction, data: gpointer): gint{.
      cdecl, dynlib: gdklib, importc: "gdk_input_add".}
  proc gdk_input_remove*(tag: gint){.cdecl, dynlib: gdklib,
                                    importc: "gdk_input_remove".}
proc gdk_pointer_grab*(window: PGdkWindow, owner_events: gboolean,
                       event_mask: TGdkEventMask, confine_to: PGdkWindow,
                       cursor: PGdkCursor, time: guint32): TGdkGrabStatus{.
    cdecl, dynlib: gdklib, importc: "gdk_pointer_grab".}
proc gdk_keyboard_grab*(window: PGdkWindow, owner_events: gboolean,
                        time: guint32): TGdkGrabStatus{.cdecl, dynlib: gdklib,
    importc: "gdk_keyboard_grab".}
when not defined(GDK_MULTIHEAD_SAFE):
  proc gdk_pointer_ungrab*(time: guint32){.cdecl, dynlib: gdklib,
      importc: "gdk_pointer_ungrab".}
  proc gdk_keyboard_ungrab*(time: guint32){.cdecl, dynlib: gdklib,
      importc: "gdk_keyboard_ungrab".}
  proc gdk_pointer_is_grabbed*(): gboolean{.cdecl, dynlib: gdklib,
      importc: "gdk_pointer_is_grabbed".}
  proc gdk_screen_width*(): gint{.cdecl, dynlib: gdklib,
                                 importc: "gdk_screen_width".}
  proc gdk_screen_height*(): gint{.cdecl, dynlib: gdklib,
                                  importc: "gdk_screen_height".}
  proc gdk_screen_width_mm*(): gint{.cdecl, dynlib: gdklib,
                                    importc: "gdk_screen_width_mm".}
  proc gdk_screen_height_mm*(): gint{.cdecl, dynlib: gdklib,
                                     importc: "gdk_screen_height_mm".}
  proc gdk_beep*(){.cdecl, dynlib: gdklib, importc: "gdk_beep".}
proc gdk_flush*(){.cdecl, dynlib: gdklib, importc: "gdk_flush".}
when not defined(GDK_MULTIHEAD_SAFE):
  proc gdk_set_double_click_time*(msec: guint){.cdecl, dynlib: gdklib,
      importc: "gdk_set_double_click_time".}
proc gdk_rectangle_intersect*(src1: PGdkRectangle, src2: PGdkRectangle,
                              dest: PGdkRectangle): gboolean{.cdecl,
    dynlib: gdklib, importc: "gdk_rectangle_intersect".}
proc gdk_rectangle_union*(src1: PGdkRectangle, src2: PGdkRectangle,
                          dest: PGdkRectangle){.cdecl, dynlib: gdklib,
    importc: "gdk_rectangle_union".}
proc gdk_rectangle_get_type*(): GType{.cdecl, dynlib: gdklib,
                                       importc: "gdk_rectangle_get_type".}
proc GDK_TYPE_RECTANGLE*(): GType
proc gdk_wcstombs*(src: PGdkWChar): cstring{.cdecl, dynlib: gdklib,
    importc: "gdk_wcstombs".}
proc gdk_mbstowcs*(dest: PGdkWChar, src: cstring, dest_max: gint): gint{.cdecl,
    dynlib: gdklib, importc: "gdk_mbstowcs".}
when not defined(GDK_MULTIHEAD_SAFE):
  proc gdk_event_send_client_message*(event: PGdkEvent, xid: guint32): gboolean{.
      cdecl, dynlib: gdklib, importc: "gdk_event_send_client_message".}
  proc gdk_event_send_clientmessage_toall*(event: PGdkEvent){.cdecl,
      dynlib: gdklib, importc: "gdk_event_send_clientmessage_toall".}
proc gdk_event_send_client_message_for_display*(display: PGdkDisplay,
    event: PGdkEvent, xid: guint32): gboolean{.cdecl, dynlib: gdklib,
    importc: "gdk_event_send_client_message_for_display".}
proc gdk_threads_enter*(){.cdecl, dynlib: gdklib, importc: "gdk_threads_enter".}
proc gdk_threads_leave*(){.cdecl, dynlib: gdklib, importc: "gdk_threads_leave".}
proc gdk_threads_init*(){.cdecl, dynlib: gdklib, importc: "gdk_threads_init".}

proc GDK_TYPE_RECTANGLE*(): GType =
  result = gdk_rectangle_get_type()

proc GDK_TYPE_COLORMAP*(): GType =
  result = gdk_colormap_get_type()

proc GDK_COLORMAP*(anObject: pointer): PGdkColormap =
  result = cast[PGdkColormap](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_COLORMAP()))

proc GDK_COLORMAP_CLASS*(klass: pointer): PGdkColormapClass =
  result = cast[PGdkColormapClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_COLORMAP()))

proc GDK_IS_COLORMAP*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_COLORMAP())

proc GDK_IS_COLORMAP_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_COLORMAP())

proc GDK_COLORMAP_GET_CLASS*(obj: pointer): PGdkColormapClass =
  result = cast[PGdkColormapClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_COLORMAP()))

proc GDK_TYPE_COLOR*(): GType =
  result = gdk_color_get_type()

proc gdk_cursor_destroy*(cursor: PGdkCursor) =
  gdk_cursor_unref(cursor)

proc GDK_TYPE_CURSOR*(): GType =
  result = gdk_cursor_get_type()

proc GDK_TYPE_DRAG_CONTEXT*(): GType =
  result = gdk_drag_context_get_type()

proc GDK_DRAG_CONTEXT*(anObject: Pointer): PGdkDragContext =
  result = cast[PGdkDragContext](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      GDK_TYPE_DRAG_CONTEXT()))

proc GDK_DRAG_CONTEXT_CLASS*(klass: Pointer): PGdkDragContextClass =
  result = cast[PGdkDragContextClass](G_TYPE_CHECK_CLASS_CAST(klass,
      GDK_TYPE_DRAG_CONTEXT()))

proc GDK_IS_DRAG_CONTEXT*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_DRAG_CONTEXT())

proc GDK_IS_DRAG_CONTEXT_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_DRAG_CONTEXT())

proc GDK_DRAG_CONTEXT_GET_CLASS*(obj: Pointer): PGdkDragContextClass =
  result = cast[PGdkDragContextClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      GDK_TYPE_DRAG_CONTEXT()))

proc gdkregion_EXTENTCHECK*(r1, r2: PGdkRegionBox): bool =
  result = ((r1.x2) > r2.x1) and ((r1.x1) < r2.x2) and
      ((r1.y2) > r2.y1) and ((r1.y1) < r2.y2)

proc gdkregion_EXTENTS*(r: PGdkRegionBox, idRect: PGdkRegion) =
  if ((r.x1) < idRect.extents.x1):
    idRect.extents.x1 = r.x1
  if (r.y1) < idRect.extents.y1:
    idRect.extents.y1 = r.y1
  if (r.x2) > idRect.extents.x2:
    idRect.extents.x2 = r.x2

proc gdkregion_MEMCHECK*(reg: PGdkRegion, ARect, firstrect: var PGdkRegionBox): bool =
  assert(false) # to implement

proc gdkregion_CHECK_PREVIOUS*(Reg: PGdkRegion, R: PGdkRegionBox,
                               Rx1, Ry1, Rx2, Ry2: gint): bool =
  assert(false) # to implement

proc gdkregion_ADDRECT*(reg: PGdkRegion, r: PGdkRegionBox,
                        rx1, ry1, rx2, ry2: gint) =
  if (((rx1) < rx2) and ((ry1) < ry2) and
      gdkregion_CHECK_PREVIOUS(reg, r, rx1, ry1, rx2, ry2)):
    r.x1 = rx1
    r.y1 = ry1
    r.x2 = rx2
    r.y2 = ry2

proc gdkregion_ADDRECTNOX*(reg: PGdkRegion, r: PGdkRegionBox,
                           rx1, ry1, rx2, ry2: gint) =
  if (((rx1) < rx2) and ((ry1) < ry2) and
      gdkregion_CHECK_PREVIOUS(reg, r, rx1, ry1, rx2, ry2)):
    r.x1 = rx1
    r.y1 = ry1
    r.x2 = rx2
    r.y2 = ry2
    inc(reg . numRects)

proc gdkregion_EMPTY_REGION*(pReg: PGdkRegion): bool =
  result = pReg.numRects == 0'i32

proc gdkregion_REGION_NOT_EMPTY*(pReg: PGdkRegion): bool =
  result = pReg.numRects != 0'i32

proc gdkregion_INBOX*(r: TGdkRegionBox, x, y: gint): bool =
  result = ((((r.x2) > x) and ((r.x1) <= x)) and
            ((r.y2) > y)) and ((r.y1) <= y)

proc GDK_TYPE_DRAWABLE*(): GType =
  result = gdk_drawable_get_type()

proc GDK_DRAWABLE*(anObject: Pointer): PGdkDrawable =
  result = cast[PGdkDrawable](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_DRAWABLE()))

proc GDK_DRAWABLE_CLASS*(klass: Pointer): PGdkDrawableClass =
  result = cast[PGdkDrawableClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_DRAWABLE()))

proc GDK_IS_DRAWABLE*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_DRAWABLE())

proc GDK_IS_DRAWABLE_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_DRAWABLE())

proc GDK_DRAWABLE_GET_CLASS*(obj: Pointer): PGdkDrawableClass =
  result = cast[PGdkDrawableClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_DRAWABLE()))

proc gdk_draw_pixmap*(drawable: PGdkDrawable, gc: PGdkGC, src: PGdkDrawable,
                      xsrc: gint, ysrc: gint, xdest: gint, ydest: gint,
                      width: gint, height: gint) =
  gdk_draw_drawable(drawable, gc, src, xsrc, ysrc, xdest, ydest, width, height)

proc gdk_draw_bitmap*(drawable: PGdkDrawable, gc: PGdkGC, src: PGdkDrawable,
                      xsrc: gint, ysrc: gint, xdest: gint, ydest: gint,
                      width: gint, height: gint) =
  gdk_draw_drawable(drawable, gc, src, xsrc, ysrc, xdest, ydest, width, height)

proc GDK_TYPE_EVENT*(): GType =
  result = gdk_event_get_type()

proc GDK_TYPE_FONT*(): GType =
  result = gdk_font_get_type()

proc GDK_TYPE_GC*(): GType =
  result = gdk_gc_get_type()

proc GDK_GC*(anObject: Pointer): PGdkGC =
  result = cast[PGdkGC](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_GC()))

proc GDK_GC_CLASS*(klass: Pointer): PGdkGCClass =
  result = cast[PGdkGCClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_GC()))

proc GDK_IS_GC*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_GC())

proc GDK_IS_GC_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_GC())

proc GDK_GC_GET_CLASS*(obj: Pointer): PGdkGCClass =
  result = cast[PGdkGCClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_GC()))

proc gdk_gc_destroy*(gc: PGdkGC) =
  g_object_unref(G_OBJECT(gc))

proc GDK_TYPE_IMAGE*(): GType =
  result = gdk_image_get_type()

proc GDK_IMAGE*(anObject: Pointer): PGdkImage =
  result = cast[PGdkImage](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_IMAGE()))

proc GDK_IMAGE_CLASS*(klass: Pointer): PGdkImageClass =
  result = cast[PGdkImageClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_IMAGE()))

proc GDK_IS_IMAGE*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_IMAGE())

proc GDK_IS_IMAGE_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_IMAGE())

proc GDK_IMAGE_GET_CLASS*(obj: Pointer): PGdkImageClass =
  result = cast[PGdkImageClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_IMAGE()))

proc gdk_image_destroy*(image: PGdkImage) =
  g_object_unref(G_OBJECT(image))

proc GDK_TYPE_DEVICE*(): GType =
  result = gdk_device_get_type()

proc GDK_DEVICE*(anObject: Pointer): PGdkDevice =
  result = cast[PGdkDevice](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_DEVICE()))

proc GDK_DEVICE_CLASS*(klass: Pointer): PGdkDeviceClass =
  result = cast[PGdkDeviceClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_DEVICE()))

proc GDK_IS_DEVICE*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_DEVICE())

proc GDK_IS_DEVICE_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_DEVICE())

proc GDK_DEVICE_GET_CLASS*(obj: Pointer): PGdkDeviceClass =
  result = cast[PGdkDeviceClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_DEVICE()))

proc GDK_TYPE_KEYMAP*(): GType =
  result = gdk_keymap_get_type()

proc GDK_KEYMAP*(anObject: Pointer): PGdkKeymap =
  result = cast[PGdkKeymap](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_KEYMAP()))

proc GDK_KEYMAP_CLASS*(klass: Pointer): PGdkKeymapClass =
  result = cast[PGdkKeymapClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_KEYMAP()))

proc GDK_IS_KEYMAP*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_KEYMAP())

proc GDK_IS_KEYMAP_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_KEYMAP())

proc GDK_KEYMAP_GET_CLASS*(obj: Pointer): PGdkKeymapClass =
  result = cast[PGdkKeymapClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_KEYMAP()))

proc GDK_TYPE_PIXMAP*(): GType =
  result = gdk_pixmap_get_type()

proc GDK_PIXMAP*(anObject: Pointer): PGdkPixmap =
  result = cast[PGdkPixmap](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_PIXMAP()))

proc GDK_PIXMAP_CLASS*(klass: Pointer): PGdkPixmapObjectClass =
  result = cast[PGdkPixmapObjectClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_PIXMAP()))

proc GDK_IS_PIXMAP*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_PIXMAP())

proc GDK_IS_PIXMAP_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_PIXMAP())

proc GDK_PIXMAP_GET_CLASS*(obj: Pointer): PGdkPixmapObjectClass =
  result = cast[PGdkPixmapObjectClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_PIXMAP()))

proc GDK_PIXMAP_OBJECT*(anObject: Pointer): PGdkPixmapObject =
  result = cast[PGdkPixmapObject](GDK_PIXMAP(anObject))

proc gdk_bitmap_ref*(drawable: PGdkDrawable): PGdkDrawable =
  result = GDK_DRAWABLE(g_object_ref(G_OBJECT(drawable)))

proc gdk_bitmap_unref*(drawable: PGdkDrawable) =
  g_object_unref(G_OBJECT(drawable))

proc gdk_pixmap_ref*(drawable: PGdkDrawable): PGdkDrawable =
  result = GDK_DRAWABLE(g_object_ref(G_OBJECT(drawable)))

proc gdk_pixmap_unref*(drawable: PGdkDrawable) =
  g_object_unref(G_OBJECT(drawable))

proc gdk_rgb_get_cmap*(): PGdkColormap =
  result = nil #gdk_rgb_get_colormap()

proc GDK_TYPE_DISPLAY*(): GType =
  nil
  #result = nil

proc GDK_DISPLAY_OBJECT*(anObject: pointer): PGdkDisplay =
  result = cast[PGdkDisplay](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_DISPLAY()))

proc GDK_DISPLAY_CLASS*(klass: pointer): PGdkDisplayClass =
  result = cast[PGdkDisplayClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_DISPLAY()))

proc GDK_IS_DISPLAY*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_DISPLAY())

proc GDK_IS_DISPLAY_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_DISPLAY())

proc GDK_DISPLAY_GET_CLASS*(obj: pointer): PGdkDisplayClass =
  result = cast[PGdkDisplayClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_DISPLAY()))

proc GDK_TYPE_SCREEN*(): GType =
  nil

proc GDK_SCREEN*(anObject: Pointer): PGdkScreen =
  result = cast[PGdkScreen](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_SCREEN()))

proc GDK_SCREEN_CLASS*(klass: Pointer): PGdkScreenClass =
  result = cast[PGdkScreenClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_SCREEN()))

proc GDK_IS_SCREEN*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_SCREEN())

proc GDK_IS_SCREEN_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_SCREEN())

proc GDK_SCREEN_GET_CLASS*(obj: Pointer): PGdkScreenClass =
  result = cast[PGdkScreenClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_SCREEN()))

proc GDK_SELECTION_PRIMARY*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(1)

proc GDK_SELECTION_SECONDARY*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(2)

proc GDK_SELECTION_CLIPBOARD*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(69)

proc GDK_TARGET_BITMAP*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(5)

proc GDK_TARGET_COLORMAP*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(7)

proc GDK_TARGET_DRAWABLE*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(17)

proc GDK_TARGET_PIXMAP*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(20)

proc GDK_TARGET_STRING*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(31)

proc GDK_SELECTION_TYPE_ATOM*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(4)

proc GDK_SELECTION_TYPE_BITMAP*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(5)

proc GDK_SELECTION_TYPE_COLORMAP*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(7)

proc GDK_SELECTION_TYPE_DRAWABLE*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(17)

proc GDK_SELECTION_TYPE_INTEGER*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(19)

proc GDK_SELECTION_TYPE_PIXMAP*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(20)

proc GDK_SELECTION_TYPE_WINDOW*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(33)

proc GDK_SELECTION_TYPE_STRING*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(31)

proc GDK_ATOM_TO_POINTER*(atom: TGdkAtom): pointer =
  result = cast[Pointer](atom)

proc GDK_POINTER_TO_ATOM*(p: Pointer): TGdkAtom =
  result = cast[TGdkAtom](p)

proc `GDK_MAKE_ATOM`*(val: guint): TGdkAtom =
  result = cast[TGdkAtom](val)

proc GDK_NONE*(): TGdkAtom =
  result = `GDK_MAKE_ATOM`(0)

proc GDK_TYPE_VISUAL*(): GType =
  result = gdk_visual_get_type()

proc GDK_VISUAL*(anObject: Pointer): PGdkVisual =
  result = cast[PGdkVisual](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_VISUAL()))

proc GDK_VISUAL_CLASS*(klass: Pointer): PGdkVisualClass =
  result = cast[PGdkVisualClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_VISUAL()))

proc GDK_IS_VISUAL*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_VISUAL())

proc GDK_IS_VISUAL_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_VISUAL())

proc GDK_VISUAL_GET_CLASS*(obj: Pointer): PGdkVisualClass =
  result = cast[PGdkVisualClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_VISUAL()))

proc gdk_visual_ref*(v: PGdkVisual) =
  discard g_object_ref(v)

proc gdk_visual_unref*(v: PGdkVisual) =
  g_object_unref(v)

proc GDK_TYPE_WINDOW*(): GType =
  result = gdk_window_object_get_type()

proc GDK_WINDOW*(anObject: Pointer): PGdkWindow =
  result = cast[PGdkWindow](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_WINDOW()))

proc GDK_WINDOW_CLASS*(klass: Pointer): PGdkWindowObjectClass =
  result = cast[PGdkWindowObjectClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_WINDOW()))

proc GDK_IS_WINDOW*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_WINDOW())

proc GDK_IS_WINDOW_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_WINDOW())

proc GDK_WINDOW_GET_CLASS*(obj: Pointer): PGdkWindowObjectClass =
  result = cast[PGdkWindowObjectClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_WINDOW()))

proc GDK_WINDOW_OBJECT*(anObject: Pointer): PGdkWindowObject =
  result = cast[PGdkWindowObject](GDK_WINDOW(anObject))

proc GdkWindowObject_guffaw_gravity*(a: var TGdkWindowObject): guint =
  result = (a.flag0 and bm_TGdkWindowObject_guffaw_gravity) shr
      bp_TGdkWindowObject_guffaw_gravity

proc GdkWindowObject_set_guffaw_gravity*(a: var TGdkWindowObject,
    `guffaw_gravity`: guint) =
  a.flag0 = a.flag0 or
      (int16(`guffaw_gravity` shl bp_TGdkWindowObject_guffaw_gravity) and
      bm_TGdkWindowObject_guffaw_gravity)

proc GdkWindowObject_input_only*(a: var TGdkWindowObject): guint =
  result = (a.flag0 and bm_TGdkWindowObject_input_only) shr
      bp_TGdkWindowObject_input_only

proc GdkWindowObject_set_input_only*(a: var TGdkWindowObject,
                                     `input_only`: guint) =
  a.flag0 = a.flag0 or
      (int16(`input_only` shl bp_TGdkWindowObject_input_only) and
      bm_TGdkWindowObject_input_only)

proc GdkWindowObject_modal_hint*(a: var TGdkWindowObject): guint =
  result = (a.flag0 and bm_TGdkWindowObject_modal_hint) shr
      bp_TGdkWindowObject_modal_hint

proc GdkWindowObject_set_modal_hint*(a: var TGdkWindowObject,
                                     `modal_hint`: guint) =
  a.flag0 = a.flag0 or
      (int16(`modal_hint` shl bp_TGdkWindowObject_modal_hint) and
      bm_TGdkWindowObject_modal_hint)

proc GdkWindowObject_destroyed*(a: var TGdkWindowObject): guint =
  result = (a.flag0 and bm_TGdkWindowObject_destroyed) shr
      bp_TGdkWindowObject_destroyed

proc GdkWindowObject_set_destroyed*(a: var TGdkWindowObject, `destroyed`: guint) =
  a.flag0 = a.flag0 or
      (int16(`destroyed` shl bp_TGdkWindowObject_destroyed) and
      bm_TGdkWindowObject_destroyed)

proc GDK_ROOT_PARENT*(): PGdkWindow =
  result = gdk_get_default_root_window()

proc gdk_window_get_size*(drawable: PGdkDrawable, width: Pgint, height: Pgint) =
  gdk_drawable_get_size(drawable, width, height)

proc gdk_window_get_type*(window: PGdkWindow): TGdkWindowType =
  result = gdk_window_get_window_type(window)

proc gdk_window_get_colormap*(drawable: PGdkDrawable): PGdkColormap =
  result = gdk_drawable_get_colormap(drawable)

proc gdk_window_set_colormap*(drawable: PGdkDrawable, colormap: PGdkColormap) =
  gdk_drawable_set_colormap(drawable, colormap)

proc gdk_window_get_visual*(drawable: PGdkDrawable): PGdkVisual =
  result = gdk_drawable_get_visual(drawable)

proc gdk_window_ref*(drawable: PGdkDrawable): PGdkDrawable =
  result = GDK_DRAWABLE(g_object_ref(G_OBJECT(drawable)))

proc gdk_window_unref*(drawable: PGdkDrawable) =
  g_object_unref(G_OBJECT(drawable))

proc gdk_window_copy_area*(drawable: PGdkDrawable, gc: PGdkGC, x, y: gint,
                           source_drawable: PGdkDrawable,
                           source_x, source_y: gint, width, height: gint) =
  gdk_draw_pixmap(drawable, gc, source_drawable, source_x, source_y, x, y,
                  width, height)
