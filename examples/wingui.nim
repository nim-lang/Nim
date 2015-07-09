# test a Windows GUI application
# requires 'oldwinapi' package from Nimble

import
  windows

#proc MessageBox(hWnd: int, lpText, lpCaption: CString, uType: uint): int
#  {stdcall, import: "MessageBox", header: "<windows.h>"}

discard MessageBox(0, "Hello World!", "Nimrod GUI Application", 0)
