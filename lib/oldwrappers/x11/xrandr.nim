#
#  $XFree86: xc/lib/Xrandr/Xrandr.h,v 1.9 2002/09/29 23:39:44 keithp Exp $
# 
#  Copyright (C) 2000 Compaq Computer Corporation, Inc.
#  Copyright (C) 2002 Hewlett-Packard Company, Inc.
# 
#  Permission to use, copy, modify, distribute, and sell this software and its
#  documentation for any purpose is hereby granted without fee, provided that
#  the above copyright notice appear in all copies and that both that
#  copyright notice and this permission notice appear in supporting
#  documentation, and that the name of Compaq not be used in advertising or
#  publicity pertaining to distribution of the software without specific,
#  written prior permission.  HP makes no representations about the
#  suitability of this software for any purpose.  It is provided "as is"
#  without express or implied warranty.
# 
#  HP DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL COMPAQ
#  BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
#  OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN 
#  CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 
#  Author:  Jim Gettys, HP Labs, HP.
#

import 
  x, xlib

const 
  libXrandr* = "libXrandr.so"
  
# * $XFree86: xc/include/extensions/randr.h,v 1.4 2001/11/24 07:24:58 keithp Exp $
# *
# * Copyright (C) 2000, Compaq Computer Corporation, 
# * Copyright (C) 2002, Hewlett Packard, Inc.
# *
# * Permission to use, copy, modify, distribute, and sell this software and its
# * documentation for any purpose is hereby granted without fee, provided that
# * the above copyright notice appear in all copies and that both that
# * copyright notice and this permission notice appear in supporting
# * documentation, and that the name of Compaq or HP not be used in advertising
# * or publicity pertaining to distribution of the software without specific,
# * written prior permission.  HP makes no representations about the
# * suitability of this software for any purpose.  It is provided "as is"
# * without express or implied warranty.
# *
# * HP DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL
# * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL HP
# * BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
# * OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN 
# * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# *
# * Author:  Jim Gettys, HP Labs, Hewlett-Packard, Inc.
# *

type 
  PRotation* = ptr TRotation
  TRotation* = cushort
  PSizeID* = ptr TSizeID
  TSizeID* = cushort
  PSubpixelOrder* = ptr TSubpixelOrder
  TSubpixelOrder* = cushort

const 
  RANDR_NAME* = "RANDR"
  RANDR_MAJOR* = 1
  RANDR_MINOR* = 1
  RRNumberErrors* = 0
  RRNumberEvents* = 1
  constX_RRQueryVersion* = 0 # we skip 1 to make old clients fail pretty immediately 
  X_RROldGetScreenInfo* = 1
  X_RR1_0SetScreenConfig* = 2 # V1.0 apps share the same set screen config request id 
  constX_RRSetScreenConfig* = 2
  X_RROldScreenChangeSelectInput* = 3 # 3 used to be ScreenChangeSelectInput; deprecated 
  constX_RRSelectInput* = 4
  constX_RRGetScreenInfo* = 5      # used in XRRSelectInput 
  RRScreenChangeNotifyMask* = 1 shl 0
  RRScreenChangeNotify* = 0   # used in the rotation field; rotation and reflection in 0.1 proto. 
  RR_Rotate_0* = 1
  RR_Rotate_90* = 2
  RR_Rotate_180* = 4
  RR_Rotate_270* = 8          # new in 1.0 protocol, to allow reflection of screen 
  RR_Reflect_X* = 16
  RR_Reflect_Y* = 32
  RRSetConfigSuccess* = 0
  RRSetConfigInvalidConfigTime* = 1
  RRSetConfigInvalidTime* = 2
  RRSetConfigFailed* = 3

type 
  PXRRScreenSize* = ptr TXRRScreenSize
  TXRRScreenSize*{.final.} = object  #
                                     #   Events.
                                     #
    width*, height*: cint
    mwidth*, mheight*: cint

  TXRRScreenChangeNotifyEvent*{.final.} = object  # internal representation is private to the library 
    typ*: cint                # event base 
    serial*: culong           # # of last request processed by server 
    send_event*: TBool        # true if this came from a SendEvent request 
    display*: PDisplay        # Display the event was read from 
    window*: TWindow          # window which selected for this event 
    root*: TWindow            # Root window for changed screen 
    timestamp*: TTime         # when the screen change occurred 
    config_timestamp*: TTime  # when the last configuration change 
    size_index*: TSizeID
    subpixel_order*: TSubpixelOrder
    rotation*: TRotation
    width*: cint
    height*: cint
    mwidth*: cint
    mheight*: cint

  PXRRScreenConfiguration* = ptr TXRRScreenConfiguration
  TXRRScreenConfiguration*{.final.} = object 

proc XRRQueryExtension*(dpy: PDisplay, event_basep, error_basep: Pcint): TBool{.
    cdecl, dynlib: libXrandr, importc.}
proc XRRQueryVersion*(dpy: PDisplay, major_versionp: Pcint, 
                      minor_versionp: Pcint): TStatus{.cdecl, dynlib: libXrandr, 
    importc.}
proc XRRGetScreenInfo*(dpy: PDisplay, draw: TDrawable): PXRRScreenConfiguration{.
    cdecl, dynlib: libXrandr, importc.}
proc XRRFreeScreenConfigInfo*(config: PXRRScreenConfiguration){.cdecl, 
    dynlib: libXrandr, importc.}
  #
  #  Note that screen configuration changes are only permitted if the client can
  #  prove it has up to date configuration information.  We are trying to
  #  insist that it become possible for screens to change dynamically, so
  #  we want to ensure the client knows what it is talking about when requesting
  #  changes.
  #
proc XRRSetScreenConfig*(dpy: PDisplay, config: PXRRScreenConfiguration, 
                         draw: TDrawable, size_index: cint, rotation: TRotation, 
                         timestamp: TTime): TStatus{.cdecl, dynlib: libXrandr, 
    importc.}
  # added in v1.1, sorry for the lame name 
proc XRRSetScreenConfigAndRate*(dpy: PDisplay, config: PXRRScreenConfiguration, 
                                draw: TDrawable, size_index: cint, 
                                rotation: TRotation, rate: cshort, 
                                timestamp: TTime): TStatus{.cdecl, 
    dynlib: libXrandr, importc.}
proc XRRConfigRotations*(config: PXRRScreenConfiguration, 
                         current_rotation: PRotation): TRotation{.cdecl, 
    dynlib: libXrandr, importc.}
proc XRRConfigTimes*(config: PXRRScreenConfiguration, config_timestamp: PTime): TTime{.
    cdecl, dynlib: libXrandr, importc.}
proc XRRConfigSizes*(config: PXRRScreenConfiguration, nsizes: Pcint): PXRRScreenSize{.
    cdecl, dynlib: libXrandr, importc.}
proc XRRConfigRates*(config: PXRRScreenConfiguration, sizeID: cint, 
                     nrates: Pcint): ptr int16{.cdecl, dynlib: libXrandr, importc.}
proc XRRConfigCurrentConfiguration*(config: PXRRScreenConfiguration, 
                                    rotation: PRotation): TSizeID{.cdecl, 
    dynlib: libXrandr, importc.}
proc XRRConfigCurrentRate*(config: PXRRScreenConfiguration): cshort{.cdecl, 
    dynlib: libXrandr, importc.}
proc XRRRootToScreen*(dpy: PDisplay, root: TWindow): cint{.cdecl, 
    dynlib: libXrandr, importc.}
  #
  #  returns the screen configuration for the specified screen; does a lazy
  #  evalution to delay getting the information, and caches the result.
  #  These routines should be used in preference to XRRGetScreenInfo
  #  to avoid unneeded round trips to the X server.  These are new
  #  in protocol version 0.1.
  #
proc XRRScreenConfig*(dpy: PDisplay, screen: cint): PXRRScreenConfiguration{.
    cdecl, dynlib: libXrandr, importc.}
proc XRRConfig*(screen: PScreen): PXRRScreenConfiguration{.cdecl, 
    dynlib: libXrandr, importc.}
proc XRRSelectInput*(dpy: PDisplay, window: TWindow, mask: cint){.cdecl, 
    dynlib: libXrandr, importc.}
  #
  #  the following are always safe to call, even if RandR is not implemented 
  #  on a screen 
  #
proc XRRRotations*(dpy: PDisplay, screen: cint, current_rotation: PRotation): TRotation{.
    cdecl, dynlib: libXrandr, importc.}
proc XRRSizes*(dpy: PDisplay, screen: cint, nsizes: Pcint): PXRRScreenSize{.
    cdecl, dynlib: libXrandr, importc.}
proc XRRRates*(dpy: PDisplay, screen: cint, sizeID: cint, nrates: Pcint): ptr int16{.
    cdecl, dynlib: libXrandr, importc.}
proc XRRTimes*(dpy: PDisplay, screen: cint, config_timestamp: PTime): TTime{.
    cdecl, dynlib: libXrandr, importc.}
  #
  #  intended to take RRScreenChangeNotify,  or 
  #  ConfigureNotify (on the root window)
  #  returns 1 if it is an event type it understands, 0 if not
  #
proc XRRUpdateConfiguration*(event: PXEvent): cint{.cdecl, dynlib: libXrandr, 
    importc.}
# implementation
