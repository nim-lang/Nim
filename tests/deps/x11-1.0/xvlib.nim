#***********************************************************
#Copyright 1991 by Digital Equipment Corporation, Maynard, Massachusetts,
#and the Massachusetts Institute of Technology, Cambridge, Massachusetts.
#
#                        All Rights Reserved
#
#Permission to use, copy, modify, and distribute this software and its
#documentation for any purpose and without fee is hereby granted,
#provided that the above copyright notice appear in all copies and that
#both that copyright notice and this permission notice appear in
#supporting documentation, and that the names of Digital or MIT not be
#used in advertising or publicity pertaining to distribution of the
#software without specific, written prior permission.
#
#DIGITAL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
#ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL
#DIGITAL BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR
#ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
#WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
#ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
#SOFTWARE.
#
#******************************************************************
# $XFree86: xc/include/extensions/Xvlib.h,v 1.3 1999/12/11 19:28:48 mvojkovi Exp $
#*
#** File:
#**
#**   Xvlib.h --- Xv library public header file
#**
#** Author:
#**
#**   David Carver (Digital Workstation Engineering/Project Athena)
#**
#** Revisions:
#**
#**   26.06.91 Carver
#**     - changed XvFreeAdaptors to XvFreeAdaptorInfo
#**     - changed XvFreeEncodings to XvFreeEncodingInfo
#**
#**   11.06.91 Carver
#**     - changed SetPortControl to SetPortAttribute
#**     - changed GetPortControl to GetPortAttribute
#**     - changed QueryBestSize
#**
#**   05.15.91 Carver
#**     - version 2.0 upgrade
#**
#**   01.24.91 Carver
#**     - version 1.4 upgrade
#**
#*

import
  x, xlib, xshm, xv

const
  libXv* = "libXv.so"

type
  PXvRational* = ptr TXvRational
  TXvRational*{.final.} = object
    numerator*: cint
    denominator*: cint

  PXvAttribute* = ptr TXvAttribute
  TXvAttribute*{.final.} = object
    flags*: cint              # XvGettable, XvSettable
    min_value*: cint
    max_value*: cint
    name*: cstring

  PPXvEncodingInfo* = ptr PXvEncodingInfo
  PXvEncodingInfo* = ptr TXvEncodingInfo
  TXvEncodingInfo*{.final.} = object
    encoding_id*: TXvEncodingID
    name*: cstring
    width*: culong
    height*: culong
    rate*: TXvRational
    num_encodings*: culong

  PXvFormat* = ptr TXvFormat
  TXvFormat*{.final.} = object
    depth*: cchar
    visual_id*: culong

  PPXvAdaptorInfo* = ptr PXvAdaptorInfo
  PXvAdaptorInfo* = ptr TXvAdaptorInfo
  TXvAdaptorInfo*{.final.} = object
    base_id*: TXvPortID
    num_ports*: culong
    thetype*: cchar
    name*: cstring
    num_formats*: culong
    formats*: PXvFormat
    num_adaptors*: culong

  PXvVideoNotifyEvent* = ptr TXvVideoNotifyEvent
  TXvVideoNotifyEvent*{.final.} = object
    theType*: cint
    serial*: culong           # # of last request processed by server
    send_event*: TBool        # true if this came from a SendEvent request
    display*: PDisplay        # Display the event was read from
    drawable*: TDrawable      # drawable
    reason*: culong           # what generated this event
    port_id*: TXvPortID       # what port
    time*: TTime              # milliseconds

  PXvPortNotifyEvent* = ptr TXvPortNotifyEvent
  TXvPortNotifyEvent*{.final.} = object
    theType*: cint
    serial*: culong           # # of last request processed by server
    send_event*: TBool        # true if this came from a SendEvent request
    display*: PDisplay        # Display the event was read from
    port_id*: TXvPortID       # what port
    time*: TTime              # milliseconds
    attribute*: TAtom         # atom that identifies attribute
    value*: clong             # value of attribute

  PXvEvent* = ptr TXvEvent
  TXvEvent*{.final.} = object
    pad*: array[0..23, clong] #case longint of
                              #      0 : (
                              #            theType : cint;
                              #	  );
                              #      1 : (
                              #            xvvideo : TXvVideoNotifyEvent;
                              #          );
                              #      2 : (
                              #            xvport : TXvPortNotifyEvent;
                              #          );
                              #      3 : (
                              #
                              #          );

  PXvImageFormatValues* = ptr TXvImageFormatValues
  TXvImageFormatValues*{.final.} = object
    id*: cint                 # Unique descriptor for the format
    theType*: cint            # XvRGB, XvYUV
    byte_order*: cint         # LSBFirst, MSBFirst
    guid*: array[0..15, cchar] # Globally Unique IDentifier
    bits_per_pixel*: cint
    format*: cint             # XvPacked, XvPlanar
    num_planes*: cint         # for RGB formats only
    depth*: cint
    red_mask*: cuint
    green_mask*: cuint
    blue_mask*: cuint         # for YUV formats only
    y_sample_bits*: cuint
    u_sample_bits*: cuint
    v_sample_bits*: cuint
    horz_y_period*: cuint
    horz_u_period*: cuint
    horz_v_period*: cuint
    vert_y_period*: cuint
    vert_u_period*: cuint
    vert_v_period*: cuint
    component_order*: array[0..31, char] # e.g. UYVY
    scanline_order*: cint     # XvTopToBottom, XvBottomToTop

  PXvImage* = ptr TXvImage
  TXvImage*{.final.} = object
    id*: cint
    width*, height*: cint
    data_size*: cint          # bytes
    num_planes*: cint
    pitches*: cint           # bytes
    offsets*: cint           # bytes
    data*: pointer
    obdata*: TXPointer


proc XvQueryExtension*(display: PDisplay, p_version, p_revision, p_requestBase,
    p_eventBase, p_errorBase: cuint): cint{.cdecl, dynlib: libXv, importc.}
proc XvQueryAdaptors*(display: PDisplay, window: TWindow, p_nAdaptors: cuint,
                      p_pAdaptors: PPXvAdaptorInfo): cint{.cdecl, dynlib: libXv,
    importc.}
proc XvQueryEncodings*(display: PDisplay, port: TXvPortID, p_nEncoding: cuint,
                       p_pEncoding: PPXvEncodingInfo): cint{.cdecl,
    dynlib: libXv, importc.}
proc XvPutVideo*(display: PDisplay, port: TXvPortID, d: TDrawable, gc: TGC,
                 vx, vy: cint, vw, vh: cuint, dx, dy: cint, dw, dh: cuint): cint{.
    cdecl, dynlib: libXv, importc.}
proc XvPutStill*(display: PDisplay, port: TXvPortID, d: TDrawable, gc: TGC,
                 vx, vy: cint, vw, vh: cuint, dx, dy: cint, dw, dh: cuint): cint{.
    cdecl, dynlib: libXv, importc.}
proc XvGetVideo*(display: PDisplay, port: TXvPortID, d: TDrawable, gc: TGC,
                 vx, vy: cint, vw, vh: cuint, dx, dy: cint, dw, dh: cuint): cint{.
    cdecl, dynlib: libXv, importc.}
proc XvGetStill*(display: PDisplay, port: TXvPortID, d: TDrawable, gc: TGC,
                 vx, vy: cint, vw, vh: cuint, dx, dy: cint, dw, dh: cuint): cint{.
    cdecl, dynlib: libXv, importc.}
proc XvStopVideo*(display: PDisplay, port: TXvPortID, drawable: TDrawable): cint{.
    cdecl, dynlib: libXv, importc.}
proc XvGrabPort*(display: PDisplay, port: TXvPortID, time: TTime): cint{.cdecl,
    dynlib: libXv, importc.}
proc XvUngrabPort*(display: PDisplay, port: TXvPortID, time: TTime): cint{.
    cdecl, dynlib: libXv, importc.}
proc XvSelectVideoNotify*(display: PDisplay, drawable: TDrawable, onoff: TBool): cint{.
    cdecl, dynlib: libXv, importc.}
proc XvSelectPortNotify*(display: PDisplay, port: TXvPortID, onoff: TBool): cint{.
    cdecl, dynlib: libXv, importc.}
proc XvSetPortAttribute*(display: PDisplay, port: TXvPortID, attribute: TAtom,
                         value: cint): cint{.cdecl, dynlib: libXv, importc.}
proc XvGetPortAttribute*(display: PDisplay, port: TXvPortID, attribute: TAtom,
                         p_value: cint): cint{.cdecl, dynlib: libXv, importc.}
proc XvQueryBestSize*(display: PDisplay, port: TXvPortID, motion: TBool,
                      vid_w, vid_h, drw_w, drw_h: cuint,
                      p_actual_width, p_actual_height: cuint): cint{.cdecl,
    dynlib: libXv, importc.}
proc XvQueryPortAttributes*(display: PDisplay, port: TXvPortID, number: cint): PXvAttribute{.
    cdecl, dynlib: libXv, importc.}
proc XvFreeAdaptorInfo*(adaptors: PXvAdaptorInfo){.cdecl, dynlib: libXv, importc.}
proc XvFreeEncodingInfo*(encodings: PXvEncodingInfo){.cdecl, dynlib: libXv,
    importc.}
proc XvListImageFormats*(display: PDisplay, port_id: TXvPortID,
                         count_return: cint): PXvImageFormatValues{.cdecl,
    dynlib: libXv, importc.}
proc XvCreateImage*(display: PDisplay, port: TXvPortID, id: cint, data: pointer,
                    width, height: cint): PXvImage{.cdecl, dynlib: libXv,
    importc.}
proc XvPutImage*(display: PDisplay, id: TXvPortID, d: TDrawable, gc: TGC,
                 image: PXvImage, src_x, src_y: cint, src_w, src_h: cuint,
                 dest_x, dest_y: cint, dest_w, dest_h: cuint): cint{.cdecl,
    dynlib: libXv, importc.}
proc XvShmPutImage*(display: PDisplay, id: TXvPortID, d: TDrawable, gc: TGC,
                    image: PXvImage, src_x, src_y: cint, src_w, src_h: cuint,
                    dest_x, dest_y: cint, dest_w, dest_h: cuint,
                    send_event: TBool): cint{.cdecl, dynlib: libXv, importc.}
proc XvShmCreateImage*(display: PDisplay, port: TXvPortID, id: cint,
                       data: pointer, width, height: cint,
                       shminfo: PXShmSegmentInfo): PXvImage{.cdecl,
    dynlib: libXv, importc.}
# implementation
