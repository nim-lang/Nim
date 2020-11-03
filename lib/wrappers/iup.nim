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


## Wrapper for the `IUP native GUI library <http://webserver2.tecgraf.puc-rio.br/iup>`_.
##
##
## Examples
## ========
##
## (Screenshots are illustrative only).
##
## Hello World
## -----------
##
## .. image:: http://webserver2.tecgraf.puc-rio.br/iup/en/tutorial/example2_1.png
##
## .. code-block:: nim
##   import os, iup
##   var argc = create(cint)
##   argc[] = paramCount().cint
##   var argv = allocCstringArray(commandLineParams())
##   assert open(argc, argv.addr) == 0         # UIP requires calling open()
##   message(r"Hello world 1", r"Hello world") # Message popup
##   close()                                   # UIP requires calling close()
##
## Multi-line Text widget
## ----------------------
##
## .. image:: http://webserver2.tecgraf.puc-rio.br/iup/en/tutorial/example3_1.png
##
## .. code-block:: nim
##   import os, iup
##   var argc = create(cint)
##   argc[] = paramCount().cint
##   var argv = allocCstringArray(commandLineParams())
##   assert open(argc, argv.addr) == 0            # UIP requires open()
##   let textarea = text(nil)                     # Text widget.
##   setAttribute(textarea, r"MULTILINE", r"YES") # Set text widget to multiline.
##   setAttribute(textarea, r"EXPAND", r"YES")    # Set text widget to auto expand.
##   let layout = vbox(textarea)                  # Vertical layout.
##   let window = dialog(layout)                  # Dialog window.
##   setAttribute(window, "TITLE", "Nim Notepad") # Set window title.
##   window.show()                                # Show window.
##   mainLoop()                                   # Main loop.
##   close()                                      # UIP requires calling close()
##
## Progressbar Dialog
## ------------------
##
## .. image:: https://webserver2.tecgraf.puc-rio.br/iup/en/dlg/images/progressdlg.png
##
## * https://webserver2.tecgraf.puc-rio.br/iup/en/dlg/iupprogressdlg.html
##
## .. code-block:: nim
##   import iup
##   var fakeArgv = allocCStringArray([])
##   discard open(create(cint), fakeArgv.addr)
##   let dialogLoading = progressDlg()
##   dialogLoading.setAttribute("STATE", "UNDEFINED")
##   dialogLoading.show()
##   mainLoop()
##   close()
##
## Detachable Widget
## -----------------
##
## .. image:: https://webserver2.tecgraf.puc-rio.br/iup/en/elem/images/iupdbox_detached.png
##
## * https://webserver2.tecgraf.puc-rio.br/iup/en/elem/iupdetachbox.html
##
## .. code-block:: nim
##   import iup
##   var fakeArgv = allocCStringArray([])
##   discard open(create(cint), fakeArgv.addr)
##   let widget = label("Hello World")
##   let container = detachBox(widget)
##   let window = dialog(container)
##   window.show()
##   mainLoop()
##   close()
##
## Date Picker
## -----------
##
## .. image:: https://webserver2.tecgraf.puc-rio.br/iup/en/elem/images/iupdatepick_gtk_open.png
##
## * https://webserver2.tecgraf.puc-rio.br/iup/en/elem/iupdatepick.html
##
## .. code-block:: nim
##   import iup
##   var fakeArgv = allocCStringArray([])
##   discard open(create(cint), fakeArgv.addr)
##   let widget = datePick()
##   let window = dialog(widget)
##   window.show()
##   mainLoop()
##   close()
##
## Web Widget
## ----------
##
## .. image:: http://webserver2.tecgraf.puc-rio.br/iup/en/ctrl/images/iupwebbrowser.png
##
## * https://webserver2.tecgraf.puc-rio.br/iup/en/ctrl/iupweb.html
##
## .. code::nim
##   import iup
##   var fakeArgv = allocCStringArray([])
##   discard open(create(cint), fakeArgv.addr)
##   webBrowserOpen()
##   var widget = webBrowser()
##   widget.setAttribute("VALUE", "http://nim-lang.org")
##   let window = dialog(widget)
##   window.setAttribute("RASTERSIZE", "666x420")
##   window.show()
##   mainLoop()
##   close()
##
## Code Editor Dialog
## ------------------
##
## .. image:: http://webserver2.tecgraf.puc-rio.br/iup/en/dlg/images/scintilladlg.png
##
## * https://webserver2.tecgraf.puc-rio.br/iup/en/dlg/iupscintilladlg.html
##
## .. code::nim
##   import iup
##   var fakeArgv = allocCStringArray([])
##   discard open(create(cint), fakeArgv.addr)
##   scintillaOpen()
##   var widget = scintillaDlg()
##   widget.show()
##   mainLoop()
##   close()
##
## Latex Math
## ----------
##
## .. image:: http://webserver2.tecgraf.puc-rio.br/iup/en/ctrl/images/iup_mgllabel.png
##
## * https://webserver2.tecgraf.puc-rio.br/iup/en/ctrl/iup_mgllabel.html
##
## .. code::nim
##   import iup
##   var fakeArgv = allocCStringArray([])
##   discard open(create(cint), fakeArgv.addr)
##   mglPlotOpen()
##   let widget = mglLabel("\\int \\alpha \\sqrt{sin(\\pi x)^2 + \\gamma_{i_k}} dx")
##   widget.setAttribute("RASTERSIZE", "666x99")
##   widget.setAttribute("LABELFONTSIZE", "9")
##   let window = dialog(widget)
##   widget.setAttribute("BGCOLOR", "0 255 128")
##   window.setAttribute("RASTERSIZE", "666x99")
##   window.show()
##   mainLoop()
##   close()
##
## Debugging Dialog
## ----------------
##
## .. image:: http://webserver2.tecgraf.puc-rio.br/iup/en/dlg/images/globalsdialog.png
##
## * http://webserver2.tecgraf.puc-rio.br/iup/en/dlg/iupglobalsdialog.html
##
## .. code::nim
##   import iup
##   var fakeArgv = allocCStringArray([])
##   discard open(create(cint), fakeArgv.addr)
##   var widget = globalsDialog()
##   widget.show()
##   mainLoop()
##   close()
##
## 3D OpenGL Plotting
## ------------------
##
## .. image:: http://webserver2.tecgraf.puc-rio.br/iup/en/ctrl/images/iup_mglplot0.png
##
## * https://webserver2.tecgraf.puc-rio.br/iup/en/ctrl/iup_mglplot.html
##
## .. code::nim
##   import iup
##   var fakeArgv = allocCStringArray([])
##   discard open(create(cint), fakeArgv.addr)
##   mglPlotOpen()
##   let widget = mglPlot()
##   widget.setAttribute("RASTERSIZE", "420x420")
##   widget.setAttribute("TITLE", "Velociraptor Incidents")
##   widget.setAttribute("AXS_XLABEL", "Velociraptors")
##   widget.setAttribute("AXS_YLABEL", "Incidents")
##   let window = dialog(widget)
##   widget.setAttribute("BGCOLOR", "0 255 128")
##   window.show()
##   mainLoop()
##   close()
##
## Clipboard
## ---------
##
## * https://webserver2.tecgraf.puc-rio.br/iup/en/elem/iupclipboard.html
##
## .. code-block:: nim
##   import iup
##   var fakeArgv = allocCStringArray([])
##   discard open(create(cint), fakeArgv.addr)
##   setClipboard("Hello World")
##   assert getClipboard() == "Hello World"
##   close()
##
## Troubleshooting
## ===============
##
## * `Requires IUP library version 3.30 or newer installed. <http://sourceforge.net/projects/iup/files/3.30>`_
## * Compile with `-d:nimDebugDlOpen` to debug the shared library opening.
## * If the GUI opens and closes quickly without error, remember to use `mainLoop()`.
## * A Widget may display as an empty blank pixel if it is empty.
## * `Search the documentation using the wrapped function name. <http://webserver2.tecgraf.puc-rio.br/iup/gSearch.html>`_

import std/private/since

type
  Ihandle = object
  PIhandle* = ptr Ihandle ## https://webserver2.tecgraf.puc-rio.br/iup/doxygen/iup__class_8h.html
  Icallback* = proc (arg: PIhandle): cint {.cdecl.}
  Iparamcb* = proc (dialog: PIhandle; paramIndex: cint; userData: pointer): cint {.cdecl.}
  IUP_Rec* = enum ## https://webserver2.tecgraf.puc-rio.br/iup/en/func/iuprecordinput.html
    RecBinary, RecText


# Utility helper functions
{.push inline.}
func isShift*(s: cstring): bool = s[0] == 'S'
func isControl*(s: cstring): bool = s[1] == 'C'
func isButton1*(s: cstring): bool = s[2] == '1'
func isButton2*(s: cstring): bool = s[3] == '2'
func isbutton3*(s: cstring): bool = s[4] == '3'
func isDouble*(s: cstring): bool = s[5] == 'D'
func isAlt*(s: cstring): bool = s[6] == 'A'
func isSys*(s: cstring): bool = s[7] == 'Y'
func isButton4*(s: cstring): bool =  s[8] == '4'
func isButton5*(s: cstring): bool = s[9] == '5'
func isPrint*(c: cint): bool = c > 31 and c < 127
func isXkey*(c: cint): bool = c > 128
func isShiftXkey*(c: cint): bool = c > 256 and c < 512
func isCtrlXkey*(c: cint): bool = c > 512 and c < 768
func isAltXkey*(c: cint): bool = c > 768 and c < 1024
func isSysXkey*(c: cint): bool = c > 1024 and c < 1280
func iUPcxCODE*(c: cint): cint = c + cint(512)  # Ctrl
func iUPmxCODE*(c: cint): cint = c + cint(768)  # Alt
func iUPyxCODE*(c: cint): cint = c + cint(1024) # Sys (Win or Apple)
func iUPxCODE*(c: cint): cint = c + cint(128) # Normal (must be above 128)
func iUPsxCODE*(c: cint): cint = c + cint(256)
{.pop.}


when defined(windows):
  const extensions = ".dll"
  const versions = "(|33|32|31|30|27|26|25|24)"
  const prefix = ""
elif defined(macosx):
  const extensions = ".dylib"
  const versions = "(|3.3|3.2|3.1|3.0|2.7|2.6|2.5|2.4)"
  const prefix = "lib"
else:
  const extensions = ".so(|.1)"
  const versions = "(|3.3|3.2|3.1|3.0|2.7|2.6|2.5|2.4)"
  const prefix = "lib"
const
  libiup = prefix & "iup" & versions & extensions
  libiupweb = prefix & "iupweb" & versions & extensions
  libiupScintilla = prefix & "iup_scintilla" & versions & extensions
  libiupgl = prefix & "iupgl" & versions & extensions
  libiupglcontrols = prefix & "iupglcontrols" & versions & extensions
  libiupMglplot = prefix & "iup_mglplot" & versions & extensions
  libiupim = prefix & "im" & versions & extensions
  libiupPlot = prefix & "iup_plot" & versions & extensions
  libiupOle {.used.} = prefix & "iupole" & versions & extensions

  # version, date, etc.
  IUP_NAME* = "IUP - Portable User Interface"
  IUP_COPYRIGHT* = "Copyright (C) 1994-2020 Tecgraf/PUC-Rio"
  IUP_DESCRIPTION* = "Multi-platform Toolkit for Building Graphical User Interfaces"
  constIUP_VERSION* = "3.30"
  constIUP_VERSION_NUMBER* = 330000
  constIUP_VERSION_DATE* = "2020/07/30"

  # Common Return Values
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

  # Pre-Defined Masks
  IUP_MASK_FLOAT* = "[+/-]?(/d+/.?/d*|/./d+)"
  IUP_MASK_UFLOAT* = "(/d+/.?/d*|/./d+)"
  IUP_MASK_EFLOAT* = "[+/-]?(/d+/.?/d*|/./d+)([eE][+/-]?/d+)?"
  IUP_MASK_INT* = "[+/-]?/d+"
  IUP_MASK_UINT* = "/d+"

  # From 32 to 126, all character sets are equal, the key code i the same as the character code.
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

  # also define the escape sequences that have keys associated
  K_BS* = cint(ord('\b'))
  K_TAB* = cint(ord('\t'))
  K_LF* = cint(10)
  K_CR* = cint(13)

  IUP_NUMMAXCODES* = 1280 ## 5 * 256 = 1280  Normal + Shift + Ctrl + Alt + Sys

  # Used by IupColorbar
  IUP_PRIMARY* = -1
  IUP_SECONDARY* = -2

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


{.push dynlib: libiup, cdecl.}
# pre-defined dialogs
proc fileDlg*: PIhandle {.importc: "IupFileDlg".}
proc messageDlg*: PIhandle {.importc: "IupMessageDlg".}
proc colorDlg*: PIhandle {.importc: "IupColorDlg".}
proc fontDlg*: PIhandle {.importc: "IupFontDlg".}
proc getFile*(arq: cstring): cint {.importc: "IupGetFile".}
proc message*(title, msg: cstring) {.importc: "IupMessage".}
proc messagef*(title, format: cstring) {.importc: "IupMessagef", varargs.}
proc alarm*(title, msg, b1, b2, b3: cstring): cint {.importc: "IupAlarm".}
proc scanf*(format: cstring): cint {.importc: "IupScanf", varargs.}
proc getText*(title, text: cstring): cint {.importc: "IupGetText".}
proc getColor*(x, y: cint, r, g, b: var byte): cint {.importc: "IupGetColor".}
proc listDialog*(theType: cint, title: cstring, size: cint, list: cstringArray,
  op, maxCol, maxLin: cint, marks: ptr cint): cint {.importc: "IupListDialog".}
proc getParam*(title: cstring, action: Iparamcb, userData: pointer,
  format: cstring): cint {.importc: "IupGetParam", varargs.}
proc getParamv*(title: cstring, action: Iparamcb, userData: pointer, format: cstring,
  paramCount, paramExtra: cint, paramData: pointer): cint {.importc: "IupGetParamv".}
# Functions
proc open*(argc: ptr cint, argv: ptr cstringArray): cint {.importc: "IupOpen".}
proc close*() {.importc: "IupClose".}
proc imageLibOpen*() {.importc: "IupImageLibOpen".}
proc mainLoop*(): cint {.importc: "IupMainLoop", discardable.}
proc loopStep*(): cint {.importc: "IupLoopStep", discardable.}
proc mainLoopLevel*(): cint {.importc: "IupMainLoopLevel", discardable.}
proc flush*() {.importc: "IupFlush".}
proc exitLoop*() {.importc: "IupExitLoop".}
proc update*(ih: PIhandle) {.importc: "IupUpdate".}
proc updateChildren*(ih: PIhandle) {.importc: "IupUpdateChildren".}
proc redraw*(ih: PIhandle, children: cint) {.importc: "IupRedraw".}
proc refresh*(ih: PIhandle) {.importc: "IupRefresh".}
proc help*(url: cstring): cint {.importc: "IupHelp".}
proc load*(filename: cstring): cstring {.importc: "IupLoad".}
proc iupVersion*(): cstring {.importc: "IupVersion".}
proc iupVersionDate*(): cstring {.importc: "IupVersionDate".}
proc iupVersionNumber*(): cint {.importc: "IupVersionNumber".}
proc setLanguage*(lng: cstring) {.importc: "IupSetLanguage".}
proc getLanguage*(): cstring {.importc: "IupGetLanguage".}
proc destroy*(ih: PIhandle) {.importc: "IupDestroy".}
proc detach*(child: PIhandle) {.importc: "IupDetach".}
proc append*(ih, child: PIhandle): PIhandle {.importc: "IupAppend", discardable.}
proc insert*(ih, refChild, child: PIhandle): PIhandle {.importc: "IupInsert", discardable.}
proc getChild*(ih: PIhandle, pos: cint): PIhandle {.importc: "IupGetChild".}
proc getChildPos*(ih, child: PIhandle): cint {.importc: "IupGetChildPos".}
proc getChildCount*(ih: PIhandle): cint {.importc: "IupGetChildCount".}
proc getNextChild*(ih, child: PIhandle): PIhandle {.importc: "IupGetNextChild".}
proc getBrother*(ih: PIhandle): PIhandle {.importc: "IupGetBrother".}
proc getParent*(ih: PIhandle): PIhandle {.importc: "IupGetParent".}
proc getDialog*(ih: PIhandle): PIhandle {.importc: "IupGetDialog".}
proc getDialogChild*(ih: PIhandle, name: cstring): PIhandle {.importc: "IupGetDialogChild".}
proc reparent*(ih, newParent: PIhandle): cint {.importc: "IupReparent".}
proc popup*(ih: PIhandle, x, y: cint): cint {.importc: "IupPopup", discardable.}
proc show*(ih: PIhandle): cint {.importc: "IupShow", discardable.}
proc showXY*(ih: PIhandle, x, y: cint): cint {.importc: "IupShowXY", discardable.}
proc hide*(ih: PIhandle): cint {.importc: "IupHide", discardable.}
proc map*(ih: PIhandle): cint {.importc: "IupMap", discardable.}
proc unmap*(ih: PIhandle) {.importc: "IupUnmap", discardable.}
proc setAttribute*(ih: PIhandle, name, value: cstring) {.importc: "IupSetAttribute".}
proc storeAttribute*(ih: PIhandle, name, value: cstring) {.importc: "IupStoreAttribute".}
proc setAttributes*(ih: PIhandle, str: cstring): PIhandle {.importc: "IupSetAttributes".}
proc getAttribute*(ih: PIhandle, name: cstring): cstring {.importc: "IupGetAttribute".}
proc getAttributes*(ih: PIhandle): cstring {.importc: "IupGetAttributes".}
proc getInt*(ih: PIhandle, name: cstring): cint {.importc: "IupGetInt".}
proc getInt2*(ih: PIhandle, name: cstring): cint {.importc: "IupGetInt2".}
proc getIntInt*(ih: PIhandle, name: cstring, i1, i2: var cint): cint {.importc: "IupGetIntInt".}
proc getFloat*(ih: PIhandle, name: cstring): cfloat {.importc: "IupGetFloat".}
proc setfAttribute*(ih: PIhandle, name, format: cstring) {.importc: "IupSetfAttribute", varargs.}
proc getAllAttributes*(ih: PIhandle, names: cstringArray, n: cint): cint {.importc: "IupGetAllAttributes".}
proc setAtt*(handleName: cstring, ih: PIhandle, name: cstring): PIhandle {.importc: "IupSetAtt", varargs, discardable.}
proc setGlobal*(name, value: cstring) {.importc: "IupSetGlobal".}
proc storeGlobal*(name, value: cstring) {.importc: "IupStoreGlobal".}
proc getGlobal*(name: cstring): cstring {.importc: "IupGetGlobal".}
proc setFocus*(ih: PIhandle): PIhandle {.importc: "IupSetFocus".}
proc getFocus*(): PIhandle {.importc: "IupGetFocus".}
proc previousField*(ih: PIhandle): PIhandle {.importc: "IupPreviousField".}
proc nextField*(ih: PIhandle): PIhandle {.importc: "IupNextField".}
proc getCallback*(ih: PIhandle, name: cstring): Icallback {.importc: "IupGetCallback".}
proc setCallback*(ih: PIhandle, name: cstring, fn: Icallback): Icallback {.importc: "IupSetCallback", discardable.}
proc setCallbacks*(ih: PIhandle, name: cstring, fn: Icallback): PIhandle {.importc: "IupSetCallbacks", varargs, discardable.}
proc getFunction*(name: cstring): Icallback {.importc: "IupGetFunction".}
proc setFunction*(name: cstring, fn: Icallback): Icallback {.importc: "IupSetFunction", discardable.}
proc getHandle*(name: cstring): PIhandle {.importc: "IupGetHandle".}
proc setHandle*(name: cstring, ih: PIhandle): PIhandle {.importc: "IupSetHandle".}
proc getAllNames*(names: cstringArray, n: cint): cint {.importc: "IupGetAllNames".}
proc getAllDialogs*(names: cstringArray, n: cint): cint {.importc: "IupGetAllDialogs".}
proc getName*(ih: PIhandle): cstring {.importc: "IupGetName".}
proc setAttributeHandle*(ih: PIhandle, name: cstring, ihNamed: PIhandle) {.importc: "IupSetAttributeHandle".}
proc getAttributeHandle*(ih: PIhandle, name: cstring): PIhandle {.importc: "IupGetAttributeHandle".}
proc getClassName*(ih: PIhandle): cstring {.importc: "IupGetClassName".}
proc getClassType*(ih: PIhandle): cstring {.importc: "IupGetClassType".}
proc getClassAttributes*(classname: cstring, names: cstringArray, n: cint): cint {.importc: "IupGetClassAttributes".}
proc saveClassAttributes*(ih: PIhandle) {.importc: "IupSaveClassAttributes".}
proc setClassDefaultAttribute*(classname, name, value: cstring) {.importc: "IupSetClassDefaultAttribute".}
proc create*(classname: cstring): PIhandle {.importc: "IupCreate".}
proc createv*(classname: cstring, params: pointer): PIhandle {.importc: "IupCreatev".}
proc createp*(classname: cstring, first: pointer): PIhandle {.importc: "IupCreatep", varargs.}
proc fill*(): PIhandle {.importc: "IupFill".}
proc radio*(child: PIhandle): PIhandle {.importc: "IupRadio".}
proc vbox*(child: PIhandle): PIhandle {.importc: "IupVbox", varargs.}
proc vboxv*(children: ptr PIhandle): PIhandle {.importc: "IupVboxv".}
proc zbox*(child: PIhandle): PIhandle {.importc: "IupZbox", varargs.}
proc zboxv*(children: ptr PIhandle): PIhandle {.importc: "IupZboxv".}
proc hbox*(child: PIhandle): PIhandle {.importc: "IupHbox", varargs.}
proc hboxv*(children: ptr PIhandle): PIhandle {.importc: "IupHboxv".}
proc normalizer*(ihFirst: PIhandle): PIhandle {.importc: "IupNormalizer", varargs.}
proc normalizerv*(ihList: ptr PIhandle): PIhandle {.importc: "IupNormalizerv".}
proc cbox*(child: PIhandle): PIhandle {.importc: "IupCbox", varargs.}
proc cboxv*(children: ptr PIhandle): PIhandle {.importc: "IupCboxv".}
proc sbox*(child: PIhandle): PIhandle {.importc: "IupSbox".}
proc frame*(child1: PIhandle): PIhandle {.importc: "IupFrame".}
proc image*(width, height: cint, pixmap: pointer): PIhandle {.importc: "IupImage".}
proc imageRGB*(width, height: cint, pixmap: pointer): PIhandle {.importc: "IupImageRGB".}
proc imageRGBA*(width, height: cint, pixmap: pointer): PIhandle {.importc: "IupImageRGBA".}
proc item*(title, action: cstring): PIhandle {.importc: "IupItem".}
proc submenu*(title: cstring, child: PIhandle): PIhandle {.importc: "IupSubmenu".}
proc separator*(): PIhandle {.importc: "IupSeparator".}
proc menu*(child: PIhandle): PIhandle {.importc: "IupMenu", varargs.}
proc menuv*(children: ptr PIhandle): PIhandle {.importc: "IupMenuv".}
proc button*(title, action: cstring): PIhandle {.importc: "IupButton".}
proc link*(url, title: cstring): PIhandle {.importc: "IupLink".}
proc canvas*(action: cstring): PIhandle {.importc: "IupCanvas".}
proc dialog*(child: PIhandle): PIhandle {.importc: "IupDialog".}
proc user*(): PIhandle {.importc: "IupUser".}
proc label*(title: cstring): PIhandle {.importc: "IupLabel".}
proc list*(action: cstring): PIhandle {.importc: "IupList".}
proc text*(action: cstring): PIhandle {.importc: "IupText".}
proc multiLine*(action: cstring): PIhandle {.importc: "IupMultiLine".}
proc toggle*(title, action: cstring): PIhandle {.importc: "IupToggle".}
proc timer*(): PIhandle {.importc: "IupTimer".}
proc progressBar*(): PIhandle {.importc: "IupProgressBar".}
proc val*(theType: cstring): PIhandle {.importc: "IupVal".}
proc tabs*(child: PIhandle): PIhandle {.importc: "IupTabs", varargs.}
proc tabsv*(children: ptr PIhandle): PIhandle {.importc: "IupTabsv".}
proc tree*(): PIhandle {.importc: "IupTree".}
proc spin*(): PIhandle {.importc: "IupSpin".}
proc spinbox*(child: PIhandle): PIhandle {.importc: "IupSpinbox".}
# IupText utilities
proc textConvertLinColToPos*(ih: PIhandle, lin, col: cint, pos: var cint) {.importc: "IupTextConvertLinColToPos".}
proc textConvertPosToLinCol*(ih: PIhandle, pos: cint, lin, col: var cint) {.importc: "IupTextConvertPosToLinCol".}
proc convertXYToPos*(ih: PIhandle, x, y: cint): cint {.importc: "IupConvertXYToPos".}
# IupTree utilities
proc treeSetUserId*(ih: PIhandle, id: cint, userid: pointer): cint {.importc: "IupTreeSetUserId", discardable.}
proc treeGetUserId*(ih: PIhandle, id: cint): pointer {.importc: "IupTreeGetUserId".}
proc treeGetId*(ih: PIhandle, userid: pointer): cint {.importc: "IupTreeGetId".}
proc controlsOpen*(): cint {.importc: "IupControlsOpen", discardable.}
proc oldValOpen*() {.importc: "IupOldValOpen".}
proc oldTabsOpen*() {.importc: "IupOldTabsOpen".}
proc colorbar*(): PIhandle {.importc: "IupColorbar".}
proc cells*(): PIhandle {.importc: "IupCells".}
proc colorBrowser*(): PIhandle {.importc: "IupColorBrowser".}
proc gauge*(): PIhandle {.importc: "IupGauge".}
proc dial*(theType: cstring): PIhandle {.importc: "IupDial".}
proc matrix*(action: cstring): PIhandle {.importc: "IupMatrix".}
{.pop.}


since (1, 5):  # New IUP stuff from version 3.0 to 3.30
  {.push dynlib: libiup, cdecl.}
  proc elementPropertiesDialog*(parent, elem: PIhandle): PIhandle {.importc: "IupElementPropertiesDialog".}
  proc setStrGlobal*(name: cstring; value: cstring) {.importc: "IupSetStrGlobal".}
  proc copyClassAttributes*(srcIh: PIhandle; dstIh: PIhandle) {.importc: "IupCopyClassAttributes".}
  proc getAllClasses*(names: cstring; n: cint): cint {.importc: "IupGetAllClasses".}
  proc refreshChildren*(ih: PIhandle) {.importc: "IupRefreshChildren".}
  proc resetAttribute*(ih: PIhandle, name: cstring) {.importc: "IupResetAttribute".}
  proc saveImageAsText*(ih: PIhandle; filename, format, name: cstring): bool {.importc: "IupSaveImageAsText".}
  proc classMatch*(ih: PIhandle; classname: cstring): cint {.importc: "IupClassMatch".}
  proc setInt*(ih: PIhandle; name: cstring; value: cint) {.importc: "IupSetInt".}
  proc setFloat*(ih: PIhandle; name: cstring; value: float32) {.importc: "IupSetFloat".}
  proc setDouble*(ih: PIhandle; name: cstring; value: float) {.importc: "IupSetDouble".}
  proc setRGB*(ih: PIhandle; name: cstring; r, g, b: cuchar) {.importc: "IupSetRGB".}
  proc setRGBA*(ih: PIhandle; name: cstring; r, g, b, a: cuchar) {.importc: "IupSetRGBA".}
  proc stringCompare*(str1, str2: cstring; casesensitive, lexicographic: bool): cint {.importc: "IupStringCompare".}
  proc setLanguagePack*(ih: PIhandle) {.importc: "IupSetLanguagePack".}
  proc getLanguageString*(name: cstring): cstring {.importc: "IupGetLanguageString".}
  proc setLanguageString*(name: cstring; value: cstring) {.importc: "IupSetLanguageString".}
  proc execute*(filename: cstring; parameters: cstring): cint {.importc: "IupExecute".}
  proc executeWait*(filename: cstring; parameters: cstring): cint {.importc: "IupExecuteWait".}
  proc copyAttributes*(src_ih: PIhandle; dst_ih: PIhandle) {.importc: "IupCopyAttributes".}
  proc recordInput*(filename: cstring; mode: IUP_Rec): cint {.importc: "IupRecordInput".}
  proc playInput*(filename: cstring): cint {.importc: "IupPlayInput".}
  proc clipboard*(): PIhandle {.importc: "IupClipboard".}
  proc loadBuffer*(filename: cstring): cstring {.importc: "IupLoadBuffer".}
  proc isOpened*(): cint {.importc: "IupIsOpened".}
  proc thread*(): PIhandle {.importc: "IupThread".}
  proc iupVersionShow*() {.importc: "IupVersionShow".}
  proc messageError*(parent: PIhandle; message: cstring) {.importc: "IupMessageError".}
  proc messageAlarm*(parent: PIhandle; title, message, buttons: cstring) {.importc: "IupMessageAlarm".}
  proc space*(): PIhandle {.importc: "IupSpace".}
  proc imageGetHandle*(name: cstring): PIhandle {.importc: "IupImageGetHandle".}
  proc split*(child1: PIhandle; child2: PIhandle): PIhandle {.importc: "IupSplit".}
  proc scrollBox*(child: PIhandle): PIhandle {.importc: "IupScrollBox".}
  proc gridBoxv*(children: PIhandle): PIhandle {.importc: "IupGridBoxv".}
  proc expander*(child: PIhandle): PIhandle {.importc: "IupExpander".}
  proc animatedLabel*(animation: PIhandle): PIhandle {.importc: "IupAnimatedLabel".}
  proc flatSeparator*(): PIhandle {.importc: "IupFlatSeparator".}
  proc flatLabel*(title: cstring): PIhandle {.importc: "IupFlatLabel".}
  proc dropButton*(dropchild: PIhandle): PIhandle {.importc: "IupDropButton".}
  proc flatToggle*(title: cstring): PIhandle {.importc: "IupFlatToggle".}
  proc progressDlg*(): PIhandle {.importc: "IupProgressDlg".}
  proc flatButton*(title: cstring): PIhandle {.importc: "IupFlatButton".}
  proc backgroundBox*(child: PIhandle): PIhandle {.importc: "IupBackgroundBox".}
  proc flatFrame*(child: PIhandle): PIhandle {.importc: "IupFlatFrame".}
  proc flatScrollBox*(child: PIhandle): PIhandle {.importc: "IupFlatScrollBox".}
  proc flatList*(): PIhandle {.importc: "IupFlatList".}
  proc flatVal*(orientation: cstring): PIhandle {.importc: "IupFlatVal".}
  proc flatTree*(): PIhandle {.importc: "IupFlatTree".}
  proc detachBox*(child: PIhandle): PIhandle {.importc: "IupDetachBox".}
  proc layoutDialog*(dlg: PIhandle): PIhandle {.importc: "IupLayoutDialog".}
  proc matrixList*(): PIhandle {.importc: "IupMatrixList".}
  proc matrixEx*(): PIhandle {.importc: "IupMatrixEx".}
  proc calendar*(): PIhandle {.importc: "IupCalendar".}
  proc datePick*(): PIhandle {.importc: "IupDatePick".}
  proc globalsDialog*(): PIhandle {.importc: "IupGlobalsDialog".}
  proc classInfoDialog*(parent: PIhandle): PIhandle {.importc: "IupClassInfoDialog".}
  proc flatTabs*(children: PIhandle): PIhandle {.importc: "IupFlatTabs", varargs.}
  proc flatTabsv*(children: ptr PIhandle): PIhandle {.importc: "IupFlatTabsv".}
  proc multiBox*(children: PIhandle): PIhandle {.importc: "IupMultiBox", varargs.}
  proc multiBoxv*(children: ptr PIhandle): PIhandle {.importc: "IupMultiBoxv".}
  proc drawBegin*(ih: PIhandle) {.importc: "IupDrawBegin".}
  proc drawEnd*(ih: PIhandle) {.importc: "IupDrawEnd".}
  proc drawSetClipRect*(ih: PIhandle; x1, y1, x2, y2: cint) {.importc: "IupDrawSetClipRect".}
  proc drawResetClip*(ih: PIhandle) {.importc: "IupDrawResetClip".}
  proc drawParentBackground*(ih: PIhandle) {.importc: "IupDrawParentBackground".}
  proc drawLine*(ih: PIhandle; x1, y1, x2, y2: cint) {.importc: "IupDrawLine".}
  proc drawRectangle*(ih: PIhandle; x1, y1, x2, y2: cint) {.importc: "IupDrawRectangle".}
  proc drawArc*(ih: PIhandle; x1, y1, x2, y2: cint; a1, a2: float) {.importc: "IupDrawArc".}
  proc drawPolygon*(ih: PIhandle; points, count: cint) {.importc: "IupDrawPolygon".}
  proc drawText*(ih: PIhandle; str: cstring; len, x, y, w, h: cint) {.importc: "IupDrawText".}
  proc drawImage*(ih: PIhandle; name: cstring; x, y, w, h: cint) {.importc: "IupDrawImage".}
  proc drawSelectRect*(ih: PIhandle; x1, y1, x2, y2: cint) {.importc: "IupDrawSelectRect".}
  proc drawFocusRect*(ih: PIhandle; x1, y1, x2, y2: cint) {.importc: "IupDrawFocusRect".}
  {.pop.}

  {.push dynlib: libiupweb, cdecl.}
  proc webBrowserOpen*(): cint {.importc: "IupWebBrowserOpen", discardable.}
  proc webBrowser*(): PIhandle {.importc: "IupWebBrowser".}
  {.pop.}

  {.push dynlib: libiupScintilla, cdecl.}
  proc scintillaOpen*() {.importc: "IupScintillaOpen".}
  proc scintilla*(): PIhandle {.importc: "IupScintilla".}
  proc scintillaDlg*(): PIhandle {.importc: "IupScintillaDlg".}
  {.pop.}

  {.push dynlib: libiupMglplot, cdecl.}
  proc mglPlotOpen*() {.importc: "IupMglPlotOpen".}
  proc mglPlot*(): PIhandle {.importc: "IupMglPlot".}
  proc mglPlotBegin*(ih: PIhandle; dim: cint) {.importc: "IupMglPlotBegin".}
  proc mglPlotAdd1D*(ih: PIhandle; name: cstring; y: float) {.importc: "IupMglPlotAdd1D".}
  proc mglPlotAdd2D*(ih: PIhandle; x: float; y: float) {.importc: "IupMglPlotAdd2D".}
  proc mglPlotAdd3D*(ih: PIhandle; x: float; y: float; z: float) {.importc: "IupMglPlotAdd3D".}
  proc mglPlotEnd*(ih: PIhandle): cint {.importc: "IupMglPlotEnd".}
  proc mglPlotNewDataSet*(ih: PIhandle; dim: cint): cint {.importc: "IupMglPlotNewDataSet".}
  proc mglPlotInsert1D*(ih: PIhandle; dsIndex, sampleIndex: cint; names: cstring; y: float; count: cint) {.importc: "IupMglPlotInsert1D".}
  proc mglPlotInsert2D*(ih: PIhandle; dsIndex, sampleIndex: cint; x, y: float; count: cint) {.importc: "IupMglPlotInsert2D".}
  proc mglPlotInsert3D*(ih: PIhandle; dsIndex, sampleIndex: cint; x, y, z: float; count: cint) {.importc: "IupMglPlotInsert3D".}
  proc mglPlotSet1D*(ih: PIhandle; dsIndex: cint; names: cstring; y: float; count: cint) {.importc: "IupMglPlotSet1D".}
  proc mglPlotSet2D*(ih: PIhandle; dsIndex: cint; names: cstring; x, y: float; count: cint) {.importc: "IupMglPlotSet2D".}
  proc mglPlotSet3D*(ih: PIhandle; dsIndex: cint; names: cstring; x, y, z: float; count: cint) {.importc: "IupMglPlotSet3D".}
  proc mglPlotSetFormula*(ih: PIhandle; dsIndex: cint; formulaX, formulaY, formulaz: cstring; count: cint) {.importc: "IupMglPlotSetFormula".}
  proc mglPlotSetData*(ih: PIhandle; dsIndex: cint; data: float; countX, countY, countZ: cint) {.importc: "IupMglPlotSetData".}
  proc mglPlotLoadData*(ih: PIhandle; dsIndex: cint; filename: cstring; countX, countY, countZ: cint) {.importc: "IupMglPlotLoadData".}
  proc mglPlotSetFromFormula*(ih: PIhandle; dsIndex: cint; formula: cstring; countX, countY, countZ: cint) {.importc: "IupMglPlotSetFromFormula".}
  proc mglPlotTransform*(ih: PIhandle; x, y, z: float; ix, iy: ptr cint) {.importc: "IupMglPlotTransform".}
  proc mglPlotTransformXYZ*(ih: ptr PIhandle; ix, iy: cint; x, y, z: ptr float) {.importc: "IupMglPlotTransformXYZ".}
  proc mglPlotDrawMark*(ih: ptr PIhandle; x, y, z: float) {.importc: "IupMglPlotDrawMark".}
  proc mglPlotDrawLine*(ih: PIhandle; x1, y1, z1, x2, y2, z2: float) {.importc: "IupMglPlotDrawLine".}
  proc mglPlotDrawText*(ih: PIhandle; text: cstring; x, y, z: float) {.importc: "IupMglPlotDrawText".}
  proc mglLabel*(title: cstring): PIhandle {.importc: "IupMglLabel".}
  {.pop.}

  {.push dynlib: libiupim, cdecl.}
  proc imOpen*() {.importc: "IupImOpen".}
  proc loadImage*(filename: cstring): PIhandle {.importc: "IupLoadImage".}
  proc saveImage*(ih: PIhandle; filename: cstring; format: cstring): bool {.importc: "IupSaveImage".}
  proc loadAnimation*(filename: cstring): PIhandle {.importc: "IupLoadAnimation".}
  proc loadAnimationFrames*(filenameList: openArray[cstring]; fileCount: cint): PIhandle {.importc: "IupLoadAnimationFrames".}
  {.pop.}

  {.push dynlib: libiupPlot, cdecl.}
  proc plotOpen*() {.importc: "IupPlotOpen".}
  proc plot*: PIhandle {.importc: "IupPlot".}
  proc plotBegin*(ih: PIhandle, strXdata: cint) {.importc: "IupPlotBegin".}
  proc plotAdd*(ih: PIhandle, x, y: cfloat) {.importc: "IupPlotAdd".}
  proc plotAddStr*(ih: PIhandle, x: cstring, y: cfloat) {.importc: "IupPlotAddStr".}
  proc plotEnd*(ih: PIhandle): cint {.importc: "IupPlotEnd".}
  proc plotAddSegment*(ih: PIhandle; x, y: float) {.importc: "IupPlotAddSegment".}
  proc plotLoadData*(ih: PIhandle; filename: cstring; strXdata: cint): cint {.importc: "IupPlotLoadData".}
  {.pop.}

  {.push dynlib: libiupgl, cdecl.}
  proc glCanvasOpen*() {.importc: "IupGLCanvasOpen", discardable.}
  proc glMakeCurrent*(ih: PIhandle) {.importc: "IupGLMakeCurrent".}
  proc glIsCurrent*(ih: PIhandle): cint {.importc: "IupGLIsCurrent".}
  proc glSwapBuffers*(ih: PIhandle) {.importc: "IupGLSwapBuffers".}
  proc glPalette*(ih: PIhandle; index: cint; r, g, b: float) {.importc: "IupGLPalette".}
  proc glUseFont*(ih: PIhandle; first, count, listBase: cint) {.importc: "IupGLUseFont".}
  proc glWait*(gl: cint) {.importc: "IupGLWait".}
  proc glBackgroundBox*(child: PIhandle): PIhandle {.importc: "IupGLBackgroundBox".}
  proc glCanvas*(action: cstring): PIhandle {.importc: "IupGLCanvas".}
  {.pop.}

  {.push dynlib: libiupglcontrols, cdecl.}
  proc glLabel*(title: cstring): PIhandle {.importc: "IupGLLabel".}
  proc glSeparator*(): PIhandle {.importc: "IupGLSeparator".}
  proc glSubCanvas*(): PIhandle {.importc: "IupGLSubCanvas".}
  proc glButton*(title: cstring): PIhandle {.importc: "IupGLButton".}
  proc glToggle*(title: cstring): PIhandle {.importc: "IupGLToggle".}
  proc glLink*(url: cstring; title: cstring): PIhandle {.importc: "IupGLLink".}
  proc glProgressBar*(): PIhandle {.importc: "IupGLProgressBar".}
  proc glVal*(): PIhandle {.importc: "IupGLVal".}
  proc glFrame*(child: PIhandle): PIhandle {.importc: "IupGLFrame".}
  proc glExpander*(child: PIhandle): PIhandle {.importc: "IupGLExpander".}
  proc glScrollBox*(child: PIhandle): PIhandle {.importc: "IupGLScrollBox".}
  proc glSizeBox*(child: PIhandle): PIhandle {.importc: "IupGLSizeBox".}
  proc glText*(): PIhandle {.importc: "IupGLText".}
  proc glCanvasBox*(child: PIhandle): PIhandle {.importc: "IupGLCanvasBox", varargs.}
  proc glCanvasBoxv*(children: ptr PIhandle): PIhandle {.importc: "IupGLCanvasBoxv".}
  proc glDrawText*(ih: PIhandle; str: cstring; len, x, y: cint) {.importc: "IupGLDrawText".}
  proc glDrawGetTextSize*(ih: PIhandle; str: cstring; w, h: cint) {.importc: "IupGLDrawGetTextSize".}
  proc glDrawImage*(ih: PIhandle; name: cstring; x, y, active: cint) {.importc: "IupGLDrawImage".}
  proc glDrawGetImageInfo*(name: cstring; w, h, bpp: cint) {.importc: "IupGLDrawGetImageInfo".}
  proc glControlsOpen*(): cint {.importc: "IupGLControlsOpen", discardable.}
  {.pop.}

  when defined(windows):  # Windows only by design.
    proc oleControl*(progID: cstring): PIhandle {.importc: "IupOleControl", dynlib: libiupOle, cdecl.}
    proc newFileDlg*(): PIhandle {.importc: "IupNewFileDlg", dynlib: libiup, cdecl.}

  template setClipboard*(text: string) =
    ## Convenience template to set `text` to `clipboard`.
    let clippy = clipboard()
    clippy.setAttribute(r"TEXT", text.cstring)
    clippy.destroy()

  template getClipboard*(): string =
    ## Convenience template to get text from `clipboard`.
    let clippy = clipboard()
    let text = clippy.getAttribute(r"TEXT")
    clippy.destroy()
    $text
