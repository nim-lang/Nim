# Converted from X11/Xinerama.h 
import                        
  xlib

const
  xineramaLib = "libXinerama.so"

type 
  PXineramaScreenInfo* = ptr TXineramaScreenInfo
  TXineramaScreenInfo*{.final.} = object 
    screen_number*: cint
    x_org*: int16
    y_org*: int16
    width*: int16
    height*: int16


proc XineramaQueryExtension*(dpy: PDisplay, event_base: Pcint, error_base: Pcint): TBool{.
    cdecl, dynlib: xineramaLib, importc.}
proc XineramaQueryVersion*(dpy: PDisplay, major: Pcint, minor: Pcint): TStatus{.
    cdecl, dynlib: xineramaLib, importc.}
proc XineramaIsActive*(dpy: PDisplay): TBool{.cdecl, dynlib: xineramaLib, importc.}
proc XineramaQueryScreens*(dpy: PDisplay, number: Pcint): PXineramaScreenInfo{.
    cdecl, dynlib: xineramaLib, importc.}

