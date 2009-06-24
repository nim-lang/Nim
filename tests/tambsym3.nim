# Test ambiguous symbols

import mambsym1, times

var
  v = mDec #ERROR_MSG ambiguous identifier

writeln(stdout, ord(v))
