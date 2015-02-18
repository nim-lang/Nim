# Claro Graphics - an abstraction layer for native UI libraries
#  
#  $Id$
#  
#  The contents of this file are subject to the Mozilla Public License
#  Version 1.1 (the "License"); you may not use this file except in
#  compliance with the License. You may obtain a copy of the License at
#  http://www.mozilla.org/MPL/
#  
#  Software distributed under the License is distributed on an "AS IS"
#  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
#  License for the specific language governing rights and limitations
#  under the License.
#  
#  See the LICENSE file for more details.
# 

## Wrapper for the Claro GUI library. 
## This wrapper calls ``claro_base_init`` and ``claro_graphics_init`` 
## automatically on startup, so you don't have to do it and in fact cannot do
## it because they are not exported.

{.deadCodeElim: on.}

when defined(windows): 
  const 
    clarodll = "claro.dll"
elif defined(macosx): 
  const 
    clarodll = "libclaro.dylib"
else: 
  const 
    clarodll = "libclaro.so"

import cairo

type 
  TNode* {.pure.} = object 
    next*: ptr TNode
    prev*: ptr TNode        # pointer to real structure 
    data*: pointer

  TList* {.pure.} = object 
    head*: ptr TNode
    tail*: ptr TNode        
    count*: int32


proc list_init*(){.cdecl, importc: "list_init", dynlib: clarodll.}
proc list_create*(list: ptr TList){.cdecl, importc: "list_create", 
                                      dynlib: clarodll.}
proc node_create*(): ptr TNode{.cdecl, importc: "node_create", 
                                  dynlib: clarodll.}
proc node_free*(n: ptr TNode){.cdecl, importc: "node_free", dynlib: clarodll.}
proc node_add*(data: pointer, n: ptr TNode, L: ptr TList){.cdecl, 
    importc: "node_add", dynlib: clarodll.}
proc node_prepend*(data: pointer, n: ptr TNode, L: ptr TList){.cdecl, 
    importc: "node_prepend", dynlib: clarodll.}
proc node_del*(n: ptr TNode, L: ptr TList){.cdecl, importc: "node_del", 
    dynlib: clarodll.}
proc node_find*(data: pointer, L: ptr TList): ptr TNode{.cdecl, 
    importc: "node_find", dynlib: clarodll.}
proc node_move*(n: ptr TNode, oldlist: ptr TList, newlist: ptr TList){.
    cdecl, importc: "node_move", dynlib: clarodll.}

type 
  TClaroObj*{.pure, inheritable.} = object 
    typ*: array[0..64 - 1, char]
    destroy_pending*: cint
    event_handlers*: TList
    children*: TList
    parent*: ptr TClaroObj
    appdata*: pointer         # !! this is for APPLICATION USE ONLY !! 
  
  TEvent*{.pure.} = object 
    obj*: ptr TClaroObj    # the object which this event was sent to 
    name*: array[0..64 - 1, char]
    handled*: cint
    arg_num*: cint            # number of arguments 
    format*: array[0..16 - 1, char] # format of the arguments sent 
    arglist*: ptr pointer     # list of args, as per format. 
  
  TEventFunc* = proc (obj: ptr TClaroObj, event: ptr TEvent){.cdecl.}
  TEventIfaceFunc* = proc (obj: ptr TClaroObj, event: ptr TEvent, 
                           data: pointer){.cdecl.}
  TEventHandler*{.pure.} = object 
    typ*: array[0..32 - 1, char]
    data*: pointer
    fun*: TEventFunc   # the function that handles this event 
  

# #define event_handler(n) void n ( TClaroObj *object, event_t *event )
#CLVEXP list_t object_list;

proc object_init*(){.cdecl, importc: "object_init", dynlib: clarodll.}

proc object_override_next_size*(size: cint){.cdecl, 
    importc: "object_override_next_size", dynlib: clarodll.}
  ## Overrides the size of next object to be created, providing the 
  ## size is more than is requested by default.
  ## 
  ## `size` specifies the full size, which is greater than both TClaroObj
  ## and the size that will be requested automatically.
    
proc event_get_arg_ptr*(e: ptr TEvent, arg: cint): pointer{.cdecl, 
    importc: "event_get_arg_ptr", dynlib: clarodll.}
proc event_get_arg_double*(e: ptr TEvent, arg: cint): cdouble{.cdecl, 
    importc: "event_get_arg_double", dynlib: clarodll.}
proc event_get_arg_int*(e: ptr TEvent, arg: cint): cint{.cdecl, 
    importc: "event_get_arg_int", dynlib: clarodll.}
proc object_create*(parent: ptr TClaroObj, size: int32, 
                    typ: cstring): ptr TClaroObj{.
    cdecl, importc: "object_create", dynlib: clarodll.}
proc object_destroy*(obj: ptr TClaroObj){.cdecl, importc: "object_destroy", 
    dynlib: clarodll.}
proc object_set_parent*(obj: ptr TClaroObj, parent: ptr TClaroObj){.cdecl, 
    importc: "object_set_parent", dynlib: clarodll.}

##define object_cmptype(o,t) (!strcmp(((TClaroObj *)o)->type,t))

# event functions 

proc object_addhandler*(obj: ptr TClaroObj, event: cstring, 
                        fun: TEventFunc){.cdecl, 
    importc: "object_addhandler", dynlib: clarodll.}
proc object_addhandler_interface*(obj: ptr TClaroObj, event: cstring, 
                                  fun: TEventFunc, data: pointer){.cdecl, 
    importc: "object_addhandler_interface", dynlib: clarodll.}
proc event_send*(obj: ptr TClaroObj, event: cstring, fmt: cstring): cint{.
    varargs, cdecl, importc: "event_send", dynlib: clarodll.}
proc event_get_name*(event: ptr TEvent): cstring{.cdecl, 
    importc: "event_get_name", dynlib: clarodll.}
proc claro_base_init(){.cdecl, importc: "claro_base_init", dynlib: clarodll.}
proc claro_loop*(){.cdecl, importc: "claro_loop", dynlib: clarodll.}
proc claro_run*(){.cdecl, importc: "claro_run", dynlib: clarodll.}
proc claro_shutdown*(){.cdecl, importc: "claro_shutdown", dynlib: clarodll.}
proc mssleep*(ms: cint){.cdecl, importc: "mssleep", dynlib: clarodll.}
proc claro_graphics_init(){.cdecl, importc: "claro_graphics_init", 
                            dynlib: clarodll.}

const 
  cWidgetNoBorder* = (1 shl 24)
  cWidgetCustomDraw* = (1 shl 25)

type 
  TBounds*{.pure.} = object 
    x*: cint
    y*: cint
    w*: cint
    h*: cint
    owner*: ptr TClaroObj


const 
  cSizeRequestChanged* = 1

type 
  TFont*{.pure.} = object 
    used*: cint
    face*: cstring
    size*: cint
    weight*: cint
    slant*: cint
    decoration*: cint
    native*: pointer

  TColor*{.pure.} = object 
    used*: cint
    r*: cfloat
    g*: cfloat
    b*: cfloat
    a*: cfloat

  TWidget* {.pure.} = object of TClaroObj
    size_req*: ptr TBounds
    size*: TBounds
    size_ct*: TBounds
    supports_alpha*: cint
    size_flags*: cint
    flags*: cint
    visible*: cint
    notify_flags*: cint
    font*: TFont
    native*: pointer          # native widget 
    ndata*: pointer           # additional native data 
    container*: pointer       # native widget container (if not ->native) 
    naddress*: array[0..3, pointer] # addressed for something 
                                    # we override or need to remember 
  
proc clipboard_set_text*(w: ptr TWidget, text: cstring): cint{.cdecl, 
    importc: "clipboard_set_text", dynlib: clarodll.}
  ## Sets the (text) clipboard to the specified text value.
  ##
  ## `w` The widget requesting the action, some platforms may use this value.
  ## `text` The text to place in the clipboard.
  ## returns 1 on success, 0 on failure.

const 
  cNotifyMouse* = 1'i32
  cNotifyKey* = 2'i32

  cFontSlantNormal* = 0
  cFontSlantItalic* = 1
  cFontWeightNormal* = 0
  cFontWeightBold* = 1
  cFontDecorationNormal* = 0
  cFontDecorationUnderline* = 1


proc widget_set_font*(widget: ptr TClaroObj, face: cstring, size: cint, 
                      weight: cint, slant: cint, decoration: cint){.cdecl, 
    importc: "widget_set_font", dynlib: clarodll.}
  ## Sets the font details of the specified widget.
  ## 
  ##  `widget` A widget
  ##  `face` Font face string
  ##  `size` Size of the font in pixels
  ##  `weight` The weight of the font
  ##  `slant` The sland of the font
  ##  `decoration` The decoration of the font
    
proc widget_font_string_width*(widget: ptr TClaroObj, text: cstring, 
                               chars: cint): cint {.
    cdecl, importc: "widget_font_string_width", dynlib: clarodll.}
  ## Calculates the pixel width of the text in the widget's font.
  ## `chars` is the number of characters of text to calculate. Return value
  ## is the width of the specified text in pixels.

const 
  CLARO_APPLICATION* = "claro.graphics"

type 
  TImage* {.pure.} = object of TClaroObj
    width*: cint
    height*: cint
    native*: pointer
    native2*: pointer
    native3*: pointer
    icon*: pointer


proc image_load*(parent: ptr TClaroObj, file: cstring): ptr TImage{.cdecl, 
    importc: "image_load", dynlib: clarodll.}
  ## Loads an image from a file and returns a new image object.
  ## 
  ## The supported formats depend on the platform.
  ## The main effort is to ensure that PNG images will always work.
  ## Generally, JPEGs and possibly GIFs will also work.
  ##
  ## `Parent` object (usually the application's main window), can be nil.
    
proc image_load_inline_png*(parent: ptr TClaroObj, data: cstring, 
                            len: cint): ptr TImage{.cdecl, 
    importc: "image_load_inline_png", dynlib: clarodll.}
  ## Loads an image from inline data and returns a new image object.
  ## `Parent` object (usually the application's main window), can be nil.
  ##  data raw PNG image
  ##  len size of data

when true:
  discard
else:
  # status icons are not supported on all platforms yet:
  type 
    TStatusIcon* {.pure.} = object of TClaroObj
      icon*: ptr TImage
      native*: pointer
      native2*: pointer

  #*
  #  \brief Creates a status icon
  # 
  #  \param parent Parent object (usually the application's main window),
  #                can be NULL.
  #  \param image The image object for the icon NOT NULL
  #  \param flags Flags
  #  \return New status_icon_t object
  # 

  proc status_icon_create*(parent: ptr TClaroObj, icon: ptr TImage, 
                           flags: cint): ptr TStatusIcon {.
      cdecl, importc: "status_icon_create", dynlib: clarodll.}

  #*
  #  \brief sets the status icon's image 
  # 
  #  \param status Status Icon
  #  \param image The image object for the icon
  # 

  proc status_icon_set_icon*(status: ptr TStatusIcon, icon: ptr TImage){.cdecl, 
      importc: "status_icon_set_icon", dynlib: clarodll.}

  #*
  #  \brief sets the status icons's menu
  # 
  #  \param status Status Icon
  #  \param menu The menu object for the popup menu
  # 

  proc status_icon_set_menu*(status: ptr TStatusIcon, menu: ptr TClaroObj){.cdecl, 
      importc: "status_icon_set_menu", dynlib: clarodll.}
  #*
  #  \brief sets the status icon's visibility
  # 
  #  \param status Status Icon
  #  \param visible whether the status icon is visible or not
  # 

  proc status_icon_set_visible*(status: ptr TStatusIcon, visible: cint){.cdecl, 
      importc: "status_icon_set_visible", dynlib: clarodll.}
  #*
  #  \brief sets the status icon's tooltip
  # 
  #  \param status Status Icon
  #  \param tooltip Tooltip string
  # 

  proc status_icon_set_tooltip*(status: ptr TStatusIcon, tooltip: cstring){.cdecl, 
      importc: "status_icon_set_tooltip", dynlib: clarodll.}
    
#*
#  \brief Makes the specified widget visible.
# 
#  \param widget A widget
# 

proc widget_show*(widget: ptr TWidget){.cdecl, importc: "widget_show", 
    dynlib: clarodll.}
#*
#  \brief Makes the specified widget invisible.
# 
#  \param widget A widget
# 

proc widget_hide*(widget: ptr TWidget){.cdecl, importc: "widget_hide", 
    dynlib: clarodll.}
#*
#  \brief Enables the widget, allowing focus
# 
#  \param widget A widget
# 

proc widget_enable*(widget: ptr TWidget){.cdecl, importc: "widget_enable", 
    dynlib: clarodll.}
#*
#  \brief Disables the widget
#  When disabled, a widget appears greyed and cannot
#  receive focus.
# 
#  \param widget A widget
# 

proc widget_disable*(widget: ptr TWidget){.cdecl, importc: "widget_disable", 
    dynlib: clarodll.}
#*
#  \brief Give focus to the specified widget
# 
#  \param widget A widget
# 

proc widget_focus*(widget: ptr TWidget){.cdecl, importc: "widget_focus", 
    dynlib: clarodll.}
#*
#  \brief Closes a widget
# 
#  Requests that a widget be closed by the platform code. 
#  This may or may not result in immediate destruction of the widget,
#  however the actual Claro widget object will remain valid until at
#  least the next loop iteration.
# 
#  \param widget A widget
# 

proc widget_close*(widget: ptr TWidget){.cdecl, importc: "widget_close", 
    dynlib: clarodll.}
#*
#  \brief Retrieve the screen offset of the specified widget.
# 
#  Retrieves the X and Y screen positions of the widget.
# 
#  \param widget A widget
#  \param dx Pointer to the location to place the X position.
#  \param dy Pointer to the location to place the Y position.
# 

proc widget_screen_offset*(widget: ptr TWidget, dx: ptr cint, dy: ptr cint){.
    cdecl, importc: "widget_screen_offset", dynlib: clarodll.}
#*
#  \brief Sets the additional notify events that should be sent.
# 
#  For performance reasons, some events, like mouse and key events,
#  are not sent by default. By specifying such events here, you can
#  elect to receive these events.
# 
#  \param widget A widget
#  \param flags Any number of cWidgetNotify flags ORed together.
# 

proc widget_set_notify*(widget: ptr TWidget, flags: cint){.cdecl, 
    importc: "widget_set_notify", dynlib: clarodll.}


type
  TCursorType* {.size: sizeof(cint).} = enum
    cCursorNormal = 0,
    cCursorTextEdit = 1,
    cCursorWait = 2,
    cCursorPoint = 3

#*
#  \brief Sets the mouse cursor for the widget
# 
#  \param widget A widget
#  \param cursor A valid cCursor* value
# 

proc widget_set_cursor*(widget: ptr TWidget, cursor: TCursorType){.cdecl, 
    importc: "widget_set_cursor", dynlib: clarodll.}

#*
#  \brief Retrieves the key pressed in a key notify event.
# 
#  \param widget A widget
#  \param event An event resource
#  \return The keycode of the key pressed.
# 

proc widget_get_notify_key*(widget: ptr TWidget, event: ptr TEvent): cint{.
    cdecl, importc: "widget_get_notify_key", dynlib: clarodll.}

#*
#  \brief Updates the bounds structure with new values
# 
#  This function should \b always be used instead of setting the
#  members manually. In the future, there may be a \b real reason
#  for this.
# 
#  \param bounds A bounds structure
#  \param x The new X position
#  \param y The new Y position
#  \param w The new width
#  \param h The new height
# 

proc bounds_set*(bounds: ptr TBounds, x: cint, y: cint, w: cint, h: cint){.
    cdecl, importc: "bounds_set", dynlib: clarodll.}
#*
#  \brief Create a new bounds object
# 
#  Creates a new bounds_t for the specified bounds.
# 
#  \param x X position
#  \param y Y position
#  \param w Width
#  \param h Height
#  \return A new bounds_t structure
# 

proc new_bounds*(x: cint, y: cint, w: cint, h: cint): ptr TBounds{.cdecl, 
    importc: "new_bounds", dynlib: clarodll.}
proc get_req_bounds*(widget: ptr TWidget): ptr TBounds{.cdecl, 
    importc: "get_req_bounds", dynlib: clarodll.}
    
var
  noBoundsVar: TBounds # set to all zero which is correct
    
template noBounds*: expr = (addr(bind noBoundsVar))

#* \internal
#  \brief Internal pre-inititalisation hook
# 
#  \param widget A widget
# 

proc widget_pre_init*(widget: ptr TWidget){.cdecl, importc: "widget_pre_init", 
    dynlib: clarodll.}
#* \internal
#  \brief Internal post-inititalisation hook
# 
#  \param widget A widget
# 

proc widget_post_init*(widget: ptr TWidget){.cdecl, 
    importc: "widget_post_init", dynlib: clarodll.}
#* \internal
#  \brief Internal resize event handler
# 
#  \param obj An object
#  \param event An event resource
# 

proc widget_resized_handle*(obj: ptr TWidget, event: ptr TEvent){.cdecl, 
    importc: "widget_resized_handle", dynlib: clarodll.}
# CLVEXP bounds_t no_bounds;
#* \internal
#  \brief Internal default widget creation function
# 
#  \param parent The parent of the widget
#  \param widget_size The size in bytes of the widget's structure
#  \param widget_name The object type of the widget (claro.graphics.widgets.*)
#  \param size_req The initial bounds of the widget
#  \param flags Widget flags
#  \param creator The platform function that will be called to actually create
#                 the widget natively.
#  \return A new widget object
# 

type
  TcgraphicsCreateFunction* = proc (widget: ptr TWidget) {.cdecl.}

proc newdefault*(parent: ptr TWidget, widget_size: int, 
                 widget_name: cstring, size_req: ptr TBounds, flags: cint, 
                 creator: TcgraphicsCreateFunction): ptr TWidget{.cdecl, 
    importc: "default_widget_create", dynlib: clarodll.}
#* \internal
#  \brief Retrieves the native container of the widget's children
# 
#  \param widget A widget
#  \return A pointer to the native widget that will hold w's children
# 

proc widget_get_container*(widget: ptr TWidget): pointer{.cdecl, 
    importc: "widget_get_container", dynlib: clarodll.}
#* \internal
#  \brief Sets the content size of the widget.
# 
#  \param widget A widget
#  \param w New width of the content area of the widget
#  \param h New height of the content area of the widget
#  \param event Whether to send a content_size event
# 

proc widget_set_content_size*(widget: ptr TWidget, w: cint, h: cint, 
                              event: cint){.cdecl, 
    importc: "widget_set_content_size", dynlib: clarodll.}
#* \internal
#  \brief Sets the size of the widget.
# 
#  \param widget A widget
#  \param w New width of the widget
#  \param h New height of the widget
#  \param event Whether to send a resize event
# 

proc widget_set_size*(widget: ptr TWidget, w: cint, h: cint, event: cint){.
    cdecl, importc: "widget_set_size", dynlib: clarodll.}
#* \internal
#  \brief Sets the position of the widget's content area.
# 
#  \param widget A widget
#  \param x New X position of the widget's content area
#  \param y New Y position of the widget's content area
#  \param event Whether to send a content_move event
# 

proc widget_set_content_position*(widget: ptr TWidget, x: cint, y: cint, 
                                  event: cint){.cdecl, 
    importc: "widget_set_content_position", dynlib: clarodll.}
#* \internal
#  \brief Sets the position of the widget.
# 
#  \param widget A widget
#  \param x New X position of the widget's content area
#  \param y New Y position of the widget's content area
#  \param event Whether to send a moved event
# 

proc widget_set_position*(widget: ptr TWidget, x: cint, y: cint, event: cint){.
    cdecl, importc: "widget_set_position", dynlib: clarodll.}
#* \internal
#  \brief Sends a destroy event to the specified widget.
# 
#  You should use widget_close() in application code instead.
# 
#  \param widget A widget
# 

proc widget_destroy*(widget: ptr TWidget){.cdecl, importc: "widget_destroy", 
    dynlib: clarodll.}

type 
  TOpenglWidget* {.pure.} = object of TWidget
    gldata*: pointer


# functions 
#*
#  \brief Creates a OpenGL widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new OpenGL widget object.
# 

proc newopengl*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                flags: cint): ptr TOpenglWidget {.
    cdecl, importc: "opengl_widget_create", dynlib: clarodll.}
#*
#  \brief Flips the front and back buffers
#  
#  \param widget A valid OpenGL widget object
# 

proc opengl_flip*(widget: ptr TOpenglWidget) {.cdecl, importc: "opengl_flip", 
    dynlib: clarodll.}
#*
#  \brief Activates this OpenGL widget's context
#  
#  \param widget A valid OpenGL widget object
# 

proc opengl_activate*(widget: ptr TOpenglWidget) {.
    cdecl, importc: "opengl_activate", dynlib: clarodll.}

type 
  TButton* {.pure.} = object of TWidget
    text*: array[0..256-1, char]


# functions 
#*
#  \brief Creates a Button widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Button widget object.
# 

proc newbutton*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                flags: cint): ptr TButton {.
    cdecl, importc: "button_widget_create", dynlib: clarodll.}
#*
#  \brief Creates a Button widget with a label
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \param label The label for the button
#  \return A new Button widget object.
# 

proc newbutton*(parent: ptr TClaroObj, 
                bounds: ptr TBounds, flags: cint, 
                label: cstring): ptr TButton{.cdecl, 
    importc: "button_widget_create_with_label", dynlib: clarodll.}
#*
#  \brief Changes the label of the button
#  
#  \param obj A valid Button widget object
#  \param label The new label for the button
# 

proc button_set_text*(obj: ptr TButton, label: cstring){.cdecl, 
    importc: "button_set_label", dynlib: clarodll.}

#*
#  \brief Changes the image of the button
# 
#  \warning This function is not implemented yet and is not portable.
#           Do not use it.
#  
#  \param obj A valid Button widget object
#  \param image The new image for the button
# 

proc button_set_image*(obj: ptr TButton, image: ptr TImage){.cdecl, 
    importc: "button_set_image", dynlib: clarodll.}

const 
  CTEXT_SLANT_NORMAL* = cFontSlantNormal
  CTEXT_SLANT_ITALIC* = cFontSlantItalic
  CTEXT_WEIGHT_NORMAL* = cFontWeightNormal
  CTEXT_WEIGHT_BOLD* = cFontWeightBold
  CTEXT_EXTRA_NONE* = cFontDecorationNormal
  CTEXT_EXTRA_UNDERLINE* = cFontDecorationUnderline

# END OLD 

type 
  TCanvas*{.pure.} = object of TWidget
    surface*: cairo.PSurface
    cr*: cairo.PContext
    surfdata*: pointer
    fontdata*: pointer
    font_height*: cint
    fr*: cfloat
    fg*: cfloat
    fb*: cfloat
    fa*: cfloat
    br*: cfloat
    bg*: cfloat
    bb*: cfloat
    ba*: cfloat
    charsize*: array[0..256 - 1, cairo.TTextExtents]
    csz_loaded*: cint
    fontsize*: cint

# functions 
#*
#  \brief Creates a Canvas widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Canvas widget object.
# 

proc newcanvas*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                flags: cint): ptr TCanvas{.
    cdecl, importc: "canvas_widget_create", dynlib: clarodll.}
#*
#  \brief Invalidates and redraws a canvas widget
#  
#  \param widget A valid Canvas widget object.
# 

proc canvas_redraw*(widget: ptr TCanvas){.cdecl, importc: "canvas_redraw", 
    dynlib: clarodll.}
# claro text functions 
#*
#  \brief Set the current text color
#  
#  \param widget A valid Canvas widget object.
#  \param r Red component (0.0 - 1.0)
#  \param g Green component (0.0 - 1.0)
#  \param b Blue component (0.0 - 1.0)
#  \param a Alpha component (0.0 - 1.0)
# 

proc canvas_set_text_color*(widget: ptr TCanvas, r: cdouble, g: cdouble, 
                            b: cdouble, a: cdouble){.cdecl, 
    importc: "canvas_set_text_color", dynlib: clarodll.}
#*
#  \brief Set the current text background color
#  
#  \param widget A valid Canvas widget object.
#  \param r Red component (0.0 - 1.0)
#  \param g Green component (0.0 - 1.0)
#  \param b Blue component (0.0 - 1.0)
#  \param a Alpha component (0.0 - 1.0)
# 

proc canvas_set_text_bgcolor*(widget: ptr TCanvas, r: cdouble, g: cdouble, 
                              b: cdouble, a: cdouble){.cdecl, 
    importc: "canvas_set_text_bgcolor", dynlib: clarodll.}
#*
#  \brief Set the current canvas font
#  
#  \param widget A valid Canvas widget object.
#  \param face The font face
#  \param size The font height in pixels
#  \param weight The weight of the font
#  \param slant The slant of the font
#  \param decoration Font decorations
# 

proc canvas_set_text_font*(widget: ptr TCanvas, face: cstring, size: cint, 
                           weight: cint, slant: cint, decoration: cint){.cdecl, 
    importc: "canvas_set_text_font", dynlib: clarodll.}
#*
#  \brief Calculates the width of the specified text
#  
#  \param widget A valid Canvas widget object.
#  \param text The text to calulate the length of
#  \param len The number of characters of text to calulcate
#  \return Width of the text in pixels
# 

proc canvas_text_width*(widget: ptr TCanvas, text: cstring, len: cint): cint{.
    cdecl, importc: "canvas_text_width", dynlib: clarodll.}
#*
#  \brief Calculates the width of the specified text's bounding box
#  
#  \param widget A valid Canvas widget object.
#  \param text The text to calulate the length of
#  \param len The number of characters of text to calulcate
#  \return Width of the text's bounding box in pixels
# 

proc canvas_text_box_width*(widget: ptr TCanvas, text: cstring, 
                            len: cint): cint{.
    cdecl, importc: "canvas_text_box_width", dynlib: clarodll.}
#*
#  \brief Calculates the number of characters of text that can be displayed
#         before width pixels.
#  
#  \param widget A valid Canvas widget object.
#  \param text The text to calulate the length of
#  \param width The width to fit the text in
#  \return The number of characters of text that will fit in width pixels.
# 

proc canvas_text_display_count*(widget: ptr TCanvas, text: cstring, 
                                width: cint): cint{.cdecl, 
    importc: "canvas_text_display_count", dynlib: clarodll.}
#*
#  \brief Displays the specified text on the canvas
#  
#  \param widget A valid Canvas widget object.
#  \param x The X position at which the text will be drawn
#  \param y The Y position at which the text will be drawn
#  \param text The text to calulate the length of
#  \param len The number of characters of text to calulcate
# 

proc canvas_show_text*(widget: ptr TCanvas, x: cint, y: cint, text: cstring, 
                       len: cint){.cdecl, importc: "canvas_show_text", 
                                   dynlib: clarodll.}
#*
#  \brief Draws a filled rectangle
#  
#  \param widget A valid Canvas widget object.
#  \param x The X position at which the rectangle will start
#  \param y The Y position at which the rectangle will start
#  \param w The width of the rectangle
#  \param h The height of the rectangle
#  \param r Red component (0.0 - 1.0)
#  \param g Green component (0.0 - 1.0)
#  \param b Blue component (0.0 - 1.0)
#  \param a Alpha component (0.0 - 1.0)
# 

proc canvas_fill_rect*(widget: ptr TCanvas, x: cint, y: cint, w: cint, 
                       h: cint, r, g, b, a: cdouble){.
    cdecl, importc: "canvas_fill_rect", dynlib: clarodll.}
#*
#  \brief Draws the specified image on the canvas
#  
#  \param widget A valid Canvas widget object.
#  \param image The image to draw
#  \param x The X position at which the image will be drawn
#  \param y The Y position at which the image will be drawn
# 

proc canvas_draw_image*(widget: ptr TCanvas, image: ptr TImage, x: cint, 
                        y: cint){.cdecl, importc: "canvas_draw_image", 
                                  dynlib: clarodll.}
# claro "extensions" of cairo 
#* \internal
#  \brief Internal claro extension of cairo text functions
# 

proc canvas_cairo_buffered_text_width*(widget: ptr TCanvas, 
                                       text: cstring, len: cint): cint{.cdecl, 
    importc: "canvas_cairo_buffered_text_width", dynlib: clarodll.}
#* \internal
#  \brief Internal claro extension of cairo text functions
# 

proc canvas_cairo_buffered_text_display_count*(widget: ptr TCanvas, 
    text: cstring, width: cint): cint{.cdecl, 
    importc: "canvas_cairo_buffered_text_display_count", 
    dynlib: clarodll.}
proc canvas_get_cairo_context*(widget: ptr TCanvas): cairo.PContext {.cdecl, 
    importc: "canvas_get_cairo_context", dynlib: clarodll.}

type 
  TCheckBox*{.pure.} = object of TWidget
    text*: array[0..256-1, char]
    checked*: cint

#*
#  \brief Creates a Checkbox widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Checkbox widget object.
# 

proc newcheckbox*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                  flags: cint): ptr TCheckBox{.
    cdecl, importc: "checkbox_widget_create", dynlib: clarodll.}
#*
#  \brief Creates a Checkbox widget with a label
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \param label The label for the checkbox
#  \return A new Checkbox widget object.
# 

proc newcheckbox*(parent: ptr TClaroObj, 
                  bounds: ptr TBounds, flags: cint, 
                  label: cstring): ptr TCheckBox {.cdecl, 
    importc: "checkbox_widget_create_with_label", dynlib: clarodll.}
#*
#  \brief Sets a new label for the Checkbox widget
#  
#  \param obj A valid Checkbox widget object.
#  \param label The new label for the checkbox
# 

proc checkbox_set_text*(obj: ptr TCheckBox, label: cstring){.cdecl, 
    importc: "checkbox_set_label", dynlib: clarodll.}
#*
#  \brief Retrieves the checkbox's check state
#  
#  \param obj A valid Checkbox widget object.
#  \return 1 if the checkbox is checked, otherwise 0
# 

proc checkbox_checked*(obj: ptr TCheckBox): cint{.cdecl, 
    importc: "checkbox_get_checked", dynlib: clarodll.}
#*
#  \brief Sets the checkbox's checked state
#  
#  \param obj A valid Checkbox widget object.
#  \param checked 1 if the checkbox should become checked, otherwise 0
# 

proc checkbox_set_checked*(obj: ptr TCheckBox, checked: cint){.cdecl, 
    importc: "checkbox_set_checked", dynlib: clarodll.}


#*
#  List items define items in a list_widget
# 

type 
  TListItem*{.pure.} = object of TClaroObj
    row*: cint
    native*: pointer
    nativeid*: int
    menu*: ptr TClaroObj
    enabled*: cint
    data*: ptr pointer
    ListItemChildren*: TList
    ListItemParent*: ptr TList
    parent_item*: ptr TListItem # drawing related info, not always required
    text_color*: TColor
    sel_text_color*: TColor
    back_color*: TColor
    sel_back_color*: TColor
    font*: TFont

  TListWidget* {.pure.} = object of TWidget ## List widget, base for 
                                            ## widgets containing items
    columns*: cint
    coltypes*: ptr cint
    items*: TList

  TCombo*{.pure.} = object of TListWidget
    selected*: ptr TListItem


# functions 
#*
#  \brief Creates a Combo widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Combo widget object.
# 

proc newcombo*(parent: ptr TClaroObj, bounds: ptr TBounds, 
               flags: cint): ptr TCombo{.
    cdecl, importc: "combo_widget_create", dynlib: clarodll.}
#*
#  \brief Append a row to a Combo widget
#  
#  \param combo A valid Combo widget object.
#  \param text The text for the item.
#  \return A new list item.
# 

proc combo_append_row*(combo: ptr TCombo, text: cstring): ptr TListItem {.
    cdecl, importc: "combo_append_row", dynlib: clarodll.}
#*
#  \brief Insert a row at the specified position into a Combo widget
#  
#  \param combo A valid Combo widget object.
#  \param pos The index at which this item will be placed.
#  \param text The text for the item.
#  \return A new list item.
# 

proc combo_insert_row*(combo: ptr TCombo, pos: cint, 
                       text: cstring): ptr TListItem {.
    cdecl, importc: "combo_insert_row", dynlib: clarodll.}
#*
#  \brief Move a row in a Combo widget
#  
#  \param combo A valid Combo widget object.
#  \param item A valid list item
#  \param row New position to place this item
# 

proc combo_move_row*(combo: ptr TCombo, item: ptr TListItem, row: cint){.
    cdecl, importc: "combo_move_row", dynlib: clarodll.}
#*
#  \brief Remove a row from a Combo widget
#  
#  \param combo A valid Combo widget object.
#  \param item A valid list item
# 

proc combo_remove_row*(combo: ptr TCombo, item: ptr TListItem){.cdecl, 
    importc: "combo_remove_row", dynlib: clarodll.}
#*
#  \brief Returns the currently selected Combo item
#  
#  \param obj A valid Combo widget object.
#  \return The currently selected Combo item, or NULL if no item is selected.
# 

proc combo_get_selected*(obj: ptr TCombo): ptr TListItem{.cdecl, 
    importc: "combo_get_selected", dynlib: clarodll.}
#*
#  \brief Returns the number of rows in a Combo widget
#  
#  \param obj A valid Combo widget object.
#  \return Number of rows
# 

proc combo_get_rows*(obj: ptr TCombo): cint{.cdecl, 
    importc: "combo_get_rows", dynlib: clarodll.}
#*
#  \brief Selects a row in a Combo widget
#  
#  \param obj A valid Combo widget object.
#  \param item A valid list item
# 

proc combo_select_item*(obj: ptr TCombo, item: ptr TListItem){.cdecl, 
    importc: "combo_select_item", dynlib: clarodll.}
#*
#  \brief Removes all entries from a Combo widget
#  
#  \param obj A valid Combo widget object.
# 

proc combo_clear*(obj: ptr TCombo){.cdecl, importc: "combo_clear", 
                                    dynlib: clarodll.}

type 
  TContainerWidget* {.pure.} = object of TWidget


# functions 
#*
#  \brief Creates a Container widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Container widget object.
# 

proc newcontainer*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                   flags: cint): ptr TContainerWidget{.
    cdecl, importc: "container_widget_create", dynlib: clarodll.}

proc newdialog*(parent: ptr TClaroObj, bounds: ptr TBounds, format: cstring, 
                flags: cint): ptr TClaroObj{.cdecl, 
    importc: "dialog_widget_create", dynlib: clarodll.}
proc dialog_set_text*(obj: ptr TClaroObj, text: cstring){.cdecl, 
    importc: "dialog_set_text", dynlib: clarodll.}
proc dialog_set_default_icon*(typ: cstring, file: cstring){.cdecl, 
    importc: "dialog_set_default_icon", dynlib: clarodll.}
proc dialog_get_default_icon*(dialog_type: cint): cstring{.cdecl, 
    importc: "dialog_get_default_icon", dynlib: clarodll.}
proc dialog_warning*(format: cstring, text: cstring): cint{.cdecl, 
    importc: "dialog_warning", dynlib: clarodll.}
proc dialog_info*(format: cstring, text: cstring): cint{.cdecl, 
    importc: "dialog_info", dynlib: clarodll.}
proc dialog_error*(format: cstring, text: cstring): cint{.cdecl, 
    importc: "dialog_error", dynlib: clarodll.}
proc dialog_other*(format: cstring, text: cstring, default_icon: cstring): cint{.
    cdecl, importc: "dialog_other", dynlib: clarodll.}

type 
  TFontDialog* {.pure.} = object of TWidget
    selected*: TFont

# functions 
#*
#  \brief Creates a Font Selection widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param flags Widget flags.
#  \return A new Font Selection widget object.
# 

proc newFontDialog*(parent: ptr TClaroObj, flags: cint): ptr TFontDialog {.
    cdecl, importc: "font_dialog_widget_create", dynlib: clarodll.}
#*
#  \brief Changes the selected font
#  
#  \param obj A valid Font Selection widget object
#  \param font The name of the font
# 

proc font_dialog_set_font*(obj: ptr TFontDialog, face: cstring, size: cint, 
                           weight: cint, slant: cint, decoration: cint){.cdecl, 
    importc: "font_dialog_set_font", dynlib: clarodll.}
#*
#  \brief Returns a structure representing the currently selected font
#  
#  \param obj A valid Font Selection widget object
#  \return A font_t structure containing information about the selected font.
# 

proc font_dialog_get_font*(obj: ptr TFontDialog): ptr TFont{.cdecl, 
    importc: "font_dialog_get_font", dynlib: clarodll.}

type 
  TFrame* {.pure.} = object of TWidget
    text*: array[0..256-1, char]


#*
#  \brief Creates a Frame widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Frame widget object.
# 

proc newframe*(parent: ptr TClaroObj, bounds: ptr TBounds, 
               flags: cint): ptr TFrame{.
    cdecl, importc: "frame_widget_create", dynlib: clarodll.}
#*
#  \brief Creates a Frame widget with a label
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \param label The initial label for the frame
#  \return A new Frame widget object.
# 

proc newframe*(parent: ptr TClaroObj, bounds: ptr TBounds, flags: cint, 
                                     label: cstring): ptr TFrame {.cdecl, 
    importc: "frame_widget_create_with_label", dynlib: clarodll.}
#*
#  \brief Creates a Container widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Container widget object.
# 

proc frame_set_text*(frame: ptr TFrame, label: cstring){.cdecl, 
    importc: "frame_set_label", dynlib: clarodll.}

type 
  TImageWidget* {.pure.} = object of TWidget
    src*: ptr TImage


#*
#  \brief Creates an Image widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Image widget object.
# 

proc newimageWidget*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                     flags: cint): ptr TImageWidget{.
    cdecl, importc: "image_widget_create", dynlib: clarodll.}
#*
#  \brief Creates an Image widget with an image
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \param image A valid Image object.
#  \return A new Image widget object.
# 

proc newimageWidget*(parent: ptr TClaroObj, 
                     bounds: ptr TBounds, flags: cint, 
                     image: ptr TImage): ptr TImageWidget{.cdecl, 
    importc: "image_widget_create_with_image", dynlib: clarodll.}
#*
#  \brief Sets the image object of the image widget
#  
#  \param image A valid image widget
#  \param src The source image object
# 

proc image_set_image*(image: ptr TImageWidget, src: ptr TImage){.cdecl, 
    importc: "image_set_image", dynlib: clarodll.}
    
type 
  TLabel*{.pure.} = object of TWidget
    text*: array[0..256-1, char]

  TcLabelJustify* = enum 
    cLabelLeft = 0x00000001, cLabelRight = 0x00000002, 
    cLabelCenter = 0x00000004, cLabelFill = 0x00000008

#*
#  \brief Creates a Label widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Label widget object.
# 

proc newlabel*(parent: ptr TClaroObj, bounds: ptr TBounds, 
               flags: cint): ptr TLabel{.
    cdecl, importc: "label_widget_create", dynlib: clarodll.}
#*
#  \brief Creates a Label widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Label widget object.
# 

proc newLabel*(parent: ptr TClaroObj, 
               bounds: ptr TBounds, flags: cint, 
               text: cstring): ptr TLabel{.cdecl, 
    importc: "label_widget_create_with_text", dynlib: clarodll.}
#*
#  \brief Sets the text of a label widget
#  
#  \param obj A valid label widget
#  \param text The text this label widget will show
# 

proc label_set_text*(obj: ptr TLabel, text: cstring){.cdecl, 
    importc: "label_set_text", dynlib: clarodll.}
    
#*
#  \brief Sets the alignment/justification of a label
#  
#  \param obj A valid label widget
#  \param text The justification (see cLabelJustify enum)
# 

proc label_set_justify*(obj: ptr TLabel, flags: cint){.cdecl, 
    importc: "label_set_justify", dynlib: clarodll.}
    
const 
  CLIST_TYPE_PTR* = 0
  CLIST_TYPE_STRING* = 1
  CLIST_TYPE_INT* = 2
  CLIST_TYPE_UINT* = 3
  CLIST_TYPE_DOUBLE* = 4

# functions 
#*
#  \brief Initialises a list_widget_t derivative's storage space.
# 
#  \param obj list widget
#  \param col_num number of columns to be used
#  \param cols An array of col_num integers, specifying the 
#              types of the columns.
# 

proc list_widget_init_ptr*(obj: ptr TListWidget, col_num: cint, 
                           cols: ptr cint) {.cdecl, 
    importc: "list_widget_init_ptr", dynlib: clarodll.}
#*
#  \brief Copies and passes on the arg list to list_widget_init_ptr.
# 
#  \param obj list widget
#  \param col_num number of columns to be used
#  \param argpi A pointer to a va_list to parse
# 

#proc list_widget_init_vaptr*(obj: ptr TClaroObj, col_num: cunsignedint, 
#                             argpi: va_list){.cdecl, 
#    importc: "list_widget_init_vaptr", dynlib: clarodll.}

#*
#  Shortcut function, simply calls list_widget_init_ptr with
#  it's own arguments, and a pointer to the first variable argument.
# 

proc list_widget_init*(obj: ptr TListWidget, col_num: cint){.varargs, 
    cdecl, importc: "list_widget_init", dynlib: clarodll.}
#*
#  \brief Inserts a row to a list under parent at the position specified.
# 
#  \param list list to insert item in
#  \param parent item in tree to be used as parent. NULL specifies
#   that it should be a root node.
#  \param row item will be inserted before the item currently at
#   this position. -1 specifies an append.
#  \param argp points to the first element of an array containing
#  the column data as specified by the types in list_widget_init.
# 

#*
#  Shortcut function, calls list_widget_row_insert_ptr with
#  it's own arguments, a position at the end of the list, and
#  a pointer to the first variable argument.
# 

proc list_widget_row_append*(list: ptr TListWidget, 
                             parent: ptr TListItem): ptr TListItem{.
    varargs, cdecl, importc: "list_widget_row_append", dynlib: clarodll.}
#*
#  Shortcut function, calls list_widget_row_insert_ptr with
#  it's own arguments, and a pointer to the first variable argument.
# 

proc list_widget_row_insert*(list: ptr TListWidget, parent: ptr TListItem, 
                             pos: cint): ptr TListItem {.varargs, cdecl, 
    importc: "list_widget_row_insert", dynlib: clarodll.}
#*
#  \brief Removes a row from a list
# 
#  \param list List widget to operate on
#  \param item The item to remove
# 

proc list_widget_row_remove*(list: ptr TListWidget, item: ptr TListItem){.
    cdecl, importc: "list_widget_row_remove", dynlib: clarodll.}
#*
#  \brief Moves a row to a new position in the list
# 
#  \param list List widget to operate on
#  \param item The item to move 
#  \param row Row position to place item before. Passing the current
#             position will result in no change.
# 

proc list_widget_row_move*(list: ptr TListWidget, item: ptr TListItem, 
                           row: cint){.cdecl, importc: "list_widget_row_move", 
                                       dynlib: clarodll.}
#*
#  \brief Return the nth row under parent in the list
# 
#  \param list List widget search
#  \param parent Parent of the item
#  \param row Row index of item to return
# 

proc list_widget_get_row*(list: ptr TListWidget, parent: ptr TListItem, 
                          row: cint): ptr TListItem{.cdecl, 
    importc: "list_widget_get_row", dynlib: clarodll.}
#*
#  \brief Edit items of a row in the list.
# 
#  \param list List widget to edit
#  \param item Row to modify
#  \param args num,val,...,-1 where num is the column and val is the new 
#              value of the column's type. Terminate with -1. 
#              Don't forget the -1.
# 

#*
#  \brief Edit items of a row in the list.
# 
#  \param list List-based (list_widget_t) object
#  \param item Row to modify
#  \param ... num,val,...,-1 where num is the column and val is the new 
#              value of the column's type. Terminate with -1. 
#              Don't forget the -1.
# 

proc list_widget_edit_row*(list: ptr TListWidget, item: ptr TListItem){.
    varargs, cdecl, importc: "list_widget_edit_row", dynlib: clarodll.}
#*
#  \brief Set the text color of an item.
#  This is currently only supported by the TreeView widget.
# 
#  \param item Target list item
#  \param r Red component between 0.0 and 1.0
#  \param g Green component between 0.0 and 1.0
#  \param b Blue component between 0.0 and 1.0
#  \param a Alpha component between 0.0 and 1.0 (reserved for future use,
#          should be 1.0)
# 

proc list_item_set_text_color*(item: ptr TListItem, r: cfloat, g: cfloat, 
                               b: cfloat, a: cfloat){.cdecl, 
    importc: "list_item_set_text_color", dynlib: clarodll.}
#*
#  \brief Set the text background color of an item.
#  This is currently only supported by the TreeView widget.
# 
#  \param item Target list item
#  \param r Red component between 0.0 and 1.0
#  \param g Green component between 0.0 and 1.0
#  \param b Blue component between 0.0 and 1.0
#  \param a Alpha component between 0.0 and 1.0 (reserved for future use,
#           should be 1.0)
# 

proc list_item_set_text_bgcolor*(item: ptr TListItem, r: cfloat, g: cfloat, 
                                 b: cfloat, a: cfloat){.cdecl, 
    importc: "list_item_set_text_bgcolor", dynlib: clarodll.}
#*
#  \brief Set the text color of a selected item.
#  This is currently only supported by the TreeView widget.
# 
#  \param item Target list item
#  \param r Red component between 0.0 and 1.0
#  \param g Green component between 0.0 and 1.0
#  \param b Blue component between 0.0 and 1.0
#  \param a Alpha component between 0.0 and 1.0 (reserved for future use,
#         should be 1.0)
# 

proc list_item_set_sel_text_color*(item: ptr TListItem, r: cfloat, g: cfloat, 
                                   b: cfloat, a: cfloat){.cdecl, 
    importc: "list_item_set_sel_text_color", dynlib: clarodll.}
#*
#  \brief Set the text background color of a selected item.
#  This is currently only supported by the TreeView widget.
# 
#  \param item Target list item
#  \param r Red component between 0.0 and 1.0
#  \param g Green component between 0.0 and 1.0
#  \param b Blue component between 0.0 and 1.0
#  \param a Alpha component between 0.0 and 1.0 (reserved for future use,
#          should be 1.0)
# 

proc list_item_set_sel_text_bgcolor*(item: ptr TListItem, r: cfloat, 
                                     g: cfloat, b: cfloat, a: cfloat){.cdecl, 
    importc: "list_item_set_sel_text_bgcolor", dynlib: clarodll.}
#*
#  \brief Set the font details of the specified item.
# 
#  \param item Target list item
#  \param weight The weight of the font
#  \param slant The slant of the font
#  \param decoration Font decorations
# 

proc list_item_set_font_extra*(item: ptr TListItem, weight: cint, 
                               slant: cint, decoration: cint){.cdecl, 
    importc: "list_item_set_font_extra", dynlib: clarodll.}

type 
  TListbox* {.pure.} = object of TListWidget
    selected*: ptr TListItem

# functions 
#*
#  \brief Creates a ListBox widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new ListBox widget object.
# 

proc newlistbox*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                 flags: cint): ptr TListbox{.
    cdecl, importc: "listbox_widget_create", dynlib: clarodll.}
#*
#  \brief Insert a row at the specified position into a ListBox widget
#  
#  \param listbox A valid ListBox widget object.
#  \param pos The index at which this item will be placed.
#  \param text The text for the item.
#  \return A new list item.
# 

proc listbox_insert_row*(listbox: ptr TListbox, pos: cint, 
                         text: cstring): ptr TListItem{.
    cdecl, importc: "listbox_insert_row", dynlib: clarodll.}
#*
#  \brief Append a row to a ListBox widget
#  
#  \param listbox A valid ListBox widget object.
#  \param text The text for the item.
#  \return A new list item.
# 

proc listbox_append_row*(listbox: ptr TListbox, text: cstring): ptr TListItem{.
    cdecl, importc: "listbox_append_row", dynlib: clarodll.}
#*
#  \brief Move a row in a ListBox widget
#  
#  \param listbox A valid ListBox widget object.
#  \param item A valid list item
#  \param row New position to place this item
# 

proc listbox_move_row*(listbox: ptr TListbox, item: ptr TListItem, row: cint){.
    cdecl, importc: "listbox_move_row", dynlib: clarodll.}
#*
#  \brief Remove a row from a ListBox widget
#  
#  \param listbox A valid ListBox widget object.
#  \param item A valid list item
# 

proc listbox_remove_row*(listbox: ptr TListbox, item: ptr TListItem){.cdecl, 
    importc: "listbox_remove_row", dynlib: clarodll.}
#*
#  \brief Returns the currently selected ListBox item
#  
#  \param obj A valid ListBox widget object.
#  \return The currently selected ListBox item, or NULL if no item is selected.
# 

proc listbox_get_selected*(obj: ptr TListbox): ptr TListItem{.cdecl, 
    importc: "listbox_get_selected", dynlib: clarodll.}
#*
#  \brief Returns the number of rows in a ListBox widget
#  
#  \param obj A valid ListBox widget object.
#  \return Number of rows
# 

proc listbox_get_rows*(obj: ptr TListbox): cint{.cdecl, 
    importc: "listbox_get_rows", dynlib: clarodll.}
#*
#  \brief Selects a row in a ListBox widget
#  
#  \param obj A valid ListBox widget object.
#  \param item A valid list item
# 

proc listbox_select_item*(obj: ptr TListbox, item: ptr TListItem){.cdecl, 
    importc: "listbox_select_item", dynlib: clarodll.}

const 
  cListViewTypeNone* = 0
  cListViewTypeText* = 1
  cListViewTypeCheckBox* = 2
  cListViewTypeProgress* = 3

# whole row checkboxes.. will we really need this? hmm.

const 
  cListViewRowCheckBoxes* = 1

type 
  TListview* {.pure.} = object of TListWidget
    titles*: cstringArray
    nativep*: pointer
    selected*: ptr TListItem


# functions 
#*
#  \brief Creates a ListView widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \param columns The number of columns in the listview
#  \param ... specifies the titles and types of each column. 
#             ("Enable",cListViewTypeCheckBox,"Title",cListViewTypeText,...)
#  \return A new ListView widget object.
# 

proc newlistview*(parent: ptr TClaroObj, bounds: ptr TBounds, columns: cint, 
                  flags: cint): ptr TListview {.varargs, cdecl, 
    importc: "listview_widget_create", dynlib: clarodll.}
#*
#  \brief Append a row to a ListView widget
#  
#  \param listview A valid ListView widget object.
#  \param ... A list of values for each column
#  \return A new list item.
# 

proc listview_append_row*(listview: ptr TListview): ptr TListItem{.varargs, 
    cdecl, importc: "listview_append_row", dynlib: clarodll.}
#*
#  \brief Insert a row at the specified position into a ListView widget
#  
#  \param listview A valid ListView widget object.
#  \param pos The index at which this item will be placed.
#  \param ... A list of values for each column
#  \return A new list item.
# 

proc listview_insert_row*(listview: ptr TListview, pos: cint): ptr TListItem{.
    varargs, cdecl, importc: "listview_insert_row", dynlib: clarodll.}
#*
#  \brief Move a row in a ListView widget
#  
#  \param listview A valid ListView widget object.
#  \param item A valid list item
#  \param row New position to place this item
# 

proc listview_move_row*(listview: ptr TListview, item: ptr TListItem, 
                        row: cint){.cdecl, importc: "listview_move_row", 
                                    dynlib: clarodll.}
#*
#  \brief Remove a row from a ListView widget
#  
#  \param listview A valid ListView widget object.
#  \param item A valid list item
# 

proc listview_remove_row*(listview: ptr TListview, item: ptr TListItem){.
    cdecl, importc: "listview_remove_row", dynlib: clarodll.}
#*
#  \brief Returns the currently selected ListView item
#  
#  \param obj A valid ListView widget object.
#  \return The currently selected ListView item, or NULL if no item is selected.
# 

proc listview_get_selected*(obj: ptr TListview): ptr TListItem{.cdecl, 
    importc: "listview_get_selected", dynlib: clarodll.}
#*
#  \brief Returns the number of rows in a ListView widget
#  
#  \param obj A valid ListView widget object.
#  \return Number of rows
# 

proc listview_get_rows*(obj: ptr TListview): cint{.cdecl, 
    importc: "listview_get_rows", dynlib: clarodll.}
#*
#  \brief Selects a row in a ListView widget
#  
#  \param obj A valid ListView widget object.
#  \param item A valid list item
# 

proc listview_select_item*(obj: ptr TListview, item: ptr TListItem){.cdecl, 
    importc: "listview_select_item", dynlib: clarodll.}

const 
  cMenuPopupAtCursor* = 1

type 
  TMenu* {.pure.} = object of TListWidget


#*
#  \brief Creates a Menu widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param flags Widget flags.
#  \return A new Menu widget object.
# 

proc newmenu*(parent: ptr TClaroObj, flags: cint): ptr TMenu {.cdecl, 
    importc: "menu_widget_create", dynlib: clarodll.}
#*
#  \brief Append a row to a Menu widget
#  
#  \param menu A valid Menu widget object.
#  \param parent The item to place the new item under, or NULL for a root item.
#  \param image An image object, or NULL.
#  \param title A string title, or NULL.
#  \return A new list item.
# 

proc menu_append_item*(menu: ptr TMenu, parent: ptr TListItem, 
                       image: ptr TImage, title: cstring): ptr TListItem{.
    cdecl, importc: "menu_append_item", dynlib: clarodll.}
#*
#  \brief Insert a row into a Menu widget
#  
#  \param menu A valid Menu widget object.
#  \param parent The item to place the new item under, or NULL for a root item.
#  \param pos The position at which to insert this item
#  \param image An image object, or NULL.
#  \param title A string title, or NULL.
#  \return A new list item.
# 

proc menu_insert_item*(menu: ptr TMenu, parent: ptr TListItem, pos: cint, 
                       image: ptr TImage, title: cstring): ptr TListItem{.
    cdecl, importc: "menu_insert_item", dynlib: clarodll.}
#*
#  \brief Append a separator to a Menu widget
#  
#  \param menu A valid Menu widget object.
#  \param parent The item to place the new item under, or NULL for a root item.
#  \return A new list item.
# 

proc menu_append_separator*(menu: ptr TMenu, 
                            parent: ptr TListItem): ptr TListItem{.
    cdecl, importc: "menu_append_separator", dynlib: clarodll.}
#*
#  \brief Insert a separator into a Menu widget
#  
#  \param menu A valid Menu widget object.
#  \param parent The item to place the new item under, or NULL for a root item.
#  \param pos The position at which to insert this item
#  \return A new list item.
# 

proc menu_insert_separator*(menu: ptr TMenu, parent: ptr TListItem, 
                            pos: cint): ptr TListItem{.cdecl, 
    importc: "menu_insert_separator", dynlib: clarodll.}
#*
#  \brief Move a row in a Menu widget
#  
#  \param menu A valid Menu widget object.
#  \param item A valid list item
#  \param row New position to place this item
# 

proc menu_move_item*(menu: ptr TMenu, item: ptr TListItem, row: cint){.
    cdecl, importc: "menu_move_item", dynlib: clarodll.}
#*
#  \brief Remove a row from a Menu widget
#  
#  \param menu A valid Menu widget object.
#  \param item A valid list item
# 

proc menu_remove_item*(menu: ptr TMenu, item: ptr TListItem){.cdecl, 
    importc: "menu_remove_item", dynlib: clarodll.}
#*
#  \brief Returns the number of rows in a Menu widget
#  
#  \param obj A valid Menu widget object.
#  \param parent Item whose children count to return, 
#  or NULL for root item count.
#  \return Number of rows
# 

proc menu_item_count*(obj: ptr TMenu, parent: ptr TListItem): cint{.
    cdecl, importc: "menu_item_count", dynlib: clarodll.}
#*
#  \brief Disables a menu item (no focus and greyed out)
#  
#  \param menu A valid Menu widget object.
#  \param item A valid list item
# 

proc menu_disable_item*(menu: ptr TMenu, item: ptr TListItem){.cdecl, 
    importc: "menu_disable_item", dynlib: clarodll.}
#*
#  \brief Enables a menu item (allows focus and not greyed out)
#  
#  \param menu A valid Menu widget object.
#  \param item A valid list item
# 

proc menu_enable_item*(menu: ptr TMenu, item: ptr TListItem){.cdecl, 
    importc: "menu_enable_item", dynlib: clarodll.}
#*
#  \brief Pops up the menu at the position specified
#  
#  \param menu A valid Menu widget object.
#  \param x The X position
#  \param y The Y position
#  \param flags Flags
# 

proc menu_popup*(menu: ptr TMenu, x: cint, y: cint, flags: cint){.cdecl, 
    importc: "menu_popup", dynlib: clarodll.}
#
#   Menu modifiers
# 

const 
  cModifierShift* = 1 shl 0
  cModifierCommand* = 1 shl 1

type 
  TMenubar* {.pure.} = object of TListWidget

#*
#  \brief Creates a MenuBar widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param flags Widget flags.
#  \return A new MenuBar widget object.
# 

proc newmenubar*(parent: ptr TClaroObj, flags: cint): ptr TMenubar {.cdecl, 
    importc: "menubar_widget_create", dynlib: clarodll.}
#*
#  \brief Add a key binding to a menu items
#  
#  \param menubar A valid MenuBar widget object.
#  \param item The item
#  \param utf8_key The key to use, NOT NULL.
#  \param modifier The modifier key, or 0.
# 

proc menubar_add_key_binding*(menubar: ptr TMenubar, item: ptr TListItem, 
                              utf8_key: cstring, modifier: cint){.cdecl, 
    importc: "menubar_add_key_binding", dynlib: clarodll.}
#*
#  \brief Append a row to a MenuBar widget
#  
#  \param menubar A valid MenuBar widget object.
#  \param parent The item to place the new item under, or NULL for a root item.
#  \param image An image object, or NULL.
#  \param title A string title, or NULL.
#  \return A new list item.
# 

proc menubar_append_item*(menubar: ptr TMenubar, parent: ptr TListItem, 
                          image: ptr TImage, title: cstring): ptr TListItem{.
    cdecl, importc: "menubar_append_item", dynlib: clarodll.}
#*
#  \brief Insert a row into a MenuBar widget
#  
#  \param menubar A valid MenuBar widget object.
#  \param parent The item to place the new item under, or NULL for a root item.
#  \param pos The position at which to insert this item
#  \param image An image object, or NULL.
#  \param title A string title, or NULL.
#  \return A new list item.
# 

proc menubar_insert_item*(menubar: ptr TMenubar, parent: ptr TListItem, 
                          pos: cint, image: ptr TImage, 
                          title: cstring): ptr TListItem{.
    cdecl, importc: "menubar_insert_item", dynlib: clarodll.}
#*
#  \brief Append a separator to a MenuBar widget
#  
#  \param menubar A valid MenuBar widget object.
#  \param parent The item to place the new item under, or NULL for a root item.
#  \return A new list item.
# 

proc menubar_append_separator*(menubar: ptr TMenubar, 
                               parent: ptr TListItem): ptr TListItem{.
    cdecl, importc: "menubar_append_separator", dynlib: clarodll.}
#*
#  \brief Insert a separator into a MenuBar widget
#  
#  \param menubar A valid MenuBar widget object.
#  \param parent The item to place the new item under, or NULL for a root item.
#  \param pos The position at which to insert this item
#  \return A new list item.
# 

proc menubar_insert_separator*(menubar: ptr TMenubar, parent: ptr TListItem, 
                               pos: cint): ptr TListItem{.cdecl, 
    importc: "menubar_insert_separator", dynlib: clarodll.}
#*
#  \brief Move a row in a MenuBar widget
#  
#  \param menubar A valid MenuBar widget object.
#  \param item A valid list item
#  \param row New position to place this item
# 

proc menubar_move_item*(menubar: ptr TMenubar, item: ptr TListItem, 
                        row: cint){.cdecl, importc: "menubar_move_item", 
                                    dynlib: clarodll.}
#*
#  \brief Remove a row from a MenuBar widget
#  
#  \param menubar A valid MenuBar widget object.
#  \param item A valid list item
# 

proc menubar_remove_item*(menubar: ptr TMenubar, item: ptr TListItem) {.
    cdecl, importc: "menubar_remove_item", dynlib: clarodll.}
#*
#  \brief Returns the number of rows in a MenuBar widget
#  
#  \param obj A valid MenuBar widget object.
#  \param parent Item whose children count to return, or NULL for root
#         item count.
#  \return Number of rows
# 

proc menubar_item_count*(obj: ptr TMenubar, parent: ptr TListItem): cint{.
    cdecl, importc: "menubar_item_count", dynlib: clarodll.}
#*
#  \brief Disables a menu item (no focus and greyed out)
#  
#  \param menubar A valid MenuBar widget object.
#  \param item A valid list item
# 

proc menubar_disable_item*(menubar: ptr TMenubar, item: ptr TListItem){.
    cdecl, importc: "menubar_disable_item", dynlib: clarodll.}
#*
#  \brief Enables a menu item (allows focus and not greyed out)
#  
#  \param menubar A valid MenuBar widget object.
#  \param item A valid list item
# 

proc menubar_enable_item*(menubar: ptr TMenubar, item: ptr TListItem){.
    cdecl, importc: "menubar_enable_item", dynlib: clarodll.}

type 
  TProgress* {.pure.} = object of TWidget

  TcProgressStyle* = enum 
    cProgressLeftRight = 0x00000000, cProgressRightLeft = 0x00000001, 
    cProgressTopBottom = 0x00000002, cProgressBottomTop = 0x00000004

#*
#  \brief Creates a Progress widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Progress widget object.
# 

proc newprogress*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                  flags: cint): ptr TProgress {.
    cdecl, importc: "progress_widget_create", dynlib: clarodll.}
#*
#  \brief Sets the value of a progress widget
#  
#  \param progress A valid progress widget object
#  \param percentage Progress value
# 

proc progress_set_level*(progress: ptr TProgress, percentage: cdouble){.cdecl, 
    importc: "progress_set_level", dynlib: clarodll.}
#*
#  \brief Sets the orientation of a progress widget
#  
#  \param progress A valid progress widget object
#  \param flags One of the cProgressStyle values
# 

proc progress_set_orientation*(progress: ptr TProgress, flags: cint){.cdecl, 
    importc: "progress_set_orientation", dynlib: clarodll.}

type 
  TRadioGroup* {.pure.} = object of TClaroObj
    buttons*: TList
    selected*: ptr TClaroObj
    ndata*: pointer

  TRadioButton* {.pure.} = object of TWidget
    text*: array[0..256-1, char]
    group*: ptr TRadioGroup


#*
#  \brief Creates a Radio Group widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param flags Widget flags.
#  \return A new Radio Group widget object.
# 

proc newRadiogroup*(parent: ptr TClaroObj, flags: cint): ptr TRadioGroup {.
    cdecl, importc: "radiogroup_create", dynlib: clarodll.}
#*
#  \brief Creates a Radio Button widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param group A valid Radio Group widget object
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param label The label of the radio widget
#  \param flags Widget flags.
#  \return A new Radio Button widget object.
# 

proc newradiobutton*(parent: ptr TClaroObj, group: ptr TRadioGroup, 
                     bounds: ptr TBounds, label: cstring, 
                     flags: cint): ptr TRadioButton{.
    cdecl, importc: "radiobutton_widget_create", dynlib: clarodll.}
#*
#  \brief Set the label of a Radio Button
#  
#  \param obj A valid Radio Button widget
#  \param label The new label for the Radio Button
# 

proc radiobutton_set_text*(obj: ptr TRadioButton, label: cstring){.cdecl, 
    importc: "radiobutton_set_label", dynlib: clarodll.}
#*
#  \brief Set the group of a Radio Button
#  
#  \param rbutton A valid Radio Button widget
#  \param group A valid Radio Group widget object
# 

proc radiobutton_set_group*(rbutton: ptr TRadioButton, group: ptr TRadioGroup){.
    cdecl, importc: "radiobutton_set_group", dynlib: clarodll.}

const 
  CLARO_SCROLLBAR_MAXIMUM* = 256

type 
  TScrollbar* {.pure.} = object of TWidget
    min*: cint
    max*: cint
    pagesize*: cint


const 
  cScrollbarHorizontal* = 0
  cScrollbarVertical* = 1

# functions 
#*
#  \brief Creates a ScrollBar widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new ScrollBar widget object.
# 

proc newscrollbar*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                   flags: cint): ptr TScrollbar{.
    cdecl, importc: "scrollbar_widget_create", dynlib: clarodll.}
#*
#  \brief Returns the width that scrollbars should be on this platform
#  
#  \return Width of vertical scrollbars
# 

proc scrollbar_get_sys_width*(): cint{.cdecl, 
                                       importc: "scrollbar_get_sys_width", 
                                       dynlib: clarodll.}
#*
#  \brief Sets the range of a ScrollBar widget
#  
#  \param w A valid ScrollBar widget object
#  \param min The minimum value
#  \param max The maximum value
# 

proc scrollbar_set_range*(w: ptr TScrollbar, min: cint, max: cint){.cdecl, 
    importc: "scrollbar_set_range", dynlib: clarodll.}
#*
#  \brief Sets the position of a ScrollBar widget
#  
#  \param w A valid ScrollBar widget object
#  \param pos The new position
# 

proc scrollbar_set_pos*(w: ptr TScrollbar, pos: cint){.cdecl, 
    importc: "scrollbar_set_pos", dynlib: clarodll.}
#*
#  \brief Gets the position of a ScrollBar widget
#  
#  \param w A valid ScrollBar widget object
#  \return The current position
# 

proc scrollbar_get_pos*(w: ptr TScrollbar): cint{.cdecl, 
    importc: "scrollbar_get_pos", dynlib: clarodll.}
#*
#  \brief Sets the page size of a ScrollBar widget
# 
#  \param w A valid ScrollBar widget object
#  \param pagesize The size of a page (the number of units visible at one time)
# 

proc scrollbar_set_pagesize*(w: ptr TScrollbar, pagesize: cint){.cdecl, 
    importc: "scrollbar_set_pagesize", dynlib: clarodll.}
    
type 
  TcSplitterChildren* = enum 
    cSplitterFirst = 0, cSplitterSecond = 1
  TSplitterChild* {.pure.} = object 
    flex*: cint
    size*: cint
    w*: ptr TWidget

  TSplitter* {.pure.} = object of TWidget
    pair*: array[0..1, TSplitterChild]


const 
  cSplitterHorizontal* = 0
  cSplitterVertical* = 1

# functions 
#*
#  \brief Creates a Splitter widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Splitter widget object.
# 

proc newsplitter*(parent: ptr TClaroObj, bounds: ptr TBounds,
                  flags: cint): ptr TSplitter{.
    cdecl, importc: "splitter_widget_create", dynlib: clarodll.}
#*
#  \brief Sets the sizing information of a child
#  
#  \param splitter A valid splitter widget object
#  \param child The child number, either cSplitterFirst or cSplitterSecond.
#  \param flex 1 if this child should receive extra space as the splitter 
#         expands, 0 if not
#  \param size The size of this child
# 

proc splitter_set_info*(splitter: ptr TSplitter, child: cint, flex: cint, 
                        size: cint){.cdecl, importc: "splitter_set_info", 
                                     dynlib: clarodll.}
                                     
type 
  TStatusbar* {.pure.} = object of TWidget
    text*: array[0..256 - 1, char]


#*
#  \brief Creates a StatusBar widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param flags Widget flags.
#  \return A new StatusBar widget object.
# 

proc newstatusbar*(parent: ptr TClaroObj, flags: cint): ptr TStatusbar {.cdecl, 
    importc: "statusbar_widget_create", dynlib: clarodll.}
#*
#  \brief Sets the text of a statusbar
#  
#  \param obj A valid StatusBar widget
#  \param text The new text
# 

proc statusbar_set_text*(obj: ptr TStatusbar, text: cstring){.cdecl, 
    importc: "statusbar_set_text", dynlib: clarodll.}
#*
#  \brief obtains a stock image
#  
#  \param stock_id The string ID of the stock image, NOT NULL.
#  \return The Image object.
# 

proc stock_get_image*(stock_id: cstring): ptr TImage{.cdecl, 
    importc: "stock_get_image", dynlib: clarodll.}
#*
#  \brief adds a stock id image
#  
#  \param stock_id The string ID of the stock image, NOT NULL.
#  \param img The Image object to add.
#  \return The Image object.
# 

proc stock_add_image*(stock_id: cstring, img: ptr TImage){.cdecl, 
    importc: "stock_add_image", dynlib: clarodll.}

const 
  CLARO_TEXTAREA_MAXIMUM = (1024 * 1024)

type 
  TTextArea* {.pure.} = object of TWidget
    text*: array[0..CLARO_TEXTAREA_MAXIMUM - 1, char]


#*
#  \brief Creates a TextArea widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new TextArea widget object.
# 

proc newtextarea*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                  flags: cint): ptr TTextArea{.
    cdecl, importc: "textarea_widget_create", dynlib: clarodll.}
#*
#  \brief Sets the text of a textarea
#  
#  \param obj A valid TextArea widget
#  \param text The new text
# 

proc textarea_set_text*(obj: ptr TTextArea, text: cstring){.cdecl, 
    importc: "textarea_set_text", dynlib: clarodll.}
#*
#  \brief Retrieve the text of a textarea
#  
#  \param obj A valid TextArea widget
#  \return Pointer to an internal reference of the text. Should not be changed.
# 

proc textarea_get_text*(obj: ptr TTextArea): cstring{.cdecl, 
    importc: "textarea_get_text", dynlib: clarodll.}

const 
  CLARO_TEXTBOX_MAXIMUM = 8192

type 
  TTextBox* {.pure.} = object of TWidget
    text*: array[0..CLARO_TEXTBOX_MAXIMUM-1, char]


const 
  cTextBoxTypePassword* = 1

# functions 
#*
#  \brief Creates a TextBox widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new TextBox widget object.
# 

proc newtextbox*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                 flags: cint): ptr TTextBox{.
    cdecl, importc: "textbox_widget_create", dynlib: clarodll.}
#*
#  \brief Sets the text of a textbox
#  
#  \param obj A valid TextBox widget
#  \param text The new text
# 

proc textbox_set_text*(obj: ptr TTextBox, text: cstring){.cdecl, 
    importc: "textbox_set_text", dynlib: clarodll.}
#*
#  \brief Retrieve the text of a textbox
#  
#  \param obj A valid TextBox widget
#  \return Pointer to an internal reference of the text. Should not be changed.
# 

proc textbox_get_text*(obj: ptr TTextBox): cstring{.cdecl, 
    importc: "textbox_get_text", dynlib: clarodll.}
#*
#  \brief Retrieve the cursor position inside a textbox
#  
#  \param obj A valid TextBox widget
#  \return Cursor position inside TextBox
# 

proc textbox_get_pos*(obj: ptr TTextBox): cint{.cdecl, 
    importc: "textbox_get_pos", dynlib: clarodll.}
#*
#  \brief Sets the cursor position inside a textbox
#  
#  \param obj A valid TextBox widget
#  \param pos New cursor position inside TextBox
# 

proc textbox_set_pos*(obj: ptr TTextBox, pos: cint){.cdecl, 
    importc: "textbox_set_pos", dynlib: clarodll.}

const 
  cToolbarShowText* = 1
  cToolbarShowImages* = 2
  cToolbarShowBoth* = 3
  cToolbarAutoSizeButtons* = 4

type 
  TToolbar* {.pure.} = object of TListWidget

#*
#  \brief Creates a ToolBar widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param flags Widget flags.
#  \return A new ToolBar widget object.
# 

proc newtoolbar*(parent: ptr TClaroObj, flags: cint): ptr TToolbar{.cdecl, 
    importc: "toolbar_widget_create", dynlib: clarodll.}
#*
#  \brief Append a row to a ToolBar widget
#  
#  \param toolbar A valid ToolBar widget object.
#  \param image An image object, or NULL.
#  \param title A string title, or NULL.
#  \param tooltip A string tooltip, or NULL.
#  \return A new list item.
# 

proc toolbar_append_icon*(toolbar: ptr TToolbar, image: ptr TImage, 
                          title: cstring, tooltip: cstring): ptr TListItem{.
    cdecl, importc: "toolbar_append_icon", dynlib: clarodll.}
#*
#  \brief Insert a row into a ToolBar widget
#  
#  \param toolbar A valid ToolBar widget object.
#  \param pos The position at which to insert this item
#  \param image An image object, or NULL.
#  \param title A string title, or NULL.
#  \param tooltip A string tooltip, or NULL.
#  \return A new list item.
# 

proc toolbar_insert_icon*(toolbar: ptr TToolbar, pos: cint, 
                          image: ptr TImage, title: cstring, 
                          tooltip: cstring): ptr TListItem{.
    cdecl, importc: "toolbar_insert_icon", dynlib: clarodll.}
#*
#  \brief Append a separator to a ToolBar widget
#  
#  \param toolbar A valid ToolBar widget object.
#  \return A new list item.
# 

proc toolbar_append_separator*(toolbar: ptr TToolbar): ptr TListItem{.cdecl, 
    importc: "toolbar_append_separator", dynlib: clarodll.}
#*
#  \brief Insert a separator into a ToolBar widget
#  
#  \param toolbar A valid ToolBar widget object.
#  \param pos The position at which to insert this item
#  \return A new list item.
# 

proc toolbar_insert_separator*(toolbar: ptr TToolbar, 
                               pos: cint): ptr TListItem {.
    cdecl, importc: "toolbar_insert_separator", dynlib: clarodll.}
#*
#  \brief Assign a menu widget to an item.
# 
#  This will show a small down arrow next to the item
#  that will open this menu.
#  
#  \param toolbar A valid ToolBar widget object.
#  \param item Toolbar item the menu is for.
#  \param menu Menu widget object, or NULL to remove a menu.
# 

proc toolbar_set_item_menu*(toolbar: ptr TToolbar, item: ptr TListItem, 
                            menu: ptr TMenu){.cdecl, 
    importc: "toolbar_set_item_menu", dynlib: clarodll.}
#*
#  \brief Move a row in a ToolBar widget
#  
#  \param toolbar A valid ToolBar widget object.
#  \param item A valid list item
#  \param row New position to place this item
# 

proc toolbar_move_icon*(toolbar: ptr TToolbar, item: ptr TListItem, 
                        row: cint){.cdecl, importc: "toolbar_move_icon", 
                                    dynlib: clarodll.}
#*
#  \brief Remove a row from a ToolBar widget
#  
#  \param toolbar A valid ToolBar widget object.
#  \param item A valid list item
# 

proc toolbar_remove_icon*(toolbar: ptr TToolbar, item: ptr TListItem){.
    cdecl, importc: "toolbar_remove_icon", dynlib: clarodll.}
#*
#  \brief Returns the number of rows in a ToolBar widget
#  
#  \param obj A valid ToolBar widget object.
#  \return Number of rows
# 

proc toolbar_item_count*(obj: ptr TToolbar): cint{.cdecl, 
    importc: "toolbar_item_count", dynlib: clarodll.}
#*
#  \brief TreeView widget
# 

type 
  TTreeview* {.pure.} = object of TListWidget
    selected*: ptr TListItem


# functions 
#*
#  \brief Creates a TreeView widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new TreeView widget object.
# 

proc newtreeview*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                  flags: cint): ptr TTreeview{.
    cdecl, importc: "treeview_widget_create", dynlib: clarodll.}
#*
#  \brief Append a row to a TreeView
#  
#  \param treeview A valid TreeView widget object.
#  \param parent The item under which to place the new item, or NULL for a root node.
#  \param image An image to go to the left of the item, or NULL for no image.
#  \param title The text for the item.
#  \return A new list item.
# 

proc treeview_append_row*(treeview: ptr TTreeview, parent: ptr TListItem, 
                          image: ptr TImage, title: cstring): ptr TListItem{.
    cdecl, importc: "treeview_append_row", dynlib: clarodll.}
#*
#  \brief Insert a row at the specified position into a TreeView
#  
#  \param treeview A valid TreeView widget object.
#  \param parent The item under which to place the new item, or NULL for a root node.
#  \param pos The index at which this item will be placed.
#  \param image An image to go to the left of the item, or NULL for no image.
#  \param title The text for the item.
#  \return A new list item.
# 

proc treeview_insert_row*(treeview: ptr TTreeview, parent: ptr TListItem, 
                          pos: cint, image: ptr TImage, 
                          title: cstring): ptr TListItem{.
    cdecl, importc: "treeview_insert_row", dynlib: clarodll.}
#*
#  \brief Move a row in a TreeView
#  
#  \param treeview A valid TreeView widget object.
#  \param item A valid list item
#  \param row New position to place this item
# 

proc treeview_move_row*(treeview: ptr TTreeview, item: ptr TListItem, 
                        row: cint){.cdecl, importc: "treeview_move_row", 
                                    dynlib: clarodll.}
#*
#  \brief Remove a row from a TreeView
#  
#  \param treeview A valid TreeView widget object.
#  \param item A valid list item
# 

proc treeview_remove_row*(treeview: ptr TTreeview, item: ptr TListItem){.
    cdecl, importc: "treeview_remove_row", dynlib: clarodll.}
#*
#  \brief Expand a row in a TreeView
#  
#  \param treeview A valid TreeView widget object.
#  \param item A valid list item
# 

proc treeview_expand*(treeview: ptr TTreeview, item: ptr TListItem){.cdecl, 
    importc: "treeview_expand", dynlib: clarodll.}
#*
#  \brief Collapse a row in a TreeView
#  
#  \param treeview A valid TreeView widget object.
#  \param item A valid list item
# 

proc treeview_collapse*(treeview: ptr TTreeview, item: ptr TListItem){.cdecl, 
    importc: "treeview_collapse", dynlib: clarodll.}
#*
#  \brief Returns the currently selected TreeView item
#  
#  \param obj A valid TreeView widget object.
#  \return The currently selected TreeView item, or NULL if no item is selected.
# 

proc treeview_get_selected*(obj: ptr TTreeview): ptr TListItem{.cdecl, 
    importc: "treeview_get_selected", dynlib: clarodll.}
#*
#  \brief Returns the number of rows in a TreeView
#  
#  \param obj A valid TreeView widget object.
#  \param parent Return the number of children of this item, or the number of
#                root items if NULL
#  \return Number of rows
# 

proc treeview_get_rows*(obj: ptr TTreeview, parent: ptr TListItem): cint{.
    cdecl, importc: "treeview_get_rows", dynlib: clarodll.}
#*
#  \brief Selects a row in a TreeView
#  
#  \param obj A valid TreeView widget object.
#  \param item A valid list item
# 

proc treeview_select_item*(obj: ptr TTreeview, item: ptr TListItem){.cdecl, 
    importc: "treeview_select_item", dynlib: clarodll.}

const 
  cWindowModalDialog* = 1
  cWindowCenterParent* = 2
  cWindowNoResizing* = 4

type 
  TWindow* {.pure.} = object of TWidget
    title*: array[0..512 - 1, char]
    icon*: ptr TImage
    menubar*: ptr TWidget
    workspace*: ptr TWidget
    exsp_tools*: cint
    exsp_status*: cint
    exsp_init*: cint


const 
  cWindowFixedSize* = 1

# functions 
#*
#  \brief Creates a Window widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Window widget object.
# 

proc newwindow*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                flags: cint): ptr TWindow {.
    cdecl, importc: "window_widget_create", dynlib: clarodll.}
#*
#  \brief Sets a Window's title
#  
#  \param w A valid Window widget object
#  \param title The new title for the window
# 

proc window_set_title*(w: ptr TWindow, title: cstring){.cdecl, 
    importc: "window_set_title", dynlib: clarodll.}
#*
#  \brief Makes a window visible
#  
#  \param w A valid Window widget object
# 

proc window_show*(w: ptr TWindow){.cdecl, importc: "window_show", 
                                     dynlib: clarodll.}
#*
#  \brief Makes a window invisible
#  
#  \param w A valid Window widget object
# 

proc window_hide*(w: ptr TWindow){.cdecl, importc: "window_hide", 
                                     dynlib: clarodll.}
#*
#  \brief Gives focus to a window
#  
#  \param w A valid Window widget object
# 

proc window_focus*(w: ptr TWindow){.cdecl, importc: "window_focus", 
                                      dynlib: clarodll.}
#*
#  \brief Maximises a window
#  
#  \param w A valid Window widget object
# 

proc window_maximize*(w: ptr TWindow){.cdecl, importc: "window_maximise", 
    dynlib: clarodll.}
#*
#  \brief Minimises a window
#  
#  \param w A valid Window widget object
# 

proc window_minimize*(w: ptr TWindow){.cdecl, importc: "window_minimise", 
    dynlib: clarodll.}
#*
#  \brief Restores a window
#  
#  \param w A valid Window widget object
# 

proc window_restore*(w: ptr TWindow){.cdecl, importc: "window_restore", 
                                        dynlib: clarodll.}
#*
#  \brief Sets a window's icon
#  
#  \param w A valid Window widget object
#  \param icon A valid Image object
# 

proc window_set_icon*(w: ptr TWindow, icon: ptr TImage){.cdecl, 
    importc: "window_set_icon", dynlib: clarodll.}

const 
  cWorkspaceTileHorizontally* = 0
  cWorkspaceTileVertically* = 1

type 
  TWorkspace*{.pure.} = object of TWidget

  TWorkspaceWindow*{.pure.} = object of TWidget
    icon*: ptr TImage
    title*: array[0..512 - 1, char]
    workspace*: ptr TWorkspace


# functions (workspace) 
#*
#  \brief Creates a Workspace widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Workspace widget object.
# 

proc newworkspace*(parent: ptr TClaroObj, bounds: ptr TBounds, 
                   flags: cint): ptr TWorkspace{.
    cdecl, importc: "workspace_widget_create", dynlib: clarodll.}
#*
#  \brief Sets the active (visible) workspace child
#  
#  \param workspace A valid workspace widget
#  \param child A valid workspace window widget
# 

proc workspace_set_active*(workspace: ptr TWorkspace, child: ptr TClaroObj){.
    cdecl, importc: "workspace_set_active", dynlib: clarodll.}
#*
#  \brief Returns the active (visible) workspace child
#  
#  \param workspace A valid workspace widget
#  \return The active workspace window widget
# 

proc workspace_get_active*(workspace: ptr TWorkspace): ptr TWorkspace{.cdecl, 
    importc: "workspace_get_active", dynlib: clarodll.}
#*
#  \brief Cascades all workspace windows
#  
#  \param workspace A valid workspace widget
# 

proc workspace_cascade*(workspace: ptr TWorkspace){.cdecl, 
    importc: "workspace_cascade", dynlib: clarodll.}
#*
#  \brief Tiles all workspace windows
#  
#  \param workspace A valid workspace widget
#  \param dir The direction to tile child widgets
# 

proc workspace_tile*(workspace: ptr TWorkspace, dir: cint){.cdecl, 
    importc: "workspace_tile", dynlib: clarodll.}
# functions (workspace_window) 
#*
#  \brief Creates a Workspace widget
#  
#  \param parent The parent widget of this widget, NOT NULL.
#  \param bounds The initial bounds of this widget, or NO_BOUNDS.
#  \param flags Widget flags.
#  \return A new Workspace widget object.
# 

proc newWorkspaceWindow*(parent: ptr TClaroObj, 
                         bounds: ptr TBounds, 
                         flags: cint): ptr TWorkspaceWindow{.
    cdecl, importc: "workspace_window_widget_create", dynlib: clarodll.}
#*
#  \brief Sets the title of a Workspace Window widget
#  
#  \param window A valid Workspace Window widget
#  \param title The new title for the widget
# 

proc workspace_window_set_title*(window: ptr TWorkspaceWindow, 
                                 title: cstring){.cdecl, 
    importc: "workspace_window_set_title", dynlib: clarodll.}
#*
#  \brief Makes a Workspace Window widget visible
#  
#  \param window A valid Workspace Window widget
# 

proc workspace_window_show*(window: ptr TWorkspaceWindow){.cdecl, 
    importc: "workspace_window_show", dynlib: clarodll.}
#*
#  \brief Makes a Workspace Window widget invisible
#  
#  \param window A valid Workspace Window widget
# 

proc workspace_window_hide*(window: ptr TWorkspaceWindow){.cdecl, 
    importc: "workspace_window_hide", dynlib: clarodll.}
#*
#  \brief Restores a Workspace Window widget
#  
#  \param window A valid Workspace Window widget
# 

proc workspace_window_restore*(window: ptr TWorkspaceWindow){.cdecl, 
    importc: "workspace_window_restore", dynlib: clarodll.}
# American spelling 

#*
#  \brief Minimises a Workspace Window widget
#  
#  \param window A valid Workspace Window widget
# 

proc workspace_window_minimize*(window: ptr TWorkspaceWindow){.cdecl, 
    importc: "workspace_window_minimise", dynlib: clarodll.}
#*
#  \brief Maxmimises a Workspace Window widget
#  
#  \param window A valid Workspace Window widget
# 

proc workspace_window_maximize*(window: ptr TWorkspaceWindow){.cdecl, 
    importc: "workspace_window_maximise", dynlib: clarodll.}
#*
#  \brief Sets the icon of a Workspace Window widget
#  
#  \param window A valid Workspace Window widget
#  \param icon A valid Image object.
# 

proc workspace_window_set_icon*(w: ptr TWorkspaceWindow, icon: ptr TImage){.
    cdecl, importc: "workspace_window_set_icon", dynlib: clarodll.}
    
claro_base_init()
claro_graphics_init()

when isMainModule:
  var w = newWindow(nil, newBounds(100, 100, 230, 230), 0)
  window_set_title(w, "Hello, World!")

  var t = newTextbox(w, new_bounds(10, 10, 210, -1), 0)
  widget_set_notify(t, cNotifyKey)
  textbox_set_text(t, "Yeehaw!")

  var b = newButton(w, new_bounds(40, 45, 150, -1), 0, "Push my button!")

  proc push_my_button(obj: ptr TClaroObj, event: ptr TEvent) {.cdecl.} =
    textbox_set_text(t, "You pushed my button!")
    var button = cast[ptr TButton](obj)
    button_set_text(button, "Ouch!")

  object_addhandler(b, "pushed", push_my_button)

  window_show(w)
  window_focus(w)

  claro_loop()

