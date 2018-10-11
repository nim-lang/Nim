
import 
  x, xlib

#const 
#  libX11* = "libX11.so"

#
#  Automatically converted by H2Pas 0.99.15 from xshm.h
#  The following command line parameters were used:
#    -p
#    -T
#    -S
#    -d
#    -c
#    xshm.h
#

const 
  constX_ShmQueryVersion* = 0
  constX_ShmAttach* = 1
  constX_ShmDetach* = 2
  constX_ShmPutImage* = 3
  constX_ShmGetImage* = 4
  constX_ShmCreatePixmap* = 5
  ShmCompletion* = 0
  ShmNumberEvents* = ShmCompletion + 1
  BadShmSeg* = 0
  ShmNumberErrors* = BadShmSeg + 1

type 
  PShmSeg* = ptr TShmSeg
  TShmSeg* = culong
  PXShmCompletionEvent* = ptr TXShmCompletionEvent
  TXShmCompletionEvent*{.final.} = object 
    theType*: cint
    serial*: culong
    send_event*: TBool
    display*: PDisplay
    drawable*: TDrawable
    major_code*: cint
    minor_code*: cint
    shmseg*: TShmSeg
    offset*: culong

  PXShmSegmentInfo* = ptr TXShmSegmentInfo
  TXShmSegmentInfo*{.final.} = object 
    shmseg*: TShmSeg
    shmid*: cint
    shmaddr*: cstring
    readOnly*: TBool


proc XShmQueryExtension*(para1: PDisplay): TBool{.cdecl, dynlib: libX11, importc.}
proc XShmGetEventBase*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XShmQueryVersion*(para1: PDisplay, para2: Pcint, para3: Pcint, para4: PBool): TBool{.
    cdecl, dynlib: libX11, importc.}
proc XShmPixmapFormat*(para1: PDisplay): cint{.cdecl, dynlib: libX11, importc.}
proc XShmAttach*(para1: PDisplay, para2: PXShmSegmentInfo): TStatus{.cdecl, 
    dynlib: libX11, importc.}
proc XShmDetach*(para1: PDisplay, para2: PXShmSegmentInfo): TStatus{.cdecl, 
    dynlib: libX11, importc.}
proc XShmPutImage*(para1: PDisplay, para2: TDrawable, para3: TGC, 
                   para4: PXImage, para5: cint, para6: cint, para7: cint, 
                   para8: cint, para9: cuint, para10: cuint, para11: TBool): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XShmGetImage*(para1: PDisplay, para2: TDrawable, para3: PXImage, 
                   para4: cint, para5: cint, para6: culong): TStatus{.cdecl, 
    dynlib: libX11, importc.}
proc XShmCreateImage*(para1: PDisplay, para2: PVisual, para3: cuint, 
                      para4: cint, para5: cstring, para6: PXShmSegmentInfo, 
                      para7: cuint, para8: cuint): PXImage{.cdecl, 
    dynlib: libX11, importc.}
proc XShmCreatePixmap*(para1: PDisplay, para2: TDrawable, para3: cstring, 
                       para4: PXShmSegmentInfo, para5: cuint, para6: cuint, 
                       para7: cuint): TPixmap{.cdecl, dynlib: libX11, importc.}
# implementation
