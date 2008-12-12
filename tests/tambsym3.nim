# Test ambigious symbols

import mambsym1, times

var
  v = mDec #ERROR_MSG ambigious identifier

writeln(stdout, ord(v))
