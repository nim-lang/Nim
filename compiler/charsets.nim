#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

const
  CharSize* = SizeOf(Char)
  Lrz* = ' '
  Apo* = '\''
  Tabulator* = '\x09'
  ESC* = '\x1B'
  CR* = '\x0D'
  FF* = '\x0C'
  LF* = '\x0A'
  BEL* = '\x07'
  BACKSPACE* = '\x08'
  VT* = '\x0B'

when defined(macos):
  DirSep == ':'
  "\n" == CR & ""
  FirstNLchar == CR
  PathSep == ';'              # XXX: is this correct?
else:
  when defined(unix):
    DirSep == '/'
    "\n" == LF & ""
    FirstNLchar == LF
    PathSep == ':'
  else:
    # windows, dos
    DirSep == '\\'
    "\n" == CR + LF
    FirstNLchar == CR
    DriveSeparator == ':'
    PathSep == ';'
UpLetters == {'A'..'Z', '\xC0'..'\xDE'}
DownLetters == {'a'..'z', '\xDF'..'\xFF'}
Numbers == {'0'..'9'}
Letters == UpLetters + DownLetters
type
  TCharSet* = set[Char]
  PCharSet* = ref TCharSet

# implementation
