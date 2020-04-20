#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#    C header files translated by hand
#    Licence of IUP follows:


# ****************************************************************************
# Copyright (C) 1994-2009 Tecgraf, PUC-Rio.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# ****************************************************************************

when defined(windows):
  const dllname = "iup(|30|27|26|25|24).dll"
elif defined(macosx):
  const dllname = "libiup(|3.0|2.7|2.6|2.5|2.4).dylib"
else:
  const dllname = "libiup(|3.0|2.7|2.6|2.5|2.4).so(|.1)"

const
  IUP_NAME* = "IUP - Portable User Interface"
  IUP_COPYRIGHT* = "Copyright (C) 1994-2009 Tecgraf, PUC-Rio."
  IUP_DESCRIPTION* = "Portable toolkit for building graphical user interfaces."
  constIUP_VERSION* = "3.0"
  constIUP_VERSION_NUMBER* = 300000
  constIUP_VERSION_DATE* = "2009/07/18"

type
  Ihandle = object
  PIhandle* = ptr Ihandle

  Icallback* = proc (arg: PIhandle): cint {.cdecl.}

#                      pre-defined dialogs
proc fileDlg*: PIhandle {.importc: "IupFileDlg", dynlib: dllname, cdecl.}
proc messageDlg*: PIhandle {.importc: "IupMessageDlg", dynlib: dllname, cdecl.}
proc colorDlg*: PIhandle {.importc: "IupColorDlg", dynlib: dllname, cdecl.}
proc fontDlg*: PIhandle {.importc: "IupFontDlg", dynlib: dllname, cdecl.}

proc getFile*(arq: cstring): cint {.
  importc: "IupGetFile", dynlib: dllname, cdecl.}
proc message*(title, msg: cstring) {.
  importc: "IupMessage", dynlib: dllname, cdecl.}
proc messagef*(title, format: cstring) {.
  importc: "IupMessagef", dynlib: dllname, cdecl, varargs.}
proc alarm*(title, msg, b1, b2, b3: cstring): cint {.
  importc: "IupAlarm", dynlib: dllname, cdecl.}
proc scanf*(format: cstring): cint {.
  importc: "IupScanf", dynlib: dllname, cdecl, varargs.}
proc listDialog*(theType: cint, title: cstring, size: cint,
                 list: cstringArray, op, maxCol, maxLin: cint,
                 marks: ptr cint): cint {.
                 importc: "IupListDialog", dynlib: dllname, cdecl.}
proc getText*(title, text: cstring): cint {.
  importc: "IupGetText", dynlib: dllname, cdecl.}
proc getColor*(x, y: cint, r, g, b: var byte): cint {.
  importc: "IupGetColor", dynlib: dllname, cdecl.}

type
  Iparamcb* = proc (dialog: PIhandle, paramIndex: cint,
                    userData: pointer): cint {.cdecl.}

proc getParam*(title: cstring, action: Iparamcb, userData: pointer,
               format: cstring): cint {.
               importc: "IupGetParam", cdecl, varargs, dynlib: dllname.}
proc getParamv*(title: cstring, action: Iparamcb, userData: pointer,
                format: cstring, paramCount, paramExtra: cint,
                paramData: pointer): cint {.
                importc: "IupGetParamv", cdecl, dynlib: dllname.}


#                      Functions

proc open*(argc: ptr cint, argv: ptr cstringArray): cint {.
  importc: "IupOpen", cdecl, dynlib: dllname.}
proc close*() {.importc: "IupClose", cdecl, dynlib: dllname.}
proc imageLibOpen*() {.importc: "IupImageLibOpen", cdecl, dynlib: dllname.}

proc mainLoop*(): cint {.importc: "IupMainLoop", cdecl, dynlib: dllname,
                         discardable.}
proc loopStep*(): cint {.importc: "IupLoopStep", cdecl, dynlib: dllname,
                         discardable.}
proc mainLoopLevel*(): cint {.importc: "IupMainLoopLevel", cdecl,
                              dynlib: dllname, discardable.}
proc flush*() {.importc: "IupFlush", cdecl, dynlib: dllname.}
proc exitLoop*() {.importc: "IupExitLoop", cdecl, dynlib: dllname.}

proc update*(ih: PIhandle) {.importc: "IupUpdate", cdecl, dynlib: dllname.}
proc updateChildren*(ih: PIhandle) {.importc: "IupUpdateChildren", cdecl, dynlib: dllname.}
proc redraw*(ih: PIhandle, children: cint) {.importc: "IupRedraw", cdecl, dynlib: dllname.}
proc refresh*(ih: PIhandle) {.importc: "IupRefresh", cdecl, dynlib: dllname.}

proc mapFont*(iupfont: cstring): cstring {.importc: "IupMapFont", cdecl, dynlib: dllname.}
proc unMapFont*(driverfont: cstring): cstring {.importc: "IupUnMapFont", cdecl, dynlib: dllname.}
proc help*(url: cstring): cint {.importc: "IupHelp", cdecl, dynlib: dllname.}
proc load*(filename: cstring): cstring {.importc: "IupLoad", cdecl, dynlib: dllname.}

proc iupVersion*(): cstring {.importc: "IupVersion", cdecl, dynlib: dllname.}
proc iupVersionDate*(): cstring {.importc: "IupVersionDate", cdecl, dynlib: dllname.}
proc iupVersionNumber*(): cint {.importc: "IupVersionNumber", cdecl, dynlib: dllname.}
proc setLanguage*(lng: cstring) {.importc: "IupSetLanguage", cdecl, dynlib: dllname.}
proc getLanguage*(): cstring {.importc: "IupGetLanguage", cdecl, dynlib: dllname.}

proc destroy*(ih: PIhandle) {.importc: "IupDestroy", cdecl, dynlib: dllname.}
proc detach*(child: PIhandle) {.importc: "IupDetach", cdecl, dynlib: dllname.}
proc append*(ih, child: PIhandle): PIhandle {.
  importc: "IupAppend", cdecl, dynlib: dllname, discardable.}
proc insert*(ih, refChild, child: PIhandle): PIhandle {.
  importc: "IupInsert", cdecl, dynlib: dllname, discardable.}
proc getChild*(ih: PIhandle, pos: cint): PIhandle {.
  importc: "IupGetChild", cdecl, dynlib: dllname.}
proc getChildPos*(ih, child: PIhandle): cint {.
  importc: "IupGetChildPos", cdecl, dynlib: dllname.}
proc getChildCount*(ih: PIhandle): cint {.
  importc: "IupGetChildCount", cdecl, dynlib: dllname.}
proc getNextChild*(ih, child: PIhandle): PIhandle {.
  importc: "IupGetNextChild", cdecl, dynlib: dllname.}
proc getBrother*(ih: PIhandle): PIhandle {.
  importc: "IupGetBrother", cdecl, dynlib: dllname.}
proc getParent*(ih: PIhandle): PIhandle {.
  importc: "IupGetParent", cdecl, dynlib: dllname.}
proc getDialog*(ih: PIhandle): PIhandle {.
  importc: "IupGetDialog", cdecl, dynlib: dllname.}
proc getDialogChild*(ih: PIhandle, name: cstring): PIhandle {.
  importc: "IupGetDialogChild", cdecl, dynlib: dllname.}
proc reparent*(ih, newParent: PIhandle): cint {.
  importc: "IupReparent", cdecl, dynlib: dllname.}

proc popup*(ih: PIhandle, x, y: cint): cint {.
  importc: "IupPopup", cdecl, dynlib: dllname, discardable.}
proc show*(ih: PIhandle): cint {.
  importc: "IupShow", cdecl, dynlib: dllname, discardable.}
proc showXY*(ih: PIhandle, x, y: cint): cint {.
  importc: "IupShowXY", cdecl, dynlib: dllname, discardable.}
proc hide*(ih: PIhandle): cint {.
  importc: "IupHide", cdecl, dynlib: dllname, discardable.}
proc map*(ih: PIhandle): cint {.
  importc: "IupMap", cdecl, dynlib: dllname, discardable.}
proc unmap*(ih: PIhandle) {.
  importc: "IupUnmap", cdecl, dynlib: dllname, discardable.}

proc setAttribute*(ih: PIhandle, name, value: cstring) {.
  importc: "IupSetAttribute", cdecl, dynlib: dllname.}
proc storeAttribute*(ih: PIhandle, name, value: cstring) {.
  importc: "IupStoreAttribute", cdecl, dynlib: dllname.}
proc setAttributes*(ih: PIhandle, str: cstring): PIhandle {.
  importc: "IupSetAttributes", cdecl, dynlib: dllname.}
proc getAttribute*(ih: PIhandle, name: cstring): cstring {.
  importc: "IupGetAttribute", cdecl, dynlib: dllname.}
proc getAttributes*(ih: PIhandle): cstring {.
  importc: "IupGetAttributes", cdecl, dynlib: dllname.}
proc getInt*(ih: PIhandle, name: cstring): cint {.
  importc: "IupGetInt", cdecl, dynlib: dllname.}
proc getInt2*(ih: PIhandle, name: cstring): cint {.
  importc: "IupGetInt2", cdecl, dynlib: dllname.}
proc getIntInt*(ih: PIhandle, name: cstring, i1, i2: var cint): cint {.
  importc: "IupGetIntInt", cdecl, dynlib: dllname.}
proc getFloat*(ih: PIhandle, name: cstring): cfloat {.
  importc: "IupGetFloat", cdecl, dynlib: dllname.}
proc setfAttribute*(ih: PIhandle, name, format: cstring) {.
  importc: "IupSetfAttribute", cdecl, dynlib: dllname, varargs.}
proc getAllAttributes*(ih: PIhandle, names: cstringArray, n: cint): cint {.
  importc: "IupGetAllAttributes", cdecl, dynlib: dllname.}
proc setAtt*(handleName: cstring, ih: PIhandle, name: cstring): PIhandle {.
  importc: "IupSetAtt", cdecl, dynlib: dllname, varargs, discardable.}

proc setGlobal*(name, value: cstring) {.
  importc: "IupSetGlobal", cdecl, dynlib: dllname.}
proc storeGlobal*(name, value: cstring) {.
  importc: "IupStoreGlobal", cdecl, dynlib: dllname.}
proc getGlobal*(name: cstring): cstring {.
  importc: "IupGetGlobal", cdecl, dynlib: dllname.}

proc setFocus*(ih: PIhandle): PIhandle {.
  importc: "IupSetFocus", cdecl, dynlib: dllname.}
proc getFocus*(): PIhandle {.
  importc: "IupGetFocus", cdecl, dynlib: dllname.}
proc previousField*(ih: PIhandle): PIhandle {.
  importc: "IupPreviousField", cdecl, dynlib: dllname.}
proc nextField*(ih: PIhandle): PIhandle {.
  importc: "IupNextField", cdecl, dynlib: dllname.}

proc getCallback*(ih: PIhandle, name: cstring): Icallback {.
  importc: "IupGetCallback", cdecl, dynlib: dllname.}
proc setCallback*(ih: PIhandle, name: cstring, fn: Icallback): Icallback {.
  importc: "IupSetCallback", cdecl, dynlib: dllname, discardable.}

proc setCallbacks*(ih: PIhandle, name: cstring, fn: Icallback): PIhandle {.
  importc: "IupSetCallbacks", cdecl, dynlib: dllname, varargs, discardable.}

proc getFunction*(name: cstring): Icallback {.
  importc: "IupGetFunction", cdecl, dynlib: dllname.}
proc setFunction*(name: cstring, fn: Icallback): Icallback {.
  importc: "IupSetFunction", cdecl, dynlib: dllname, discardable.}
proc getActionName*(): cstring {.
  importc: "IupGetActionName", cdecl, dynlib: dllname.}

proc getHandle*(name: cstring): PIhandle {.
  importc: "IupGetHandle", cdecl, dynlib: dllname.}
proc setHandle*(name: cstring, ih: PIhandle): PIhandle {.
  importc: "IupSetHandle", cdecl, dynlib: dllname.}
proc getAllNames*(names: cstringArray, n: cint): cint {.
  importc: "IupGetAllNames", cdecl, dynlib: dllname.}
proc getAllDialogs*(names: cstringArray, n: cint): cint {.
  importc: "IupGetAllDialogs", cdecl, dynlib: dllname.}
proc getName*(ih: PIhandle): cstring {.
  importc: "IupGetName", cdecl, dynlib: dllname.}

proc setAttributeHandle*(ih: PIhandle, name: cstring, ihNamed: PIhandle) {.
  importc: "IupSetAttributeHandle", cdecl, dynlib: dllname.}
proc getAttributeHandle*(ih: PIhandle, name: cstring): PIhandle {.
  importc: "IupGetAttributeHandle", cdecl, dynlib: dllname.}

proc getClassName*(ih: PIhandle): cstring {.
  importc: "IupGetClassName", cdecl, dynlib: dllname.}
proc getClassType*(ih: PIhandle): cstring {.
  importc: "IupGetClassType", cdecl, dynlib: dllname.}
proc getClassAttributes*(classname: cstring, names: cstringArray,
                         n: cint): cint {.
  importc: "IupGetClassAttributes", cdecl, dynlib: dllname.}
proc saveClassAttributes*(ih: PIhandle) {.
  importc: "IupSaveClassAttributes", cdecl, dynlib: dllname.}
proc setClassDefaultAttribute*(classname, name, value: cstring) {.
  importc: "IupSetClassDefaultAttribute", cdecl, dynlib: dllname.}

proc create*(classname: cstring): PIhandle {.
  importc: "IupCreate", cdecl, dynlib: dllname.}
proc createv*(classname: cstring, params: pointer): PIhandle {.
  importc: "IupCreatev", cdecl, dynlib: dllname.}
proc createp*(classname: cstring, first: pointer): PIhandle {.
  importc: "IupCreatep", cdecl, dynlib: dllname, varargs.}

proc fill*(): PIhandle {.importc: "IupFill", cdecl, dynlib: dllname.}
proc radio*(child: PIhandle): PIhandle {.
  importc: "IupRadio", cdecl, dynlib: dllname.}
proc vbox*(child: PIhandle): PIhandle {.
  importc: "IupVbox", cdecl, dynlib: dllname, varargs.}
proc vboxv*(children: ptr PIhandle): PIhandle {.
  importc: "IupVboxv", cdecl, dynlib: dllname.}
proc zbox*(child: PIhandle): PIhandle {.
  importc: "IupZbox", cdecl, dynlib: dllname, varargs.}
proc zboxv*(children: ptr PIhandle): PIhandle {.
  importc: "IupZboxv", cdecl, dynlib: dllname.}
proc hbox*(child: PIhandle): PIhandle {.
  importc: "IupHbox", cdecl, dynlib: dllname, varargs.}
proc hboxv*(children: ptr PIhandle): PIhandle {.
  importc: "IupHboxv", cdecl, dynlib: dllname.}

proc normalizer*(ihFirst: PIhandle): PIhandle {.
  importc: "IupNormalizer", cdecl, dynlib: dllname, varargs.}
proc normalizerv*(ihList: ptr PIhandle): PIhandle {.
  importc: "IupNormalizerv", cdecl, dynlib: dllname.}

proc cbox*(child: PIhandle): PIhandle {.
  importc: "IupCbox", cdecl, dynlib: dllname, varargs.}
proc cboxv*(children: ptr PIhandle): PIhandle {.
  importc: "IupCboxv", cdecl, dynlib: dllname.}
proc sbox*(child: PIhandle): PIhandle {.
  importc: "IupSbox", cdecl, dynlib: dllname.}

proc frame*(child: PIhandle): PIhandle {.
  importc: "IupFrame", cdecl, dynlib: dllname.}

proc image*(width, height: cint, pixmap: pointer): PIhandle {.
  importc: "IupImage", cdecl, dynlib: dllname.}
proc imageRGB*(width, height: cint, pixmap: pointer): PIhandle {.
  importc: "IupImageRGB", cdecl, dynlib: dllname.}
proc imageRGBA*(width, height: cint, pixmap: pointer): PIhandle {.
  importc: "IupImageRGBA", cdecl, dynlib: dllname.}

proc item*(title, action: cstring): PIhandle {.
  importc: "IupItem", cdecl, dynlib: dllname.}
proc submenu*(title: cstring, child: PIhandle): PIhandle {.
  importc: "IupSubmenu", cdecl, dynlib: dllname.}
proc separator*(): PIhandle {.
  importc: "IupSeparator", cdecl, dynlib: dllname.}
proc menu*(child: PIhandle): PIhandle {.
  importc: "IupMenu", cdecl, dynlib: dllname, varargs.}
proc menuv*(children: ptr PIhandle): PIhandle {.
  importc: "IupMenuv", cdecl, dynlib: dllname.}

proc button*(title, action: cstring): PIhandle {.
  importc: "IupButton", cdecl, dynlib: dllname.}
proc link*(url, title: cstring): PIhandle {.
  importc: "IupLink", cdecl, dynlib: dllname.}
proc canvas*(action: cstring): PIhandle {.
  importc: "IupCanvas", cdecl, dynlib: dllname.}
proc dialog*(child: PIhandle): PIhandle {.
  importc: "IupDialog", cdecl, dynlib: dllname.}
proc user*(): PIhandle {.
  importc: "IupUser", cdecl, dynlib: dllname.}
proc label*(title: cstring): PIhandle {.
  importc: "IupLabel", cdecl, dynlib: dllname.}
proc list*(action: cstring): PIhandle {.
  importc: "IupList", cdecl, dynlib: dllname.}
proc text*(action: cstring): PIhandle {.
  importc: "IupText", cdecl, dynlib: dllname.}
proc multiLine*(action: cstring): PIhandle {.
  importc: "IupMultiLine", cdecl, dynlib: dllname.}
proc toggle*(title, action: cstring): PIhandle {.
  importc: "IupToggle", cdecl, dynlib: dllname.}
proc timer*(): PIhandle {.
  importc: "IupTimer", cdecl, dynlib: dllname.}
proc progressBar*(): PIhandle {.
  importc: "IupProgressBar", cdecl, dynlib: dllname.}
proc val*(theType: cstring): PIhandle {.
  importc: "IupVal", cdecl, dynlib: dllname.}
proc tabs*(child: PIhandle): PIhandle {.
  importc: "IupTabs", cdecl, dynlib: dllname, varargs.}
proc tabsv*(children: ptr PIhandle): PIhandle {.
  importc: "IupTabsv", cdecl, dynlib: dllname.}
proc tree*(): PIhandle {.importc: "IupTree", cdecl, dynlib: dllname.}

proc spin*(): PIhandle {.importc: "IupSpin", cdecl, dynlib: dllname.}
proc spinbox*(child: PIhandle): PIhandle {.
  importc: "IupSpinbox", cdecl, dynlib: dllname.}

# IupText utilities
proc textConvertLinColToPos*(ih: PIhandle, lin, col: cint, pos: var cint) {.
  importc: "IupTextConvertLinColToPos", cdecl, dynlib: dllname.}
proc textConvertPosToLinCol*(ih: PIhandle, pos: cint, lin, col: var cint) {.
  importc: "IupTextConvertPosToLinCol", cdecl, dynlib: dllname.}

proc convertXYToPos*(ih: PIhandle, x, y: cint): cint {.
  importc: "IupConvertXYToPos", cdecl, dynlib: dllname.}

# IupTree utilities
proc treeSetUserId*(ih: PIhandle, id: cint, userid: pointer): cint {.
  importc: "IupTreeSetUserId", cdecl, dynlib: dllname, discardable.}
proc treeGetUserId*(ih: PIhandle, id: cint): pointer {.
  importc: "IupTreeGetUserId", cdecl, dynlib: dllname.}
proc treeGetId*(ih: PIhandle, userid: pointer): cint {.
  importc: "IupTreeGetId", cdecl, dynlib: dllname.}

proc treeSetAttribute*(ih: PIhandle, name: cstring, id: cint, value: cstring) {.
  importc: "IupTreeSetAttribute", cdecl, dynlib: dllname.}
proc treeStoreAttribute*(ih: PIhandle, name: cstring, id: cint, value: cstring) {.
  importc: "IupTreeStoreAttribute", cdecl, dynlib: dllname.}
proc treeGetAttribute*(ih: PIhandle, name: cstring, id: cint): cstring {.
  importc: "IupTreeGetAttribute", cdecl, dynlib: dllname.}
proc treeGetInt*(ih: PIhandle, name: cstring, id: cint): cint {.
  importc: "IupTreeGetInt", cdecl, dynlib: dllname.}
proc treeGetFloat*(ih: PIhandle, name: cstring, id: cint): cfloat {.
  importc: "IupTreeGetFloat", cdecl, dynlib: dllname.}
proc treeSetfAttribute*(ih: PIhandle, name: cstring, id: cint, format: cstring) {.
  importc: "IupTreeSetfAttribute", cdecl, dynlib: dllname, varargs.}


#                   Common Return Values
const
  IUP_ERROR* = cint(1)
  IUP_NOERROR* = cint(0)
  IUP_OPENED* = cint(-1)
  IUP_INVALID* = cint(-1)

  # Callback Return Values
  IUP_IGNORE* = cint(-1)
  IUP_DEFAULT* = cint(-2)
  IUP_CLOSE* = cint(-3)
  IUP_CONTINUE* = cint(-4)

  # IupPopup and IupShowXY Parameter Values
  IUP_CENTER* = cint(0xFFFF)
  IUP_LEFT* = cint(0xFFFE)
  IUP_RIGHT* = cint(0xFFFD)
  IUP_MOUSEPOS* = cint(0xFFFC)
  IUP_CURRENT* = cint(0xFFFB)
  IUP_CENTERPARENT* = cint(0xFFFA)
  IUP_TOP* = IUP_LEFT
  IUP_BOTTOM* = IUP_RIGHT

  # SHOW_CB Callback Values
  IUP_SHOW* = cint(0)
  IUP_RESTORE* = cint(1)
  IUP_MINIMIZE* = cint(2)
  IUP_MAXIMIZE* = cint(3)
  IUP_HIDE* = cint(4)

  # SCROLL_CB Callback Values
  IUP_SBUP* = cint(0)
  IUP_SBDN* = cint(1)
  IUP_SBPGUP* = cint(2)
  IUP_SBPGDN* = cint(3)
  IUP_SBPOSV* = cint(4)
  IUP_SBDRAGV* = cint(5)
  IUP_SBLEFT* = cint(6)
  IUP_SBRIGHT* = cint(7)
  IUP_SBPGLEFT* = cint(8)
  IUP_SBPGRIGHT* = cint(9)
  IUP_SBPOSH* = cint(10)
  IUP_SBDRAGH* = cint(11)

  # Mouse Button Values and Macros
  IUP_BUTTON1* = cint(ord('1'))
  IUP_BUTTON2* = cint(ord('2'))
  IUP_BUTTON3* = cint(ord('3'))
  IUP_BUTTON4* = cint(ord('4'))
  IUP_BUTTON5* = cint(ord('5'))

proc isShift*(s: cstring): bool = return s[0] == 'S'
proc isControl*(s: cstring): bool = return s[1] == 'C'
proc isButton1*(s: cstring): bool = return s[2] == '1'
proc isButton2*(s: cstring): bool = return s[3] == '2'
proc isbutton3*(s: cstring): bool = return s[4] == '3'
proc isDouble*(s: cstring): bool = return s[5] == 'D'
proc isAlt*(s: cstring): bool = return s[6] == 'A'
proc isSys*(s: cstring): bool = return s[7] == 'Y'
proc isButton4*(s: cstring): bool = return s[8] == '4'
proc isButton5*(s: cstring): bool = return s[9] == '5'

# Pre-Defined Masks
const
  IUP_MASK_FLOAT* = "[+/-]?(/d+/.?/d*|/./d+)"
  IUP_MASK_UFLOAT* = "(/d+/.?/d*|/./d+)"
  IUP_MASK_EFLOAT* = "[+/-]?(/d+/.?/d*|/./d+)([eE][+/-]?/d+)?"
  IUP_MASK_INT* = "[+/-]?/d+"
  IUP_MASK_UINT* = "/d+"

# from 32 to 126, all character sets are equal,
# the key code i the same as the character code.
const
  K_SP* = cint(ord(' '))
  K_exclam* = cint(ord('!'))
  K_quotedbl* = cint(ord('\"'))
  K_numbersign* = cint(ord('#'))
  K_dollar* = cint(ord('$'))
  K_percent* = cint(ord('%'))
  K_ampersand* = cint(ord('&'))
  K_apostrophe* = cint(ord('\''))
  K_parentleft* = cint(ord('('))
  K_parentright* = cint(ord(')'))
  K_asterisk* = cint(ord('*'))
  K_plus* = cint(ord('+'))
  K_comma* = cint(ord(','))
  K_minus* = cint(ord('-'))
  K_period* = cint(ord('.'))
  K_slash* = cint(ord('/'))
  K_0* = cint(ord('0'))
  K_1* = cint(ord('1'))
  K_2* = cint(ord('2'))
  K_3* = cint(ord('3'))
  K_4* = cint(ord('4'))
  K_5* = cint(ord('5'))
  K_6* = cint(ord('6'))
  K_7* = cint(ord('7'))
  K_8* = cint(ord('8'))
  K_9* = cint(ord('9'))
  K_colon* = cint(ord(':'))
  K_semicolon* = cint(ord(';'))
  K_less* = cint(ord('<'))
  K_equal* = cint(ord('='))
  K_greater* = cint(ord('>'))
  K_question* = cint(ord('?'))
  K_at* = cint(ord('@'))
  K_upperA* = cint(ord('A'))
  K_upperB* = cint(ord('B'))
  K_upperC* = cint(ord('C'))
  K_upperD* = cint(ord('D'))
  K_upperE* = cint(ord('E'))
  K_upperF* = cint(ord('F'))
  K_upperG* = cint(ord('G'))
  K_upperH* = cint(ord('H'))
  K_upperI* = cint(ord('I'))
  K_upperJ* = cint(ord('J'))
  K_upperK* = cint(ord('K'))
  K_upperL* = cint(ord('L'))
  K_upperM* = cint(ord('M'))
  K_upperN* = cint(ord('N'))
  K_upperO* = cint(ord('O'))
  K_upperP* = cint(ord('P'))
  K_upperQ* = cint(ord('Q'))
  K_upperR* = cint(ord('R'))
  K_upperS* = cint(ord('S'))
  K_upperT* = cint(ord('T'))
  K_upperU* = cint(ord('U'))
  K_upperV* = cint(ord('V'))
  K_upperW* = cint(ord('W'))
  K_upperX* = cint(ord('X'))
  K_upperY* = cint(ord('Y'))
  K_upperZ* = cint(ord('Z'))
  K_bracketleft* = cint(ord('['))
  K_backslash* = cint(ord('\\'))
  K_bracketright* = cint(ord(']'))
  K_circum* = cint(ord('^'))
  K_underscore* = cint(ord('_'))
  K_grave* = cint(ord('`'))
  K_lowera* = cint(ord('a'))
  K_lowerb* = cint(ord('b'))
  K_lowerc* = cint(ord('c'))
  K_lowerd* = cint(ord('d'))
  K_lowere* = cint(ord('e'))
  K_lowerf* = cint(ord('f'))
  K_lowerg* = cint(ord('g'))
  K_lowerh* = cint(ord('h'))
  K_loweri* = cint(ord('i'))
  K_lowerj* = cint(ord('j'))
  K_lowerk* = cint(ord('k'))
  K_lowerl* = cint(ord('l'))
  K_lowerm* = cint(ord('m'))
  K_lowern* = cint(ord('n'))
  K_lowero* = cint(ord('o'))
  K_lowerp* = cint(ord('p'))
  K_lowerq* = cint(ord('q'))
  K_lowerr* = cint(ord('r'))
  K_lowers* = cint(ord('s'))
  K_lowert* = cint(ord('t'))
  K_loweru* = cint(ord('u'))
  K_lowerv* = cint(ord('v'))
  K_lowerw* = cint(ord('w'))
  K_lowerx* = cint(ord('x'))
  K_lowery* = cint(ord('y'))
  K_lowerz* = cint(ord('z'))
  K_braceleft* = cint(ord('{'))
  K_bar* = cint(ord('|'))
  K_braceright* = cint(ord('}'))
  K_tilde* = cint(ord('~'))

proc isPrint*(c: cint): bool = return c > 31 and c < 127

# also define the escape sequences that have keys associated
const
  K_BS* = cint(ord('\b'))
  K_TAB* = cint(ord('\t'))
  K_LF* = cint(10)
  K_CR* = cint(13)

# IUP Extended Key Codes, range start at 128
# Modifiers use 256 interval
# These key code definitions are specific to IUP

proc isXkey*(c: cint): bool = return c > 128
proc isShiftXkey*(c: cint): bool = return c > 256 and c < 512
proc isCtrlXkey*(c: cint): bool = return c > 512 and c < 768
proc isAltXkey*(c: cint): bool = return c > 768 and c < 1024
proc isSysXkey*(c: cint): bool = return c > 1024 and c < 1280

proc iUPxCODE*(c: cint): cint = return c + cint(128) # Normal (must be above 128)
proc iUPsxCODE*(c: cint): cint =
  return c + cint(256)
  # Shift (must have range to include the standard keys and the normal
  # extended keys, so must be above 256

proc iUPcxCODE*(c: cint): cint = return c + cint(512) # Ctrl
proc iUPmxCODE*(c: cint): cint = return c + cint(768) # Alt
proc iUPyxCODE*(c: cint): cint = return c + cint(1024) # Sys (Win or Apple)

const
  IUP_NUMMAXCODES* = 1280 ## 5*256=1280  Normal+Shift+Ctrl+Alt+Sys

  K_HOME* = iUPxCODE(1)
  K_UP* = iUPxCODE(2)
  K_PGUP* = iUPxCODE(3)
  K_LEFT* = iUPxCODE(4)
  K_MIDDLE* = iUPxCODE(5)
  K_RIGHT* = iUPxCODE(6)
  K_END* = iUPxCODE(7)
  K_DOWN* = iUPxCODE(8)
  K_PGDN* = iUPxCODE(9)
  K_INS* = iUPxCODE(10)
  K_DEL* = iUPxCODE(11)
  K_PAUSE* = iUPxCODE(12)
  K_ESC* = iUPxCODE(13)
  K_ccedilla* = iUPxCODE(14)
  K_F1* = iUPxCODE(15)
  K_F2* = iUPxCODE(16)
  K_F3* = iUPxCODE(17)
  K_F4* = iUPxCODE(18)
  K_F5* = iUPxCODE(19)
  K_F6* = iUPxCODE(20)
  K_F7* = iUPxCODE(21)
  K_F8* = iUPxCODE(22)
  K_F9* = iUPxCODE(23)
  K_F10* = iUPxCODE(24)
  K_F11* = iUPxCODE(25)
  K_F12* = iUPxCODE(26)
  K_Print* = iUPxCODE(27)
  K_Menu* = iUPxCODE(28)

  K_acute* = iUPxCODE(29) # no Shift/Ctrl/Alt

  K_sHOME* = iUPsxCODE(K_HOME)
  K_sUP* = iUPsxCODE(K_UP)
  K_sPGUP* = iUPsxCODE(K_PGUP)
  K_sLEFT* = iUPsxCODE(K_LEFT)
  K_sMIDDLE* = iUPsxCODE(K_MIDDLE)
  K_sRIGHT* = iUPsxCODE(K_RIGHT)
  K_sEND* = iUPsxCODE(K_END)
  K_sDOWN* = iUPsxCODE(K_DOWN)
  K_sPGDN* = iUPsxCODE(K_PGDN)
  K_sINS* = iUPsxCODE(K_INS)
  K_sDEL* = iUPsxCODE(K_DEL)
  K_sSP* = iUPsxCODE(K_SP)
  K_sTAB* = iUPsxCODE(K_TAB)
  K_sCR* = iUPsxCODE(K_CR)
  K_sBS* = iUPsxCODE(K_BS)
  K_sPAUSE* = iUPsxCODE(K_PAUSE)
  K_sESC* = iUPsxCODE(K_ESC)
  K_sCcedilla* = iUPsxCODE(K_ccedilla)
  K_sF1* = iUPsxCODE(K_F1)
  K_sF2* = iUPsxCODE(K_F2)
  K_sF3* = iUPsxCODE(K_F3)
  K_sF4* = iUPsxCODE(K_F4)
  K_sF5* = iUPsxCODE(K_F5)
  K_sF6* = iUPsxCODE(K_F6)
  K_sF7* = iUPsxCODE(K_F7)
  K_sF8* = iUPsxCODE(K_F8)
  K_sF9* = iUPsxCODE(K_F9)
  K_sF10* = iUPsxCODE(K_F10)
  K_sF11* = iUPsxCODE(K_F11)
  K_sF12* = iUPsxCODE(K_F12)
  K_sPrint* = iUPsxCODE(K_Print)
  K_sMenu* = iUPsxCODE(K_Menu)

  K_cHOME* = iUPcxCODE(K_HOME)
  K_cUP* = iUPcxCODE(K_UP)
  K_cPGUP* = iUPcxCODE(K_PGUP)
  K_cLEFT* = iUPcxCODE(K_LEFT)
  K_cMIDDLE* = iUPcxCODE(K_MIDDLE)
  K_cRIGHT* = iUPcxCODE(K_RIGHT)
  K_cEND* = iUPcxCODE(K_END)
  K_cDOWN* = iUPcxCODE(K_DOWN)
  K_cPGDN* = iUPcxCODE(K_PGDN)
  K_cINS* = iUPcxCODE(K_INS)
  K_cDEL* = iUPcxCODE(K_DEL)
  K_cSP* = iUPcxCODE(K_SP)
  K_cTAB* = iUPcxCODE(K_TAB)
  K_cCR* = iUPcxCODE(K_CR)
  K_cBS* = iUPcxCODE(K_BS)
  K_cPAUSE* = iUPcxCODE(K_PAUSE)
  K_cESC* = iUPcxCODE(K_ESC)
  K_cCcedilla* = iUPcxCODE(K_ccedilla)
  K_cF1* = iUPcxCODE(K_F1)
  K_cF2* = iUPcxCODE(K_F2)
  K_cF3* = iUPcxCODE(K_F3)
  K_cF4* = iUPcxCODE(K_F4)
  K_cF5* = iUPcxCODE(K_F5)
  K_cF6* = iUPcxCODE(K_F6)
  K_cF7* = iUPcxCODE(K_F7)
  K_cF8* = iUPcxCODE(K_F8)
  K_cF9* = iUPcxCODE(K_F9)
  K_cF10* = iUPcxCODE(K_F10)
  K_cF11* = iUPcxCODE(K_F11)
  K_cF12* = iUPcxCODE(K_F12)
  K_cPrint* = iUPcxCODE(K_Print)
  K_cMenu* = iUPcxCODE(K_Menu)

  K_mHOME* = iUPmxCODE(K_HOME)
  K_mUP* = iUPmxCODE(K_UP)
  K_mPGUP* = iUPmxCODE(K_PGUP)
  K_mLEFT* = iUPmxCODE(K_LEFT)
  K_mMIDDLE* = iUPmxCODE(K_MIDDLE)
  K_mRIGHT* = iUPmxCODE(K_RIGHT)
  K_mEND* = iUPmxCODE(K_END)
  K_mDOWN* = iUPmxCODE(K_DOWN)
  K_mPGDN* = iUPmxCODE(K_PGDN)
  K_mINS* = iUPmxCODE(K_INS)
  K_mDEL* = iUPmxCODE(K_DEL)
  K_mSP* = iUPmxCODE(K_SP)
  K_mTAB* = iUPmxCODE(K_TAB)
  K_mCR* = iUPmxCODE(K_CR)
  K_mBS* = iUPmxCODE(K_BS)
  K_mPAUSE* = iUPmxCODE(K_PAUSE)
  K_mESC* = iUPmxCODE(K_ESC)
  K_mCcedilla* = iUPmxCODE(K_ccedilla)
  K_mF1* = iUPmxCODE(K_F1)
  K_mF2* = iUPmxCODE(K_F2)
  K_mF3* = iUPmxCODE(K_F3)
  K_mF4* = iUPmxCODE(K_F4)
  K_mF5* = iUPmxCODE(K_F5)
  K_mF6* = iUPmxCODE(K_F6)
  K_mF7* = iUPmxCODE(K_F7)
  K_mF8* = iUPmxCODE(K_F8)
  K_mF9* = iUPmxCODE(K_F9)
  K_mF10* = iUPmxCODE(K_F10)
  K_mF11* = iUPmxCODE(K_F11)
  K_mF12* = iUPmxCODE(K_F12)
  K_mPrint* = iUPmxCODE(K_Print)
  K_mMenu* = iUPmxCODE(K_Menu)

  K_yHOME* = iUPyxCODE(K_HOME)
  K_yUP* = iUPyxCODE(K_UP)
  K_yPGUP* = iUPyxCODE(K_PGUP)
  K_yLEFT* = iUPyxCODE(K_LEFT)
  K_yMIDDLE* = iUPyxCODE(K_MIDDLE)
  K_yRIGHT* = iUPyxCODE(K_RIGHT)
  K_yEND* = iUPyxCODE(K_END)
  K_yDOWN* = iUPyxCODE(K_DOWN)
  K_yPGDN* = iUPyxCODE(K_PGDN)
  K_yINS* = iUPyxCODE(K_INS)
  K_yDEL* = iUPyxCODE(K_DEL)
  K_ySP* = iUPyxCODE(K_SP)
  K_yTAB* = iUPyxCODE(K_TAB)
  K_yCR* = iUPyxCODE(K_CR)
  K_yBS* = iUPyxCODE(K_BS)
  K_yPAUSE* = iUPyxCODE(K_PAUSE)
  K_yESC* = iUPyxCODE(K_ESC)
  K_yCcedilla* = iUPyxCODE(K_ccedilla)
  K_yF1* = iUPyxCODE(K_F1)
  K_yF2* = iUPyxCODE(K_F2)
  K_yF3* = iUPyxCODE(K_F3)
  K_yF4* = iUPyxCODE(K_F4)
  K_yF5* = iUPyxCODE(K_F5)
  K_yF6* = iUPyxCODE(K_F6)
  K_yF7* = iUPyxCODE(K_F7)
  K_yF8* = iUPyxCODE(K_F8)
  K_yF9* = iUPyxCODE(K_F9)
  K_yF10* = iUPyxCODE(K_F10)
  K_yF11* = iUPyxCODE(K_F11)
  K_yF12* = iUPyxCODE(K_F12)
  K_yPrint* = iUPyxCODE(K_Print)
  K_yMenu* = iUPyxCODE(K_Menu)

  K_sPlus* = iUPsxCODE(K_plus)
  K_sComma* = iUPsxCODE(K_comma)
  K_sMinus* = iUPsxCODE(K_minus)
  K_sPeriod* = iUPsxCODE(K_period)
  K_sSlash* = iUPsxCODE(K_slash)
  K_sAsterisk* = iUPsxCODE(K_asterisk)

  K_cupperA* = iUPcxCODE(K_upperA)
  K_cupperB* = iUPcxCODE(K_upperB)
  K_cupperC* = iUPcxCODE(K_upperC)
  K_cupperD* = iUPcxCODE(K_upperD)
  K_cupperE* = iUPcxCODE(K_upperE)
  K_cupperF* = iUPcxCODE(K_upperF)
  K_cupperG* = iUPcxCODE(K_upperG)
  K_cupperH* = iUPcxCODE(K_upperH)
  K_cupperI* = iUPcxCODE(K_upperI)
  K_cupperJ* = iUPcxCODE(K_upperJ)
  K_cupperK* = iUPcxCODE(K_upperK)
  K_cupperL* = iUPcxCODE(K_upperL)
  K_cupperM* = iUPcxCODE(K_upperM)
  K_cupperN* = iUPcxCODE(K_upperN)
  K_cupperO* = iUPcxCODE(K_upperO)
  K_cupperP* = iUPcxCODE(K_upperP)
  K_cupperQ* = iUPcxCODE(K_upperQ)
  K_cupperR* = iUPcxCODE(K_upperR)
  K_cupperS* = iUPcxCODE(K_upperS)
  K_cupperT* = iUPcxCODE(K_upperT)
  K_cupperU* = iUPcxCODE(K_upperU)
  K_cupperV* = iUPcxCODE(K_upperV)
  K_cupperW* = iUPcxCODE(K_upperW)
  K_cupperX* = iUPcxCODE(K_upperX)
  K_cupperY* = iUPcxCODE(K_upperY)
  K_cupperZ* = iUPcxCODE(K_upperZ)
  K_c1* = iUPcxCODE(K_1)
  K_c2* = iUPcxCODE(K_2)
  K_c3* = iUPcxCODE(K_3)
  K_c4* = iUPcxCODE(K_4)
  K_c5* = iUPcxCODE(K_5)
  K_c6* = iUPcxCODE(K_6)
  K_c7* = iUPcxCODE(K_7)
  K_c8* = iUPcxCODE(K_8)
  K_c9* = iUPcxCODE(K_9)
  K_c0* = iUPcxCODE(K_0)
  K_cPlus* = iUPcxCODE(K_plus)
  K_cComma* = iUPcxCODE(K_comma)
  K_cMinus* = iUPcxCODE(K_minus)
  K_cPeriod* = iUPcxCODE(K_period)
  K_cSlash* = iUPcxCODE(K_slash)
  K_cSemicolon* = iUPcxCODE(K_semicolon)
  K_cEqual* = iUPcxCODE(K_equal)
  K_cBracketleft* = iUPcxCODE(K_bracketleft)
  K_cBracketright* = iUPcxCODE(K_bracketright)
  K_cBackslash* = iUPcxCODE(K_backslash)
  K_cAsterisk* = iUPcxCODE(K_asterisk)

  K_mupperA* = iUPmxCODE(K_upperA)
  K_mupperB* = iUPmxCODE(K_upperB)
  K_mupperC* = iUPmxCODE(K_upperC)
  K_mupperD* = iUPmxCODE(K_upperD)
  K_mupperE* = iUPmxCODE(K_upperE)
  K_mupperF* = iUPmxCODE(K_upperF)
  K_mupperG* = iUPmxCODE(K_upperG)
  K_mupperH* = iUPmxCODE(K_upperH)
  K_mupperI* = iUPmxCODE(K_upperI)
  K_mupperJ* = iUPmxCODE(K_upperJ)
  K_mupperK* = iUPmxCODE(K_upperK)
  K_mupperL* = iUPmxCODE(K_upperL)
  K_mupperM* = iUPmxCODE(K_upperM)
  K_mupperN* = iUPmxCODE(K_upperN)
  K_mupperO* = iUPmxCODE(K_upperO)
  K_mupperP* = iUPmxCODE(K_upperP)
  K_mupperQ* = iUPmxCODE(K_upperQ)
  K_mupperR* = iUPmxCODE(K_upperR)
  K_mupperS* = iUPmxCODE(K_upperS)
  K_mupperT* = iUPmxCODE(K_upperT)
  K_mupperU* = iUPmxCODE(K_upperU)
  K_mupperV* = iUPmxCODE(K_upperV)
  K_mupperW* = iUPmxCODE(K_upperW)
  K_mupperX* = iUPmxCODE(K_upperX)
  K_mupperY* = iUPmxCODE(K_upperY)
  K_mupperZ* = iUPmxCODE(K_upperZ)
  K_m1* = iUPmxCODE(K_1)
  K_m2* = iUPmxCODE(K_2)
  K_m3* = iUPmxCODE(K_3)
  K_m4* = iUPmxCODE(K_4)
  K_m5* = iUPmxCODE(K_5)
  K_m6* = iUPmxCODE(K_6)
  K_m7* = iUPmxCODE(K_7)
  K_m8* = iUPmxCODE(K_8)
  K_m9* = iUPmxCODE(K_9)
  K_m0* = iUPmxCODE(K_0)
  K_mPlus* = iUPmxCODE(K_plus)
  K_mComma* = iUPmxCODE(K_comma)
  K_mMinus* = iUPmxCODE(K_minus)
  K_mPeriod* = iUPmxCODE(K_period)
  K_mSlash* = iUPmxCODE(K_slash)
  K_mSemicolon* = iUPmxCODE(K_semicolon)
  K_mEqual* = iUPmxCODE(K_equal)
  K_mBracketleft* = iUPmxCODE(K_bracketleft)
  K_mBracketright* = iUPmxCODE(K_bracketright)
  K_mBackslash* = iUPmxCODE(K_backslash)
  K_mAsterisk* = iUPmxCODE(K_asterisk)

  K_yA* = iUPyxCODE(K_upperA)
  K_yB* = iUPyxCODE(K_upperB)
  K_yC* = iUPyxCODE(K_upperC)
  K_yD* = iUPyxCODE(K_upperD)
  K_yE* = iUPyxCODE(K_upperE)
  K_yF* = iUPyxCODE(K_upperF)
  K_yG* = iUPyxCODE(K_upperG)
  K_yH* = iUPyxCODE(K_upperH)
  K_yI* = iUPyxCODE(K_upperI)
  K_yJ* = iUPyxCODE(K_upperJ)
  K_yK* = iUPyxCODE(K_upperK)
  K_yL* = iUPyxCODE(K_upperL)
  K_yM* = iUPyxCODE(K_upperM)
  K_yN* = iUPyxCODE(K_upperN)
  K_yO* = iUPyxCODE(K_upperO)
  K_yP* = iUPyxCODE(K_upperP)
  K_yQ* = iUPyxCODE(K_upperQ)
  K_yR* = iUPyxCODE(K_upperR)
  K_yS* = iUPyxCODE(K_upperS)
  K_yT* = iUPyxCODE(K_upperT)
  K_yU* = iUPyxCODE(K_upperU)
  K_yV* = iUPyxCODE(K_upperV)
  K_yW* = iUPyxCODE(K_upperW)
  K_yX* = iUPyxCODE(K_upperX)
  K_yY* = iUPyxCODE(K_upperY)
  K_yZ* = iUPyxCODE(K_upperZ)
  K_y1* = iUPyxCODE(K_1)
  K_y2* = iUPyxCODE(K_2)
  K_y3* = iUPyxCODE(K_3)
  K_y4* = iUPyxCODE(K_4)
  K_y5* = iUPyxCODE(K_5)
  K_y6* = iUPyxCODE(K_6)
  K_y7* = iUPyxCODE(K_7)
  K_y8* = iUPyxCODE(K_8)
  K_y9* = iUPyxCODE(K_9)
  K_y0* = iUPyxCODE(K_0)
  K_yPlus* = iUPyxCODE(K_plus)
  K_yComma* = iUPyxCODE(K_comma)
  K_yMinus* = iUPyxCODE(K_minus)
  K_yPeriod* = iUPyxCODE(K_period)
  K_ySlash* = iUPyxCODE(K_slash)
  K_ySemicolon* = iUPyxCODE(K_semicolon)
  K_yEqual* = iUPyxCODE(K_equal)
  K_yBracketleft* = iUPyxCODE(K_bracketleft)
  K_yBracketright* = iUPyxCODE(K_bracketright)
  K_yBackslash* = iUPyxCODE(K_backslash)
  K_yAsterisk* = iUPyxCODE(K_asterisk)

proc controlsOpen*(): cint {.cdecl, importc: "IupControlsOpen", dynlib: dllname.}
proc controlsClose*() {.cdecl, importc: "IupControlsClose", dynlib: dllname.}

proc oldValOpen*() {.cdecl, importc: "IupOldValOpen", dynlib: dllname.}
proc oldTabsOpen*() {.cdecl, importc: "IupOldTabsOpen", dynlib: dllname.}

proc colorbar*(): PIhandle {.cdecl, importc: "IupColorbar", dynlib: dllname.}
proc cells*(): PIhandle {.cdecl, importc: "IupCells", dynlib: dllname.}
proc colorBrowser*(): PIhandle {.cdecl, importc: "IupColorBrowser", dynlib: dllname.}
proc gauge*(): PIhandle {.cdecl, importc: "IupGauge", dynlib: dllname.}
proc dial*(theType: cstring): PIhandle {.cdecl, importc: "IupDial", dynlib: dllname.}
proc matrix*(action: cstring): PIhandle {.cdecl, importc: "IupMatrix", dynlib: dllname.}

# IupMatrix utilities
proc matSetAttribute*(ih: PIhandle, name: cstring, lin, col: cint,
                      value: cstring) {.
                      cdecl, importc: "IupMatSetAttribute", dynlib: dllname.}
proc matStoreAttribute*(ih: PIhandle, name: cstring, lin, col: cint,
                        value: cstring) {.cdecl,
                        importc: "IupMatStoreAttribute", dynlib: dllname.}
proc matGetAttribute*(ih: PIhandle, name: cstring, lin, col: cint): cstring {.
  cdecl, importc: "IupMatGetAttribute", dynlib: dllname.}
proc matGetInt*(ih: PIhandle, name: cstring, lin, col: cint): cint {.
  cdecl, importc: "IupMatGetInt", dynlib: dllname.}
proc matGetFloat*(ih: PIhandle, name: cstring, lin, col: cint): cfloat {.
  cdecl, importc: "IupMatGetFloat", dynlib: dllname.}
proc matSetfAttribute*(ih: PIhandle, name: cstring, lin, col: cint,
                       format: cstring) {.cdecl,
                       importc: "IupMatSetfAttribute",
                       dynlib: dllname, varargs.}

# Used by IupColorbar
const
  IUP_PRIMARY* = -1
  IUP_SECONDARY* = -2

# Initialize PPlot widget class
proc pPlotOpen*() {.cdecl, importc: "IupPPlotOpen", dynlib: dllname.}

# Create an PPlot widget instance
proc pPlot*: PIhandle {.cdecl, importc: "IupPPlot", dynlib: dllname.}

# Add dataset to plot
proc pPlotBegin*(ih: PIhandle, strXdata: cint) {.
  cdecl, importc: "IupPPlotBegin", dynlib: dllname.}
proc pPlotAdd*(ih: PIhandle, x, y: cfloat) {.
  cdecl, importc: "IupPPlotAdd", dynlib: dllname.}
proc pPlotAddStr*(ih: PIhandle, x: cstring, y: cfloat) {.
  cdecl, importc: "IupPPlotAddStr", dynlib: dllname.}
proc pPlotEnd*(ih: PIhandle): cint {.
  cdecl, importc: "IupPPlotEnd", dynlib: dllname.}

proc pPlotInsertStr*(ih: PIhandle, index, sampleIndex: cint, x: cstring,
                     y: cfloat) {.cdecl, importc: "IupPPlotInsertStr",
                     dynlib: dllname.}
proc pPlotInsert*(ih: PIhandle, index, sampleIndex: cint,
                  x, y: cfloat) {.
                  cdecl, importc: "IupPPlotInsert", dynlib: dllname.}

# convert from plot coordinates to pixels
proc pPlotTransform*(ih: PIhandle, x, y: cfloat, ix, iy: var cint) {.
  cdecl, importc: "IupPPlotTransform", dynlib: dllname.}

# Plot on the given device. Uses a "cdCanvas*".
proc pPlotPaintTo*(ih: PIhandle, cnv: pointer) {.
  cdecl, importc: "IupPPlotPaintTo", dynlib: dllname.}


