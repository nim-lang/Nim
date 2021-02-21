#
# $Xorg: XKB.h,v 1.3 2000/08/18 04:05:45 coskrey Exp $
#************************************************************
# $Xorg: XKBstr.h,v 1.3 2000/08/18 04:05:45 coskrey Exp $
#************************************************************
# $Xorg: XKBgeom.h,v 1.3 2000/08/18 04:05:45 coskrey Exp $
#************************************************************
#
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
#DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
#DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
#OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION  WITH
#THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
#********************************************************
# $XFree86: xc/include/extensions/XKB.h,v 1.5 2002/11/20 04:49:01 dawes Exp $
# $XFree86: xc/include/extensions/XKBgeom.h,v 3.9 2002/09/18 17:11:40 tsi Exp $
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
#        2004/10/15           - Fixed a bug of accessing second based records by removing "paced record" and
#                               chnaged it to "reocrd" only.
#        2004/10/04 - 06      - Convertion from the c header of XKBgeom.h.
#        2004/10/03           - Removed the XKBstr_UNIT compiler decleration. Afther the joined files,
#                                                                                     There is no need for it anymore.
#                                                                             - There is a need to define (for now) XKBgeom (compiler define) in order
#                                                                               to use the code of it. At this moment, I did not yet converted it to Pascal.
#
#        2004/09/17 - 10/04   - Convertion from the c header of XKBstr.
#
#        2004/10/03           - Joined xkbstr.pas into xkb.pas because of the circular calls problems.
#                             - Added the history of xkbstr.pas above this addition.
#
#        2004/09/17           - Fixed a wrong convertion number of XkbPerKeyBitArraySize, instead
#                               of float, it's now converted into integer (as it should have been).
#
#        2004/09/15 - 16      - Convertion from the c header of XKB.h.
#

import
  X, Xlib

include "x11pragma.nim"

proc XkbcharToInt*(v: int8): int16
proc XkbIntTo2chars*(i: int16, h, L: var int8)
proc Xkb2charsToInt*(h, L: int8): int16
  #
  #          Common data structures and access macros
  #
type
  PWord* = ptr array[0..64_000, int16]
  PByte* = ptr byte
  PXkbStatePtr* = ptr TXkbStateRec
  TXkbStateRec*{.final.} = object
    group*: int8
    locked_group*: int8
    base_group*: int16
    latched_group*: int16
    mods*: int8
    base_mods*: int8
    latched_mods*: int8
    locked_mods*: int8
    compat_state*: int8
    grab_mods*: int8
    compat_grab_mods*: int8
    lookup_mods*: int8
    compat_lookup_mods*: int8
    ptr_buttons*: int16


proc XkbModLocks*(s: PXkbStatePtr): int8
proc XkbStateMods*(s: PXkbStatePtr): int16
proc XkbGroupLock*(s: PXkbStatePtr): int8
proc XkbStateGroup*(s: PXkbStatePtr): int16
proc XkbStateFieldFromRec*(s: PXkbStatePtr): int
proc XkbGrabStateFromRec*(s: PXkbStatePtr): int
type
  PXkbModsPtr* = ptr TXkbModsRec
  TXkbModsRec*{.final.} = object
    mask*: int8               # effective mods
    real_mods*: int8
    vmods*: int16


type
  PXkbKTMapEntryPtr* = ptr TXkbKTMapEntryRec
  TXkbKTMapEntryRec*{.final.} = object
    active*: bool
    level*: int8
    mods*: TXkbModsRec


type
  PXkbKeyTypePtr* = ptr TXkbKeyTypeRec
  TXkbKeyTypeRec*{.final.} = object
    mods*: TXkbModsRec
    num_levels*: int8
    map_count*: int8
    map*: PXkbKTMapEntryPtr
    preserve*: PXkbModsPtr
    name*: TAtom
    level_names*: TAtom


proc XkbNumGroups*(g: int16): int16
proc XkbOutOfRangeGroupInfo*(g: int16): int16
proc XkbOutOfRangeGroupAction*(g: int16): int16
proc XkbOutOfRangeGroupNumber*(g: int16): int16
proc XkbSetGroupInfo*(g, w, n: int16): int16
proc XkbSetNumGroups*(g, n: int16): int16
  #
  #          Structures and access macros used primarily by the server
  #
type
  PXkbBehavior* = ptr TXkbBehavior
  TXkbBehavior*{.final.} = object
    theType*: int8
    data*: int8


type
  PXkbModAction* = ptr TXkbModAction
  TXkbModAction*{.final.} = object
    theType*: int8
    flags*: int8
    mask*: int8
    real_mods*: int8
    vmods1*: int8
    vmods2*: int8


proc XkbModActionVMods*(a: PXkbModAction): int16
proc XkbSetModActionVMods*(a: PXkbModAction, v: int8)
type
  PXkbGroupAction* = ptr TXkbGroupAction
  TXkbGroupAction*{.final.} = object
    theType*: int8
    flags*: int8
    group_XXX*: int8


proc XkbSAGroup*(a: PXkbGroupAction): int8
proc XkbSASetGroupProc*(a: PXkbGroupAction, g: int8)
type
  PXkbISOAction* = ptr TXkbISOAction
  TXkbISOAction*{.final.} = object
    theType*: int8
    flags*: int8
    mask*: int8
    real_mods*: int8
    group_XXX*: int8
    affect*: int8
    vmods1*: int8
    vmods2*: int8


type
  PXkbPtrAction* = ptr TXkbPtrAction
  TXkbPtrAction*{.final.} = object
    theType*: int8
    flags*: int8
    high_XXX*: int8
    low_XXX*: int8
    high_YYY*: int8
    low_YYY*: int8


proc XkbPtrActionX*(a: PXkbPtrAction): int16
proc XkbPtrActionY*(a: PXkbPtrAction): int16
proc XkbSetPtrActionX*(a: PXkbPtrAction, x: int8)
proc XkbSetPtrActionY*(a: PXkbPtrAction, y: int8)
type
  PXkbPtrBtnAction* = ptr TXkbPtrBtnAction
  TXkbPtrBtnAction*{.final.} = object
    theType*: int8
    flags*: int8
    count*: int8
    button*: int8


type
  PXkbPtrDfltAction* = ptr TXkbPtrDfltAction
  TXkbPtrDfltAction*{.final.} = object
    theType*: int8
    flags*: int8
    affect*: int8
    valueXXX*: int8


proc XkbSAPtrDfltValue*(a: PXkbPtrDfltAction): int8
proc XkbSASetPtrDfltValue*(a: PXkbPtrDfltAction, c: pointer)
type
  PXkbSwitchScreenAction* = ptr TXkbSwitchScreenAction
  TXkbSwitchScreenAction*{.final.} = object
    theType*: int8
    flags*: int8
    screenXXX*: int8


proc XkbSAScreen*(a: PXkbSwitchScreenAction): int8
proc XkbSASetScreen*(a: PXkbSwitchScreenAction, s: pointer)
type
  PXkbCtrlsAction* = ptr TXkbCtrlsAction
  TXkbCtrlsAction*{.final.} = object
    theType*: int8
    flags*: int8
    ctrls3*: int8
    ctrls2*: int8
    ctrls1*: int8
    ctrls0*: int8


proc XkbActionSetCtrls*(a: PXkbCtrlsAction, c: int8)
proc XkbActionCtrls*(a: PXkbCtrlsAction): int16
type
  PXkbMessageAction* = ptr TXkbMessageAction
  TXkbMessageAction*{.final.} = object
    theType*: int8
    flags*: int8
    message*: array[0..5, char]


type
  PXkbRedirectKeyAction* = ptr TXkbRedirectKeyAction
  TXkbRedirectKeyAction*{.final.} = object
    theType*: int8
    new_key*: int8
    mods_mask*: int8
    mods*: int8
    vmods_mask0*: int8
    vmods_mask1*: int8
    vmods0*: int8
    vmods1*: int8


proc XkbSARedirectVMods*(a: PXkbRedirectKeyAction): int16
proc XkbSARedirectSetVMods*(a: PXkbRedirectKeyAction, m: int8)
proc XkbSARedirectVModsMask*(a: PXkbRedirectKeyAction): int16
proc XkbSARedirectSetVModsMask*(a: PXkbRedirectKeyAction, m: int8)
type
  PXkbDeviceBtnAction* = ptr TXkbDeviceBtnAction
  TXkbDeviceBtnAction*{.final.} = object
    theType*: int8
    flags*: int8
    count*: int8
    button*: int8
    device*: int8


type
  PXkbDeviceValuatorAction* = ptr TXkbDeviceValuatorAction
  TXkbDeviceValuatorAction*{.final.} = object  #
                                               #      Macros to classify key actions
                                               #
    theType*: int8
    device*: int8
    v1_what*: int8
    v1_ndx*: int8
    v1_value*: int8
    v2_what*: int8
    v2_ndx*: int8
    v2_value*: int8


const
  XkbAnyActionDataSize* = 7

type
  PXkbAnyAction* = ptr TXkbAnyAction
  TXkbAnyAction*{.final.} = object
    theType*: int8
    data*: array[0..XkbAnyActionDataSize - 1, int8]


proc XkbIsModAction*(a: PXkbAnyAction): bool
proc XkbIsGroupAction*(a: PXkbAnyAction): bool
proc XkbIsPtrAction*(a: PXkbAnyAction): bool
type
  PXkbAction* = ptr TXkbAction
  TXkbAction*{.final.} = object  #
                                 #      XKB request codes, used in:
                                 #      -  xkbReqType field of all requests
                                 #      -  requestMinor field of some events
                                 #
    any*: TXkbAnyAction
    mods*: TXkbModAction
    group*: TXkbGroupAction
    iso*: TXkbISOAction
    thePtr*: TXkbPtrAction
    btn*: TXkbPtrBtnAction
    dflt*: TXkbPtrDfltAction
    screen*: TXkbSwitchScreenAction
    ctrls*: TXkbCtrlsAction
    msg*: TXkbMessageAction
    redirect*: TXkbRedirectKeyAction
    devbtn*: TXkbDeviceBtnAction
    devval*: TXkbDeviceValuatorAction
    theType*: int8


const
  X_kbUseExtension* = 0
  X_kbSelectEvents* = 1
  X_kbBell* = 3
  X_kbGetState* = 4
  X_kbLatchLockState* = 5
  X_kbGetControls* = 6
  X_kbSetControls* = 7
  X_kbGetMap* = 8
  X_kbSetMap* = 9
  X_kbGetCompatMap* = 10
  X_kbSetCompatMap* = 11
  X_kbGetIndicatorState* = 12
  X_kbGetIndicatorMap* = 13
  X_kbSetIndicatorMap* = 14
  X_kbGetNamedIndicator* = 15
  X_kbSetNamedIndicator* = 16
  X_kbGetNames* = 17
  X_kbSetNames* = 18
  X_kbGetGeometry* = 19
  X_kbSetGeometry* = 20
  X_kbPerClientFlags* = 21
  X_kbListComponents* = 22
  X_kbGetKbdByName* = 23
  X_kbGetDeviceInfo* = 24
  X_kbSetDeviceInfo* = 25
  X_kbSetDebuggingFlags* = 101 #
                               #      In the X sense, XKB reports only one event.
                               #      The type field of all XKB events is XkbEventCode
                               #

const
  XkbEventCode* = 0
  XkbNumberEvents* = XkbEventCode + 1 #
                                      #      XKB has a minor event code so it can use one X event code for
                                      #      multiple purposes.
                                      #       - reported in the xkbType field of all XKB events.
                                      #       - XkbSelectEventDetails: Indicates the event for which event details
                                      #         are being changed
                                      #

const
  XkbNewKeyboardNotify* = 0
  XkbMapNotify* = 1
  XkbStateNotify* = 2
  XkbControlsNotify* = 3
  XkbIndicatorStateNotify* = 4
  XkbIndicatorMapNotify* = 5
  XkbNamesNotify* = 6
  XkbCompatMapNotify* = 7
  XkbBellNotify* = 8
  XkbActionMessage* = 9
  XkbAccessXNotify* = 10
  XkbExtensionDeviceNotify* = 11 #
                                 #      Event Mask:
                                 #       - XkbSelectEvents:  Specifies event interest.
                                 #

const
  XkbNewKeyboardNotifyMask* = int(1) shl 0
  XkbMapNotifyMask* = int(1) shl 1
  XkbStateNotifyMask* = int(1) shl 2
  XkbControlsNotifyMask* = int(1) shl 3
  XkbIndicatorStateNotifyMask* = int(1) shl 4
  XkbIndicatorMapNotifyMask* = int(1) shl 5
  XkbNamesNotifyMask* = int(1) shl 6
  XkbCompatMapNotifyMask* = int(1) shl 7
  XkbBellNotifyMask* = int(1) shl 8
  XkbActionMessageMask* = int(1) shl 9
  XkbAccessXNotifyMask* = int(1) shl 10
  XkbExtensionDeviceNotifyMask* = int(1) shl 11
  XkbAllEventsMask* = 0x00000FFF #
                                 #      NewKeyboardNotify event details:
                                 #

const
  XkbNKN_KeycodesMask* = int(1) shl 0
  XkbNKN_GeometryMask* = int(1) shl 1
  XkbNKN_DeviceIDMask* = int(1) shl 2
  XkbAllNewKeyboardEventsMask* = 0x00000007 #
                                            #      AccessXNotify event types:
                                            #       - The 'what' field of AccessXNotify events reports the
                                            #         reason that the event was generated.
                                            #

const
  XkbAXN_SKPress* = 0
  XkbAXN_SKAccept* = 1
  XkbAXN_SKReject* = 2
  XkbAXN_SKRelease* = 3
  XkbAXN_BKAccept* = 4
  XkbAXN_BKReject* = 5
  XkbAXN_AXKWarning* = 6 #
                         #      AccessXNotify details:
                         #      - Used as an event detail mask to limit the conditions under which
                         #        AccessXNotify events are reported
                         #

const
  XkbAXN_SKPressMask* = int(1) shl 0
  XkbAXN_SKAcceptMask* = int(1) shl 1
  XkbAXN_SKRejectMask* = int(1) shl 2
  XkbAXN_SKReleaseMask* = int(1) shl 3
  XkbAXN_BKAcceptMask* = int(1) shl 4
  XkbAXN_BKRejectMask* = int(1) shl 5
  XkbAXN_AXKWarningMask* = int(1) shl 6
  XkbAllAccessXEventsMask* = 0x0000000F #
                                        #      State detail mask:
                                        #       - The 'changed' field of StateNotify events reports which of
                                        #         the keyboard state components have changed.
                                        #       - Used as an event detail mask to limit the conditions under
                                        #         which StateNotify events are reported.
                                        #

const
  XkbModifierStateMask* = int(1) shl 0
  XkbModifierBaseMask* = int(1) shl 1
  XkbModifierLatchMask* = int(1) shl 2
  XkbModifierLockMask* = int(1) shl 3
  XkbGroupStateMask* = int(1) shl 4
  XkbGroupBaseMask* = int(1) shl 5
  XkbGroupLatchMask* = int(1) shl 6
  XkbGroupLockMask* = int(1) shl 7
  XkbCompatStateMask* = int(1) shl 8
  XkbGrabModsMask* = int(1) shl 9
  XkbCompatGrabModsMask* = int(1) shl 10
  XkbLookupModsMask* = int(1) shl 11
  XkbCompatLookupModsMask* = int(1) shl 12
  XkbPointerButtonMask* = int(1) shl 13
  XkbAllStateComponentsMask* = 0x00003FFF #
                                          #      Controls detail masks:
                                          #       The controls specified in XkbAllControlsMask:
                                          #       - The 'changed' field of ControlsNotify events reports which of
                                          #         the keyboard controls have changed.
                                          #       - The 'changeControls' field of the SetControls request specifies
                                          #         the controls for which values are to be changed.
                                          #       - Used as an event detail mask to limit the conditions under
                                          #         which ControlsNotify events are reported.
                                          #
                                          #       The controls specified in the XkbAllBooleanCtrlsMask:
                                          #       - The 'enabledControls' field of ControlsNotify events reports the
                                          #         current status of the boolean controls.
                                          #       - The 'enabledControlsChanges' field of ControlsNotify events reports
                                          #         any boolean controls that have been turned on or off.
                                          #       - The 'affectEnabledControls' and 'enabledControls' fields of the
                                          #         kbSetControls request change the set of enabled controls.
                                          #       - The 'accessXTimeoutMask' and 'accessXTimeoutValues' fields of
                                          #         an XkbControlsRec specify the controls to be changed if the keyboard
                                          #         times out and the values to which they should be changed.
                                          #       - The 'autoCtrls' and 'autoCtrlsValues' fields of the PerClientFlags
                                          #         request specifies the specify the controls to be reset when the
                                          #         client exits and the values to which they should be reset.
                                          #       - The 'ctrls' field of an indicator map specifies the controls
                                          #         that drive the indicator.
                                          #       - Specifies the boolean controls affected by the SetControls and
                                          #         LockControls key actions.
                                          #

const
  XkbRepeatKeysMask* = int(1) shl 0
  XkbSlowKeysMask* = int(1) shl 1
  XkbBounceKeysMask* = int(1) shl 2
  XkbStickyKeysMask* = int(1) shl 3
  XkbMouseKeysMask* = int(1) shl 4
  XkbMouseKeysAccelMask* = int(1) shl 5
  XkbAccessXKeysMask* = int(1) shl 6
  XkbAccessXTimeoutMask* = int(1) shl 7
  XkbAccessXFeedbackMask* = int(1) shl 8
  XkbAudibleBellMask* = int(1) shl 9
  XkbOverlay1Mask* = int(1) shl 10
  XkbOverlay2Mask* = int(1) shl 11
  XkbIgnoreGroupLockMask* = int(1) shl 12
  XkbGroupsWrapMask* = int(1) shl 27
  XkbInternalModsMask* = int(1) shl 28
  XkbIgnoreLockModsMask* = int(1) shl 29
  XkbPerKeyRepeatMask* = int(1) shl 30
  XkbControlsEnabledMask* = int(1) shl 31
  XkbAccessXOptionsMask* = XkbStickyKeysMask or XkbAccessXFeedbackMask
  XkbAllBooleanCtrlsMask* = 0x00001FFF
  XkbAllControlsMask* = 0xF8001FFF #
                                   #      Compatibility Map Compontents:
                                   #       - Specifies the components to be allocated in XkbAllocCompatMap.
                                   #

const
  XkbSymInterpMask* = 1 shl 0
  XkbGroupCompatMask* = 1 shl 1
  XkbAllCompatMask* = 0x00000003 #
                                 #      Assorted constants and limits.
                                 #

const
  XkbAllIndicatorsMask* = 0xFFFFFFFF #
                                     #      Map components masks:
                                     #      Those in AllMapComponentsMask:
                                     #       - Specifies the individual fields to be loaded or changed for the
                                     #         GetMap and SetMap requests.
                                     #      Those in ClientInfoMask:
                                     #       - Specifies the components to be allocated by XkbAllocClientMap.
                                     #      Those in ServerInfoMask:
                                     #       - Specifies the components to be allocated by XkbAllocServerMap.
                                     #

const
  XkbKeyTypesMask* = 1 shl 0
  XkbKeySymsMask* = 1 shl 1
  XkbModifierMapMask* = 1 shl 2
  XkbExplicitComponentsMask* = 1 shl 3
  XkbKeyActionsMask* = 1 shl 4
  XkbKeyBehaviorsMask* = 1 shl 5
  XkbVirtualModsMask* = 1 shl 6
  XkbVirtualModMapMask* = 1 shl 7
  XkbAllClientInfoMask* = XkbKeyTypesMask or XkbKeySymsMask or
      XkbModifierMapMask
  XkbAllServerInfoMask* = XkbExplicitComponentsMask or XkbKeyActionsMask or
      XkbKeyBehaviorsMask or XkbVirtualModsMask or XkbVirtualModMapMask
  XkbAllMapComponentsMask* = XkbAllClientInfoMask or XkbAllServerInfoMask #
                                                                          #      Names component mask:
                                                                          #       - Specifies the names to be loaded or changed for the GetNames and
                                                                          #         SetNames requests.
                                                                          #       - Specifies the names that have changed in a NamesNotify event.
                                                                          #       - Specifies the names components to be allocated by XkbAllocNames.
                                                                          #

const
  XkbKeycodesNameMask* = 1 shl 0
  XkbGeometryNameMask* = 1 shl 1
  XkbSymbolsNameMask* = 1 shl 2
  XkbPhysSymbolsNameMask* = 1 shl 3
  XkbTypesNameMask* = 1 shl 4
  XkbCompatNameMask* = 1 shl 5
  XkbKeyTypeNamesMask* = 1 shl 6
  XkbKTLevelNamesMask* = 1 shl 7
  XkbIndicatorNamesMask* = 1 shl 8
  XkbKeyNamesMask* = 1 shl 9
  XkbKeyAliasesMask* = 1 shl 10
  XkbVirtualModNamesMask* = 1 shl 11
  XkbGroupNamesMask* = 1 shl 12
  XkbRGNamesMask* = 1 shl 13
  XkbComponentNamesMask* = 0x0000003F
  XkbAllNamesMask* = 0x00003FFF #
                                #      Miscellaneous event details:
                                #      - event detail masks for assorted events that don't reall
                                #        have any details.
                                #

const
  XkbAllStateEventsMask* = XkbAllStateComponentsMask
  XkbAllMapEventsMask* = XkbAllMapComponentsMask
  XkbAllControlEventsMask* = XkbAllControlsMask
  XkbAllIndicatorEventsMask* = XkbAllIndicatorsMask
  XkbAllNameEventsMask* = XkbAllNamesMask
  XkbAllCompatMapEventsMask* = XkbAllCompatMask
  XkbAllBellEventsMask* = int(1) shl 0
  XkbAllActionMessagesMask* = int(1) shl 0 #
                                           #      XKB reports one error:  BadKeyboard
                                           #      A further reason for the error is encoded into to most significant
                                           #      byte of the resourceID for the error:
                                           #         XkbErr_BadDevice - the device in question was not found
                                           #         XkbErr_BadClass  - the device was found but it doesn't belong to
                                           #                            the appropriate class.
                                           #         XkbErr_BadId     - the device was found and belongs to the right
                                           #                            class, but not feedback with a matching id was
                                           #                            found.
                                           #      The low byte of the resourceID for this error contains the device
                                           #      id, class specifier or feedback id that failed.
                                           #

const
  XkbKeyboard* = 0
  XkbNumberErrors* = 1
  XkbErr_BadDevice* = 0x000000FF
  XkbErr_BadClass* = 0x000000FE
  XkbErr_BadId* = 0x000000FD #
                             #      Keyboard Components Mask:
                             #      - Specifies the components that follow a GetKeyboardByNameReply
                             #

const
  XkbClientMapMask* = int(1) shl 0
  XkbServerMapMask* = int(1) shl 1
  XkbCompatMapMask* = int(1) shl 2
  XkbIndicatorMapMask* = int(1) shl 3
  XkbNamesMask* = int(1) shl 4
  XkbGeometryMask* = int(1) shl 5
  XkbControlsMask* = int(1) shl 6
  XkbAllComponentsMask* = 0x0000007F #
                                     #      AccessX Options Mask
                                     #       - The 'accessXOptions' field of an XkbControlsRec specifies the
                                     #         AccessX options that are currently in effect.
                                     #       - The 'accessXTimeoutOptionsMask' and 'accessXTimeoutOptionsValues'
                                     #         fields of an XkbControlsRec specify the Access X options to be
                                     #         changed if the keyboard times out and the values to which they
                                     #         should be changed.
                                     #

const
  XkbAX_SKPressFBMask* = int(1) shl 0
  XkbAX_SKAcceptFBMask* = int(1) shl 1
  XkbAX_FeatureFBMask* = int(1) shl 2
  XkbAX_SlowWarnFBMask* = int(1) shl 3
  XkbAX_IndicatorFBMask* = int(1) shl 4
  XkbAX_StickyKeysFBMask* = int(1) shl 5
  XkbAX_TwoKeysMask* = int(1) shl 6
  XkbAX_LatchToLockMask* = int(1) shl 7
  XkbAX_SKReleaseFBMask* = int(1) shl 8
  XkbAX_SKRejectFBMask* = int(1) shl 9
  XkbAX_BKRejectFBMask* = int(1) shl 10
  XkbAX_DumbBellFBMask* = int(1) shl 11
  XkbAX_FBOptionsMask* = 0x00000F3F
  XkbAX_SKOptionsMask* = 0x000000C0
  XkbAX_AllOptionsMask* = 0x00000FFF #
                                     #      XkbUseCoreKbd is used to specify the core keyboard without having
                                     #                        to look up its X input extension identifier.
                                     #      XkbUseCorePtr is used to specify the core pointer without having
                                     #                        to look up its X input extension identifier.
                                     #      XkbDfltXIClass is used to specify "don't care" any place that the
                                     #                        XKB protocol is looking for an X Input Extension
                                     #                        device class.
                                     #      XkbDfltXIId is used to specify "don't care" any place that the
                                     #                        XKB protocol is looking for an X Input Extension
                                     #                        feedback identifier.
                                     #      XkbAllXIClasses is used to get information about all device indicators,
                                     #                        whether they're part of the indicator feedback class
                                     #                        or the keyboard feedback class.
                                     #      XkbAllXIIds is used to get information about all device indicator
                                     #                        feedbacks without having to list them.
                                     #      XkbXINone is used to indicate that no class or id has been specified.
                                     #      XkbLegalXILedClass(c)  True if 'c' specifies a legal class with LEDs
                                     #      XkbLegalXIBellClass(c) True if 'c' specifies a legal class with bells
                                     #      XkbExplicitXIDevice(d) True if 'd' explicitly specifies a device
                                     #      XkbExplicitXIClass(c)  True if 'c' explicitly specifies a device class
                                     #      XkbExplicitXIId(c)     True if 'i' explicitly specifies a device id
                                     #      XkbSingleXIClass(c)    True if 'c' specifies exactly one device class,
                                     #                             including the default.
                                     #      XkbSingleXIId(i)       True if 'i' specifies exactly one device
                                     #                              identifier, including the default.
                                     #

const
  XkbUseCoreKbd* = 0x00000100
  XkbUseCorePtr* = 0x00000200
  XkbDfltXIClass* = 0x00000300
  XkbDfltXIId* = 0x00000400
  XkbAllXIClasses* = 0x00000500
  XkbAllXIIds* = 0x00000600
  XkbXINone* = 0x0000FF00

proc XkbLegalXILedClass*(c: int): bool
proc XkbLegalXIBellClass*(c: int): bool
proc XkbExplicitXIDevice*(c: int): bool
proc XkbExplicitXIClass*(c: int): bool
proc XkbExplicitXIId*(c: int): bool
proc XkbSingleXIClass*(c: int): bool
proc XkbSingleXIId*(c: int): bool
const
  XkbNoModifier* = 0x000000FF
  XkbNoShiftLevel* = 0x000000FF
  XkbNoShape* = 0x000000FF
  XkbNoIndicator* = 0x000000FF
  XkbNoModifierMask* = 0
  XkbAllModifiersMask* = 0x000000FF
  XkbAllVirtualModsMask* = 0x0000FFFF
  XkbNumKbdGroups* = 4
  XkbMaxKbdGroup* = XkbNumKbdGroups - 1
  XkbMaxMouseKeysBtn* = 4 #
                          #      Group Index and Mask:
                          #       - Indices into the kt_index array of a key type.
                          #       - Mask specifies types to be changed for XkbChangeTypesOfKey
                          #

const
  XkbGroup1Index* = 0
  XkbGroup2Index* = 1
  XkbGroup3Index* = 2
  XkbGroup4Index* = 3
  XkbAnyGroup* = 254
  XkbAllGroups* = 255
  XkbGroup1Mask* = 1 shl 0
  XkbGroup2Mask* = 1 shl 1
  XkbGroup3Mask* = 1 shl 2
  XkbGroup4Mask* = 1 shl 3
  XkbAnyGroupMask* = 1 shl 7
  XkbAllGroupsMask* = 0x0000000F #
                                 #      BuildCoreState: Given a keyboard group and a modifier state,
                                 #                      construct the value to be reported an event.
                                 #      GroupForCoreState:  Given the state reported in an event,
                                 #                      determine the keyboard group.
                                 #      IsLegalGroup:   Returns TRUE if 'g' is a valid group index.
                                 #

proc XkbBuildCoreState*(m, g: int): int
proc XkbGroupForCoreState*(s: int): int
proc XkbIsLegalGroup*(g: int): bool
  #
  #      GroupsWrap values:
  #       - The 'groupsWrap' field of an XkbControlsRec specifies the
  #         treatment of out of range groups.
  #       - Bits 6 and 7 of the group info field of a key symbol map
  #         specify the interpretation of out of range groups for the
  #         corresponding key.
  #
const
  XkbWrapIntoRange* = 0x00000000
  XkbClampIntoRange* = 0x00000040
  XkbRedirectIntoRange* = 0x00000080 #
                                     #      Action flags:  Reported in the 'flags' field of most key actions.
                                     #      Interpretation depends on the type of the action; not all actions
                                     #      accept all flags.
                                     #
                                     #      Option                    Used for Actions
                                     #      ------                    ----------------
                                     #      ClearLocks                SetMods, LatchMods, SetGroup, LatchGroup
                                     #      LatchToLock               SetMods, LatchMods, SetGroup, LatchGroup
                                     #      LockNoLock                LockMods, ISOLock, LockPtrBtn, LockDeviceBtn
                                     #      LockNoUnlock              LockMods, ISOLock, LockPtrBtn, LockDeviceBtn
                                     #      UseModMapMods             SetMods, LatchMods, LockMods, ISOLock
                                     #      GroupAbsolute             SetGroup, LatchGroup, LockGroup, ISOLock
                                     #      UseDfltButton             PtrBtn, LockPtrBtn
                                     #      NoAcceleration            MovePtr
                                     #      MoveAbsoluteX             MovePtr
                                     #      MoveAbsoluteY             MovePtr
                                     #      ISODfltIsGroup            ISOLock
                                     #      ISONoAffectMods           ISOLock
                                     #      ISONoAffectGroup          ISOLock
                                     #      ISONoAffectPtr            ISOLock
                                     #      ISONoAffectCtrls          ISOLock
                                     #      MessageOnPress            ActionMessage
                                     #      MessageOnRelease          ActionMessage
                                     #      MessageGenKeyEvent        ActionMessage
                                     #      AffectDfltBtn             SetPtrDflt
                                     #      DfltBtnAbsolute           SetPtrDflt
                                     #      SwitchApplication SwitchScreen
                                     #      SwitchAbsolute            SwitchScreen
                                     #

const
  XkbSA_ClearLocks* = int(1) shl 0
  XkbSA_LatchToLock* = int(1) shl 1
  XkbSA_LockNoLock* = int(1) shl 0
  XkbSA_LockNoUnlock* = int(1) shl 1
  XkbSA_UseModMapMods* = int(1) shl 2
  XkbSA_GroupAbsolute* = int(1) shl 2
  XkbSA_UseDfltButton* = 0
  XkbSA_NoAcceleration* = int(1) shl 0
  XkbSA_MoveAbsoluteX* = int(1) shl 1
  XkbSA_MoveAbsoluteY* = int(1) shl 2
  XkbSA_ISODfltIsGroup* = int(1) shl 7
  XkbSA_ISONoAffectMods* = int(1) shl 6
  XkbSA_ISONoAffectGroup* = int(1) shl 5
  XkbSA_ISONoAffectPtr* = int(1) shl 4
  XkbSA_ISONoAffectCtrls* = int(1) shl 3
  XkbSA_ISOAffectMask* = 0x00000078
  XkbSA_MessageOnPress* = int(1) shl 0
  XkbSA_MessageOnRelease* = int(1) shl 1
  XkbSA_MessageGenKeyEvent* = int(1) shl 2
  XkbSA_AffectDfltBtn* = 1
  XkbSA_DfltBtnAbsolute* = int(1) shl 2
  XkbSA_SwitchApplication* = int(1) shl 0
  XkbSA_SwitchAbsolute* = int(1) shl 2 #
                                       #      The following values apply to the SA_DeviceValuator
                                       #      action only.  Valuator operations specify the action
                                       #      to be taken.   Values specified in the action are
                                       #      multiplied by 2^scale before they are applied.
                                       #

const
  XkbSA_IgnoreVal* = 0x00000000
  XkbSA_SetValMin* = 0x00000010
  XkbSA_SetValCenter* = 0x00000020
  XkbSA_SetValMax* = 0x00000030
  XkbSA_SetValRelative* = 0x00000040
  XkbSA_SetValAbsolute* = 0x00000050
  XkbSA_ValOpMask* = 0x00000070
  XkbSA_ValScaleMask* = 0x00000007

proc XkbSA_ValOp*(a: int): int
proc XkbSA_ValScale*(a: int): int
  #
  #      Action types: specifies the type of a key action.  Reported in the
  #      type field of all key actions.
  #
const
  XkbSA_NoAction* = 0x00000000
  XkbSA_SetMods* = 0x00000001
  XkbSA_LatchMods* = 0x00000002
  XkbSA_LockMods* = 0x00000003
  XkbSA_SetGroup* = 0x00000004
  XkbSA_LatchGroup* = 0x00000005
  XkbSA_LockGroup* = 0x00000006
  XkbSA_MovePtr* = 0x00000007
  XkbSA_PtrBtn* = 0x00000008
  XkbSA_LockPtrBtn* = 0x00000009
  XkbSA_SetPtrDflt* = 0x0000000A
  XkbSA_ISOLock* = 0x0000000B
  XkbSA_Terminate* = 0x0000000C
  XkbSA_SwitchScreen* = 0x0000000D
  XkbSA_SetControls* = 0x0000000E
  XkbSA_LockControls* = 0x0000000F
  XkbSA_ActionMessage* = 0x00000010
  XkbSA_RedirectKey* = 0x00000011
  XkbSA_DeviceBtn* = 0x00000012
  XkbSA_LockDeviceBtn* = 0x00000013
  XkbSA_DeviceValuator* = 0x00000014
  XkbSA_LastAction* = XkbSA_DeviceValuator
  XkbSA_NumActions* = XkbSA_LastAction + 1

const
  XkbSA_XFree86Private* = 0x00000086
#
#      Specifies the key actions that clear latched groups or modifiers.
#

const  ##define        XkbSA_BreakLatch \
       #        ((1<<XkbSA_NoAction)|(1<<XkbSA_PtrBtn)|(1<<XkbSA_LockPtrBtn)|\
       #        (1<<XkbSA_Terminate)|(1<<XkbSA_SwitchScreen)|(1<<XkbSA_SetControls)|\
       #        (1<<XkbSA_LockControls)|(1<<XkbSA_ActionMessage)|\
       #        (1<<XkbSA_RedirectKey)|(1<<XkbSA_DeviceBtn)|(1<<XkbSA_LockDeviceBtn))
       #
  XkbSA_BreakLatch* = (1 shl XkbSA_PtrBtn) or (1 shl XkbSA_LockPtrBtn) or
      (1 shl XkbSA_Terminate) or (1 shl XkbSA_SwitchScreen) or
      (1 shl XkbSA_SetControls) or (1 shl XkbSA_LockControls) or
      (1 shl XkbSA_ActionMessage) or (1 shl XkbSA_RedirectKey) or
      (1 shl XkbSA_DeviceBtn) or (1 shl XkbSA_LockDeviceBtn) #
                                                             #      Key Behavior Qualifier:
                                                             #         KB_Permanent indicates that the behavior describes an unalterable
                                                             #         characteristic of the keyboard, not an XKB software-simulation of
                                                             #         the listed behavior.
                                                             #      Key Behavior Types:
                                                             #         Specifies the behavior of the underlying key.
                                                             #

const
  XkbKB_Permanent* = 0x00000080
  XkbKB_OpMask* = 0x0000007F
  XkbKB_Default* = 0x00000000
  XkbKB_Lock* = 0x00000001
  XkbKB_RadioGroup* = 0x00000002
  XkbKB_Overlay1* = 0x00000003
  XkbKB_Overlay2* = 0x00000004
  XkbKB_RGAllowNone* = 0x00000080 #
                                  #      Various macros which describe the range of legal keycodes.
                                  #

const
  XkbMinLegalKeyCode* = 8
  XkbMaxLegalKeyCode* = 255
  XkbMaxKeyCount* = XkbMaxLegalKeyCode - XkbMinLegalKeyCode + 1
  XkbPerKeyBitArraySize* = (XkbMaxLegalKeyCode + 1) div 8

proc XkbIsLegalKeycode*(k: int): bool
type
  PXkbControlsPtr* = ptr TXkbControlsRec
  TXkbControlsRec*{.final.} = object
    mk_dflt_btn*: int8
    num_groups*: int8
    groups_wrap*: int8
    internal*: TXkbModsRec
    ignore_lock*: TXkbModsRec
    enabled_ctrls*: int16
    repeat_delay*: int16
    repeat_interval*: int16
    slow_keys_delay*: int16
    debounce_delay*: int16
    mk_delay*: int16
    mk_interval*: int16
    mk_time_to_max*: int16
    mk_max_speed*: int16
    mk_curve*: int16
    ax_options*: int16
    ax_timeout*: int16
    axt_opts_mask*: int16
    axt_opts_values*: int16
    axt_ctrls_mask*: int16
    axt_ctrls_values*: int16
    per_key_repeat*: array[0..XkbPerKeyBitArraySize - 1, int8]


proc XkbAX_AnyFeedback*(c: PXkbControlsPtr): int16
proc XkbAX_NeedOption*(c: PXkbControlsPtr, w: int16): int16
proc XkbAX_NeedFeedback*(c: PXkbControlsPtr, w: int16): bool
  #
  #      Assorted constants and limits.
  #
const
  XkbNumModifiers* = 8
  XkbNumVirtualMods* = 16
  XkbNumIndicators* = 32
  XkbMaxRadioGroups* = 32
  XkbAllRadioGroupsMask* = 0xFFFFFFFF
  XkbMaxShiftLevel* = 63
  XkbMaxSymsPerKey* = XkbMaxShiftLevel * XkbNumKbdGroups
  XkbRGMaxMembers* = 12
  XkbActionMessageLength* = 6
  XkbKeyNameLength* = 4
  XkbMaxRedirectCount* = 8
  XkbGeomPtsPerMM* = 10
  XkbGeomMaxColors* = 32
  XkbGeomMaxLabelColors* = 3
  XkbGeomMaxPriority* = 255

type
  PXkbServerMapPtr* = ptr TXkbServerMapRec
  TXkbServerMapRec*{.final.} = object
    num_acts*: int16
    size_acts*: int16
    acts*: ptr array[0..0xfff, TXkbAction]
    behaviors*: PXkbBehavior
    key_acts*: PWord
    explicit*: PByte
    vmods*: array[0..XkbNumVirtualMods - 1, int8]
    vmodmap*: PWord


proc XkbSMKeyActionsPtr*(m: PXkbServerMapPtr, k: int16): PXkbAction
  #
  #          Structures and access macros used primarily by clients
  #
type
  PXkbSymMapPtr* = ptr TXkbSymMapRec
  TXkbSymMapRec*{.final.} = object
    kt_index*: array[0..XkbNumKbdGroups - 1, int8]
    group_info*: int8
    width*: int8
    offset*: int8


type
  PXkbClientMapPtr* = ptr TXkbClientMapRec
  TXkbClientMapRec*{.final.} = object
    size_types*: int8
    num_types*: int8
    types*: ptr array[0..0xffff, TXkbKeyTypeRec]
    size_syms*: int16
    num_syms*: int16
    syms*: ptr array[0..0xffff, TKeySym]
    key_sym_map*: ptr array[0..0xffff, TXkbSymMapRec]
    modmap*: PByte


proc XkbCMKeyGroupInfo*(m: PXkbClientMapPtr, k: int16): int8
proc XkbCMKeyNumGroups*(m: PXkbClientMapPtr, k: int16): int8
proc XkbCMKeyGroupWidth*(m: PXkbClientMapPtr, k: int16, g: int8): int8
proc XkbCMKeyGroupsWidth*(m: PXkbClientMapPtr, k: int16): int8
proc XkbCMKeyTypeIndex*(m: PXkbClientMapPtr, k: int16, g: int8): int8
proc XkbCMKeyType*(m: PXkbClientMapPtr, k: int16, g: int8): PXkbKeyTypePtr
proc XkbCMKeyNumSyms*(m: PXkbClientMapPtr, k: int16): int16
proc XkbCMKeySymsOffset*(m: PXkbClientMapPtr, k: int16): int8
  #
  #          Compatibility structures and access macros
  #
type
  PXkbSymInterpretPtr* = ptr TXkbSymInterpretRec
  TXkbSymInterpretRec*{.final.} = object
    sym*: TKeySym
    flags*: int8
    match*: int8
    mods*: int8
    virtual_mod*: int8
    act*: TXkbAnyAction


type
  PXkbCompatMapPtr* = ptr TXkbCompatMapRec
  TXkbCompatMapRec*{.final.} = object
    sym_interpret*: PXkbSymInterpretPtr
    groups*: array[0..XkbNumKbdGroups - 1, TXkbModsRec]
    num_si*: int16
    size_si*: int16


type
  PXkbIndicatorMapPtr* = ptr TXkbIndicatorMapRec
  TXkbIndicatorMapRec*{.final.} = object
    flags*: int8
    which_groups*: int8
    groups*: int8
    which_mods*: int8
    mods*: TXkbModsRec
    ctrls*: int16


proc XkbIM_IsAuto*(i: PXkbIndicatorMapPtr): bool
proc XkbIM_InUse*(i: PXkbIndicatorMapPtr): bool
type
  PXkbIndicatorPtr* = ptr TXkbIndicatorRec
  TXkbIndicatorRec*{.final.} = object
    phys_indicators*: int32
    maps*: array[0..XkbNumIndicators - 1, TXkbIndicatorMapRec]


type
  PXkbKeyNamePtr* = ptr TXkbKeyNameRec
  TXkbKeyNameRec*{.final.} = object
    name*: array[0..XkbKeyNameLength - 1, char]


type
  PXkbKeyAliasPtr* = ptr TXkbKeyAliasRec
  TXkbKeyAliasRec*{.final.} = object  #
                                      #          Names for everything
                                      #
    float*: array[0..XkbKeyNameLength - 1, char]
    alias*: array[0..XkbKeyNameLength - 1, char]


type
  PXkbNamesPtr* = ptr TXkbNamesRec
  TXkbNamesRec*{.final.} = object  #
                                   #      Key Type index and mask for the four standard key types.
                                   #
    keycodes*: TAtom
    geometry*: TAtom
    symbols*: TAtom
    types*: TAtom
    compat*: TAtom
    vmods*: array[0..XkbNumVirtualMods - 1, TAtom]
    indicators*: array[0..XkbNumIndicators - 1, TAtom]
    groups*: array[0..XkbNumKbdGroups - 1, TAtom]
    keys*: PXkbKeyNamePtr
    key_aliases*: PXkbKeyAliasPtr
    radio_groups*: PAtom
    phys_symbols*: TAtom
    num_keys*: int8
    num_key_aliases*: int8
    num_rg*: int16


const
  XkbOneLevelIndex* = 0
  XkbTwoLevelIndex* = 1
  XkbAlphabeticIndex* = 2
  XkbKeypadIndex* = 3
  XkbLastRequiredType* = XkbKeypadIndex
  XkbNumRequiredTypes* = XkbLastRequiredType + 1
  XkbMaxKeyTypes* = 255
  XkbOneLevelMask* = 1 shl 0
  XkbTwoLevelMask* = 1 shl 1
  XkbAlphabeticMask* = 1 shl 2
  XkbKeypadMask* = 1 shl 3
  XkbAllRequiredTypes* = 0x0000000F

proc XkbShiftLevel*(n: int8): int8
proc XkbShiftLevelMask*(n: int8): int8
  #
  #      Extension name and version information
  #
const
  XkbName* = "XKEYBOARD"
  XkbMajorVersion* = 1
  XkbMinorVersion* = 0 #
                       #      Explicit map components:
                       #       - Used in the 'explicit' field of an XkbServerMap.  Specifies
                       #         the keyboard components that should _not_ be updated automatically
                       #         in response to core protocol keyboard mapping requests.
                       #

const
  XkbExplicitKeyTypesMask* = 0x0000000F
  XkbExplicitKeyType1Mask* = 1 shl 0
  XkbExplicitKeyType2Mask* = 1 shl 1
  XkbExplicitKeyType3Mask* = 1 shl 2
  XkbExplicitKeyType4Mask* = 1 shl 3
  XkbExplicitInterpretMask* = 1 shl 4
  XkbExplicitAutoRepeatMask* = 1 shl 5
  XkbExplicitBehaviorMask* = 1 shl 6
  XkbExplicitVModMapMask* = 1 shl 7
  XkbAllExplicitMask* = 0x000000FF #
                                   #      Symbol interpretations flags:
                                   #       - Used in the flags field of a symbol interpretation
                                   #

const
  XkbSI_AutoRepeat* = 1 shl 0
  XkbSI_LockingKey* = 1 shl 1 #
                              #      Symbol interpretations match specification:
                              #       - Used in the match field of a symbol interpretation to specify
                              #         the conditions under which an interpretation is used.
                              #

const
  XkbSI_LevelOneOnly* = 0x00000080
  XkbSI_OpMask* = 0x0000007F
  XkbSI_NoneOf* = 0
  XkbSI_AnyOfOrNone* = 1
  XkbSI_AnyOf* = 2
  XkbSI_AllOf* = 3
  XkbSI_Exactly* = 4 #
                     #      Indicator map flags:
                     #       - Used in the flags field of an indicator map to indicate the
                     #         conditions under which and indicator can be changed and the
                     #         effects of changing the indicator.
                     #

const
  XkbIM_NoExplicit* = int(1) shl 7
  XkbIM_NoAutomatic* = int(1) shl 6
  XkbIM_LEDDrivesKB* = int(1) shl 5 #
                                    #      Indicator map component specifications:
                                    #       - Used by the 'which_groups' and 'which_mods' fields of an indicator
                                    #         map to specify which keyboard components should be used to drive
                                    #         the indicator.
                                    #

const
  XkbIM_UseBase* = int(1) shl 0
  XkbIM_UseLatched* = int(1) shl 1
  XkbIM_UseLocked* = int(1) shl 2
  XkbIM_UseEffective* = int(1) shl 3
  XkbIM_UseCompat* = int(1) shl 4
  XkbIM_UseNone* = 0
  XkbIM_UseAnyGroup* = XkbIM_UseBase or XkbIM_UseLatched or XkbIM_UseLocked or
      XkbIM_UseEffective
  XkbIM_UseAnyMods* = XkbIM_UseAnyGroup or XkbIM_UseCompat #
                                                           #      GetByName components:
                                                           #       - Specifies desired or necessary components to GetKbdByName request.
                                                           #       - Reports the components that were found in a GetKbdByNameReply
                                                           #

const
  XkbGBN_TypesMask* = int(1) shl 0
  XkbGBN_CompatMapMask* = int(1) shl 1
  XkbGBN_ClientSymbolsMask* = int(1) shl 2
  XkbGBN_ServerSymbolsMask* = int(1) shl 3
  XkbGBN_SymbolsMask* = XkbGBN_ClientSymbolsMask or XkbGBN_ServerSymbolsMask
  XkbGBN_IndicatorMapMask* = int(1) shl 4
  XkbGBN_KeyNamesMask* = int(1) shl 5
  XkbGBN_GeometryMask* = int(1) shl 6
  XkbGBN_OtherNamesMask* = int(1) shl 7
  XkbGBN_AllComponentsMask* = 0x000000FF #
                                         #       ListComponents flags
                                         #

const
  XkbLC_Hidden* = int(1) shl 0
  XkbLC_Default* = int(1) shl 1
  XkbLC_Partial* = int(1) shl 2
  XkbLC_AlphanumericKeys* = int(1) shl 8
  XkbLC_ModifierKeys* = int(1) shl 9
  XkbLC_KeypadKeys* = int(1) shl 10
  XkbLC_FunctionKeys* = int(1) shl 11
  XkbLC_AlternateGroup* = int(1) shl 12 #
                                        #      X Input Extension Interactions
                                        #      - Specifies the possible interactions between XKB and the X input
                                        #        extension
                                        #      - Used to request (XkbGetDeviceInfo) or change (XKbSetDeviceInfo)
                                        #        XKB information about an extension device.
                                        #      - Reports the list of supported optional features in the reply to
                                        #        XkbGetDeviceInfo or in an XkbExtensionDeviceNotify event.
                                        #      XkbXI_UnsupportedFeature is reported in XkbExtensionDeviceNotify
                                        #      events to indicate an attempt to use an unsupported feature.
                                        #

const
  XkbXI_KeyboardsMask* = int(1) shl 0
  XkbXI_ButtonActionsMask* = int(1) shl 1
  XkbXI_IndicatorNamesMask* = int(1) shl 2
  XkbXI_IndicatorMapsMask* = int(1) shl 3
  XkbXI_IndicatorStateMask* = int(1) shl 4
  XkbXI_UnsupportedFeatureMask* = int(1) shl 15
  XkbXI_AllFeaturesMask* = 0x0000001F
  XkbXI_AllDeviceFeaturesMask* = 0x0000001E
  XkbXI_IndicatorsMask* = 0x0000001C
  XkbAllExtensionDeviceEventsMask* = 0x0000801F #
                                                #      Per-Client Flags:
                                                #       - Specifies flags to be changed by the PerClientFlags request.
                                                #

const
  XkbPCF_DetectableAutoRepeatMask* = int(1) shl 0
  XkbPCF_GrabsUseXKBStateMask* = int(1) shl 1
  XkbPCF_AutoResetControlsMask* = int(1) shl 2
  XkbPCF_LookupStateWhenGrabbed* = int(1) shl 3
  XkbPCF_SendEventUsesXKBState* = int(1) shl 4
  XkbPCF_AllFlagsMask* = 0x0000001F #
                                    #      Debugging flags and controls
                                    #

const
  XkbDF_DisableLocks* = 1 shl 0

type
  PXkbPropertyPtr* = ptr TXkbPropertyRec
  TXkbPropertyRec*{.final.} = object
    name*: cstring
    value*: cstring


type
  PXkbColorPtr* = ptr TXkbColorRec
  TXkbColorRec*{.final.} = object
    pixel*: int16
    spec*: cstring


type
  PXkbPointPtr* = ptr TXkbPointRec
  TXkbPointRec*{.final.} = object
    x*: int16
    y*: int16


type
  PXkbBoundsPtr* = ptr TXkbBoundsRec
  TXkbBoundsRec*{.final.} = object
    x1*: int16
    y1*: int16
    x2*: int16
    y2*: int16


proc XkbBoundsWidth*(b: PXkbBoundsPtr): int16
proc XkbBoundsHeight*(b: PXkbBoundsPtr): int16
type
  PXkbOutlinePtr* = ptr TXkbOutlineRec
  TXkbOutlineRec*{.final.} = object
    num_points*: int16
    sz_points*: int16
    corner_radius*: int16
    points*: PXkbPointPtr


type
  PXkbShapePtr* = ptr TXkbShapeRec
  TXkbShapeRec*{.final.} = object
    name*: TAtom
    num_outlines*: int16
    sz_outlines*: int16
    outlines*: ptr array [0..0xffff, TXkbOutlineRec]
    approx*: ptr array[0..0xffff, TXkbOutlineRec]
    primary*: ptr array[0..0xffff, TXkbOutlineRec]
    bounds*: TXkbBoundsRec


proc XkbOutlineIndex*(s: PXkbShapePtr, o: PXkbOutlinePtr): int32
type
  PXkbShapeDoodadPtr* = ptr TXkbShapeDoodadRec
  TXkbShapeDoodadRec*{.final.} = object
    name*: TAtom
    theType*: int8
    priority*: int8
    top*: int16
    left*: int16
    angle*: int16
    color_ndx*: int16
    shape_ndx*: int16


type
  PXkbTextDoodadPtr* = ptr TXkbTextDoodadRec
  TXkbTextDoodadRec*{.final.} = object
    name*: TAtom
    theType*: int8
    priority*: int8
    top*: int16
    left*: int16
    angle*: int16
    width*: int16
    height*: int16
    color_ndx*: int16
    text*: cstring
    font*: cstring


type
  PXkbIndicatorDoodadPtr* = ptr TXkbIndicatorDoodadRec
  TXkbIndicatorDoodadRec*{.final.} = object
    name*: TAtom
    theType*: int8
    priority*: int8
    top*: int16
    left*: int16
    angle*: int16
    shape_ndx*: int16
    on_color_ndx*: int16
    off_color_ndx*: int16


type
  PXkbLogoDoodadPtr* = ptr TXkbLogoDoodadRec
  TXkbLogoDoodadRec*{.final.} = object
    name*: TAtom
    theType*: int8
    priority*: int8
    top*: int16
    left*: int16
    angle*: int16
    color_ndx*: int16
    shape_ndx*: int16
    logo_name*: cstring


type
  PXkbAnyDoodadPtr* = ptr TXkbAnyDoodadRec
  TXkbAnyDoodadRec*{.final.} = object
    name*: TAtom
    theType*: int8
    priority*: int8
    top*: int16
    left*: int16
    angle*: int16


type
  PXkbDoodadPtr* = ptr TXkbDoodadRec
  TXkbDoodadRec*{.final.} = object
    any*: TXkbAnyDoodadRec
    shape*: TXkbShapeDoodadRec
    text*: TXkbTextDoodadRec
    indicator*: TXkbIndicatorDoodadRec
    logo*: TXkbLogoDoodadRec


const
  XkbUnknownDoodad* = 0
  XkbOutlineDoodad* = 1
  XkbSolidDoodad* = 2
  XkbTextDoodad* = 3
  XkbIndicatorDoodad* = 4
  XkbLogoDoodad* = 5

type
  PXkbKeyPtr* = ptr TXkbKeyRec
  TXkbKeyRec*{.final.} = object
    name*: TXkbKeyNameRec
    gap*: int16
    shape_ndx*: int8
    color_ndx*: int8


type
  PXkbRowPtr* = ptr TXkbRowRec
  TXkbRowRec*{.final.} = object
    top*: int16
    left*: int16
    num_keys*: int16
    sz_keys*: int16
    vertical*: int16
    Keys*: PXkbKeyPtr
    bounds*: TXkbBoundsRec


type
  PXkbOverlayPtr* = ptr TXkbOverlayRec #forward for TXkbSectionRec use.
                                       #Do not add more "type"
  PXkbSectionPtr* = ptr TXkbSectionRec
  TXkbSectionRec*{.final.} = object  #Do not add more "type"
    name*: TAtom
    priority*: int8
    top*: int16
    left*: int16
    width*: int16
    height*: int16
    angle*: int16
    num_rows*: int16
    num_doodads*: int16
    num_overlays*: int16
    rows*: PXkbRowPtr
    doodads*: PXkbDoodadPtr
    bounds*: TXkbBoundsRec
    overlays*: PXkbOverlayPtr

  PXkbOverlayKeyPtr* = ptr TXkbOverlayKeyRec
  TXkbOverlayKeyRec*{.final.} = object  #Do not add more "type"
    over*: TXkbKeyNameRec
    under*: TXkbKeyNameRec

  PXkbOverlayRowPtr* = ptr TXkbOverlayRowRec
  TXkbOverlayRowRec*{.final.} = object  #Do not add more "type"
    row_under*: int16
    num_keys*: int16
    sz_keys*: int16
    keys*: PXkbOverlayKeyPtr

  TXkbOverlayRec*{.final.} = object
    name*: TAtom
    section_under*: PXkbSectionPtr
    num_rows*: int16
    sz_rows*: int16
    rows*: PXkbOverlayRowPtr
    bounds*: PXkbBoundsPtr


type
  PXkbGeometryRec* = ptr TXkbGeometryRec
  PXkbGeometryPtr* = PXkbGeometryRec
  TXkbGeometryRec*{.final.} = object
    name*: TAtom
    width_mm*: int16
    height_mm*: int16
    label_font*: cstring
    label_color*: PXkbColorPtr
    base_color*: PXkbColorPtr
    sz_properties*: int16
    sz_colors*: int16
    sz_shapes*: int16
    sz_sections*: int16
    sz_doodads*: int16
    sz_key_aliases*: int16
    num_properties*: int16
    num_colors*: int16
    num_shapes*: int16
    num_sections*: int16
    num_doodads*: int16
    num_key_aliases*: int16
    properties*: ptr array[0..0xffff, TXkbPropertyRec]
    colors*: ptr array[0..0xffff, TXkbColorRec]
    shapes*: ptr array[0..0xffff, TXkbShapeRec]
    sections*: ptr array[0..0xffff, TXkbSectionRec]
    key_aliases*: ptr array[0..0xffff, TXkbKeyAliasRec]


const
  XkbGeomPropertiesMask* = 1 shl 0
  XkbGeomColorsMask* = 1 shl 1
  XkbGeomShapesMask* = 1 shl 2
  XkbGeomSectionsMask* = 1 shl 3
  XkbGeomDoodadsMask* = 1 shl 4
  XkbGeomKeyAliasesMask* = 1 shl 5
  XkbGeomAllMask* = 0x0000003F

type
  PXkbGeometrySizesPtr* = ptr TXkbGeometrySizesRec
  TXkbGeometrySizesRec*{.final.} = object  #
                                           #          Tie it all together into one big keyboard description
                                           #
    which*: int16
    num_properties*: int16
    num_colors*: int16
    num_shapes*: int16
    num_sections*: int16
    num_doodads*: int16
    num_key_aliases*: int16


type
  PXkbDescPtr* = ptr TXkbDescRec
  TXkbDescRec*{.final.} = object
    dpy*: PDisplay
    flags*: int16
    device_spec*: int16
    min_key_code*: TKeyCode
    max_key_code*: TKeyCode
    ctrls*: PXkbControlsPtr
    server*: PXkbServerMapPtr
    map*: PXkbClientMapPtr
    indicators*: PXkbIndicatorPtr
    names*: PXkbNamesPtr
    compat*: PXkbCompatMapPtr
    geom*: PXkbGeometryPtr


proc XkbKeyKeyTypeIndex*(d: PXkbDescPtr, k: int16, g: int8): int8
proc XkbKeyKeyType*(d: PXkbDescPtr, k: int16, g: int8): PXkbKeyTypePtr
proc XkbKeyGroupWidth*(d: PXkbDescPtr, k: int16, g: int8): int8
proc XkbKeyGroupsWidth*(d: PXkbDescPtr, k: int16): int8
proc XkbKeyGroupInfo*(d: PXkbDescPtr, k: int16): int8
proc XkbKeyNumGroups*(d: PXkbDescPtr, k: int16): int8
proc XkbKeyNumSyms*(d: PXkbDescPtr, k: int16): int16
proc XkbKeySym*(d: PXkbDescPtr, k: int16, n: int16): TKeySym
proc XkbKeySymEntry*(d: PXkbDescPtr, k: int16, sl: int16, g: int8): TKeySym
proc XkbKeyAction*(d: PXkbDescPtr, k: int16, n: int16): PXkbAction
proc XkbKeyActionEntry*(d: PXkbDescPtr, k: int16, sl: int16, g: int8): int8
proc XkbKeyHasActions*(d: PXkbDescPtr, k: int16): bool
proc XkbKeyNumActions*(d: PXkbDescPtr, k: int16): int16
proc XkbKeyActionsPtr*(d: PXkbDescPtr, k: int16): PXkbAction
proc XkbKeycodeInRange*(d: PXkbDescPtr, k: int16): bool
proc XkbNumKeys*(d: PXkbDescPtr): int8
  #
  #          The following structures can be used to track changes
  #          to a keyboard device
  #
type
  PXkbMapChangesPtr* = ptr TXkbMapChangesRec
  TXkbMapChangesRec*{.final.} = object
    changed*: int16
    min_key_code*: TKeyCode
    max_key_code*: TKeyCode
    first_type*: int8
    num_types*: int8
    first_key_sym*: TKeyCode
    num_key_syms*: int8
    first_key_act*: TKeyCode
    num_key_acts*: int8
    first_key_behavior*: TKeyCode
    num_key_behaviors*: int8
    first_key_explicit*: TKeyCode
    num_key_explicit*: int8
    first_modmap_key*: TKeyCode
    num_modmap_keys*: int8
    first_vmodmap_key*: TKeyCode
    num_vmodmap_keys*: int8
    pad*: int8
    vmods*: int16


type
  PXkbControlsChangesPtr* = ptr TXkbControlsChangesRec
  TXkbControlsChangesRec*{.final.} = object
    changed_ctrls*: int16
    enabled_ctrls_changes*: int16
    num_groups_changed*: bool


type
  PXkbIndicatorChangesPtr* = ptr TXkbIndicatorChangesRec
  TXkbIndicatorChangesRec*{.final.} = object
    state_changes*: int16
    map_changes*: int16


type
  PXkbNameChangesPtr* = ptr TXkbNameChangesRec
  TXkbNameChangesRec*{.final.} = object
    changed*: int16
    first_type*: int8
    num_types*: int8
    first_lvl*: int8
    num_lvls*: int8
    num_aliases*: int8
    num_rg*: int8
    first_key*: int8
    num_keys*: int8
    changed_vmods*: int16
    changed_indicators*: int32
    changed_groups*: int8


type
  PXkbCompatChangesPtr* = ptr TXkbCompatChangesRec
  TXkbCompatChangesRec*{.final.} = object
    changed_groups*: int8
    first_si*: int16
    num_si*: int16


type
  PXkbChangesPtr* = ptr TXkbChangesRec
  TXkbChangesRec*{.final.} = object  #
                                     #          These data structures are used to construct a keymap from
                                     #          a set of components or to list components in the server
                                     #          database.
                                     #
    device_spec*: int16
    state_changes*: int16
    map*: TXkbMapChangesRec
    ctrls*: TXkbControlsChangesRec
    indicators*: TXkbIndicatorChangesRec
    names*: TXkbNameChangesRec
    compat*: TXkbCompatChangesRec


type
  PXkbComponentNamesPtr* = ptr TXkbComponentNamesRec
  TXkbComponentNamesRec*{.final.} = object
    keymap*: ptr int16
    keycodes*: ptr int16
    types*: ptr int16
    compat*: ptr int16
    symbols*: ptr int16
    geometry*: ptr int16


type
  PXkbComponentNamePtr* = ptr TXkbComponentNameRec
  TXkbComponentNameRec*{.final.} = object
    flags*: int16
    name*: cstring


type
  PXkbComponentListPtr* = ptr TXkbComponentListRec
  TXkbComponentListRec*{.final.} = object  #
                                           #          The following data structures describe and track changes to a
                                           #          non-keyboard extension device
                                           #
    num_keymaps*: int16
    num_keycodes*: int16
    num_types*: int16
    num_compat*: int16
    num_symbols*: int16
    num_geometry*: int16
    keymaps*: PXkbComponentNamePtr
    keycodes*: PXkbComponentNamePtr
    types*: PXkbComponentNamePtr
    compat*: PXkbComponentNamePtr
    symbols*: PXkbComponentNamePtr
    geometry*: PXkbComponentNamePtr


type
  PXkbDeviceLedInfoPtr* = ptr TXkbDeviceLedInfoRec
  TXkbDeviceLedInfoRec*{.final.} = object
    led_class*: int16
    led_id*: int16
    phys_indicators*: int16
    maps_present*: int16
    names_present*: int16
    state*: int16
    names*: array[0..XkbNumIndicators - 1, TAtom]
    maps*: array[0..XkbNumIndicators - 1, TXkbIndicatorMapRec]


type
  PXkbDeviceInfoPtr* = ptr TXkbDeviceInfoRec
  TXkbDeviceInfoRec*{.final.} = object
    name*: cstring
    theType*: TAtom
    device_spec*: int16
    has_own_state*: bool
    supported*: int16
    unsupported*: int16
    num_btns*: int16
    btn_acts*: PXkbAction
    sz_leds*: int16
    num_leds*: int16
    dflt_kbd_fb*: int16
    dflt_led_fb*: int16
    leds*: PXkbDeviceLedInfoPtr


proc XkbXI_DevHasBtnActs*(d: PXkbDeviceInfoPtr): bool
proc XkbXI_LegalDevBtn*(d: PXkbDeviceInfoPtr, b: int16): bool
proc XkbXI_DevHasLeds*(d: PXkbDeviceInfoPtr): bool
type
  PXkbDeviceLedChangesPtr* = ptr TXkbDeviceLedChangesRec
  TXkbDeviceLedChangesRec*{.final.} = object
    led_class*: int16
    led_id*: int16
    defined*: int16           #names or maps changed
    next*: PXkbDeviceLedChangesPtr


type
  PXkbDeviceChangesPtr* = ptr TXkbDeviceChangesRec
  TXkbDeviceChangesRec*{.final.} = object
    changed*: int16
    first_btn*: int16
    num_btns*: int16
    leds*: TXkbDeviceLedChangesRec


proc XkbShapeDoodadColor*(g: PXkbGeometryPtr, d: PXkbShapeDoodadPtr): PXkbColorPtr
proc XkbShapeDoodadShape*(g: PXkbGeometryPtr, d: PXkbShapeDoodadPtr): PXkbShapePtr
proc XkbSetShapeDoodadColor*(g: PXkbGeometryPtr, d: PXkbShapeDoodadPtr,
                             c: PXkbColorPtr)
proc XkbSetShapeDoodadShape*(g: PXkbGeometryPtr, d: PXkbShapeDoodadPtr,
                             s: PXkbShapePtr)
proc XkbTextDoodadColor*(g: PXkbGeometryPtr, d: PXkbTextDoodadPtr): PXkbColorPtr
proc XkbSetTextDoodadColor*(g: PXkbGeometryPtr, d: PXkbTextDoodadPtr,
                            c: PXkbColorPtr)
proc XkbIndicatorDoodadShape*(g: PXkbGeometryPtr, d: PXkbIndicatorDoodadPtr): PXkbShapeDoodadPtr
proc XkbIndicatorDoodadOnColor*(g: PXkbGeometryPtr, d: PXkbIndicatorDoodadPtr): PXkbColorPtr
proc XkbIndicatorDoodadOffColor*(g: PXkbGeometryPtr, d: PXkbIndicatorDoodadPtr): PXkbColorPtr
proc XkbSetIndicatorDoodadOnColor*(g: PXkbGeometryPtr,
                                   d: PXkbIndicatorDoodadPtr, c: PXkbColorPtr)
proc XkbSetIndicatorDoodadOffColor*(g: PXkbGeometryPtr,
                                    d: PXkbIndicatorDoodadPtr, c: PXkbColorPtr)
proc XkbSetIndicatorDoodadShape*(g: PXkbGeometryPtr, d: PXkbIndicatorDoodadPtr,
                                 s: PXkbShapeDoodadPtr)
proc XkbLogoDoodadColor*(g: PXkbGeometryPtr, d: PXkbLogoDoodadPtr): PXkbColorPtr
proc XkbLogoDoodadShape*(g: PXkbGeometryPtr, d: PXkbLogoDoodadPtr): PXkbShapeDoodadPtr
proc XkbSetLogoDoodadColor*(g: PXkbGeometryPtr, d: PXkbLogoDoodadPtr,
                            c: PXkbColorPtr)
proc XkbSetLogoDoodadShape*(g: PXkbGeometryPtr, d: PXkbLogoDoodadPtr,
                            s: PXkbShapeDoodadPtr)
proc XkbKeyShape*(g: PXkbGeometryPtr, k: PXkbKeyPtr): PXkbShapeDoodadPtr
proc XkbKeyColor*(g: PXkbGeometryPtr, k: PXkbKeyPtr): PXkbColorPtr
proc XkbSetKeyShape*(g: PXkbGeometryPtr, k: PXkbKeyPtr, s: PXkbShapeDoodadPtr)
proc XkbSetKeyColor*(g: PXkbGeometryPtr, k: PXkbKeyPtr, c: PXkbColorPtr)
proc XkbGeomColorIndex*(g: PXkbGeometryPtr, c: PXkbColorPtr): int32
proc XkbAddGeomProperty*(geom: PXkbGeometryPtr, name: cstring, value: cstring): PXkbPropertyPtr{.
    libx11c, importc: "XkbAddGeomProperty".}
proc XkbAddGeomKeyAlias*(geom: PXkbGeometryPtr, alias: cstring, float: cstring): PXkbKeyAliasPtr{.
    libx11c, importc: "XkbAddGeomKeyAlias".}
proc XkbAddGeomColor*(geom: PXkbGeometryPtr, spec: cstring, pixel: int16): PXkbColorPtr{.
    libx11c, importc: "XkbAddGeomColor".}
proc XkbAddGeomOutline*(shape: PXkbShapePtr, sz_points: int16): PXkbOutlinePtr{.
    libx11c, importc: "XkbAddGeomOutline".}
proc XkbAddGeomShape*(geom: PXkbGeometryPtr, name: TAtom, sz_outlines: int16): PXkbShapePtr{.
    libx11c, importc: "XkbAddGeomShape".}
proc XkbAddGeomKey*(row: PXkbRowPtr): PXkbKeyPtr{.libx11c,
    importc: "XkbAddGeomKey".}
proc XkbAddGeomRow*(section: PXkbSectionPtr, sz_keys: int16): PXkbRowPtr{.libx11c, importc: "XkbAddGeomRow".}
proc XkbAddGeomSection*(geom: PXkbGeometryPtr, name: TAtom, sz_rows: int16,
                        sz_doodads: int16, sz_overlays: int16): PXkbSectionPtr{.
    libx11c, importc: "XkbAddGeomSection".}
proc XkbAddGeomOverlay*(section: PXkbSectionPtr, name: TAtom, sz_rows: int16): PXkbOverlayPtr{.
    libx11c, importc: "XkbAddGeomOverlay".}
proc XkbAddGeomOverlayRow*(overlay: PXkbOverlayPtr, row_under: int16,
                           sz_keys: int16): PXkbOverlayRowPtr{.libx11c, importc: "XkbAddGeomOverlayRow".}
proc XkbAddGeomOverlayKey*(overlay: PXkbOverlayPtr, row: PXkbOverlayRowPtr,
                           over: cstring, under: cstring): PXkbOverlayKeyPtr{.
    libx11c, importc: "XkbAddGeomOverlayKey".}
proc XkbAddGeomDoodad*(geom: PXkbGeometryPtr, section: PXkbSectionPtr,
                       name: TAtom): PXkbDoodadPtr{.libx11c,
    importc: "XkbAddGeomDoodad".}
proc XkbFreeGeomKeyAliases*(geom: PXkbGeometryPtr, first: int16, count: int16,
                            freeAll: bool){.libx11c,
    importc: "XkbFreeGeomKeyAliases".}
proc XkbFreeGeomColors*(geom: PXkbGeometryPtr, first: int16, count: int16,
                        freeAll: bool){.libx11c,
                                        importc: "XkbFreeGeomColors".}
proc XkbFreeGeomDoodads*(doodads: PXkbDoodadPtr, nDoodads: int16, freeAll: bool){.
    libx11c, importc: "XkbFreeGeomDoodads".}
proc XkbFreeGeomProperties*(geom: PXkbGeometryPtr, first: int16, count: int16,
                            freeAll: bool){.libx11c,
    importc: "XkbFreeGeomProperties".}
proc XkbFreeGeomOverlayKeys*(row: PXkbOverlayRowPtr, first: int16, count: int16,
                             freeAll: bool){.libx11c,
    importc: "XkbFreeGeomOverlayKeys".}
proc XkbFreeGeomOverlayRows*(overlay: PXkbOverlayPtr, first: int16,
                             count: int16, freeAll: bool){.libx11c, importc: "XkbFreeGeomOverlayRows".}
proc XkbFreeGeomOverlays*(section: PXkbSectionPtr, first: int16, count: int16,
                          freeAll: bool){.libx11c,
    importc: "XkbFreeGeomOverlays".}
proc XkbFreeGeomKeys*(row: PXkbRowPtr, first: int16, count: int16, freeAll: bool){.
    libx11c, importc: "XkbFreeGeomKeys".}
proc XkbFreeGeomRows*(section: PXkbSectionPtr, first: int16, count: int16,
                      freeAll: bool){.libx11c,
                                      importc: "XkbFreeGeomRows".}
proc XkbFreeGeomSections*(geom: PXkbGeometryPtr, first: int16, count: int16,
                          freeAll: bool){.libx11c,
    importc: "XkbFreeGeomSections".}
proc XkbFreeGeomPoints*(outline: PXkbOutlinePtr, first: int16, count: int16,
                        freeAll: bool){.libx11c,
                                        importc: "XkbFreeGeomPoints".}
proc XkbFreeGeomOutlines*(shape: PXkbShapePtr, first: int16, count: int16,
                          freeAll: bool){.libx11c,
    importc: "XkbFreeGeomOutlines".}
proc XkbFreeGeomShapes*(geom: PXkbGeometryPtr, first: int16, count: int16,
                        freeAll: bool){.libx11c,
                                        importc: "XkbFreeGeomShapes".}
proc XkbFreeGeometry*(geom: PXkbGeometryPtr, which: int16, freeMap: bool){.
    libx11c, importc: "XkbFreeGeometry".}
proc XkbAllocGeomProps*(geom: PXkbGeometryPtr, nProps: int16): TStatus{.libx11c, importc: "XkbAllocGeomProps".}
proc XkbAllocGeomKeyAliases*(geom: PXkbGeometryPtr, nAliases: int16): TStatus{.
    libx11c, importc: "XkbAllocGeomKeyAliases".}
proc XkbAllocGeomColors*(geom: PXkbGeometryPtr, nColors: int16): TStatus{.libx11c, importc: "XkbAllocGeomColors".}
proc XkbAllocGeomShapes*(geom: PXkbGeometryPtr, nShapes: int16): TStatus{.libx11c, importc: "XkbAllocGeomShapes".}
proc XkbAllocGeomSections*(geom: PXkbGeometryPtr, nSections: int16): TStatus{.
    libx11c, importc: "XkbAllocGeomSections".}
proc XkbAllocGeomOverlays*(section: PXkbSectionPtr, num_needed: int16): TStatus{.
    libx11c, importc: "XkbAllocGeomOverlays".}
proc XkbAllocGeomOverlayRows*(overlay: PXkbOverlayPtr, num_needed: int16): TStatus{.
    libx11c, importc: "XkbAllocGeomOverlayRows".}
proc XkbAllocGeomOverlayKeys*(row: PXkbOverlayRowPtr, num_needed: int16): TStatus{.
    libx11c, importc: "XkbAllocGeomOverlayKeys".}
proc XkbAllocGeomDoodads*(geom: PXkbGeometryPtr, nDoodads: int16): TStatus{.
    libx11c, importc: "XkbAllocGeomDoodads".}
proc XkbAllocGeomSectionDoodads*(section: PXkbSectionPtr, nDoodads: int16): TStatus{.
    libx11c, importc: "XkbAllocGeomSectionDoodads".}
proc XkbAllocGeomOutlines*(shape: PXkbShapePtr, nOL: int16): TStatus{.libx11c, importc: "XkbAllocGeomOutlines".}
proc XkbAllocGeomRows*(section: PXkbSectionPtr, nRows: int16): TStatus{.libx11c, importc: "XkbAllocGeomRows".}
proc XkbAllocGeomPoints*(ol: PXkbOutlinePtr, nPts: int16): TStatus{.libx11c, importc: "XkbAllocGeomPoints".}
proc XkbAllocGeomKeys*(row: PXkbRowPtr, nKeys: int16): TStatus{.libx11c, importc: "XkbAllocGeomKeys".}
proc XkbAllocGeometry*(xkb: PXkbDescPtr, sizes: PXkbGeometrySizesPtr): TStatus{.
    libx11c, importc: "XkbAllocGeometry".}
proc XkbSetGeometryProc*(dpy: PDisplay, deviceSpec: int16, geom: PXkbGeometryPtr): TStatus{.
    libx11c, importc: "XkbSetGeometry".}
proc XkbComputeShapeTop*(shape: PXkbShapePtr, bounds: PXkbBoundsPtr): bool{.
    libx11c, importc: "XkbComputeShapeTop".}
proc XkbComputeShapeBounds*(shape: PXkbShapePtr): bool{.libx11c,
    importc: "XkbComputeShapeBounds".}
proc XkbComputeRowBounds*(geom: PXkbGeometryPtr, section: PXkbSectionPtr,
                          row: PXkbRowPtr): bool{.libx11c,
    importc: "XkbComputeRowBounds".}
proc XkbComputeSectionBounds*(geom: PXkbGeometryPtr, section: PXkbSectionPtr): bool{.
    libx11c, importc: "XkbComputeSectionBounds".}
proc XkbFindOverlayForKey*(geom: PXkbGeometryPtr, wanted: PXkbSectionPtr,
                           under: cstring): cstring{.libx11c,
    importc: "XkbFindOverlayForKey".}
proc XkbGetGeometryProc*(dpy: PDisplay, xkb: PXkbDescPtr): TStatus{.libx11c, importc: "XkbGetGeometry".}
proc XkbGetNamedGeometry*(dpy: PDisplay, xkb: PXkbDescPtr, name: TAtom): TStatus{.
    libx11c, importc: "XkbGetNamedGeometry".}
when defined(XKB_IN_SERVER):
  proc SrvXkbAddGeomKeyAlias*(geom: PXkbGeometryPtr, alias: cstring,
                              float: cstring): PXkbKeyAliasPtr{.libx11c, importc: "XkbAddGeomKeyAlias".}
  proc SrvXkbAddGeomColor*(geom: PXkbGeometryPtr, spec: cstring, pixel: int16): PXkbColorPtr{.
      libx11c, importc: "XkbAddGeomColor".}
  proc SrvXkbAddGeomDoodad*(geom: PXkbGeometryPtr, section: PXkbSectionPtr,
                            name: TAtom): PXkbDoodadPtr{.libx11c,
      importc: "XkbAddGeomDoodad".}
  proc SrvXkbAddGeomKey*(geom: PXkbGeometryPtr, alias: cstring, float: cstring): PXkbKeyAliasPtr{.
      libx11c, importc: "XkbAddGeomKeyAlias".}
  proc SrvXkbAddGeomOutline*(shape: PXkbShapePtr, sz_points: int16): PXkbOutlinePtr{.
      libx11c, importc: "XkbAddGeomOutline".}
  proc SrvXkbAddGeomOverlay*(overlay: PXkbOverlayPtr, row: PXkbOverlayRowPtr,
                             over: cstring, under: cstring): PXkbOverlayKeyPtr{.
      libx11c, importc: "XkbAddGeomOverlayKey".}
  proc SrvXkbAddGeomOverlayRow*(overlay: PXkbOverlayPtr, row_under: int16,
                                sz_keys: int16): PXkbOverlayRowPtr{.libx11c, importc: "XkbAddGeomOverlayRow".}
  proc SrvXkbAddGeomOverlayKey*(overlay: PXkbOverlayPtr, row: PXkbOverlayRowPtr,
                                over: cstring, under: cstring): PXkbOverlayKeyPtr{.
      libx11c, importc: "XkbAddGeomOverlayKey".}
  proc SrvXkbAddGeomProperty*(geom: PXkbGeometryPtr, name: cstring,
                              value: cstring): PXkbPropertyPtr{.libx11c, importc: "XkbAddGeomProperty".}
  proc SrvXkbAddGeomRow*(section: PXkbSectionPtr, sz_keys: int16): PXkbRowPtr{.
      libx11c, importc: "XkbAddGeomRow".}
  proc SrvXkbAddGeomSection*(geom: PXkbGeometryPtr, name: TAtom, sz_rows: int16,
                             sz_doodads: int16, sz_overlays: int16): PXkbSectionPtr{.
      libx11c, importc: "XkbAddGeomSection".}
  proc SrvXkbAddGeomShape*(geom: PXkbGeometryPtr, name: TAtom,
                           sz_outlines: int16): PXkbShapePtr{.libx11c, importc: "XkbAddGeomShape".}
  proc SrvXkbAllocGeomKeyAliases*(geom: PXkbGeometryPtr, nAliases: int16): TStatus{.
      libx11c, importc: "XkbAllocGeomKeyAliases".}
  proc SrvXkbAllocGeomColors*(geom: PXkbGeometryPtr, nColors: int16): TStatus{.
      libx11c, importc: "XkbAllocGeomColors".}
  proc SrvXkbAllocGeomDoodads*(geom: PXkbGeometryPtr, nDoodads: int16): TStatus{.
      libx11c, importc: "XkbAllocGeomDoodads".}
  proc SrvXkbAllocGeomKeys*(row: PXkbRowPtr, nKeys: int16): TStatus{.libx11c, importc: "XkbAllocGeomKeys".}
  proc SrvXkbAllocGeomOutlines*(shape: PXkbShapePtr, nOL: int16): TStatus{.
      libx11c, importc: "XkbAllocGeomOutlines".}
  proc SrvXkbAllocGeomPoints*(ol: PXkbOutlinePtr, nPts: int16): TStatus{.libx11c, importc: "XkbAllocGeomPoints".}
  proc SrvXkbAllocGeomProps*(geom: PXkbGeometryPtr, nProps: int16): TStatus{.
      libx11c, importc: "XkbAllocGeomProps".}
  proc SrvXkbAllocGeomRows*(section: PXkbSectionPtr, nRows: int16): TStatus{.
      libx11c, importc: "XkbAllocGeomRows".}
  proc SrvXkbAllocGeomSectionDoodads*(section: PXkbSectionPtr, nDoodads: int16): TStatus{.
      libx11c, importc: "XkbAllocGeomSectionDoodads".}
  proc SrvXkbAllocGeomSections*(geom: PXkbGeometryPtr, nSections: int16): TStatus{.
      libx11c, importc: "XkbAllocGeomSections".}
  proc SrvXkbAllocGeomOverlays*(section: PXkbSectionPtr, num_needed: int16): TStatus{.
      libx11c, importc: "XkbAllocGeomOverlays".}
  proc SrvXkbAllocGeomOverlayRows*(overlay: PXkbOverlayPtr, num_needed: int16): TStatus{.
      libx11c, importc: "XkbAllocGeomOverlayRows".}
  proc SrvXkbAllocGeomOverlayKeys*(row: PXkbOverlayRowPtr, num_needed: int16): TStatus{.
      libx11c, importc: "XkbAllocGeomOverlayKeys".}
  proc SrvXkbAllocGeomShapes*(geom: PXkbGeometryPtr, nShapes: int16): TStatus{.
      libx11c, importc: "XkbAllocGeomShapes".}
  proc SrvXkbAllocGeometry*(xkb: PXkbDescPtr, sizes: PXkbGeometrySizesPtr): TStatus{.
      libx11c, importc: "XkbAllocGeometry".}
  proc SrvXkbFreeGeomKeyAliases*(geom: PXkbGeometryPtr, first: int16,
                                 count: int16, freeAll: bool){.libx11c, importc: "XkbFreeGeomKeyAliases".}
  proc SrvXkbFreeGeomColors*(geom: PXkbGeometryPtr, first: int16, count: int16,
                             freeAll: bool){.libx11c,
      importc: "XkbFreeGeomColors".}
  proc SrvXkbFreeGeomDoodads*(doodads: PXkbDoodadPtr, nDoodads: int16,
                              freeAll: bool){.libx11c,
      importc: "XkbFreeGeomDoodads".}
  proc SrvXkbFreeGeomProperties*(geom: PXkbGeometryPtr, first: int16,
                                 count: int16, freeAll: bool){.libx11c, importc: "XkbFreeGeomProperties".}
  proc SrvXkbFreeGeomOverlayKeys*(row: PXkbOverlayRowPtr, first: int16,
                                  count: int16, freeAll: bool){.libx11c, importc: "XkbFreeGeomOverlayKeys".}
  proc SrvXkbFreeGeomOverlayRows*(overlay: PXkbOverlayPtr, first: int16,
                                  count: int16, freeAll: bool){.libx11c, importc: "XkbFreeGeomOverlayRows".}
  proc SrvXkbFreeGeomOverlays*(section: PXkbSectionPtr, first: int16,
                               count: int16, freeAll: bool){.libx11c, importc: "XkbFreeGeomOverlays".}
  proc SrvXkbFreeGeomKeys*(row: PXkbRowPtr, first: int16, count: int16,
                           freeAll: bool){.libx11c,
      importc: "XkbFreeGeomKeys".}
  proc SrvXkbFreeGeomRows*(section: PXkbSectionPtr, first: int16, count: int16,
                           freeAll: bool){.libx11c,
      importc: "XkbFreeGeomRows".}
  proc SrvXkbFreeGeomSections*(geom: PXkbGeometryPtr, first: int16,
                               count: int16, freeAll: bool){.libx11c, importc: "XkbFreeGeomSections".}
  proc SrvXkbFreeGeomPoints*(outline: PXkbOutlinePtr, first: int16,
                             count: int16, freeAll: bool){.libx11c, importc: "XkbFreeGeomPoints".}
  proc SrvXkbFreeGeomOutlines*(shape: PXkbShapePtr, first: int16, count: int16,
                               freeAll: bool){.libx11c,
      importc: "XkbFreeGeomOutlines".}
  proc SrvXkbFreeGeomShapes*(geom: PXkbGeometryPtr, first: int16, count: int16,
                             freeAll: bool){.libx11c,
      importc: "XkbFreeGeomShapes".}
  proc SrvXkbFreeGeometry*(geom: PXkbGeometryPtr, which: int16, freeMap: bool){.
      libx11c, importc: "XkbFreeGeometry".}
# implementation

import                        #************************************ xkb ************************************
  xi

proc XkbLegalXILedClass(c: int): bool =
  ##define XkbLegalXILedClass(c) (((c)==KbdFeedbackClass)||((c)==LedFeedbackClass)||
  #                                ((c)==XkbDfltXIClass)||((c)==XkbAllXIClasses))
  result = (c == KbdFeedbackClass) or (c == LedFeedbackClass) or
      (c == XkbDfltXIClass) or (c == XkbAllXIClasses)

proc XkbLegalXIBellClass(c: int): bool =
  ##define XkbLegalXIBellClass(c) (((c)==KbdFeedbackClass)||((c)==BellFeedbackClass)||
  #                                 ((c)==XkbDfltXIClass)||((c)==XkbAllXIClasses))
  result = (c == KbdFeedbackClass) or (c == BellFeedbackClass) or
      (c == XkbDfltXIClass) or (c == XkbAllXIClasses)

proc XkbExplicitXIDevice(c: int): bool =
  ##define XkbExplicitXIDevice(c) (((c)&(~0xff))==0)
  result = (c and (not 0x000000FF)) == 0

proc XkbExplicitXIClass(c: int): bool =
  ##define XkbExplicitXIClass(c) (((c)&(~0xff))==0)
  result = (c and (not 0x000000FF)) == 0

proc XkbExplicitXIId(c: int): bool =
  ##define XkbExplicitXIId(c) (((c)&(~0xff))==0)
  result = (c and (not 0x000000FF)) == 0

proc XkbSingleXIClass(c: int): bool =
  ##define XkbSingleXIClass(c) ((((c)&(~0xff))==0)||((c)==XkbDfltXIClass))
  result = ((c and (not 0x000000FF)) == 0) or (c == XkbDfltXIClass)

proc XkbSingleXIId(c: int): bool =
  ##define XkbSingleXIId(c) ((((c)&(~0xff))==0)||((c)==XkbDfltXIId))
  result = ((c and (not 0x000000FF)) == 0) or (c == XkbDfltXIId)

proc XkbBuildCoreState(m, g: int): int =
  ##define XkbBuildCoreState(m,g) ((((g)&0x3)<<13)|((m)&0xff))
  result = ((g and 0x00000003) shl 13) or (m and 0x000000FF)

proc XkbGroupForCoreState(s: int): int =
  ##define XkbGroupForCoreState(s) (((s)>>13)&0x3)
  result = (s shr 13) and 0x00000003

proc XkbIsLegalGroup(g: int): bool =
  ##define XkbIsLegalGroup(g) (((g)>=0)&&((g)<XkbNumKbdGroups))
  result = (g >= 0) and (g < XkbNumKbdGroups)

proc XkbSA_ValOp(a: int): int =
  ##define XkbSA_ValOp(a) ((a)&XkbSA_ValOpMask)
  result = a and XkbSA_ValOpMask

proc XkbSA_ValScale(a: int): int =
  ##define XkbSA_ValScale(a) ((a)&XkbSA_ValScaleMask)
  result = a and XkbSA_ValScaleMask

proc XkbIsModAction(a: PXkbAnyAction): bool =
  ##define XkbIsModAction(a) (((a)->type>=Xkb_SASetMods)&&((a)->type<=XkbSA_LockMods))
  result = (ze(a.theType) >= XkbSA_SetMods) and (ze(a.theType) <= XkbSA_LockMods)

proc XkbIsGroupAction(a: PXkbAnyAction): bool =
  ##define XkbIsGroupAction(a) (((a)->type>=XkbSA_SetGroup)&&((a)->type<=XkbSA_LockGroup))
  result = (ze(a.theType) >= XkbSA_SetGroup) or (ze(a.theType) <= XkbSA_LockGroup)

proc XkbIsPtrAction(a: PXkbAnyAction): bool =
  ##define XkbIsPtrAction(a) (((a)->type>=XkbSA_MovePtr)&&((a)->type<=XkbSA_SetPtrDflt))
  result = (ze(a.theType) >= XkbSA_MovePtr) and
      (ze(a.theType) <= XkbSA_SetPtrDflt)

proc XkbIsLegalKeycode(k: int): bool =
  ##define        XkbIsLegalKeycode(k)    (((k)>=XkbMinLegalKeyCode)&&((k)<=XkbMaxLegalKeyCode))
  result = (k >= XkbMinLegalKeyCode) and (k <= XkbMaxLegalKeyCode)

proc XkbShiftLevel(n: int8): int8 =
  ##define XkbShiftLevel(n) ((n)-1)
  result = n - 1'i8

proc XkbShiftLevelMask(n: int8): int8 =
  ##define XkbShiftLevelMask(n) (1<<((n)-1))
  result = 1'i8 shl (n - 1'i8)

proc XkbcharToInt(v: int8): int16 =
  ##define XkbcharToInt(v) ((v)&0x80?(int)((v)|(~0xff)):(int)((v)&0x7f))
  if ((v and 0x80'i8) != 0'i8): result = v or (not 0xFF'i16)
  else: result = int16(v and 0x7F'i8)

proc XkbIntTo2chars(i: int16, h, L: var int8) =
  ##define XkbIntTo2chars(i,h,l) (((h)=((i>>8)&0xff)),((l)=((i)&0xff)))
  h = toU8((i shr 8'i16) and 0x00FF'i16)
  L = toU8(i and 0xFF'i16)

proc Xkb2charsToInt(h, L: int8): int16 =
  when defined(cpu64):
    ##define Xkb2charsToInt(h,l) ((h)&0x80?(int)(((h)<<8)|(l)|(~0xffff)): (int)(((h)<<8)|(l)&0x7fff))
    if (h and 0x80'i8) != 0'i8:
      result = toU16((ze(h) shl 8) or ze(L) or not 0x0000FFFF)
    else:
      result = toU16((ze(h) shl 8) or ze(L) and 0x00007FFF)
  else:
    ##define Xkb2charsToInt(h,l) ((short)(((h)<<8)|(l)))
    result = toU16(ze(h) shl 8 or ze(L))

proc XkbModLocks(s: PXkbStatePtr): int8 =
  ##define XkbModLocks(s) ((s)->locked_mods)
  result = s.locked_mods

proc XkbStateMods(s: PXkbStatePtr): int16 =
  ##define XkbStateMods(s) ((s)->base_mods|(s)->latched_mods|XkbModLocks(s))
  result = s.base_mods or s.latched_mods or XkbModLocks(s)

proc XkbGroupLock(s: PXkbStatePtr): int8 =
  ##define XkbGroupLock(s) ((s)->locked_group)
  result = s.locked_group

proc XkbStateGroup(s: PXkbStatePtr): int16 =
  ##define XkbStateGroup(s) ((s)->base_group+(s)->latched_group+XkbGroupLock(s))
  result = s.base_group + (s.latched_group) + XkbGroupLock(s)

proc XkbStateFieldFromRec(s: PXkbStatePtr): int =
  ##define XkbStateFieldFromRec(s) XkbBuildCoreState((s)->lookup_mods,(s)->group)
  result = XkbBuildCoreState(s.lookup_mods, s.group)

proc XkbGrabStateFromRec(s: PXkbStatePtr): int =
  ##define XkbGrabStateFromRec(s) XkbBuildCoreState((s)->grab_mods,(s)->group)
  result = XkbBuildCoreState(s.grab_mods, s.group)

proc XkbNumGroups(g: int16): int16 =
  ##define XkbNumGroups(g) ((g)&0x0f)
  result = g and 0x0000000F'i16

proc XkbOutOfRangeGroupInfo(g: int16): int16 =
  ##define XkbOutOfRangeGroupInfo(g) ((g)&0xf0)
  result = g and 0x000000F0'i16

proc XkbOutOfRangeGroupAction(g: int16): int16 =
  ##define XkbOutOfRangeGroupAction(g) ((g)&0xc0)
  result = g and 0x000000C0'i16

proc XkbOutOfRangeGroupNumber(g: int16): int16 =
  ##define XkbOutOfRangeGroupNumber(g) (((g)&0x30)>>4)
  result = (g and 0x00000030'i16) shr 4'i16

proc XkbSetGroupInfo(g, w, n: int16): int16 =
  ##define XkbSetGroupInfo(g,w,n) (((w)&0xc0)|(((n)&3)<<4)|((g)&0x0f))
  result = (w and 0x000000C0'i16) or
    ((n and 3'i16) shl 4'i16) or (g and 0x0000000F'i16)

proc XkbSetNumGroups(g, n: int16): int16 =
  ##define XkbSetNumGroups(g,n) (((g)&0xf0)|((n)&0x0f))
  result = (g and 0x000000F0'i16) or (n and 0x0000000F'i16)

proc XkbModActionVMods(a: PXkbModAction): int16 =
  ##define XkbModActionVMods(a) ((short)(((a)->vmods1<<8)|((a)->vmods2)))
  result = toU16((ze(a.vmods1) shl 8) or ze(a.vmods2))

proc XkbSetModActionVMods(a: PXkbModAction, v: int8) =
  ##define XkbSetModActionVMods(a,v) (((a)->vmods1=(((v)>>8)&0xff)),(a)->vmods2=((v)&0xff))
  a.vmods1 = toU8((ze(v) shr 8) and 0x000000FF)
  a.vmods2 = toU8(ze(v) and 0x000000FF)

proc XkbSAGroup(a: PXkbGroupAction): int8 =
  ##define XkbSAGroup(a) (XkbcharToInt((a)->group_XXX))
  result = int8(XkbcharToInt(a.group_XXX))

proc XkbSASetGroupProc(a: PXkbGroupAction, g: int8) =
  ##define XkbSASetGroup(a,g) ((a)->group_XXX=(g))
  a.group_XXX = g

proc XkbPtrActionX(a: PXkbPtrAction): int16 =
  ##define XkbPtrActionX(a) (Xkb2charsToInt((a)->high_XXX,(a)->low_XXX))
  result = int16(Xkb2charsToInt(a.high_XXX, a.low_XXX))

proc XkbPtrActionY(a: PXkbPtrAction): int16 =
  ##define XkbPtrActionY(a) (Xkb2charsToInt((a)->high_YYY,(a)->low_YYY))
  result = int16(Xkb2charsToInt(a.high_YYY, a.low_YYY))

proc XkbSetPtrActionX(a: PXkbPtrAction, x: int8) =
  ##define XkbSetPtrActionX(a,x) (XkbIntTo2chars(x,(a)->high_XXX,(a)->low_XXX))
  XkbIntTo2chars(x, a.high_XXX, a.low_XXX)

proc XkbSetPtrActionY(a: PXkbPtrAction, y: int8) =
  ##define XkbSetPtrActionY(a,y) (XkbIntTo2chars(y,(a)->high_YYY,(a)->low_YYY))
  XkbIntTo2chars(y, a.high_YYY, a.low_YYY)

proc XkbSAPtrDfltValue(a: PXkbPtrDfltAction): int8 =
  ##define XkbSAPtrDfltValue(a) (XkbcharToInt((a)->valueXXX))
  result = int8(XkbcharToInt(a.valueXXX))

proc XkbSASetPtrDfltValue(a: PXkbPtrDfltAction, c: pointer) =
  ##define XkbSASetPtrDfltValue(a,c) ((a)->valueXXX= ((c)&0xff))
  a.valueXXX = toU8(cast[int](c))

proc XkbSAScreen(a: PXkbSwitchScreenAction): int8 =
  ##define XkbSAScreen(a) (XkbcharToInt((a)->screenXXX))
  result = toU8(XkbcharToInt(a.screenXXX))

proc XkbSASetScreen(a: PXkbSwitchScreenAction, s: pointer) =
  ##define XkbSASetScreen(a,s) ((a)->screenXXX= ((s)&0xff))
  a.screenXXX = toU8(cast[int](s))

proc XkbActionSetCtrls(a: PXkbCtrlsAction, c: int8) =
  ##define XkbActionSetCtrls(a,c) (((a)->ctrls3=(((c)>>24)&0xff)),((a)->ctrls2=(((c)>>16)&0xff)),
  #                                 ((a)->ctrls1=(((c)>>8)&0xff)),((a)->ctrls0=((c)&0xff)))
  a.ctrls3 = toU8((ze(c) shr 24) and 0x000000FF)
  a.ctrls2 = toU8((ze(c) shr 16) and 0x000000FF)
  a.ctrls1 = toU8((ze(c) shr 8) and 0x000000FF)
  a.ctrls0 = toU8(ze(c) and 0x000000FF)

proc XkbActionCtrls(a: PXkbCtrlsAction): int16 =
  ##define XkbActionCtrls(a) ((((unsigned int)(a)->ctrls3)<<24)|(((unsigned int)(a)->ctrls2)<<16)|
  #                            (((unsigned int)(a)->ctrls1)<<8)|((unsigned int)((a)->ctrls0)))
  result = toU16((ze(a.ctrls3) shl 24) or (ze(a.ctrls2) shl 16) or
     (ze(a.ctrls1) shl 8) or ze(a.ctrls0))

proc XkbSARedirectVMods(a: PXkbRedirectKeyAction): int16 =
  ##define XkbSARedirectVMods(a) ((((unsigned int)(a)->vmods1)<<8)|((unsigned int)(a)->vmods0))
  result = toU16((ze(a.vmods1) shl 8) or ze(a.vmods0))

proc XkbSARedirectSetVMods(a: PXkbRedirectKeyAction, m: int8) =
  ##define XkbSARedirectSetVMods(a,m) (((a)->vmods_mask1=(((m)>>8)&0xff)),((a)->vmods_mask0=((m)&0xff)))
  a.vmods_mask1 = toU8((ze(m) shr 8) and 0x000000FF)
  a.vmods_mask0 = toU8(ze(m) or 0x000000FF)

proc XkbSARedirectVModsMask(a: PXkbRedirectKeyAction): int16 =
  ##define XkbSARedirectVModsMask(a) ((((unsigned int)(a)->vmods_mask1)<<8)|
  #                                     ((unsigned int)(a)->vmods_mask0))
  result = toU16((ze(a.vmods_mask1) shl 8) or ze(a.vmods_mask0))

proc XkbSARedirectSetVModsMask(a: PXkbRedirectKeyAction, m: int8) =
  ##define XkbSARedirectSetVModsMask(a,m) (((a)->vmods_mask1=(((m)>>8)&0xff)),((a)->vmods_mask0=((m)&0xff)))
  a.vmods_mask1 = toU8(ze(m) shr 8 and 0x000000FF)
  a.vmods_mask0 = toU8(ze(m) and 0x000000FF)

proc XkbAX_AnyFeedback(c: PXkbControlsPtr): int16 =
  ##define XkbAX_AnyFeedback(c) ((c)->enabled_ctrls&XkbAccessXFeedbackMask)
  result = toU16(ze(c.enabled_ctrls) and XkbAccessXFeedbackMask)

proc XkbAX_NeedOption(c: PXkbControlsPtr, w: int16): int16 =
  ##define XkbAX_NeedOption(c,w) ((c)->ax_options&(w))
  result = toU16(ze(c.ax_options) and ze(w))

proc XkbAX_NeedFeedback(c: PXkbControlsPtr, w: int16): bool =
  ##define XkbAX_NeedFeedback(c,w) (XkbAX_AnyFeedback(c)&&XkbAX_NeedOption(c,w))
  result = (XkbAX_AnyFeedback(c) > 0'i16) and (XkbAX_NeedOption(c, w) > 0'i16)

proc XkbSMKeyActionsPtr(m: PXkbServerMapPtr, k: int16): PXkbAction =
  ##define XkbSMKeyActionsPtr(m,k) (&(m)->acts[(m)->key_acts[k]])
  result = addr(m.acts[ze(m.key_acts[ze(k)])])

proc XkbCMKeyGroupInfo(m: PXkbClientMapPtr, k: int16): int8 =
  ##define XkbCMKeyGroupInfo(m,k) ((m)->key_sym_map[k].group_info)
  result = m.key_sym_map[ze(k)].group_info

proc XkbCMKeyNumGroups(m: PXkbClientMapPtr, k: int16): int8 =
  ##define XkbCMKeyNumGroups(m,k) (XkbNumGroups((m)->key_sym_map[k].group_info))
  result = toU8(XkbNumGroups(m.key_sym_map[ze(k)].group_info))

proc XkbCMKeyGroupWidth(m: PXkbClientMapPtr, k: int16, g: int8): int8 =
  ##define XkbCMKeyGroupWidth(m,k,g) (XkbCMKeyType(m,k,g)->num_levels)
  result = XkbCMKeyType(m, k, g).num_levels

proc XkbCMKeyGroupsWidth(m: PXkbClientMapPtr, k: int16): int8 =
  ##define XkbCMKeyGroupsWidth(m,k) ((m)->key_sym_map[k].width)
  result = m.key_sym_map[ze(k)].width

proc XkbCMKeyTypeIndex(m: PXkbClientMapPtr, k: int16, g: int8): int8 =
  ##define XkbCMKeyTypeIndex(m,k,g) ((m)->key_sym_map[k].kt_index[g&0x3])
  result = m.key_sym_map[ze(k)].kt_index[ze(g) and 0x00000003]

proc XkbCMKeyType(m: PXkbClientMapPtr, k: int16, g: int8): PXkbKeyTypePtr =
  ##define XkbCMKeyType(m,k,g) (&(m)->types[XkbCMKeyTypeIndex(m,k,g)])
  result = addr(m.types[ze(XkbCMKeyTypeIndex(m, k, g))])

proc XkbCMKeyNumSyms(m: PXkbClientMapPtr, k: int16): int16 =
  ##define XkbCMKeyNumSyms(m,k) (XkbCMKeyGroupsWidth(m,k)*XkbCMKeyNumGroups(m,k))
  result = toU16(ze(XkbCMKeyGroupsWidth(m, k)) or ze(XkbCMKeyNumGroups(m, k)))

proc XkbCMKeySymsOffset(m: PXkbClientMapPtr, k: int16): int8 =
  ##define XkbCMKeySymsOffset(m,k) ((m)->key_sym_map[k].offset)
  result = m.key_sym_map[ze(k)].offset

proc XkbCMKeySymsPtr*(m: PXkbClientMapPtr, k: int16): PKeySym =
  ##define XkbCMKeySymsPtr(m,k) (&(m)->syms[XkbCMKeySymsOffset(m,k)])
  result = addr(m.syms[ze(XkbCMKeySymsOffset(m, k))])

proc XkbIM_IsAuto(i: PXkbIndicatorMapPtr): bool =
  ##define XkbIM_IsAuto(i) ((((i)->flags&XkbIM_NoAutomatic)==0)&&(((i)->which_groups&&(i)->groups)||
  #                           ((i)->which_mods&&(i)->mods.mask)||  ((i)->ctrls)))
  result = ((ze(i.flags) and XkbIM_NoAutomatic) == 0) and
      (((i.which_groups > 0'i8) and (i.groups > 0'i8)) or
      ((i.which_mods > 0'i8) and (i.mods.mask > 0'i8)) or (i.ctrls > 0'i8))

proc XkbIM_InUse(i: PXkbIndicatorMapPtr): bool =
  ##define XkbIM_InUse(i) (((i)->flags)||((i)->which_groups)||((i)->which_mods)||((i)->ctrls))
  result = (i.flags > 0'i8) or (i.which_groups > 0'i8) or (i.which_mods > 0'i8) or
      (i.ctrls > 0'i8)

proc XkbKeyKeyTypeIndex(d: PXkbDescPtr, k: int16, g: int8): int8 =
  ##define XkbKeyKeyTypeIndex(d,k,g)      (XkbCMKeyTypeIndex((d)->map,k,g))
  result = XkbCMKeyTypeIndex(d.map, k, g)

proc XkbKeyKeyType(d: PXkbDescPtr, k: int16, g: int8): PXkbKeyTypePtr =
  ##define XkbKeyKeyType(d,k,g) (XkbCMKeyType((d)->map,k,g))
  result = XkbCMKeyType(d.map, k, g)

proc XkbKeyGroupWidth(d: PXkbDescPtr, k: int16, g: int8): int8 =
  ##define XkbKeyGroupWidth(d,k,g) (XkbCMKeyGroupWidth((d)->map,k,g))
  result = XkbCMKeyGroupWidth(d.map, k, g)

proc XkbKeyGroupsWidth(d: PXkbDescPtr, k: int16): int8 =
  ##define XkbKeyGroupsWidth(d,k) (XkbCMKeyGroupsWidth((d)->map,k))
  result = XkbCMKeyGroupsWidth(d.map, k)

proc XkbKeyGroupInfo(d: PXkbDescPtr, k: int16): int8 =
  ##define XkbKeyGroupInfo(d,k) (XkbCMKeyGroupInfo((d)->map,(k)))
  result = XkbCMKeyGroupInfo(d.map, k)

proc XkbKeyNumGroups(d: PXkbDescPtr, k: int16): int8 =
  ##define XkbKeyNumGroups(d,k) (XkbCMKeyNumGroups((d)->map,(k)))
  result = XkbCMKeyNumGroups(d.map, k)

proc XkbKeyNumSyms(d: PXkbDescPtr, k: int16): int16 =
  ##define XkbKeyNumSyms(d,k) (XkbCMKeyNumSyms((d)->map,(k)))
  result = XkbCMKeyNumSyms(d.map, k)

proc XkbKeySymsPtr*(d: PXkbDescPtr, k: int16): PKeySym =
  ##define XkbKeySymsPtr(d,k) (XkbCMKeySymsPtr((d)->map,(k)))
  result = XkbCMKeySymsPtr(d.map, k)

proc XkbKeySym(d: PXkbDescPtr, k: int16, n: int16): TKeySym =
  ##define XkbKeySym(d,k,n) (XkbKeySymsPtr(d,k)[n])
  result = cast[ptr array[0..0xffff, TKeySym]](XkbKeySymsPtr(d, k))[ze(n)] # XXX: this seems strange!

proc XkbKeySymEntry(d: PXkbDescPtr, k: int16, sl: int16, g: int8): TKeySym =
  ##define XkbKeySymEntry(d,k,sl,g) (XkbKeySym(d,k,((XkbKeyGroupsWidth(d,k)*(g))+(sl))))
  result = XkbKeySym(d, k, toU16(ze(XkbKeyGroupsWidth(d, k)) * ze(g) + ze(sl)))

proc XkbKeyAction(d: PXkbDescPtr, k: int16, n: int16): PXkbAction =
  ##define XkbKeyAction(d,k,n) (XkbKeyHasActions(d,k)?&XkbKeyActionsPtr(d,k)[n]:NULL)
  #if (XkbKeyHasActions(d, k)):
  #  result = XkbKeyActionsPtr(d, k)[ze(n)] #Buggy !!!
  assert(false)
  result = nil

proc XkbKeyActionEntry(d: PXkbDescPtr, k: int16, sl: int16, g: int8): int8 =
  ##define XkbKeyActionEntry(d,k,sl,g) (XkbKeyHasActions(d,k) ?
  #                                      XkbKeyAction(d, k, ((XkbKeyGroupsWidth(d, k) * (g))+(sl))):NULL)
  if XkbKeyHasActions(d, k):
    result = XkbKeyGroupsWidth(d, k) *% g +% toU8(sl)
  else:
    result = 0'i8

proc XkbKeyHasActions(d: PXkbDescPtr, k: int16): bool =
  ##define XkbKeyHasActions(d,k) ((d)->server->key_acts[k]!=0)
  result = d.server.key_acts[ze(k)] != 0'i16

proc XkbKeyNumActions(d: PXkbDescPtr, k: int16): int16 =
  ##define XkbKeyNumActions(d,k) (XkbKeyHasActions(d,k)?XkbKeyNumSyms(d,k):1)
  if (XkbKeyHasActions(d, k)): result = XkbKeyNumSyms(d, k)
  else: result = 1'i16

proc XkbKeyActionsPtr(d: PXkbDescPtr, k: int16): PXkbAction =
  ##define XkbKeyActionsPtr(d,k) (XkbSMKeyActionsPtr((d)->server,k))
  result = XkbSMKeyActionsPtr(d.server, k)

proc XkbKeycodeInRange(d: PXkbDescPtr, k: int16): bool =
  ##define XkbKeycodeInRange(d,k) (((k)>=(d)->min_key_code)&& ((k)<=(d)->max_key_code))
  result = (char(toU8(k)) >= d.min_key_code) and (char(toU8(k)) <= d.max_key_code)

proc XkbNumKeys(d: PXkbDescPtr): int8 =
  ##define XkbNumKeys(d) ((d)->max_key_code-(d)->min_key_code+1)
  result = toU8(ord(d.max_key_code) - ord(d.min_key_code) + 1)

proc XkbXI_DevHasBtnActs(d: PXkbDeviceInfoPtr): bool =
  ##define XkbXI_DevHasBtnActs(d) (((d)->num_btns>0)&&((d)->btn_acts!=NULL))
  result = (d.num_btns > 0'i16) and (not (d.btn_acts == nil))

proc XkbXI_LegalDevBtn(d: PXkbDeviceInfoPtr, b: int16): bool =
  ##define XkbXI_LegalDevBtn(d,b) (XkbXI_DevHasBtnActs(d)&&((b)<(d)->num_btns))
  result = XkbXI_DevHasBtnActs(d) and (b <% d.num_btns)

proc XkbXI_DevHasLeds(d: PXkbDeviceInfoPtr): bool =
  ##define XkbXI_DevHasLeds(d) (((d)->num_leds>0)&&((d)->leds!=NULL))
  result = (d.num_leds > 0'i16) and (not (d.leds == nil))

proc XkbBoundsWidth(b: PXkbBoundsPtr): int16 =
  ##define XkbBoundsWidth(b) (((b)->x2)-((b)->x1))
  result = (b.x2) - b.x1

proc XkbBoundsHeight(b: PXkbBoundsPtr): int16 =
  ##define XkbBoundsHeight(b) (((b)->y2)-((b)->y1))
  result = (b.y2) - b.y1

proc XkbOutlineIndex(s: PXkbShapePtr, o: PXkbOutlinePtr): int32 =
  ##define XkbOutlineIndex(s,o) ((int)((o)-&(s)->outlines[0]))
  result = int32((cast[TAddress](o) - cast[TAddress](addr(s.outlines[0]))) div sizeof(PXkbOutlinePtr))

proc XkbShapeDoodadColor(g: PXkbGeometryPtr, d: PXkbShapeDoodadPtr): PXkbColorPtr =
  ##define XkbShapeDoodadColor(g,d) (&(g)->colors[(d)->color_ndx])
  result = addr((g.colors[ze(d.color_ndx)]))

proc XkbShapeDoodadShape(g: PXkbGeometryPtr, d: PXkbShapeDoodadPtr): PXkbShapePtr =
  ##define XkbShapeDoodadShape(g,d) (&(g)->shapes[(d)->shape_ndx])
  result = addr(g.shapes[ze(d.shape_ndx)])

proc XkbSetShapeDoodadColor(g: PXkbGeometryPtr, d: PXkbShapeDoodadPtr,
                            c: PXkbColorPtr) =
  ##define XkbSetShapeDoodadColor(g,d,c) ((d)->color_ndx= (c)-&(g)->colors[0])
  d.color_ndx = toU16((cast[TAddress](c) - cast[TAddress](addr(g.colors[0]))) div sizeof(TXkbColorRec))

proc XkbSetShapeDoodadShape(g: PXkbGeometryPtr, d: PXkbShapeDoodadPtr,
                            s: PXkbShapePtr) =
  ##define XkbSetShapeDoodadShape(g,d,s) ((d)->shape_ndx= (s)-&(g)->shapes[0])
  d.shape_ndx = toU16((cast[TAddress](s) - cast[TAddress](addr(g.shapes[0]))) div sizeof(TXkbShapeRec))

proc XkbTextDoodadColor(g: PXkbGeometryPtr, d: PXkbTextDoodadPtr): PXkbColorPtr =
  ##define XkbTextDoodadColor(g,d) (&(g)->colors[(d)->color_ndx])
  result = addr(g.colors[ze(d.color_ndx)])

proc XkbSetTextDoodadColor(g: PXkbGeometryPtr, d: PXkbTextDoodadPtr,
                           c: PXkbColorPtr) =
  ##define XkbSetTextDoodadColor(g,d,c) ((d)->color_ndx= (c)-&(g)->colors[0])
  d.color_ndx = toU16((cast[TAddress](c) - cast[TAddress](addr(g.colors[0]))) div sizeof(TXkbColorRec))

proc XkbIndicatorDoodadShape(g: PXkbGeometryPtr, d: PXkbIndicatorDoodadPtr): PXkbShapeDoodadPtr =
  ##define XkbIndicatorDoodadShape(g,d) (&(g)->shapes[(d)->shape_ndx])
  result = cast[PXkbShapeDoodadPtr](addr(g.shapes[ze(d.shape_ndx)]))

proc XkbIndicatorDoodadOnColor(g: PXkbGeometryPtr, d: PXkbIndicatorDoodadPtr): PXkbColorPtr =
  ##define XkbIndicatorDoodadOnColor(g,d) (&(g)->colors[(d)->on_color_ndx])
  result = addr(g.colors[ze(d.on_color_ndx)])

proc XkbIndicatorDoodadOffColor(g: PXkbGeometryPtr, d: PXkbIndicatorDoodadPtr): PXkbColorPtr =
  ##define XkbIndicatorDoodadOffColor(g,d) (&(g)->colors[(d)->off_color_ndx])
  result = addr(g.colors[ze(d.off_color_ndx)])

proc XkbSetIndicatorDoodadOnColor(g: PXkbGeometryPtr, d: PXkbIndicatorDoodadPtr,
                                  c: PXkbColorPtr) =
  ##define XkbSetIndicatorDoodadOnColor(g,d,c) ((d)->on_color_ndx= (c)-&(g)->colors[0])
  d.on_color_ndx = toU16((cast[TAddress](c) - cast[TAddress](addr(g.colors[0]))) div sizeof(TXkbColorRec))

proc XkbSetIndicatorDoodadOffColor(g: PXkbGeometryPtr,
                                   d: PXkbIndicatorDoodadPtr, c: PXkbColorPtr) =
  ##define        XkbSetIndicatorDoodadOffColor(g,d,c) ((d)->off_color_ndx= (c)-&(g)->colors[0])
  d.off_color_ndx = toU16((cast[TAddress](c) - cast[TAddress](addr(g.colors[0]))) div sizeof(TxkbColorRec))

proc XkbSetIndicatorDoodadShape(g: PXkbGeometryPtr, d: PXkbIndicatorDoodadPtr,
                                s: PXkbShapeDoodadPtr) =
  ##define XkbSetIndicatorDoodadShape(g,d,s) ((d)->shape_ndx= (s)-&(g)->shapes[0])
  d.shape_ndx = toU16((cast[TAddress](s) - (cast[TAddress](addr(g.shapes[0])))) div sizeof(TXkbShapeRec))

proc XkbLogoDoodadColor(g: PXkbGeometryPtr, d: PXkbLogoDoodadPtr): PXkbColorPtr =
  ##define XkbLogoDoodadColor(g,d) (&(g)->colors[(d)->color_ndx])
  result = addr(g.colors[ze(d.color_ndx)])

proc XkbLogoDoodadShape(g: PXkbGeometryPtr, d: PXkbLogoDoodadPtr): PXkbShapeDoodadPtr =
  ##define XkbLogoDoodadShape(g,d) (&(g)->shapes[(d)->shape_ndx])
  result = cast[PXkbShapeDoodadPtr](addr(g.shapes[ze(d.shape_ndx)]))

proc XkbSetLogoDoodadColor(g: PXkbGeometryPtr, d: PXkbLogoDoodadPtr,
                           c: PXkbColorPtr) =
  ##define XkbSetLogoDoodadColor(g,d,c) ((d)->color_ndx= (c)-&(g)->colors[0])
  d.color_ndx = toU16((cast[TAddress](c) - cast[TAddress](addr(g.colors[0]))) div sizeof(TXkbColorRec))

proc XkbSetLogoDoodadShape(g: PXkbGeometryPtr, d: PXkbLogoDoodadPtr,
                           s: PXkbShapeDoodadPtr) =
  ##define XkbSetLogoDoodadShape(g,d,s) ((d)->shape_ndx= (s)-&(g)->shapes[0])
  d.shape_ndx = toU16((cast[TAddress](s) - cast[TAddress](addr(g.shapes[0]))) div sizeof(TXkbShapeRec))

proc XkbKeyShape(g: PXkbGeometryPtr, k: PXkbKeyPtr): PXkbShapeDoodadPtr =
  ##define XkbKeyShape(g,k) (&(g)->shapes[(k)->shape_ndx])
  result = cast[PXkbShapeDoodadPtr](addr(g.shapes[ze(k.shape_ndx)]))

proc XkbKeyColor(g: PXkbGeometryPtr, k: PXkbKeyPtr): PXkbColorPtr =
  ##define XkbKeyColor(g,k) (&(g)->colors[(k)->color_ndx])
  result = addr(g.colors[ze(k.color_ndx)])

proc XkbSetKeyShape(g: PXkbGeometryPtr, k: PXkbKeyPtr, s: PXkbShapeDoodadPtr) =
  ##define XkbSetKeyShape(g,k,s) ((k)->shape_ndx= (s)-&(g)->shapes[0])
  k.shape_ndx = toU8((cast[TAddress](s) - cast[TAddress](addr(g.shapes[0]))) div sizeof(TXkbShapeRec))

proc XkbSetKeyColor(g: PXkbGeometryPtr, k: PXkbKeyPtr, c: PXkbColorPtr) =
  ##define XkbSetKeyColor(g,k,c) ((k)->color_ndx= (c)-&(g)->colors[0])
  k.color_ndx = toU8((cast[TAddress](c) - cast[TAddress](addr(g.colors[0]))) div sizeof(TxkbColorRec))

proc XkbGeomColorIndex(g: PXkbGeometryPtr, c: PXkbColorPtr): int32 =
  ##define XkbGeomColorIndex(g,c) ((int)((c)-&(g)->colors[0]))
  result = toU16((cast[TAddress](c) - (cast[TAddress](addr(g.colors[0])))) div sizeof(TxkbColorRec))
