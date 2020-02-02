# $Xorg: XKBlib.h,v 1.6 2000/08/17 19:45:03 cpqbld Exp $
#************************************************************
#Copyright (c) 1993 by Silicon Graphics Computer Systems, Inc.
#
#Permission to use, copy, modify, and distribute this
#software and its documentation for any purpose and without
#fee is hereby granted, provided that the above copyright
#notice appear in all copies and that both that copyright
#notice and this permission notice appear in supporting
#documentation, and that the name of Silicon Graphics not be
#used in advertising or publicity pertaining to distribution
#of the software without specific prior written permission.
#Silicon Graphics makes no representation about the suitability
#of this software for any purpose. It is provided "as is"
#without any express or implied warranty.
#
#SILICON GRAPHICS DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
#SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
#AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL SILICON
#GRAPHICS BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL
#DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING `from` LOSS OF USE,
#DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
#OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION  WITH
#THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
#********************************************************/
# $XFree86: xc/lib/X11/XKBlib.h,v 3.3 2001/08/01 00:44:38 tsi Exp $
#
# Pascal Convertion was made by Ido Kannner - kanerido@actcom.net.il
#
#Thanks:
#         I want to thanks to oliebol for putting up with all of the problems that was found
#         while translating this code. ;)
#
#         I want to thanks #fpc channel in freenode irc, for helping me, and to put up with my
#         weird questions ;)
#
#         Thanks for mmc in #xlib on freenode irc And so for the channel itself for the helping me to
#         understanding some of the problems I had converting this headers and pointing me to resources
#         that helped translating this headers.
#
# Ido
#
#History:
#        2004/10/15        - Fixed a bug of accessing second based records by removing "paced record" and
#                            chnaged it to "reocrd" only.
#        2004/10/10        - Added to TXkbGetAtomNameFunc and TXkbInternAtomFunc the cdecl call.
#        2004/10/06 - 09   - Convertion `from` the c header of XKBlib.h
#
#

import
  X, Xlib, XKB


include "x11pragma.nim"


type
  PXkbAnyEvent* = ptr TXkbAnyEvent
  TXkbAnyEvent*{.final.} = object
    theType*: int16           # XkbAnyEvent
    serial*: int32            # # of last req processed by server
    send_event*: bool         # is this `from` a SendEvent request?
    display*: PDisplay        # Display the event was read `from`
    time*: TTime              # milliseconds;
    xkb_type*: int16          # XKB event minor code
    device*: int16            # device ID


type
  PXkbNewKeyboardNotifyEvent* = ptr TXkbNewKeyboardNotifyEvent
  TXkbNewKeyboardNotifyEvent*{.final.} = object
    theType*: int16           # XkbAnyEvent
    serial*: int32            # of last req processed by server
    send_event*: bool         # is this `from` a SendEvent request?
    display*: PDisplay        # Display the event was read `from`
    time*: TTime              # milliseconds
    xkb_type*: int16          # XkbNewKeyboardNotify
    device*: int16            # device ID
    old_device*: int16        # device ID of previous keyboard
    min_key_code*: int16      # minimum key code
    max_key_code*: int16      # maximum key code
    old_min_key_code*: int16  # min key code of previous kbd
    old_max_key_code*: int16  # max key code of previous kbd
    changed*: int16           # changed aspects of the keyboard
    req_major*: int8          # major and minor opcode of req
    req_minor*: int8          # that caused change, if applicable


type
  PXkbMapNotifyEvent* = ptr TXkbMapNotifyEvent
  TXkbMapNotifyEvent*{.final.} = object
    theType*: int16           # XkbAnyEvent
    serial*: int32            # of last req processed by server
    send_event*: bool         # is this `from` a SendEvent request
    display*: PDisplay        # Display the event was read `from`
    time*: TTime              # milliseconds
    xkb_type*: int16          # XkbMapNotify
    device*: int16            # device ID
    changed*: int16           # fields which have been changed
    flags*: int16             # reserved
    first_type*: int16        # first changed key type
    num_types*: int16         # number of changed key types
    min_key_code*: TKeyCode
    max_key_code*: TKeyCode
    first_key_sym*: TKeyCode
    first_key_act*: TKeyCode
    first_key_behavior*: TKeyCode
    first_key_explicit*: TKeyCode
    first_modmap_key*: TKeyCode
    first_vmodmap_key*: TKeyCode
    num_key_syms*: int16
    num_key_acts*: int16
    num_key_behaviors*: int16
    num_key_explicit*: int16
    num_modmap_keys*: int16
    num_vmodmap_keys*: int16
    vmods*: int16             # mask of changed virtual mods


type
  PXkbStateNotifyEvent* = ptr TXkbStateNotifyEvent
  TXkbStateNotifyEvent*{.final.} = object
    theType*: int16           # XkbAnyEvent
    serial*: int32            # # of last req processed by server
    send_event*: bool         # is this `from` a SendEvent request?
    display*: PDisplay        # Display the event was read `from`
    time*: TTime              # milliseconds
    xkb_type*: int16          # XkbStateNotify
    device*: int16            # device ID
    changed*: int16           # mask of changed state components
    group*: int16             # keyboard group
    base_group*: int16        # base keyboard group
    latched_group*: int16     # latched keyboard group
    locked_group*: int16      # locked keyboard group
    mods*: int16              # modifier state
    base_mods*: int16         # base modifier state
    latched_mods*: int16      # latched modifiers
    locked_mods*: int16       # locked modifiers
    compat_state*: int16      # compatibility state
    grab_mods*: int8          # mods used for grabs
    compat_grab_mods*: int8   # grab mods for non-XKB clients
    lookup_mods*: int8        # mods sent to clients
    compat_lookup_mods*: int8 # mods sent to non-XKB clients
    ptr_buttons*: int16       # pointer button state
    keycode*: TKeyCode        # keycode that caused the change
    event_type*: int8         # KeyPress or KeyRelease
    req_major*: int8          # Major opcode of request
    req_minor*: int8          # Minor opcode of request


type
  PXkbControlsNotifyEvent* = ptr TXkbControlsNotifyEvent
  TXkbControlsNotifyEvent*{.final.} = object
    theType*: int16           # XkbAnyEvent
    serial*: int32            # of last req processed by server
    send_event*: bool         # is this `from` a SendEvent request?
    display*: PDisplay        # Display the event was read `from`
    time*: TTime              # milliseconds
    xkb_type*: int16          # XkbControlsNotify
    device*: int16            # device ID
    changed_ctrls*: int16     # controls with changed sub-values
    enabled_ctrls*: int16     # controls currently enabled
    enabled_ctrl_changes*: int16 # controls just {en,dis}abled
    num_groups*: int16        # total groups on keyboard
    keycode*: TKeyCode        # key that caused change or 0
    event_type*: int8         # type of event that caused change
    req_major*: int8          # if keycode==0, major and minor
    req_minor*: int8          # opcode of req that caused change


type
  PXkbIndicatorNotifyEvent* = ptr TXkbIndicatorNotifyEvent
  TXkbIndicatorNotifyEvent*{.final.} = object
    theType*: int16           # XkbAnyEvent
    serial*: int32            # of last req processed by server
    send_event*: bool         # is this `from` a SendEvent request?
    display*: PDisplay        # Display the event was read `from`
    time*: TTime              # milliseconds
    xkb_type*: int16          # XkbIndicatorNotify
    device*: int16            # device
    changed*: int16           # indicators with new state or map
    state*: int16             # current state of all indicators


type
  PXkbNamesNotifyEvent* = ptr TXkbNamesNotifyEvent
  TXkbNamesNotifyEvent*{.final.} = object
    theType*: int16           # XkbAnyEvent
    serial*: int32            # of last req processed by server
    send_event*: bool         # is this `from` a SendEvent request?
    display*: PDisplay        # Display the event was read `from`
    time*: TTime              # milliseconds
    xkb_type*: int16          # XkbNamesNotify
    device*: int16            # device ID
    changed*: int32           # names that have changed
    first_type*: int16        # first key type with new name
    num_types*: int16         # number of key types with new names
    first_lvl*: int16         # first key type new new level names
    num_lvls*: int16          # # of key types w/new level names
    num_aliases*: int16       # total number of key aliases
    num_radio_groups*: int16  # total number of radio groups
    changed_vmods*: int16     # virtual modifiers with new names
    changed_groups*: int16    # groups with new names
    changed_indicators*: int16 # indicators with new names
    first_key*: int16         # first key with new name
    num_keys*: int16          # number of keys with new names


type
  PXkbCompatMapNotifyEvent* = ptr TXkbCompatMapNotifyEvent
  TXkbCompatMapNotifyEvent*{.final.} = object
    theType*: int16           # XkbAnyEvent
    serial*: int32            # of last req processed by server
    send_event*: bool         # is this `from` a SendEvent request?
    display*: PDisplay        # Display the event was read `from`
    time*: TTime              # milliseconds
    xkb_type*: int16          # XkbCompatMapNotify
    device*: int16            # device ID
    changed_groups*: int16    # groups with new compat maps
    first_si*: int16          # first new symbol interp
    num_si*: int16            # number of new symbol interps
    num_total_si*: int16      # total # of symbol interps


type
  PXkbBellNotifyEvent* = ptr TXkbBellNotifyEvent
  TXkbBellNotifyEvent*{.final.} = object
    theType*: int16           # XkbAnyEvent
    serial*: int32            # of last req processed by server
    send_event*: bool         # is this `from` a SendEvent request?
    display*: PDisplay        # Display the event was read `from`
    time*: TTime              # milliseconds
    xkb_type*: int16          # XkbBellNotify
    device*: int16            # device ID
    percent*: int16           # requested volume as a % of maximum
    pitch*: int16             # requested pitch in Hz
    duration*: int16          # requested duration in useconds
    bell_class*: int16        # (input extension) feedback class
    bell_id*: int16           # (input extension) ID of feedback
    name*: TAtom              # "name" of requested bell
    window*: TWindow          # window associated with event
    event_only*: bool         # "event only" requested


type
  PXkbActionMessageEvent* = ptr TXkbActionMessageEvent
  TXkbActionMessageEvent*{.final.} = object
    theType*: int16           # XkbAnyEvent
    serial*: int32            # of last req processed by server
    send_event*: bool         # is this `from` a SendEvent request?
    display*: PDisplay        # Display the event was read `from`
    time*: TTime              # milliseconds
    xkb_type*: int16          # XkbActionMessage
    device*: int16            # device ID
    keycode*: TKeyCode        # key that generated the event
    press*: bool              # true if act caused by key press
    key_event_follows*: bool  # true if key event also generated
    group*: int16             # effective group
    mods*: int16              # effective mods
    message*: array[0..XkbActionMessageLength, char] # message -- leave space for NUL


type
  PXkbAccessXNotifyEvent* = ptr TXkbAccessXNotifyEvent
  TXkbAccessXNotifyEvent*{.final.} = object
    theType*: int16           # XkbAnyEvent
    serial*: int32            # of last req processed by server
    send_event*: bool         # is this `from` a SendEvent request?
    display*: PDisplay        # Display the event was read `from`
    time*: TTime              # milliseconds
    xkb_type*: int16          # XkbAccessXNotify
    device*: int16            # device ID
    detail*: int16            # XkbAXN_*
    keycode*: int16           # key of event
    sk_delay*: int16          # current slow keys delay
    debounce_delay*: int16    # current debounce delay


type
  PXkbExtensionDeviceNotifyEvent* = ptr TXkbExtensionDeviceNotifyEvent
  TXkbExtensionDeviceNotifyEvent*{.final.} = object
    theType*: int16           # XkbAnyEvent
    serial*: int32            # of last req processed by server
    send_event*: bool         # is this `from` a SendEvent request?
    display*: PDisplay        # Display the event was read `from`
    time*: TTime              # milliseconds
    xkb_type*: int16          # XkbExtensionDeviceNotify
    device*: int16            # device ID
    reason*: int16            # reason for the event
    supported*: int16         # mask of supported features
    unsupported*: int16       # mask of unsupported features
                              # that some app tried to use
    first_btn*: int16         # first button that changed
    num_btns*: int16          # range of buttons changed
    leds_defined*: int16      # indicators with names or maps
    led_state*: int16         # current state of the indicators
    led_class*: int16         # feedback class for led changes
    led_id*: int16            # feedback id for led changes


type
  PXkbEvent* = ptr TXkbEvent
  TXkbEvent*{.final.} = object
    theType*: int16
    any*: TXkbAnyEvent
    new_kbd*: TXkbNewKeyboardNotifyEvent
    map*: TXkbMapNotifyEvent
    state*: TXkbStateNotifyEvent
    ctrls*: TXkbControlsNotifyEvent
    indicators*: TXkbIndicatorNotifyEvent
    names*: TXkbNamesNotifyEvent
    compat*: TXkbCompatMapNotifyEvent
    bell*: TXkbBellNotifyEvent
    message*: TXkbActionMessageEvent
    accessx*: TXkbAccessXNotifyEvent
    device*: TXkbExtensionDeviceNotifyEvent
    core*: TXEvent


type
  PXkbKbdDpyStatePtr* = ptr TXkbKbdDpyStateRec
  TXkbKbdDpyStateRec*{.final.} = object  # XkbOpenDisplay error codes

const
  XkbOD_Success* = 0
  XkbOD_BadLibraryVersion* = 1
  XkbOD_ConnectionRefused* = 2
  XkbOD_NonXkbServer* = 3
  XkbOD_BadServerVersion* = 4 # Values for XlibFlags

const
  XkbLC_ForceLatin1Lookup* = 1 shl 0
  XkbLC_ConsumeLookupMods* = 1 shl 1
  XkbLC_AlwaysConsumeShiftAndLock* = 1 shl 2
  XkbLC_IgnoreNewKeyboards* = 1 shl 3
  XkbLC_ControlFallback* = 1 shl 4
  XkbLC_ConsumeKeysOnComposeFail* = 1 shl 29
  XkbLC_ComposeLED* = 1 shl 30
  XkbLC_BeepOnComposeFail* = 1 shl 31
  XkbLC_AllComposeControls* = 0xC0000000
  XkbLC_AllControls* = 0xC000001F

proc XkbIgnoreExtension*(ignore: bool): bool{.libx11c,
    importc: "XkbIgnoreExtension".}
proc XkbOpenDisplay*(name: cstring, ev_rtrn, err_rtrn, major_rtrn, minor_rtrn,
                                    reason: ptr int16): PDisplay{.libx11c, importc: "XkbOpenDisplay".}
proc XkbQueryExtension*(dpy: PDisplay, opcodeReturn, eventBaseReturn,
                                       errorBaseReturn, majorRtrn, minorRtrn: ptr int16): bool{.
    libx11c, importc: "XkbQueryExtension".}
proc XkbUseExtension*(dpy: PDisplay, major_rtrn, minor_rtrn: ptr int16): bool{.
    libx11c, importc: "XkbUseExtension".}
proc XkbLibraryVersion*(libMajorRtrn, libMinorRtrn: ptr int16): bool{.libx11c, importc: "XkbLibraryVersion".}
proc XkbSetXlibControls*(dpy: PDisplay, affect, values: int16): int16{.libx11c, importc: "XkbSetXlibControls".}
proc XkbGetXlibControls*(dpy: PDisplay): int16{.libx11c,
    importc: "XkbGetXlibControls".}
type
  TXkbInternAtomFunc* = proc (dpy: PDisplay, name: cstring, only_if_exists: bool): TAtom{.
      cdecl.}

type
  TXkbGetAtomNameFunc* = proc (dpy: PDisplay, atom: TAtom): cstring{.cdecl.}

proc XkbSetAtomFuncs*(getAtom: TXkbInternAtomFunc, getName: TXkbGetAtomNameFunc){.
    libx11c, importc: "XkbSetAtomFuncs".}
proc XkbKeycodeToKeysym*(dpy: PDisplay, kc: TKeyCode, group, level: int16): TKeySym{.
    libx11c, importc: "XkbKeycodeToKeysym".}
proc XkbKeysymToModifiers*(dpy: PDisplay, ks: TKeySym): int16{.libx11c, importc: "XkbKeysymToModifiers".}
proc XkbLookupKeySym*(dpy: PDisplay, keycode: TKeyCode,
                      modifiers, modifiers_return: int16, keysym_return: PKeySym): bool{.
    libx11c, importc: "XkbLookupKeySym".}
proc XkbLookupKeyBinding*(dpy: PDisplay, sym_rtrn: TKeySym, mods: int16,
                          buffer: cstring, nbytes: int16, extra_rtrn: ptr int16): int16{.
    libx11c, importc: "XkbLookupKeyBinding".}
proc XkbTranslateKeyCode*(xkb: PXkbDescPtr, keycode: TKeyCode,
                          modifiers, modifiers_return: int16,
                          keysym_return: PKeySym): bool{.libx11c,
    importc: "XkbTranslateKeyCode".}
proc XkbTranslateKeySym*(dpy: PDisplay, sym_return: TKeySym, modifiers: int16,
                         buffer: cstring, nbytes: int16, extra_rtrn: ptr int16): int16{.
    libx11c, importc: "XkbTranslateKeySym".}
proc XkbSetAutoRepeatRate*(dpy: PDisplay, deviceSpec, delay, interval: int16): bool{.
    libx11c, importc: "XkbSetAutoRepeatRate".}
proc XkbGetAutoRepeatRate*(dpy: PDisplay, deviceSpec: int16,
                           delayRtrn, intervalRtrn: PWord): bool{.libx11c, importc: "XkbGetAutoRepeatRate".}
proc XkbChangeEnabledControls*(dpy: PDisplay, deviceSpec, affect, values: int16): bool{.
    libx11c, importc: "XkbChangeEnabledControls".}
proc XkbDeviceBell*(dpy: PDisplay, win: TWindow,
                    deviceSpec, bellClass, bellID, percent: int16, name: TAtom): bool{.
    libx11c, importc: "XkbDeviceBell".}
proc XkbForceDeviceBell*(dpy: PDisplay,
                         deviceSpec, bellClass, bellID, percent: int16): bool{.
    libx11c, importc: "XkbForceDeviceBell".}
proc XkbDeviceBellEvent*(dpy: PDisplay, win: TWindow,
                         deviceSpec, bellClass, bellID, percent: int16,
                         name: TAtom): bool{.libx11c,
    importc: "XkbDeviceBellEvent".}
proc XkbBell*(dpy: PDisplay, win: TWindow, percent: int16, name: TAtom): bool{.
    libx11c, importc: "XkbBell".}
proc XkbForceBell*(dpy: PDisplay, percent: int16): bool{.libx11c,
    importc: "XkbForceBell".}
proc XkbBellEvent*(dpy: PDisplay, win: TWindow, percent: int16, name: TAtom): bool{.
    libx11c, importc: "XkbBellEvent".}
proc XkbSelectEvents*(dpy: PDisplay, deviceID, affect, values: int16): bool{.
    libx11c, importc: "XkbSelectEvents".}
proc XkbSelectEventDetails*(dpy: PDisplay, deviceID, eventType: int16,
                            affect, details: int32): bool{.libx11c, importc: "XkbSelectEventDetails".}
proc XkbNoteMapChanges*(old: PXkbMapChangesPtr, new: PXkbMapNotifyEvent,
                        wanted: int16){.libx11c,
                                        importc: "XkbNoteMapChanges".}
proc XkbNoteNameChanges*(old: PXkbNameChangesPtr, new: PXkbNamesNotifyEvent,
                         wanted: int16){.libx11c,
    importc: "XkbNoteNameChanges".}
proc XkbGetIndicatorState*(dpy: PDisplay, deviceSpec: int16, pStateRtrn: PWord): TStatus{.
    libx11c, importc: "XkbGetIndicatorState".}
proc XkbGetDeviceIndicatorState*(dpy: PDisplay,
                                 deviceSpec, ledClass, ledID: int16,
                                 pStateRtrn: PWord): TStatus{.libx11c, importc: "XkbGetDeviceIndicatorState".}
proc XkbGetIndicatorMap*(dpy: PDisplay, which: int32, desc: PXkbDescPtr): TStatus{.
    libx11c, importc: "XkbGetIndicatorMap".}
proc XkbSetIndicatorMap*(dpy: PDisplay, which: int32, desc: PXkbDescPtr): bool{.
    libx11c, importc: "XkbSetIndicatorMap".}
proc XkbNoteIndicatorMapChanges*(o, n: PXkbIndicatorChangesPtr, w: int16)
proc XkbNoteIndicatorStateChanges*(o, n: PXkbIndicatorChangesPtr, w: int16)
proc XkbGetIndicatorMapChanges*(d: PDisplay, x: PXkbDescPtr,
                                c: PXkbIndicatorChangesPtr): TStatus
proc XkbChangeIndicatorMaps*(d: PDisplay, x: PXkbDescPtr,
                             c: PXkbIndicatorChangesPtr): bool
proc XkbGetNamedIndicator*(dpy: PDisplay, name: TAtom, pNdxRtrn: ptr int16,
                           pStateRtrn: ptr bool, pMapRtrn: PXkbIndicatorMapPtr,
                           pRealRtrn: ptr bool): bool{.libx11c,
    importc: "XkbGetNamedIndicator".}
proc XkbGetNamedDeviceIndicator*(dpy: PDisplay,
                                 deviceSpec, ledClass, ledID: int16,
                                 name: TAtom, pNdxRtrn: ptr int16,
                                 pStateRtrn: ptr bool,
                                 pMapRtrn: PXkbIndicatorMapPtr,
                                 pRealRtrn: ptr bool): bool{.libx11c, importc: "XkbGetNamedDeviceIndicator".}
proc XkbSetNamedIndicator*(dpy: PDisplay, name: TAtom,
                           changeState, state, createNewMap: bool,
                           pMap: PXkbIndicatorMapPtr): bool{.libx11c, importc: "XkbSetNamedIndicator".}
proc XkbSetNamedDeviceIndicator*(dpy: PDisplay,
                                 deviceSpec, ledClass, ledID: int16,
                                 name: TAtom,
                                 changeState, state, createNewMap: bool,
                                 pMap: PXkbIndicatorMapPtr): bool{.libx11c, importc: "XkbSetNamedDeviceIndicator".}
proc XkbLockModifiers*(dpy: PDisplay, deviceSpec, affect, values: int16): bool{.
    libx11c, importc: "XkbLockModifiers".}
proc XkbLatchModifiers*(dpy: PDisplay, deviceSpec, affect, values: int16): bool{.
    libx11c, importc: "XkbLatchModifiers".}
proc XkbLockGroup*(dpy: PDisplay, deviceSpec, group: int16): bool{.libx11c, importc: "XkbLockGroup".}
proc XkbLatchGroup*(dpy: PDisplay, deviceSpec, group: int16): bool{.libx11c, importc: "XkbLatchGroup".}
proc XkbSetServerInternalMods*(dpy: PDisplay, deviceSpec, affectReal,
    realValues, affectVirtual, virtualValues: int16): bool{.libx11c, importc: "XkbSetServerInternalMods".}
proc XkbSetIgnoreLockMods*(dpy: PDisplay, deviceSpec, affectReal, realValues,
    affectVirtual, virtualValues: int16): bool{.libx11c,
    importc: "XkbSetIgnoreLockMods".}
proc XkbVirtualModsToReal*(dpy: PDisplay, virtual_mask: int16, mask_rtrn: PWord): bool{.
    libx11c, importc: "XkbVirtualModsToReal".}
proc XkbComputeEffectiveMap*(xkb: PXkbDescPtr, theType: PXkbKeyTypePtr,
                             map_rtrn: PByte): bool{.libx11c,
    importc: "XkbComputeEffectiveMap".}
proc XkbInitCanonicalKeyTypes*(xkb: PXkbDescPtr, which: int16, keypadVMod: int16): TStatus{.
    libx11c, importc: "XkbInitCanonicalKeyTypes".}
proc XkbAllocKeyboard*(): PXkbDescPtr{.libx11c,
                                       importc: "XkbAllocKeyboard".}
proc XkbFreeKeyboard*(xkb: PXkbDescPtr, which: int16, freeDesc: bool){.libx11c, importc: "XkbFreeKeyboard".}
proc XkbAllocClientMap*(xkb: PXkbDescPtr, which, nTypes: int16): TStatus{.libx11c, importc: "XkbAllocClientMap".}
proc XkbAllocServerMap*(xkb: PXkbDescPtr, which, nActions: int16): TStatus{.
    libx11c, importc: "XkbAllocServerMap".}
proc XkbFreeClientMap*(xkb: PXkbDescPtr, what: int16, freeMap: bool){.libx11c, importc: "XkbFreeClientMap".}
proc XkbFreeServerMap*(xkb: PXkbDescPtr, what: int16, freeMap: bool){.libx11c, importc: "XkbFreeServerMap".}
proc XkbAddKeyType*(xkb: PXkbDescPtr, name: TAtom, map_count: int16,
                    want_preserve: bool, num_lvls: int16): PXkbKeyTypePtr{.
    libx11c, importc: "XkbAddKeyType".}
proc XkbAllocIndicatorMaps*(xkb: PXkbDescPtr): TStatus{.libx11c,
    importc: "XkbAllocIndicatorMaps".}
proc XkbFreeIndicatorMaps*(xkb: PXkbDescPtr){.libx11c,
    importc: "XkbFreeIndicatorMaps".}
proc XkbGetMap*(dpy: PDisplay, which, deviceSpec: int16): PXkbDescPtr{.libx11c, importc: "XkbGetMap".}
proc XkbGetUpdatedMap*(dpy: PDisplay, which: int16, desc: PXkbDescPtr): TStatus{.
    libx11c, importc: "XkbGetUpdatedMap".}
proc XkbGetMapChanges*(dpy: PDisplay, xkb: PXkbDescPtr,
                       changes: PXkbMapChangesPtr): TStatus{.libx11c, importc: "XkbGetMapChanges".}
proc XkbRefreshKeyboardMapping*(event: PXkbMapNotifyEvent): TStatus{.libx11c, importc: "XkbRefreshKeyboardMapping".}
proc XkbGetKeyTypes*(dpy: PDisplay, first, num: int16, xkb: PXkbDescPtr): TStatus{.
    libx11c, importc: "XkbGetKeyTypes".}
proc XkbGetKeySyms*(dpy: PDisplay, first, num: int16, xkb: PXkbDescPtr): TStatus{.
    libx11c, importc: "XkbGetKeySyms".}
proc XkbGetKeyActions*(dpy: PDisplay, first, num: int16, xkb: PXkbDescPtr): TStatus{.
    libx11c, importc: "XkbGetKeyActions".}
proc XkbGetKeyBehaviors*(dpy: PDisplay, firstKey, nKeys: int16,
                         desc: PXkbDescPtr): TStatus{.libx11c,
    importc: "XkbGetKeyBehaviors".}
proc XkbGetVirtualMods*(dpy: PDisplay, which: int16, desc: PXkbDescPtr): TStatus{.
    libx11c, importc: "XkbGetVirtualMods".}
proc XkbGetKeyExplicitComponents*(dpy: PDisplay, firstKey, nKeys: int16,
                                  desc: PXkbDescPtr): TStatus{.libx11c, importc: "XkbGetKeyExplicitComponents".}
proc XkbGetKeyModifierMap*(dpy: PDisplay, firstKey, nKeys: int16,
                           desc: PXkbDescPtr): TStatus{.libx11c,
    importc: "XkbGetKeyModifierMap".}
proc XkbAllocControls*(xkb: PXkbDescPtr, which: int16): TStatus{.libx11c, importc: "XkbAllocControls".}
proc XkbFreeControls*(xkb: PXkbDescPtr, which: int16, freeMap: bool){.libx11c, importc: "XkbFreeControls".}
proc XkbGetControls*(dpy: PDisplay, which: int32, desc: PXkbDescPtr): TStatus{.
    libx11c, importc: "XkbGetControls".}
proc XkbSetControls*(dpy: PDisplay, which: int32, desc: PXkbDescPtr): bool{.
    libx11c, importc: "XkbSetControls".}
proc XkbNoteControlsChanges*(old: PXkbControlsChangesPtr,
                             new: PXkbControlsNotifyEvent, wanted: int16){.
    libx11c, importc: "XkbNoteControlsChanges".}
proc XkbGetControlsChanges*(d: PDisplay, x: PXkbDescPtr,
                            c: PXkbControlsChangesPtr): TStatus
proc XkbChangeControls*(d: PDisplay, x: PXkbDescPtr, c: PXkbControlsChangesPtr): bool
proc XkbAllocCompatMap*(xkb: PXkbDescPtr, which, nInterpret: int16): TStatus{.
    libx11c, importc: "XkbAllocCompatMap".}
proc XkbFreeCompatMap*(xkib: PXkbDescPtr, which: int16, freeMap: bool){.libx11c, importc: "XkbFreeCompatMap".}
proc XkbGetCompatMap*(dpy: PDisplay, which: int16, xkb: PXkbDescPtr): TStatus{.
    libx11c, importc: "XkbGetCompatMap".}
proc XkbSetCompatMap*(dpy: PDisplay, which: int16, xkb: PXkbDescPtr,
                      updateActions: bool): bool{.libx11c,
    importc: "XkbSetCompatMap".}
proc XkbAddSymInterpret*(xkb: PXkbDescPtr, si: PXkbSymInterpretPtr,
                         updateMap: bool, changes: PXkbChangesPtr): PXkbSymInterpretPtr{.
    libx11c, importc: "XkbAddSymInterpret".}
proc XkbAllocNames*(xkb: PXkbDescPtr, which: int16,
                    nTotalRG, nTotalAliases: int16): TStatus{.libx11c, importc: "XkbAllocNames".}
proc XkbGetNames*(dpy: PDisplay, which: int16, desc: PXkbDescPtr): TStatus{.
    libx11c, importc: "XkbGetNames".}
proc XkbSetNames*(dpy: PDisplay, which, firstType, nTypes: int16,
                  desc: PXkbDescPtr): bool{.libx11c,
    importc: "XkbSetNames".}
proc XkbChangeNames*(dpy: PDisplay, xkb: PXkbDescPtr,
                     changes: PXkbNameChangesPtr): bool{.libx11c,
    importc: "XkbChangeNames".}
proc XkbFreeNames*(xkb: PXkbDescPtr, which: int16, freeMap: bool){.libx11c, importc: "XkbFreeNames".}
proc XkbGetState*(dpy: PDisplay, deviceSpec: int16, rtrnState: PXkbStatePtr): TStatus{.
    libx11c, importc: "XkbGetState".}
proc XkbSetMap*(dpy: PDisplay, which: int16, desc: PXkbDescPtr): bool{.libx11c, importc: "XkbSetMap".}
proc XkbChangeMap*(dpy: PDisplay, desc: PXkbDescPtr, changes: PXkbMapChangesPtr): bool{.
    libx11c, importc: "XkbChangeMap".}
proc XkbSetDetectableAutoRepeat*(dpy: PDisplay, detectable: bool,
                                 supported: ptr bool): bool{.libx11c, importc: "XkbSetDetectableAutoRepeat".}
proc XkbGetDetectableAutoRepeat*(dpy: PDisplay, supported: ptr bool): bool{.
    libx11c, importc: "XkbGetDetectableAutoRepeat".}
proc XkbSetAutoResetControls*(dpy: PDisplay, changes: int16,
                              auto_ctrls, auto_values: PWord): bool{.libx11c, importc: "XkbSetAutoResetControls".}
proc XkbGetAutoResetControls*(dpy: PDisplay, auto_ctrls, auto_ctrl_values: PWord): bool{.
    libx11c, importc: "XkbGetAutoResetControls".}
proc XkbSetPerClientControls*(dpy: PDisplay, change: int16, values: PWord): bool{.
    libx11c, importc: "XkbSetPerClientControls".}
proc XkbGetPerClientControls*(dpy: PDisplay, ctrls: PWord): bool{.libx11c, importc: "XkbGetPerClientControls".}
proc XkbCopyKeyType*(`from`, into: PXkbKeyTypePtr): TStatus{.libx11c, importc: "XkbCopyKeyType".}
proc XkbCopyKeyTypes*(`from`, into: PXkbKeyTypePtr, num_types: int16): TStatus{.
    libx11c, importc: "XkbCopyKeyTypes".}
proc XkbResizeKeyType*(xkb: PXkbDescPtr, type_ndx, map_count: int16,
                       want_preserve: bool, new_num_lvls: int16): TStatus{.
    libx11c, importc: "XkbResizeKeyType".}
proc XkbResizeKeySyms*(desc: PXkbDescPtr, forKey, symsNeeded: int16): PKeySym{.
    libx11c, importc: "XkbResizeKeySyms".}
proc XkbResizeKeyActions*(desc: PXkbDescPtr, forKey, actsNeeded: int16): PXkbAction{.
    libx11c, importc: "XkbResizeKeyActions".}
proc XkbChangeTypesOfKey*(xkb: PXkbDescPtr, key, num_groups: int16,
                          groups: int16, newTypes: ptr int16,
                          pChanges: PXkbMapChangesPtr): TStatus{.libx11c, importc: "XkbChangeTypesOfKey".}

proc XkbListComponents*(dpy: PDisplay, deviceSpec: int16,
                        ptrns: PXkbComponentNamesPtr, max_inout: ptr int16): PXkbComponentListPtr{.
    libx11c, importc: "XkbListComponents".}
proc XkbFreeComponentList*(list: PXkbComponentListPtr){.libx11c,
    importc: "XkbFreeComponentList".}
proc XkbGetKeyboard*(dpy: PDisplay, which, deviceSpec: int16): PXkbDescPtr{.
    libx11c, importc: "XkbGetKeyboard".}
proc XkbGetKeyboardByName*(dpy: PDisplay, deviceSpec: int16,
                           names: PXkbComponentNamesPtr, want, need: int16,
                           load: bool): PXkbDescPtr{.libx11c,
    importc: "XkbGetKeyboardByName".}

proc XkbKeyTypesForCoreSymbols*(xkb: PXkbDescPtr,
                                map_width: int16,  # keyboard device
                                core_syms: PKeySym,  # always mapWidth symbols
                                protected: int16,  # explicit key types
                                types_inout: ptr int16,  # always four type indices
                                xkb_syms_rtrn: PKeySym): int16{.libx11c, importc: "XkbKeyTypesForCoreSymbols".}
  # must have enough space
proc XkbApplyCompatMapToKey*(xkb: PXkbDescPtr,
                             key: TKeyCode,  # key to be updated
                             changes: PXkbChangesPtr): bool{.libx11c, importc: "XkbApplyCompatMapToKey".}
  # resulting changes to map
proc XkbUpdateMapFromCore*(xkb: PXkbDescPtr,
                           first_key: TKeyCode,  # first changed key
                           num_keys,
                           map_width: int16,
                           core_keysyms: PKeySym,  # symbols `from` core keymap
                           changes: PXkbChangesPtr): bool{.libx11c, importc: "XkbUpdateMapFromCore".}

proc XkbAddDeviceLedInfo*(devi: PXkbDeviceInfoPtr, ledClass, ledId: int16): PXkbDeviceLedInfoPtr{.
    libx11c, importc: "XkbAddDeviceLedInfo".}
proc XkbResizeDeviceButtonActions*(devi: PXkbDeviceInfoPtr, newTotal: int16): TStatus{.
    libx11c, importc: "XkbResizeDeviceButtonActions".}
proc XkbAllocDeviceInfo*(deviceSpec, nButtons, szLeds: int16): PXkbDeviceInfoPtr{.
    libx11c, importc: "XkbAllocDeviceInfo".}
proc XkbFreeDeviceInfo*(devi: PXkbDeviceInfoPtr, which: int16, freeDevI: bool){.
    libx11c, importc: "XkbFreeDeviceInfo".}
proc XkbNoteDeviceChanges*(old: PXkbDeviceChangesPtr,
                           new: PXkbExtensionDeviceNotifyEvent, wanted: int16){.
    libx11c, importc: "XkbNoteDeviceChanges".}
proc XkbGetDeviceInfo*(dpy: PDisplay, which, deviceSpec, ledClass, ledID: int16): PXkbDeviceInfoPtr{.
    libx11c, importc: "XkbGetDeviceInfo".}
proc XkbGetDeviceInfoChanges*(dpy: PDisplay, devi: PXkbDeviceInfoPtr,
                              changes: PXkbDeviceChangesPtr): TStatus{.libx11c, importc: "XkbGetDeviceInfoChanges".}
proc XkbGetDeviceButtonActions*(dpy: PDisplay, devi: PXkbDeviceInfoPtr,
                                all: bool, first, nBtns: int16): TStatus{.libx11c, importc: "XkbGetDeviceButtonActions".}
proc XkbGetDeviceLedInfo*(dpy: PDisplay, devi: PXkbDeviceInfoPtr,
                          ledClass, ledId, which: int16): TStatus{.libx11c, importc: "XkbGetDeviceLedInfo".}
proc XkbSetDeviceInfo*(dpy: PDisplay, which: int16, devi: PXkbDeviceInfoPtr): bool{.
    libx11c, importc: "XkbSetDeviceInfo".}
proc XkbChangeDeviceInfo*(dpy: PDisplay, desc: PXkbDeviceInfoPtr,
                          changes: PXkbDeviceChangesPtr): bool{.libx11c, importc: "XkbChangeDeviceInfo".}
proc XkbSetDeviceLedInfo*(dpy: PDisplay, devi: PXkbDeviceInfoPtr,
                          ledClass, ledID, which: int16): bool{.libx11c, importc: "XkbSetDeviceLedInfo".}
proc XkbSetDeviceButtonActions*(dpy: PDisplay, devi: PXkbDeviceInfoPtr,
                                first, nBtns: int16): bool{.libx11c, importc: "XkbSetDeviceButtonActions".}

proc XkbToControl*(c: int8): int8{.libx11c,
                                   importc: "XkbToControl".}

proc XkbSetDebuggingFlags*(dpy: PDisplay, mask, flags: int16, msg: cstring,
                           ctrls_mask, ctrls, rtrn_flags, rtrn_ctrls: int16): bool{.
    libx11c, importc: "XkbSetDebuggingFlags".}
proc XkbApplyVirtualModChanges*(xkb: PXkbDescPtr, changed: int16,
                                changes: PXkbChangesPtr): bool{.libx11c, importc: "XkbApplyVirtualModChanges".}

# implementation

proc XkbNoteIndicatorMapChanges(o, n: PXkbIndicatorChangesPtr, w: int16) =
  ##define XkbNoteIndicatorMapChanges(o,n,w) ((o)->map_changes|=((n)->map_changes&(w)))
  o.map_changes = o.map_changes or (n.map_changes and w)

proc XkbNoteIndicatorStateChanges(o, n: PXkbIndicatorChangesPtr, w: int16) =
  ##define XkbNoteIndicatorStateChanges(o,n,w) ((o)->state_changes|=((n)->state_changes&(w)))
  o.state_changes = o.state_changes or (n.state_changes and (w))

proc XkbGetIndicatorMapChanges(d: PDisplay, x: PXkbDescPtr,
                               c: PXkbIndicatorChangesPtr): TStatus =
  ##define XkbGetIndicatorMapChanges(d,x,c) (XkbGetIndicatorMap((d),(c)->map_changes,x)
  result = XkbGetIndicatorMap(d, c.map_changes, x)

proc XkbChangeIndicatorMaps(d: PDisplay, x: PXkbDescPtr,
                            c: PXkbIndicatorChangesPtr): bool =
  ##define XkbChangeIndicatorMaps(d,x,c) (XkbSetIndicatorMap((d),(c)->map_changes,x))
  result = XkbSetIndicatorMap(d, c.map_changes, x)

proc XkbGetControlsChanges(d: PDisplay, x: PXkbDescPtr,
                           c: PXkbControlsChangesPtr): TStatus =
  ##define XkbGetControlsChanges(d,x,c) XkbGetControls(d,(c)->changed_ctrls,x)
  result = XkbGetControls(d, c.changed_ctrls, x)

proc XkbChangeControls(d: PDisplay, x: PXkbDescPtr, c: PXkbControlsChangesPtr): bool =
  ##define XkbChangeControls(d,x,c) XkbSetControls(d,(c)->changed_ctrls,x)
  result = XkbSetControls(d, c.changed_ctrls, x)
