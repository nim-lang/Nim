#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import posix

type
  Speed* = cuint
  Cflag* = cuint

const
  NCCS* = when defined(macosx): 20 else: 32

when defined(linux) and defined(amd64):
  type
    Termios* {.importc: "struct termios", header: "<termios.h>".} = object
      c_iflag*: Cflag        # input mode flags
      c_oflag*: Cflag        # output mode flags
      c_cflag*: Cflag        # control mode flags
      c_lflag*: Cflag        # local mode flags
      c_line*: cuchar
      c_cc*: array[NCCS, cuchar]  # control characters
      c_ispeed*: Speed
      c_ospeed*: Speed
else:
  type
    Termios* {.importc: "struct termios", header: "<termios.h>".} = object
      c_iflag*: Cflag        # input mode flags
      c_oflag*: Cflag        # output mode flags
      c_cflag*: Cflag        # control mode flags
      c_lflag*: Cflag        # local mode flags
      c_cc*: array[NCCS, cuchar]  # control characters

# cc characters

var
  VINTR* {.importc, header: "<termios.h>".}: cint
  VQUIT* {.importc, header: "<termios.h>".}: cint
  VERASE* {.importc, header: "<termios.h>".}: cint
  VKILL* {.importc, header: "<termios.h>".}: cint
  VEOF* {.importc, header: "<termios.h>".}: cint
  VTIME* {.importc, header: "<termios.h>".}: cint
  VMIN* {.importc, header: "<termios.h>".}: cint
  VSTART* {.importc, header: "<termios.h>".}: cint
  VSTOP* {.importc, header: "<termios.h>".}: cint
  VSUSP* {.importc, header: "<termios.h>".}: cint
  VEOL* {.importc, header: "<termios.h>".}: cint

# iflag bits

var
  IGNBRK* {.importc, header: "<termios.h>".}: Cflag
  BRKINT* {.importc, header: "<termios.h>".}: Cflag
  IGNPAR* {.importc, header: "<termios.h>".}: Cflag
  PARMRK* {.importc, header: "<termios.h>".}: Cflag
  INPCK* {.importc, header: "<termios.h>".}: Cflag
  ISTRIP* {.importc, header: "<termios.h>".}: Cflag
  INLCR* {.importc, header: "<termios.h>".}: Cflag
  IGNCR* {.importc, header: "<termios.h>".}: Cflag
  ICRNL* {.importc, header: "<termios.h>".}: Cflag
  IUCLC* {.importc, header: "<termios.h>".}: Cflag
  IXON* {.importc, header: "<termios.h>".}: Cflag
  IXANY* {.importc, header: "<termios.h>".}: Cflag
  IXOFF* {.importc, header: "<termios.h>".}: Cflag

# oflag bits

var
  OPOST* {.importc, header: "<termios.h>".}: Cflag
  ONLCR* {.importc, header: "<termios.h>".}: Cflag
  OCRNL* {.importc, header: "<termios.h>".}: Cflag
  ONOCR* {.importc, header: "<termios.h>".}: Cflag
  ONLRET* {.importc, header: "<termios.h>".}: Cflag
  OFILL* {.importc, header: "<termios.h>".}: Cflag
  OFDEL* {.importc, header: "<termios.h>".}: Cflag
  NLDLY* {.importc, header: "<termios.h>".}: Cflag
  NL0* {.importc, header: "<termios.h>".}: Cflag
  NL1* {.importc, header: "<termios.h>".}: Cflag
  CRDLY* {.importc, header: "<termios.h>".}: Cflag
  CR0* {.importc, header: "<termios.h>".}: Cflag
  CR1* {.importc, header: "<termios.h>".}: Cflag
  CR2* {.importc, header: "<termios.h>".}: Cflag
  CR3* {.importc, header: "<termios.h>".}: Cflag
  TABDLY* {.importc, header: "<termios.h>".}: Cflag
  TAB0* {.importc, header: "<termios.h>".}: Cflag
  TAB1* {.importc, header: "<termios.h>".}: Cflag
  TAB2* {.importc, header: "<termios.h>".}: Cflag
  TAB3* {.importc, header: "<termios.h>".}: Cflag
  BSDLY* {.importc, header: "<termios.h>".}: Cflag
  BS0* {.importc, header: "<termios.h>".}: Cflag
  BS1* {.importc, header: "<termios.h>".}: Cflag
  FFDLY* {.importc, header: "<termios.h>".}: Cflag
  FF0* {.importc, header: "<termios.h>".}: Cflag
  FF1* {.importc, header: "<termios.h>".}: Cflag
  VTDLY* {.importc, header: "<termios.h>".}: Cflag
  VT0* {.importc, header: "<termios.h>".}: Cflag
  VT1* {.importc, header: "<termios.h>".}: Cflag

# cflag bit meaning

var
  B0* {.importc, header: "<termios.h>".}: Speed
  B50* {.importc, header: "<termios.h>".}: Speed
  B75* {.importc, header: "<termios.h>".}: Speed
  B110* {.importc, header: "<termios.h>".}: Speed
  B134* {.importc, header: "<termios.h>".}: Speed
  B150* {.importc, header: "<termios.h>".}: Speed
  B200* {.importc, header: "<termios.h>".}: Speed
  B300* {.importc, header: "<termios.h>".}: Speed
  B600* {.importc, header: "<termios.h>".}: Speed
  B1200* {.importc, header: "<termios.h>".}: Speed
  B1800* {.importc, header: "<termios.h>".}: Speed
  B2400* {.importc, header: "<termios.h>".}: Speed
  B4800* {.importc, header: "<termios.h>".}: Speed
  B9600* {.importc, header: "<termios.h>".}: Speed
  B19200* {.importc, header: "<termios.h>".}: Speed
  B38400* {.importc, header: "<termios.h>".}: Speed
  B57600* {.importc, header: "<termios.h>".}: Speed
  B115200* {.importc, header: "<termios.h>".}: Speed
  B230400* {.importc, header: "<termios.h>".}: Speed
  B460800* {.importc, header: "<termios.h>".}: Speed
  B500000* {.importc, header: "<termios.h>".}: Speed
  B576000* {.importc, header: "<termios.h>".}: Speed
  B921600* {.importc, header: "<termios.h>".}: Speed
  B1000000* {.importc, header: "<termios.h>".}: Speed
  B1152000* {.importc, header: "<termios.h>".}: Speed
  B1500000* {.importc, header: "<termios.h>".}: Speed
  B2000000* {.importc, header: "<termios.h>".}: Speed
  B2500000* {.importc, header: "<termios.h>".}: Speed
  B3000000* {.importc, header: "<termios.h>".}: Speed
  B3500000* {.importc, header: "<termios.h>".}: Speed
  B4000000* {.importc, header: "<termios.h>".}: Speed
  EXTA* {.importc, header: "<termios.h>".}: Speed
  EXTB* {.importc, header: "<termios.h>".}: Speed
  CSIZE* {.importc, header: "<termios.h>".}: Cflag
  CS5* {.importc, header: "<termios.h>".}: Cflag
  CS6* {.importc, header: "<termios.h>".}: Cflag
  CS7* {.importc, header: "<termios.h>".}: Cflag
  CS8* {.importc, header: "<termios.h>".}: Cflag
  CSTOPB* {.importc, header: "<termios.h>".}: Cflag
  CREAD* {.importc, header: "<termios.h>".}: Cflag
  PARENB* {.importc, header: "<termios.h>".}: Cflag
  PARODD* {.importc, header: "<termios.h>".}: Cflag
  HUPCL* {.importc, header: "<termios.h>".}: Cflag
  CLOCAL* {.importc, header: "<termios.h>".}: Cflag

# lflag bits

var
  ISIG* {.importc, header: "<termios.h>".}: Cflag
  ICANON* {.importc, header: "<termios.h>".}: Cflag
  ECHO* {.importc, header: "<termios.h>".}: Cflag
  ECHOE* {.importc, header: "<termios.h>".}: Cflag
  ECHOK* {.importc, header: "<termios.h>".}: Cflag
  ECHONL* {.importc, header: "<termios.h>".}: Cflag
  NOFLSH* {.importc, header: "<termios.h>".}: Cflag
  TOSTOP* {.importc, header: "<termios.h>".}: Cflag
  IEXTEN* {.importc, header: "<termios.h>".}: Cflag

# tcflow() and TCXONC use these

var
  TCOOFF* {.importc, header: "<termios.h>".}: cint
  TCOON* {.importc, header: "<termios.h>".}: cint
  TCIOFF* {.importc, header: "<termios.h>".}: cint
  TCION* {.importc, header: "<termios.h>".}: cint

# tcflush() and TCFLSH use these

var
  TCIFLUSH* {.importc, header: "<termios.h>".}: cint
  TCOFLUSH* {.importc, header: "<termios.h>".}: cint
  TCIOFLUSH* {.importc, header: "<termios.h>".}: cint

# tcsetattr uses these

var
  TCSANOW* {.importc, header: "<termios.h>".}: cint
  TCSADRAIN* {.importc, header: "<termios.h>".}: cint
  TCSAFLUSH* {.importc, header: "<termios.h>".}: cint

# Compare a character C to a value VAL from the `cc' array in a
#   `struct termios'.  If VAL is _POSIX_VDISABLE, no character can match it.

template cceq*(val, c): untyped =
  c == val and val != POSIX_VDISABLE

# Return the output baud rate stored in *TERMIOS_P.

proc cfGetOspeed*(termios: ptr Termios): Speed {.importc: "cfgetospeed",
    header: "<termios.h>".}
# Return the input baud rate stored in *TERMIOS_P.

proc cfGetIspeed*(termios: ptr Termios): Speed {.importc: "cfgetispeed",
    header: "<termios.h>".}
# Set the output baud rate stored in *TERMIOS_P to SPEED.

proc cfSetOspeed*(termios: ptr Termios; speed: Speed): cint {.
    importc: "cfsetospeed", header: "<termios.h>".}
# Set the input baud rate stored in *TERMIOS_P to SPEED.

proc cfSetIspeed*(termios: ptr Termios; speed: Speed): cint {.
    importc: "cfsetispeed", header: "<termios.h>".}
# Set both the input and output baud rates in *TERMIOS_OP to SPEED.

proc tcGetAttr*(fd: cint; termios: ptr Termios): cint {.
    importc: "tcgetattr", header: "<termios.h>".}
# Set the state of FD to *TERMIOS_P.
#   Values for OPTIONAL_ACTIONS (TCSA*) are in <bits/termios.h>.

proc tcSetAttr*(fd: cint; optional_actions: cint; termios: ptr Termios): cint {.
    importc: "tcsetattr", header: "<termios.h>".}
# Set *TERMIOS_P to indicate raw mode.

proc tcSendBreak*(fd: cint; duration: cint): cint {.importc: "tcsendbreak",
    header: "<termios.h>".}
# Wait for pending output to be written on FD.
#
#   This function is a cancellation point and therefore not marked with
#  .

proc tcDrain*(fd: cint): cint {.importc: "tcdrain", header: "<termios.h>".}
# Flush pending data on FD.
#   Values for QUEUE_SELECTOR (TC{I,O,IO}FLUSH) are in <bits/termios.h>.

proc tcFlush*(fd: cint; queue_selector: cint): cint {.importc: "tcflush",
    header: "<termios.h>".}
# Suspend or restart transmission on FD.
#   Values for ACTION (TC[IO]{OFF,ON}) are in <bits/termios.h>.

proc tcFlow*(fd: cint; action: cint): cint {.importc: "tcflow",
    header: "<termios.h>".}
# Get process group ID for session leader for controlling terminal FD.

# Window size ioctl.  Should work on on any Unix that xterm has been ported to.
var TIOCGWINSZ*{.importc, header: "<sys/ioctl.h>".}: culong

when defined(nimHasStyleChecks):
  {.push styleChecks: off.}

type IOctl_WinSize* = object
  ws_row*, ws_col*, ws_xpixel*, ws_ypixel*: cushort

when defined(nimHasStyleChecks):
  {.pop.}

proc ioctl*(fd: cint, request: culong, reply: ptr IOctl_WinSize): int {.
  importc: "ioctl", header: "<stdio.h>", varargs.}
