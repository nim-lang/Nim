# Test ambigious symbols

import mambsym1, mambsym2

var
  v: TExport #ERROR_MSG ambigious identifier

v = y
