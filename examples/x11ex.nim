import xlib, xutil, x, keysym

const
  WINDOW_WIDTH = 400
  WINDOW_HEIGHT = 300
  
var
  width, height: cint
  display: PDisplay
  screen: cint
  depth: int
  win: TWindow
  sizeHints: TXSizeHints

proc create_window = 
  width = WINDOW_WIDTH
  height = WINDOW_HEIGHT

  display = XOpenDisplay(nil)
  if display == nil:
    echo("Verbindung zum X-Server fehlgeschlagen")
    quit(1)

  screen = XDefaultScreen(display)
  depth = XDefaultDepth(display, screen)
  var rootwin = XRootWindow(display, screen)
  win = XCreateSimpleWindow(display, rootwin, 100, 10,
                            width, height, 5,
                            XBlackPixel(display, screen),
                            XWhitePixel(display, screen))
  size_hints.flags = PSize or PMinSize or PMaxSize
  size_hints.min_width =  width
  size_hints.max_width =  width
  size_hints.min_height = height
  size_hints.max_height = height
  discard XSetStandardProperties(display, win, "Simple Window", "window",
                         0, nil, 0, addr(size_hints))
  discard XSelectInput(display, win, ButtonPressMask or KeyPressMask or 
                                     PointerMotionMask)
  discard XMapWindow(display, win)

proc close_window =
  discard XDestroyWindow(display, win)
  discard XCloseDisplay(display)
    
var
  xev: TXEvent

proc process_event =
  var key: TKeySym
  case int(xev.theType)
  of KeyPress:
    key = XLookupKeysym(cast[ptr TXKeyEvent](addr(xev)), 0)
    if key != 0:
      echo("keyboard event")
  of ButtonPressMask, PointerMotionMask:
    Echo("Mouse event")
  else: nil

proc eventloop =
  discard XFlush(display)
  var num_events = int(XPending(display))
  while num_events != 0:
    dec(num_events)
    discard XNextEvent(display, addr(xev))
    process_event()

create_window()
while true:
  eventloop()
close_window()
