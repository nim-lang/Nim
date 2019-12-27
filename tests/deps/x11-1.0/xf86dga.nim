#
#   Copyright (c) 1999  XFree86 Inc
#
# $XFree86: xc/include/extensions/xf86dga.h,v 3.20 1999/10/13 04:20:48 dawes Exp $

import
  x, xlib

const
  libXxf86dga* = "libXxf86dga.so"

#type
#  cfloat* = float32

# $XFree86: xc/include/extensions/xf86dga1.h,v 1.2 1999/04/17 07:05:41 dawes Exp $
#
#
#Copyright (c) 1995  Jon Tombs
#Copyright (c) 1995  XFree86 Inc
#
#
#************************************************************************
#
#   THIS IS THE OLD DGA API AND IS OBSOLETE.  PLEASE DO NOT USE IT ANYMORE
#
#************************************************************************

type
  PPcchar* = ptr ptr cstring

const
  X_XF86DGAQueryVersion* = 0
  X_XF86DGAGetVideoLL* = 1
  X_XF86DGADirectVideo* = 2
  X_XF86DGAGetViewPortSize* = 3
  X_XF86DGASetViewPort* = 4
  X_XF86DGAGetVidPage* = 5
  X_XF86DGASetVidPage* = 6
  X_XF86DGAInstallColormap* = 7
  X_XF86DGAQueryDirectVideo* = 8
  X_XF86DGAViewPortChanged* = 9
  XF86DGADirectPresent* = 0x00000001
  XF86DGADirectGraphics* = 0x00000002
  XF86DGADirectMouse* = 0x00000004
  XF86DGADirectKeyb* = 0x00000008
  XF86DGAHasColormap* = 0x00000100
  XF86DGADirectColormap* = 0x00000200

proc XF86DGAQueryVersion*(dpy: PDisplay, majorVersion: Pcint,
                          minorVersion: Pcint): TBool{.cdecl,
    dynlib: libXxf86dga, importc.}
proc XF86DGAQueryExtension*(dpy: PDisplay, event_base: Pcint, error_base: Pcint): TBool{.
    cdecl, dynlib: libXxf86dga, importc.}
proc XF86DGAGetVideoLL*(dpy: PDisplay, screen: cint, base_addr: Pcint,
                        width: Pcint, bank_size: Pcint, ram_size: Pcint): TStatus{.
    cdecl, dynlib: libXxf86dga, importc.}
proc XF86DGAGetVideo*(dpy: PDisplay, screen: cint, base_addr: PPcchar,
                      width: Pcint, bank_size: Pcint, ram_size: Pcint): TStatus{.
    cdecl, dynlib: libXxf86dga, importc.}
proc XF86DGADirectVideo*(dpy: PDisplay, screen: cint, enable: cint): TStatus{.
    cdecl, dynlib: libXxf86dga, importc.}
proc XF86DGADirectVideoLL*(dpy: PDisplay, screen: cint, enable: cint): TStatus{.
    cdecl, dynlib: libXxf86dga, importc.}
proc XF86DGAGetViewPortSize*(dpy: PDisplay, screen: cint, width: Pcint,
                             height: Pcint): TStatus{.cdecl,
    dynlib: libXxf86dga, importc.}
proc XF86DGASetViewPort*(dpy: PDisplay, screen: cint, x: cint, y: cint): TStatus{.
    cdecl, dynlib: libXxf86dga, importc.}
proc XF86DGAGetVidPage*(dpy: PDisplay, screen: cint, vid_page: Pcint): TStatus{.
    cdecl, dynlib: libXxf86dga, importc.}
proc XF86DGASetVidPage*(dpy: PDisplay, screen: cint, vid_page: cint): TStatus{.
    cdecl, dynlib: libXxf86dga, importc.}
proc XF86DGAInstallColormap*(dpy: PDisplay, screen: cint, Colormap: TColormap): TStatus{.
    cdecl, dynlib: libXxf86dga, importc.}
proc XF86DGAForkApp*(screen: cint): cint{.cdecl, dynlib: libXxf86dga, importc.}
proc XF86DGAQueryDirectVideo*(dpy: PDisplay, screen: cint, flags: Pcint): TStatus{.
    cdecl, dynlib: libXxf86dga, importc.}
proc XF86DGAViewPortChanged*(dpy: PDisplay, screen: cint, n: cint): TBool{.
    cdecl, dynlib: libXxf86dga, importc.}
const
  X_XDGAQueryVersion* = 0     # 1 through 9 are in xf86dga1.pp
                              # 10 and 11 are reserved to avoid conflicts with rogue DGA extensions
  X_XDGAQueryModes* = 12
  X_XDGASetMode* = 13
  X_XDGASetViewport* = 14
  X_XDGAInstallColormap* = 15
  X_XDGASelectInput* = 16
  X_XDGAFillRectangle* = 17
  X_XDGACopyArea* = 18
  X_XDGACopyTransparentArea* = 19
  X_XDGAGetViewportStatus* = 20
  X_XDGASync* = 21
  X_XDGAOpenFramebuffer* = 22
  X_XDGACloseFramebuffer* = 23
  X_XDGASetClientVersion* = 24
  X_XDGAChangePixmapMode* = 25
  X_XDGACreateColormap* = 26
  XDGAConcurrentAccess* = 0x00000001
  XDGASolidFillRect* = 0x00000002
  XDGABlitRect* = 0x00000004
  XDGABlitTransRect* = 0x00000008
  XDGAPixmap* = 0x00000010
  XDGAInterlaced* = 0x00010000
  XDGADoublescan* = 0x00020000
  XDGAFlipImmediate* = 0x00000001
  XDGAFlipRetrace* = 0x00000002
  XDGANeedRoot* = 0x00000001
  XF86DGANumberEvents* = 7
  XDGAPixmapModeLarge* = 0
  XDGAPixmapModeSmall* = 1
  XF86DGAClientNotLocal* = 0
  XF86DGANoDirectVideoMode* = 1
  XF86DGAScreenNotActive* = 2
  XF86DGADirectNotActivated* = 3
  XF86DGAOperationNotSupported* = 4
  XF86DGANumberErrors* = (XF86DGAOperationNotSupported + 1)

type
  PXDGAMode* = ptr TXDGAMode
  TXDGAMode*{.final.} = object
    num*: cint                # A unique identifier for the mode (num > 0)
    name*: cstring            # name of mode given in the XF86Config
    verticalRefresh*: cfloat
    flags*: cint              # DGA_CONCURRENT_ACCESS, etc...
    imageWidth*: cint         # linear accessible portion (pixels)
    imageHeight*: cint
    pixmapWidth*: cint        # Xlib accessible portion (pixels)
    pixmapHeight*: cint       # both fields ignored if no concurrent access
    bytesPerScanline*: cint
    byteOrder*: cint          # MSBFirst, LSBFirst
    depth*: cint
    bitsPerPixel*: cint
    redMask*: culong
    greenMask*: culong
    blueMask*: culong
    visualClass*: cshort
    viewportWidth*: cint
    viewportHeight*: cint
    xViewportStep*: cint      # viewport position granularity
    yViewportStep*: cint
    maxViewportX*: cint       # max viewport origin
    maxViewportY*: cint
    viewportFlags*: cint      # types of page flipping possible
    reserved1*: cint
    reserved2*: cint

  PXDGADevice* = ptr TXDGADevice
  TXDGADevice*{.final.} = object
    mode*: TXDGAMode
    data*: Pcuchar
    pixmap*: TPixmap

  PXDGAButtonEvent* = ptr TXDGAButtonEvent
  TXDGAButtonEvent*{.final.} = object
    theType*: cint
    serial*: culong
    display*: PDisplay
    screen*: cint
    time*: TTime
    state*: cuint
    button*: cuint

  PXDGAKeyEvent* = ptr TXDGAKeyEvent
  TXDGAKeyEvent*{.final.} = object
    theType*: cint
    serial*: culong
    display*: PDisplay
    screen*: cint
    time*: TTime
    state*: cuint
    keycode*: cuint

  PXDGAMotionEvent* = ptr TXDGAMotionEvent
  TXDGAMotionEvent*{.final.} = object
    theType*: cint
    serial*: culong
    display*: PDisplay
    screen*: cint
    time*: TTime
    state*: cuint
    dx*: cint
    dy*: cint

  PXDGAEvent* = ptr TXDGAEvent
  TXDGAEvent*{.final.} = object
    pad*: array[0..23, clong] # sorry you have to cast if you want access
                              #Case LongInt Of
                              #      0 : (_type : cint);
                              #      1 : (xbutton : TXDGAButtonEvent);
                              #      2 : (xkey : TXDGAKeyEvent);
                              #      3 : (xmotion : TXDGAMotionEvent);
                              #      4 : (pad : Array[0..23] Of clong);


proc XDGAQueryExtension*(dpy: PDisplay, eventBase: Pcint, erroBase: Pcint): TBool{.
    cdecl, dynlib: libXxf86dga, importc.}
proc XDGAQueryVersion*(dpy: PDisplay, majorVersion: Pcint, minorVersion: Pcint): TBool{.
    cdecl, dynlib: libXxf86dga, importc.}
proc XDGAQueryModes*(dpy: PDisplay, screen: cint, num: Pcint): PXDGAMode{.cdecl,
    dynlib: libXxf86dga, importc.}
proc XDGASetMode*(dpy: PDisplay, screen: cint, mode: cint): PXDGADevice{.cdecl,
    dynlib: libXxf86dga, importc.}
proc XDGAOpenFramebuffer*(dpy: PDisplay, screen: cint): TBool{.cdecl,
    dynlib: libXxf86dga, importc.}
proc XDGACloseFramebuffer*(dpy: PDisplay, screen: cint){.cdecl,
    dynlib: libXxf86dga, importc.}
proc XDGASetViewport*(dpy: PDisplay, screen: cint, x: cint, y: cint, flags: cint){.
    cdecl, dynlib: libXxf86dga, importc.}
proc XDGAInstallColormap*(dpy: PDisplay, screen: cint, cmap: TColormap){.cdecl,
    dynlib: libXxf86dga, importc.}
proc XDGACreateColormap*(dpy: PDisplay, screen: cint, device: PXDGADevice,
                         alloc: cint): TColormap{.cdecl, dynlib: libXxf86dga,
    importc.}
proc XDGASelectInput*(dpy: PDisplay, screen: cint, event_mask: clong){.cdecl,
    dynlib: libXxf86dga, importc.}
proc XDGAFillRectangle*(dpy: PDisplay, screen: cint, x: cint, y: cint,
                        width: cuint, height: cuint, color: culong){.cdecl,
    dynlib: libXxf86dga, importc.}
proc XDGACopyArea*(dpy: PDisplay, screen: cint, srcx: cint, srcy: cint,
                   width: cuint, height: cuint, dstx: cint, dsty: cint){.cdecl,
    dynlib: libXxf86dga, importc.}
proc XDGACopyTransparentArea*(dpy: PDisplay, screen: cint, srcx: cint,
                              srcy: cint, width: cuint, height: cuint,
                              dstx: cint, dsty: cint, key: culong){.cdecl,
    dynlib: libXxf86dga, importc.}
proc XDGAGetViewportStatus*(dpy: PDisplay, screen: cint): cint{.cdecl,
    dynlib: libXxf86dga, importc.}
proc XDGASync*(dpy: PDisplay, screen: cint){.cdecl, dynlib: libXxf86dga, importc.}
proc XDGASetClientVersion*(dpy: PDisplay): TBool{.cdecl, dynlib: libXxf86dga,
    importc.}
proc XDGAChangePixmapMode*(dpy: PDisplay, screen: cint, x: Pcint, y: Pcint,
                           mode: cint){.cdecl, dynlib: libXxf86dga, importc.}
proc XDGAKeyEventToXKeyEvent*(dk: PXDGAKeyEvent, xk: PXKeyEvent){.cdecl,
    dynlib: libXxf86dga, importc.}
# implementation
