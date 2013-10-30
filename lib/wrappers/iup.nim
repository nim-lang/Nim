#
#    Binding for the IUP GUI toolkit
#       (c) 2012 Andreas Rumpf
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

{.deadCodeElim: on.}

when defined(windows):
  const dllname = "iup(30|27|26|25|24).dll"
elif defined(macosx):
  const dllname = "libiup(3.0|2.7|2.6|2.5|2.4).dylib"
else:
  const dllname = "libiup(3.0|2.7|2.6|2.5|2.4).so.1"

const
  IUP_NAME* = "IUP - Portable User Interface"
  IUP_COPYRIGHT* = "Copyright (C) 1994-2009 Tecgraf, PUC-Rio."
  IUP_DESCRIPTION* = "Portable toolkit for building graphical user interfaces."
  constIUP_VERSION* = "3.0"
  constIUP_VERSION_NUMBER* = 300000
  constIUP_VERSION_DATE* = "2009/07/18"

type
  Ihandle {.pure.} = object
  PIhandle* = ptr Ihandle

  Icallback* = proc (arg: PIhandle): cint {.cdecl.}

#                      pre-definided dialogs
proc FileDlg*: PIhandle {.importc: "IupFileDlg", dynlib: dllname, cdecl.}
proc MessageDlg*: PIhandle {.importc: "IupMessageDlg", dynlib: dllname, cdecl.}
proc ColorDlg*: PIhandle {.importc: "IupColorDlg", dynlib: dllname, cdecl.}
proc FontDlg*: PIhandle {.importc: "IupFontDlg", dynlib: dllname, cdecl.}

proc GetFile*(arq: cstring): cint {.
  importc: "IupGetFile", dynlib: dllname, cdecl.}
proc Message*(title, msg: cstring) {.
  importc: "IupMessage", dynlib: dllname, cdecl.}
proc Messagef*(title, format: cstring) {.
  importc: "IupMessagef", dynlib: dllname, cdecl, varargs.}
proc Alarm*(title, msg, b1, b2, b3: cstring): cint {.
  importc: "IupAlarm", dynlib: dllname, cdecl.}
proc Scanf*(format: cstring): cint {.
  importc: "IupScanf", dynlib: dllname, cdecl, varargs.}
proc ListDialog*(theType: cint, title: cstring, size: cint,
                 list: cstringArray, op, max_col, max_lin: cint,
                 marks: ptr cint): cint {.
                 importc: "IupListDialog", dynlib: dllname, cdecl.}
proc GetText*(title, text: cstring): cint {.
  importc: "IupGetText", dynlib: dllname, cdecl.}
proc GetColor*(x, y: cint, r, g, b: var byte): cint {.
  importc: "IupGetColor", dynlib: dllname, cdecl.}

type
  Iparamcb* = proc (dialog: PIhandle, param_index: cint,
                    user_data: pointer): cint {.cdecl.}

proc GetParam*(title: cstring, action: Iparamcb, user_data: pointer,
               format: cstring): cint {.
               importc: "IupGetParam", cdecl, varargs, dynlib: dllname.}
proc GetParamv*(title: cstring, action: Iparamcb, user_data: pointer,
                format: cstring, param_count, param_extra: cint,
                param_data: pointer): cint {.
                importc: "IupGetParamv", cdecl, dynlib: dllname.}


#                      Functions

proc Open*(argc: ptr cint, argv: ptr cstringArray): cint {.
  importc: "IupOpen", cdecl, dynlib: dllname.}
proc Close*() {.importc: "IupClose", cdecl, dynlib: dllname.}
proc ImageLibOpen*() {.importc: "IupImageLibOpen", cdecl, dynlib: dllname.}

proc MainLoop*(): cint {.importc: "IupMainLoop", cdecl, dynlib: dllname,
                         discardable.}
proc LoopStep*(): cint {.importc: "IupLoopStep", cdecl, dynlib: dllname,
                         discardable.}
proc MainLoopLevel*(): cint {.importc: "IupMainLoopLevel", cdecl,
                              dynlib: dllname, discardable.}
proc Flush*() {.importc: "IupFlush", cdecl, dynlib: dllname.}
proc ExitLoop*() {.importc: "IupExitLoop", cdecl, dynlib: dllname.}

proc Update*(ih: PIhandle) {.importc: "IupUpdate", cdecl, dynlib: dllname.}
proc UpdateChildren*(ih: PIhandle) {.importc: "IupUpdateChildren", cdecl, dynlib: dllname.}
proc Redraw*(ih: PIhandle, children: cint) {.importc: "IupRedraw", cdecl, dynlib: dllname.}
proc Refresh*(ih: PIhandle) {.importc: "IupRefresh", cdecl, dynlib: dllname.}

proc MapFont*(iupfont: cstring): cstring {.importc: "IupMapFont", cdecl, dynlib: dllname.}
proc UnMapFont*(driverfont: cstring): cstring {.importc: "IupUnMapFont", cdecl, dynlib: dllname.}
proc Help*(url: cstring): cint {.importc: "IupHelp", cdecl, dynlib: dllname.}
proc Load*(filename: cstring): cstring {.importc: "IupLoad", cdecl, dynlib: dllname.}

proc IupVersion*(): cstring {.importc: "IupVersion", cdecl, dynlib: dllname.}
proc IupVersionDate*(): cstring {.importc: "IupVersionDate", cdecl, dynlib: dllname.}
proc IupVersionNumber*(): cint {.importc: "IupVersionNumber", cdecl, dynlib: dllname.}
proc SetLanguage*(lng: cstring) {.importc: "IupSetLanguage", cdecl, dynlib: dllname.}
proc GetLanguage*(): cstring {.importc: "IupGetLanguage", cdecl, dynlib: dllname.}

proc Destroy*(ih: PIhandle) {.importc: "IupDestroy", cdecl, dynlib: dllname.}
proc Detach*(child: PIhandle) {.importc: "IupDetach", cdecl, dynlib: dllname.}
proc Append*(ih, child: PIhandle): PIhandle {.
  importc: "IupAppend", cdecl, dynlib: dllname, discardable.}
proc Insert*(ih, ref_child, child: PIhandle): PIhandle {.
  importc: "IupInsert", cdecl, dynlib: dllname, discardable.}
proc GetChild*(ih: PIhandle, pos: cint): PIhandle {.
  importc: "IupGetChild", cdecl, dynlib: dllname.}
proc GetChildPos*(ih, child: PIhandle): cint {.
  importc: "IupGetChildPos", cdecl, dynlib: dllname.}
proc GetChildCount*(ih: PIhandle): cint {.
  importc: "IupGetChildCount", cdecl, dynlib: dllname.}
proc GetNextChild*(ih, child: PIhandle): PIhandle {.
  importc: "IupGetNextChild", cdecl, dynlib: dllname.}
proc GetBrother*(ih: PIhandle): PIhandle {.
  importc: "IupGetBrother", cdecl, dynlib: dllname.}
proc GetParent*(ih: PIhandle): PIhandle {.
  importc: "IupGetParent", cdecl, dynlib: dllname.}
proc GetDialog*(ih: PIhandle): PIhandle {.
  importc: "IupGetDialog", cdecl, dynlib: dllname.}
proc GetDialogChild*(ih: PIhandle, name: cstring): PIhandle {.
  importc: "IupGetDialogChild", cdecl, dynlib: dllname.}
proc Reparent*(ih, new_parent: PIhandle): cint {.
  importc: "IupReparent", cdecl, dynlib: dllname.}

proc Popup*(ih: PIhandle, x, y: cint): cint {.
  importc: "IupPopup", cdecl, dynlib: dllname, discardable.}
proc Show*(ih: PIhandle): cint {.
  importc: "IupShow", cdecl, dynlib: dllname, discardable.}
proc ShowXY*(ih: PIhandle, x, y: cint): cint {.
  importc: "IupShowXY", cdecl, dynlib: dllname, discardable.}
proc Hide*(ih: PIhandle): cint {.
  importc: "IupHide", cdecl, dynlib: dllname, discardable.}
proc Map*(ih: PIhandle): cint {.
  importc: "IupMap", cdecl, dynlib: dllname, discardable.}
proc Unmap*(ih: PIhandle) {.
  importc: "IupUnmap", cdecl, dynlib: dllname, discardable.}

proc SetAttribute*(ih: PIhandle, name, value: cstring) {.
  importc: "IupSetAttribute", cdecl, dynlib: dllname.}
proc StoreAttribute*(ih: PIhandle, name, value: cstring) {.
  importc: "IupStoreAttribute", cdecl, dynlib: dllname.}
proc SetAttributes*(ih: PIhandle, str: cstring): PIhandle {.
  importc: "IupSetAttributes", cdecl, dynlib: dllname.}
proc GetAttribute*(ih: PIhandle, name: cstring): cstring {.
  importc: "IupGetAttribute", cdecl, dynlib: dllname.}
proc GetAttributes*(ih: PIhandle): cstring {.
  importc: "IupGetAttributes", cdecl, dynlib: dllname.}
proc GetInt*(ih: PIhandle, name: cstring): cint {.
  importc: "IupGetInt", cdecl, dynlib: dllname.}
proc GetInt2*(ih: PIhandle, name: cstring): cint {.
  importc: "IupGetInt2", cdecl, dynlib: dllname.}
proc GetIntInt*(ih: PIhandle, name: cstring, i1, i2: var cint): cint {.
  importc: "IupGetIntInt", cdecl, dynlib: dllname.}
proc GetFloat*(ih: PIhandle, name: cstring): cfloat {.
  importc: "IupGetFloat", cdecl, dynlib: dllname.}
proc SetfAttribute*(ih: PIhandle, name, format: cstring) {.
  importc: "IupSetfAttribute", cdecl, dynlib: dllname, varargs.}
proc GetAllAttributes*(ih: PIhandle, names: cstringArray, n: cint): cint {.
  importc: "IupGetAllAttributes", cdecl, dynlib: dllname.}
proc SetAtt*(handle_name: cstring, ih: PIhandle, name: cstring): PIhandle {.
  importc: "IupSetAtt", cdecl, dynlib: dllname, varargs, discardable.}

proc SetGlobal*(name, value: cstring) {.
  importc: "IupSetGlobal", cdecl, dynlib: dllname.}
proc StoreGlobal*(name, value: cstring) {.
  importc: "IupStoreGlobal", cdecl, dynlib: dllname.}
proc GetGlobal*(name: cstring): cstring {.
  importc: "IupGetGlobal", cdecl, dynlib: dllname.}

proc SetFocus*(ih: PIhandle): PIhandle {.
  importc: "IupSetFocus", cdecl, dynlib: dllname.}
proc GetFocus*(): PIhandle {.
  importc: "IupGetFocus", cdecl, dynlib: dllname.}
proc PreviousField*(ih: PIhandle): PIhandle {.
  importc: "IupPreviousField", cdecl, dynlib: dllname.}
proc NextField*(ih: PIhandle): PIhandle {.
  importc: "IupNextField", cdecl, dynlib: dllname.}

proc GetCallback*(ih: PIhandle, name: cstring): Icallback {.
  importc: "IupGetCallback", cdecl, dynlib: dllname.}
proc SetCallback*(ih: PIhandle, name: cstring, func: Icallback): Icallback {.
  importc: "IupSetCallback", cdecl, dynlib: dllname, discardable.}

proc SetCallbacks*(ih: PIhandle, name: cstring, func: Icallback): PIhandle {.
  importc: "IupSetCallbacks", cdecl, dynlib: dllname, varargs, discardable.}

proc GetFunction*(name: cstring): Icallback {.
  importc: "IupGetFunction", cdecl, dynlib: dllname.}
proc SetFunction*(name: cstring, func: Icallback): Icallback {.
  importc: "IupSetFunction", cdecl, dynlib: dllname, discardable.}
proc GetActionName*(): cstring {.
  importc: "IupGetActionName", cdecl, dynlib: dllname.}

proc GetHandle*(name: cstring): PIhandle {.
  importc: "IupGetHandle", cdecl, dynlib: dllname.}
proc SetHandle*(name: cstring, ih: PIhandle): PIhandle {.
  importc: "IupSetHandle", cdecl, dynlib: dllname.}
proc GetAllNames*(names: cstringArray, n: cint): cint {.
  importc: "IupGetAllNames", cdecl, dynlib: dllname.}
proc GetAllDialogs*(names: cstringArray, n: cint): cint {.
  importc: "IupGetAllDialogs", cdecl, dynlib: dllname.}
proc GetName*(ih: PIhandle): cstring {.
  importc: "IupGetName", cdecl, dynlib: dllname.}

proc SetAttributeHandle*(ih: PIhandle, name: cstring, ih_named: PIhandle) {.
  importc: "IupSetAttributeHandle", cdecl, dynlib: dllname.}
proc GetAttributeHandle*(ih: PIhandle, name: cstring): PIhandle {.
  importc: "IupGetAttributeHandle", cdecl, dynlib: dllname.}

proc GetClassName*(ih: PIhandle): cstring {.
  importc: "IupGetClassName", cdecl, dynlib: dllname.}
proc GetClassType*(ih: PIhandle): cstring {.
  importc: "IupGetClassType", cdecl, dynlib: dllname.}
proc GetClassAttributes*(classname: cstring, names: cstringArray,
                         n: cint): cint {.
  importc: "IupGetClassAttributes", cdecl, dynlib: dllname.}
proc SaveClassAttributes*(ih: PIhandle) {.
  importc: "IupSaveClassAttributes", cdecl, dynlib: dllname.}
proc SetClassDefaultAttribute*(classname, name, value: cstring) {.
  importc: "IupSetClassDefaultAttribute", cdecl, dynlib: dllname.}

proc Create*(classname: cstring): PIhandle {.
  importc: "IupCreate", cdecl, dynlib: dllname.}
proc Createv*(classname: cstring, params: pointer): PIhandle {.
  importc: "IupCreatev", cdecl, dynlib: dllname.}
proc Createp*(classname: cstring, first: pointer): PIhandle {.
  importc: "IupCreatep", cdecl, dynlib: dllname, varargs.}

proc Fill*(): PIhandle {.importc: "IupFill", cdecl, dynlib: dllname.}
proc Radio*(child: PIhandle): PIhandle {.
  importc: "IupRadio", cdecl, dynlib: dllname.}
proc Vbox*(child: PIhandle): PIhandle {.
  importc: "IupVbox", cdecl, dynlib: dllname, varargs.}
proc Vboxv*(children: ptr PIhandle): PIhandle {.
  importc: "IupVboxv", cdecl, dynlib: dllname.}
proc Zbox*(child: PIhandle): PIhandle {.
  importc: "IupZbox", cdecl, dynlib: dllname, varargs.}
proc Zboxv*(children: ptr PIhandle): PIhandle {.
  importc: "IupZboxv", cdecl, dynlib: dllname.}
proc Hbox*(child: PIhandle): PIhandle {.
  importc: "IupHbox", cdecl, dynlib: dllname, varargs.}
proc Hboxv*(children: ptr PIhandle): PIhandle {.
  importc: "IupHboxv", cdecl, dynlib: dllname.}

proc Normalizer*(ih_first: PIhandle): PIhandle {.
  importc: "IupNormalizer", cdecl, dynlib: dllname, varargs.}
proc Normalizerv*(ih_list: ptr PIhandle): PIhandle {.
  importc: "IupNormalizerv", cdecl, dynlib: dllname.}

proc Cbox*(child: PIhandle): PIhandle {.
  importc: "IupCbox", cdecl, dynlib: dllname, varargs.}
proc Cboxv*(children: ptr PIhandle): PIhandle {.
  importc: "IupCboxv", cdecl, dynlib: dllname.}
proc Sbox*(child: PIhandle): PIhandle {.
  importc: "IupSbox", cdecl, dynlib: dllname.}

proc Frame*(child: PIhandle): PIhandle {.
  importc: "IupFrame", cdecl, dynlib: dllname.}

proc Image*(width, height: cint, pixmap: pointer): PIhandle {.
  importc: "IupImage", cdecl, dynlib: dllname.}
proc ImageRGB*(width, height: cint, pixmap: pointer): PIhandle {.
  importc: "IupImageRGB", cdecl, dynlib: dllname.}
proc ImageRGBA*(width, height: cint, pixmap: pointer): PIhandle {.
  importc: "IupImageRGBA", cdecl, dynlib: dllname.}

proc Item*(title, action: cstring): PIhandle {.
  importc: "IupItem", cdecl, dynlib: dllname.}
proc Submenu*(title: cstring, child: PIhandle): PIhandle {.
  importc: "IupSubmenu", cdecl, dynlib: dllname.}
proc Separator*(): PIhandle {.
  importc: "IupSeparator", cdecl, dynlib: dllname.}
proc Menu*(child: PIhandle): PIhandle {.
  importc: "IupMenu", cdecl, dynlib: dllname, varargs.}
proc Menuv*(children: ptr PIhandle): PIhandle {.
  importc: "IupMenuv", cdecl, dynlib: dllname.}

proc Button*(title, action: cstring): PIhandle {.
  importc: "IupButton", cdecl, dynlib: dllname.}
proc Canvas*(action: cstring): PIhandle {.
  importc: "IupCanvas", cdecl, dynlib: dllname.}
proc Dialog*(child: PIhandle): PIhandle {.
  importc: "IupDialog", cdecl, dynlib: dllname.}
proc User*(): PIhandle {.
  importc: "IupUser", cdecl, dynlib: dllname.}
proc Label*(title: cstring): PIhandle {.
  importc: "IupLabel", cdecl, dynlib: dllname.}
proc List*(action: cstring): PIhandle {.
  importc: "IupList", cdecl, dynlib: dllname.}
proc Text*(action: cstring): PIhandle {.
  importc: "IupText", cdecl, dynlib: dllname.}
proc MultiLine*(action: cstring): PIhandle {.
  importc: "IupMultiLine", cdecl, dynlib: dllname.}
proc Toggle*(title, action: cstring): PIhandle {.
  importc: "IupToggle", cdecl, dynlib: dllname.}
proc Timer*(): PIhandle {.
  importc: "IupTimer", cdecl, dynlib: dllname.}
proc ProgressBar*(): PIhandle {.
  importc: "IupProgressBar", cdecl, dynlib: dllname.}
proc Val*(theType: cstring): PIhandle {.
  importc: "IupVal", cdecl, dynlib: dllname.}
proc Tabs*(child: PIhandle): PIhandle {.
  importc: "IupTabs", cdecl, dynlib: dllname, varargs.}
proc Tabsv*(children: ptr PIhandle): PIhandle {.
  importc: "IupTabsv", cdecl, dynlib: dllname.}
proc Tree*(): PIhandle {.importc: "IupTree", cdecl, dynlib: dllname.}

proc Spin*(): PIhandle {.importc: "IupSpin", cdecl, dynlib: dllname.}
proc Spinbox*(child: PIhandle): PIhandle {.
  importc: "IupSpinbox", cdecl, dynlib: dllname.}

# IupText utilities
proc TextConvertLinColToPos*(ih: PIhandle, lin, col: cint, pos: var cint) {.
  importc: "IupTextConvertLinColToPos", cdecl, dynlib: dllname.}
proc TextConvertPosToLinCol*(ih: PIhandle, pos: cint, lin, col: var cint) {.
  importc: "IupTextConvertPosToLinCol", cdecl, dynlib: dllname.}

proc ConvertXYToPos*(ih: PIhandle, x, y: cint): cint {.
  importc: "IupConvertXYToPos", cdecl, dynlib: dllname.}

# IupTree utilities
proc TreeSetUserId*(ih: PIhandle, id: cint, userid: pointer): cint {.
  importc: "IupTreeSetUserId", cdecl, dynlib: dllname, discardable.}
proc TreeGetUserId*(ih: PIhandle, id: cint): pointer {.
  importc: "IupTreeGetUserId", cdecl, dynlib: dllname.}
proc TreeGetId*(ih: PIhandle, userid: pointer): cint {.
  importc: "IupTreeGetId", cdecl, dynlib: dllname.}

proc TreeSetAttribute*(ih: PIhandle, name: cstring, id: cint, value: cstring) {.
  importc: "IupTreeSetAttribute", cdecl, dynlib: dllname.}
proc TreeStoreAttribute*(ih: PIhandle, name: cstring, id: cint, value: cstring) {.
  importc: "IupTreeStoreAttribute", cdecl, dynlib: dllname.}
proc TreeGetAttribute*(ih: PIhandle, name: cstring, id: cint): cstring {.
  importc: "IupTreeGetAttribute", cdecl, dynlib: dllname.}
proc TreeGetInt*(ih: PIhandle, name: cstring, id: cint): cint {.
  importc: "IupTreeGetInt", cdecl, dynlib: dllname.}
proc TreeGetFloat*(ih: PIhandle, name: cstring, id: cint): cfloat {.
  importc: "IupTreeGetFloat", cdecl, dynlib: dllname.}
proc TreeSetfAttribute*(ih: PIhandle, name: cstring, id: cint, format: cstring) {.
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

proc IUPxCODE*(c: cint): cint = return c + cint(128) # Normal (must be above 128)
proc IUPsxCODE*(c: cint): cint =
  return c + cint(256)
  # Shift (must have range to include the standard keys and the normal
  # extended keys, so must be above 256

proc IUPcxCODE*(c: cint): cint = return c + cint(512) # Ctrl
proc IUPmxCODE*(c: cint): cint = return c + cint(768) # Alt
proc IUPyxCODE*(c: cint): cint = return c + cint(1024) # Sys (Win or Apple)

const
  IUP_NUMMAXCODES* = 1280 ## 5*256=1280  Normal+Shift+Ctrl+Alt+Sys

  K_HOME* = IUPxCODE(1)
  K_UP* = IUPxCODE(2)
  K_PGUP* = IUPxCODE(3)
  K_LEFT* = IUPxCODE(4)
  K_MIDDLE* = IUPxCODE(5)
  K_RIGHT* = IUPxCODE(6)
  K_END* = IUPxCODE(7)
  K_DOWN* = IUPxCODE(8)
  K_PGDN* = IUPxCODE(9)
  K_INS* = IUPxCODE(10)
  K_DEL* = IUPxCODE(11)
  K_PAUSE* = IUPxCODE(12)
  K_ESC* = IUPxCODE(13)
  K_ccedilla* = IUPxCODE(14)
  K_F1* = IUPxCODE(15)
  K_F2* = IUPxCODE(16)
  K_F3* = IUPxCODE(17)
  K_F4* = IUPxCODE(18)
  K_F5* = IUPxCODE(19)
  K_F6* = IUPxCODE(20)
  K_F7* = IUPxCODE(21)
  K_F8* = IUPxCODE(22)
  K_F9* = IUPxCODE(23)
  K_F10* = IUPxCODE(24)
  K_F11* = IUPxCODE(25)
  K_F12* = IUPxCODE(26)
  K_Print* = IUPxCODE(27)
  K_Menu* = IUPxCODE(28)

  K_acute* = IUPxCODE(29) # no Shift/Ctrl/Alt

  K_sHOME* = IUPsxCODE(K_HOME)
  K_sUP* = IUPsxCODE(K_UP)
  K_sPGUP* = IUPsxCODE(K_PGUP)
  K_sLEFT* = IUPsxCODE(K_LEFT)
  K_sMIDDLE* = IUPsxCODE(K_MIDDLE)
  K_sRIGHT* = IUPsxCODE(K_RIGHT)
  K_sEND* = IUPsxCODE(K_END)
  K_sDOWN* = IUPsxCODE(K_DOWN)
  K_sPGDN* = IUPsxCODE(K_PGDN)
  K_sINS* = IUPsxCODE(K_INS)
  K_sDEL* = IUPsxCODE(K_DEL)
  K_sSP* = IUPsxCODE(K_SP)
  K_sTAB* = IUPsxCODE(K_TAB)
  K_sCR* = IUPsxCODE(K_CR)
  K_sBS* = IUPsxCODE(K_BS)
  K_sPAUSE* = IUPsxCODE(K_PAUSE)
  K_sESC* = IUPsxCODE(K_ESC)
  K_sCcedilla* = IUPsxCODE(K_ccedilla)
  K_sF1* = IUPsxCODE(K_F1)
  K_sF2* = IUPsxCODE(K_F2)
  K_sF3* = IUPsxCODE(K_F3)
  K_sF4* = IUPsxCODE(K_F4)
  K_sF5* = IUPsxCODE(K_F5)
  K_sF6* = IUPsxCODE(K_F6)
  K_sF7* = IUPsxCODE(K_F7)
  K_sF8* = IUPsxCODE(K_F8)
  K_sF9* = IUPsxCODE(K_F9)
  K_sF10* = IUPsxCODE(K_F10)
  K_sF11* = IUPsxCODE(K_F11)
  K_sF12* = IUPsxCODE(K_F12)
  K_sPrint* = IUPsxCODE(K_Print)
  K_sMenu* = IUPsxCODE(K_Menu)

  K_cHOME* = IUPcxCODE(K_HOME)
  K_cUP* = IUPcxCODE(K_UP)
  K_cPGUP* = IUPcxCODE(K_PGUP)
  K_cLEFT* = IUPcxCODE(K_LEFT)
  K_cMIDDLE* = IUPcxCODE(K_MIDDLE)
  K_cRIGHT* = IUPcxCODE(K_RIGHT)
  K_cEND* = IUPcxCODE(K_END)
  K_cDOWN* = IUPcxCODE(K_DOWN)
  K_cPGDN* = IUPcxCODE(K_PGDN)
  K_cINS* = IUPcxCODE(K_INS)
  K_cDEL* = IUPcxCODE(K_DEL)
  K_cSP* = IUPcxCODE(K_SP)
  K_cTAB* = IUPcxCODE(K_TAB)
  K_cCR* = IUPcxCODE(K_CR)
  K_cBS* = IUPcxCODE(K_BS)
  K_cPAUSE* = IUPcxCODE(K_PAUSE)
  K_cESC* = IUPcxCODE(K_ESC)
  K_cCcedilla* = IUPcxCODE(K_ccedilla)
  K_cF1* = IUPcxCODE(K_F1)
  K_cF2* = IUPcxCODE(K_F2)
  K_cF3* = IUPcxCODE(K_F3)
  K_cF4* = IUPcxCODE(K_F4)
  K_cF5* = IUPcxCODE(K_F5)
  K_cF6* = IUPcxCODE(K_F6)
  K_cF7* = IUPcxCODE(K_F7)
  K_cF8* = IUPcxCODE(K_F8)
  K_cF9* = IUPcxCODE(K_F9)
  K_cF10* = IUPcxCODE(K_F10)
  K_cF11* = IUPcxCODE(K_F11)
  K_cF12* = IUPcxCODE(K_F12)
  K_cPrint* = IUPcxCODE(K_Print)
  K_cMenu* = IUPcxCODE(K_Menu)

  K_mHOME* = IUPmxCODE(K_HOME)
  K_mUP* = IUPmxCODE(K_UP)
  K_mPGUP* = IUPmxCODE(K_PGUP)
  K_mLEFT* = IUPmxCODE(K_LEFT)
  K_mMIDDLE* = IUPmxCODE(K_MIDDLE)
  K_mRIGHT* = IUPmxCODE(K_RIGHT)
  K_mEND* = IUPmxCODE(K_END)
  K_mDOWN* = IUPmxCODE(K_DOWN)
  K_mPGDN* = IUPmxCODE(K_PGDN)
  K_mINS* = IUPmxCODE(K_INS)
  K_mDEL* = IUPmxCODE(K_DEL)
  K_mSP* = IUPmxCODE(K_SP)
  K_mTAB* = IUPmxCODE(K_TAB)
  K_mCR* = IUPmxCODE(K_CR)
  K_mBS* = IUPmxCODE(K_BS)
  K_mPAUSE* = IUPmxCODE(K_PAUSE)
  K_mESC* = IUPmxCODE(K_ESC)
  K_mCcedilla* = IUPmxCODE(K_ccedilla)
  K_mF1* = IUPmxCODE(K_F1)
  K_mF2* = IUPmxCODE(K_F2)
  K_mF3* = IUPmxCODE(K_F3)
  K_mF4* = IUPmxCODE(K_F4)
  K_mF5* = IUPmxCODE(K_F5)
  K_mF6* = IUPmxCODE(K_F6)
  K_mF7* = IUPmxCODE(K_F7)
  K_mF8* = IUPmxCODE(K_F8)
  K_mF9* = IUPmxCODE(K_F9)
  K_mF10* = IUPmxCODE(K_F10)
  K_mF11* = IUPmxCODE(K_F11)
  K_mF12* = IUPmxCODE(K_F12)
  K_mPrint* = IUPmxCODE(K_Print)
  K_mMenu* = IUPmxCODE(K_Menu)

  K_yHOME* = IUPyxCODE(K_HOME)
  K_yUP* = IUPyxCODE(K_UP)
  K_yPGUP* = IUPyxCODE(K_PGUP)
  K_yLEFT* = IUPyxCODE(K_LEFT)
  K_yMIDDLE* = IUPyxCODE(K_MIDDLE)
  K_yRIGHT* = IUPyxCODE(K_RIGHT)
  K_yEND* = IUPyxCODE(K_END)
  K_yDOWN* = IUPyxCODE(K_DOWN)
  K_yPGDN* = IUPyxCODE(K_PGDN)
  K_yINS* = IUPyxCODE(K_INS)
  K_yDEL* = IUPyxCODE(K_DEL)
  K_ySP* = IUPyxCODE(K_SP)
  K_yTAB* = IUPyxCODE(K_TAB)
  K_yCR* = IUPyxCODE(K_CR)
  K_yBS* = IUPyxCODE(K_BS)
  K_yPAUSE* = IUPyxCODE(K_PAUSE)
  K_yESC* = IUPyxCODE(K_ESC)
  K_yCcedilla* = IUPyxCODE(K_ccedilla)
  K_yF1* = IUPyxCODE(K_F1)
  K_yF2* = IUPyxCODE(K_F2)
  K_yF3* = IUPyxCODE(K_F3)
  K_yF4* = IUPyxCODE(K_F4)
  K_yF5* = IUPyxCODE(K_F5)
  K_yF6* = IUPyxCODE(K_F6)
  K_yF7* = IUPyxCODE(K_F7)
  K_yF8* = IUPyxCODE(K_F8)
  K_yF9* = IUPyxCODE(K_F9)
  K_yF10* = IUPyxCODE(K_F10)
  K_yF11* = IUPyxCODE(K_F11)
  K_yF12* = IUPyxCODE(K_F12)
  K_yPrint* = IUPyxCODE(K_Print)
  K_yMenu* = IUPyxCODE(K_Menu)

  K_sPlus* = IUPsxCODE(K_plus)
  K_sComma* = IUPsxCODE(K_comma)
  K_sMinus* = IUPsxCODE(K_minus)
  K_sPeriod* = IUPsxCODE(K_period)
  K_sSlash* = IUPsxCODE(K_slash)
  K_sAsterisk* = IUPsxCODE(K_asterisk)

  K_cupperA* = IUPcxCODE(K_upperA)
  K_cupperB* = IUPcxCODE(K_upperB)
  K_cupperC* = IUPcxCODE(K_upperC)
  K_cupperD* = IUPcxCODE(K_upperD)
  K_cupperE* = IUPcxCODE(K_upperE)
  K_cupperF* = IUPcxCODE(K_upperF)
  K_cupperG* = IUPcxCODE(K_upperG)
  K_cupperH* = IUPcxCODE(K_upperH)
  K_cupperI* = IUPcxCODE(K_upperI)
  K_cupperJ* = IUPcxCODE(K_upperJ)
  K_cupperK* = IUPcxCODE(K_upperK)
  K_cupperL* = IUPcxCODE(K_upperL)
  K_cupperM* = IUPcxCODE(K_upperM)
  K_cupperN* = IUPcxCODE(K_upperN)
  K_cupperO* = IUPcxCODE(K_upperO)
  K_cupperP* = IUPcxCODE(K_upperP)
  K_cupperQ* = IUPcxCODE(K_upperQ)
  K_cupperR* = IUPcxCODE(K_upperR)
  K_cupperS* = IUPcxCODE(K_upperS)
  K_cupperT* = IUPcxCODE(K_upperT)
  K_cupperU* = IUPcxCODE(K_upperU)
  K_cupperV* = IUPcxCODE(K_upperV)
  K_cupperW* = IUPcxCODE(K_upperW)
  K_cupperX* = IUPcxCODE(K_upperX)
  K_cupperY* = IUPcxCODE(K_upperY)
  K_cupperZ* = IUPcxCODE(K_upperZ)
  K_c1* = IUPcxCODE(K_1)
  K_c2* = IUPcxCODE(K_2)
  K_c3* = IUPcxCODE(K_3)
  K_c4* = IUPcxCODE(K_4)
  K_c5* = IUPcxCODE(K_5)
  K_c6* = IUPcxCODE(K_6)
  K_c7* = IUPcxCODE(K_7)
  K_c8* = IUPcxCODE(K_8)
  K_c9* = IUPcxCODE(K_9)
  K_c0* = IUPcxCODE(K_0)
  K_cPlus* = IUPcxCODE(K_plus)
  K_cComma* = IUPcxCODE(K_comma)
  K_cMinus* = IUPcxCODE(K_minus)
  K_cPeriod* = IUPcxCODE(K_period)
  K_cSlash* = IUPcxCODE(K_slash)
  K_cSemicolon* = IUPcxCODE(K_semicolon)
  K_cEqual* = IUPcxCODE(K_equal)
  K_cBracketleft* = IUPcxCODE(K_bracketleft)
  K_cBracketright* = IUPcxCODE(K_bracketright)
  K_cBackslash* = IUPcxCODE(K_backslash)
  K_cAsterisk* = IUPcxCODE(K_asterisk)

  K_mupperA* = IUPmxCODE(K_upperA)
  K_mupperB* = IUPmxCODE(K_upperB)
  K_mupperC* = IUPmxCODE(K_upperC)
  K_mupperD* = IUPmxCODE(K_upperD)
  K_mupperE* = IUPmxCODE(K_upperE)
  K_mupperF* = IUPmxCODE(K_upperF)
  K_mupperG* = IUPmxCODE(K_upperG)
  K_mupperH* = IUPmxCODE(K_upperH)
  K_mupperI* = IUPmxCODE(K_upperI)
  K_mupperJ* = IUPmxCODE(K_upperJ)
  K_mupperK* = IUPmxCODE(K_upperK)
  K_mupperL* = IUPmxCODE(K_upperL)
  K_mupperM* = IUPmxCODE(K_upperM)
  K_mupperN* = IUPmxCODE(K_upperN)
  K_mupperO* = IUPmxCODE(K_upperO)
  K_mupperP* = IUPmxCODE(K_upperP)
  K_mupperQ* = IUPmxCODE(K_upperQ)
  K_mupperR* = IUPmxCODE(K_upperR)
  K_mupperS* = IUPmxCODE(K_upperS)
  K_mupperT* = IUPmxCODE(K_upperT)
  K_mupperU* = IUPmxCODE(K_upperU)
  K_mupperV* = IUPmxCODE(K_upperV)
  K_mupperW* = IUPmxCODE(K_upperW)
  K_mupperX* = IUPmxCODE(K_upperX)
  K_mupperY* = IUPmxCODE(K_upperY)
  K_mupperZ* = IUPmxCODE(K_upperZ)
  K_m1* = IUPmxCODE(K_1)
  K_m2* = IUPmxCODE(K_2)
  K_m3* = IUPmxCODE(K_3)
  K_m4* = IUPmxCODE(K_4)
  K_m5* = IUPmxCODE(K_5)
  K_m6* = IUPmxCODE(K_6)
  K_m7* = IUPmxCODE(K_7)
  K_m8* = IUPmxCODE(K_8)
  K_m9* = IUPmxCODE(K_9)
  K_m0* = IUPmxCODE(K_0)
  K_mPlus* = IUPmxCODE(K_plus)
  K_mComma* = IUPmxCODE(K_comma)
  K_mMinus* = IUPmxCODE(K_minus)
  K_mPeriod* = IUPmxCODE(K_period)
  K_mSlash* = IUPmxCODE(K_slash)
  K_mSemicolon* = IUPmxCODE(K_semicolon)
  K_mEqual* = IUPmxCODE(K_equal)
  K_mBracketleft* = IUPmxCODE(K_bracketleft)
  K_mBracketright* = IUPmxCODE(K_bracketright)
  K_mBackslash* = IUPmxCODE(K_backslash)
  K_mAsterisk* = IUPmxCODE(K_asterisk)

  K_yA* = IUPyxCODE(K_upperA)
  K_yB* = IUPyxCODE(K_upperB)
  K_yC* = IUPyxCODE(K_upperC)
  K_yD* = IUPyxCODE(K_upperD)
  K_yE* = IUPyxCODE(K_upperE)
  K_yF* = IUPyxCODE(K_upperF)
  K_yG* = IUPyxCODE(K_upperG)
  K_yH* = IUPyxCODE(K_upperH)
  K_yI* = IUPyxCODE(K_upperI)
  K_yJ* = IUPyxCODE(K_upperJ)
  K_yK* = IUPyxCODE(K_upperK)
  K_yL* = IUPyxCODE(K_upperL)
  K_yM* = IUPyxCODE(K_upperM)
  K_yN* = IUPyxCODE(K_upperN)
  K_yO* = IUPyxCODE(K_upperO)
  K_yP* = IUPyxCODE(K_upperP)
  K_yQ* = IUPyxCODE(K_upperQ)
  K_yR* = IUPyxCODE(K_upperR)
  K_yS* = IUPyxCODE(K_upperS)
  K_yT* = IUPyxCODE(K_upperT)
  K_yU* = IUPyxCODE(K_upperU)
  K_yV* = IUPyxCODE(K_upperV)
  K_yW* = IUPyxCODE(K_upperW)
  K_yX* = IUPyxCODE(K_upperX)
  K_yY* = IUPyxCODE(K_upperY)
  K_yZ* = IUPyxCODE(K_upperZ)
  K_y1* = IUPyxCODE(K_1)
  K_y2* = IUPyxCODE(K_2)
  K_y3* = IUPyxCODE(K_3)
  K_y4* = IUPyxCODE(K_4)
  K_y5* = IUPyxCODE(K_5)
  K_y6* = IUPyxCODE(K_6)
  K_y7* = IUPyxCODE(K_7)
  K_y8* = IUPyxCODE(K_8)
  K_y9* = IUPyxCODE(K_9)
  K_y0* = IUPyxCODE(K_0)
  K_yPlus* = IUPyxCODE(K_plus)
  K_yComma* = IUPyxCODE(K_comma)
  K_yMinus* = IUPyxCODE(K_minus)
  K_yPeriod* = IUPyxCODE(K_period)
  K_ySlash* = IUPyxCODE(K_slash)
  K_ySemicolon* = IUPyxCODE(K_semicolon)
  K_yEqual* = IUPyxCODE(K_equal)
  K_yBracketleft* = IUPyxCODE(K_bracketleft)
  K_yBracketright* = IUPyxCODE(K_bracketright)
  K_yBackslash* = IUPyxCODE(K_backslash)
  K_yAsterisk* = IUPyxCODE(K_asterisk)

proc ControlsOpen*(): cint {.cdecl, importc: "IupControlsOpen", dynlib: dllname.}
proc ControlsClose*() {.cdecl, importc: "IupControlsClose", dynlib: dllname.}

proc OldValOpen*() {.cdecl, importc: "IupOldValOpen", dynlib: dllname.}
proc OldTabsOpen*() {.cdecl, importc: "IupOldTabsOpen", dynlib: dllname.}

proc Colorbar*(): PIhandle {.cdecl, importc: "IupColorbar", dynlib: dllname.}
proc Cells*(): PIhandle {.cdecl, importc: "IupCells", dynlib: dllname.}
proc ColorBrowser*(): PIhandle {.cdecl, importc: "IupColorBrowser", dynlib: dllname.}
proc Gauge*(): PIhandle {.cdecl, importc: "IupGauge", dynlib: dllname.}
proc Dial*(theType: cstring): PIhandle {.cdecl, importc: "IupDial", dynlib: dllname.}
proc Matrix*(action: cstring): PIhandle {.cdecl, importc: "IupMatrix", dynlib: dllname.}

# IupMatrix utilities
proc MatSetAttribute*(ih: PIhandle, name: cstring, lin, col: cint,
                      value: cstring) {.
                      cdecl, importc: "IupMatSetAttribute", dynlib: dllname.}
proc MatStoreAttribute*(ih: PIhandle, name: cstring, lin, col: cint,
                        value: cstring) {.cdecl,
                        importc: "IupMatStoreAttribute", dynlib: dllname.}
proc MatGetAttribute*(ih: PIhandle, name: cstring, lin, col: cint): cstring {.
  cdecl, importc: "IupMatGetAttribute", dynlib: dllname.}
proc MatGetInt*(ih: PIhandle, name: cstring, lin, col: cint): cint {.
  cdecl, importc: "IupMatGetInt", dynlib: dllname.}
proc MatGetFloat*(ih: PIhandle, name: cstring, lin, col: cint): cfloat {.
  cdecl, importc: "IupMatGetFloat", dynlib: dllname.}
proc MatSetfAttribute*(ih: PIhandle, name: cstring, lin, col: cint,
                       format: cstring) {.cdecl,
                       importc: "IupMatSetfAttribute",
                       dynlib: dllname, varargs.}

# Used by IupColorbar
const
  IUP_PRIMARY* = -1
  IUP_SECONDARY* = -2

# Initialize PPlot widget class
proc PPlotOpen*() {.cdecl, importc: "IupPPlotOpen", dynlib: dllname.}

# Create an PPlot widget instance
proc PPlot*: PIhandle {.cdecl, importc: "IupPPlot", dynlib: dllname.}

# Add dataset to plot
proc PPlotBegin*(ih: PIhandle, strXdata: cint) {.
  cdecl, importc: "IupPPlotBegin", dynlib: dllname.}
proc PPlotAdd*(ih: PIhandle, x, y: cfloat) {.
  cdecl, importc: "IupPPlotAdd", dynlib: dllname.}
proc PPlotAddStr*(ih: PIhandle, x: cstring, y: cfloat) {.
  cdecl, importc: "IupPPlotAddStr", dynlib: dllname.}
proc PPlotEnd*(ih: PIhandle): cint {.
  cdecl, importc: "IupPPlotEnd", dynlib: dllname.}

proc PPlotInsertStr*(ih: PIhandle, index, sample_index: cint, x: cstring,
                     y: cfloat) {.cdecl, importc: "IupPPlotInsertStr",
                     dynlib: dllname.}
proc PPlotInsert*(ih: PIhandle, index, sample_index: cint,
                  x, y: cfloat) {.
                  cdecl, importc: "IupPPlotInsert", dynlib: dllname.}

# convert from plot coordinates to pixels
proc PPlotTransform*(ih: PIhandle, x, y: cfloat, ix, iy: var cint) {.
  cdecl, importc: "IupPPlotTransform", dynlib: dllname.}

# Plot on the given device. Uses a "cdCanvas*".
proc PPlotPaintTo*(ih: PIhandle, cnv: pointer) {.
  cdecl, importc: "IupPPlotPaintTo", dynlib: dllname.}


