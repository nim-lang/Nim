#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

{.deadCodeElim: on.}
import posix

type 
  Speed* = cuint
  Tcflag* = cuint

const 
  NCCS* = 32

type 
  Termios* = object {.importc: "struct termios", header: "<termios.h>", final, pure.}
    iflag*: Tcflag        # input mode flags 
    oflag*: Tcflag        # output mode flags 
    cflag*: Tcflag        # control mode flags 
    lflag*: Tcflag        # local mode flags 
    line*: cuchar             # line discipline 
    cc*: array[NCCS, cuchar]  # control characters 
    ispeed*: Speed        # input speed 
    ospeed*: Speed        # output speed 
  

# cc characters 

const 
  VINTR* = 0
  VQUIT* = 1
  VERASE* = 2
  VKILL* = 3
  VEOF* = 4
  VTIME* = 5
  VMIN* = 6
  VSWTC* = 7
  VSTART* = 8
  VSTOP* = 9
  VSUSP* = 10
  VEOL* = 11
  VREPRINT* = 12
  VDISCARD* = 13
  VWERASE* = 14
  VLNEXT* = 15
  VEOL2* = 16

# iflag bits 

const 
  IGNBRK* = 1
  BRKINT* = 2
  IGNPAR* = 4
  PARMRK* = 10
  INPCK* = 20
  ISTRIP* = 40
  INLCR* = 100
  IGNCR* = 200
  ICRNL* = 400
  IUCLC* = 1000
  IXON* = 2000
  IXANY* = 4000
  IXOFF* = 10000
  IMAXBEL* = 20000
  IUTF8* = 40000

# oflag bits 

const 
  OPOST* = 1
  OLCUC* = 2
  ONLCR* = 4
  OCRNL* = 10
  ONOCR* = 20
  ONLRET* = 40
  OFILL* = 100
  OFDEL* = 200
  NLDLY* = 400
  NL0* = 0
  NL1* = 400
  CRDLY* = 3000
  CR0* = 0
  CR1* = 1000
  CR2* = 2000
  CR3* = 3000
  TABDLY* = 14000
  TAB0* = 0
  TAB1* = 4000
  TAB2* = 10000
  TAB3* = 14000
  BSDLY* = 20000
  BS0* = 0
  BS1* = 20000
  FFDLY* = 0o000000100000
  FF0* = 0
  FF1* = 0o000000100000
  VTDLY* = 40000
  VT0* = 0
  VT1* = 40000
  XTABS* = 14000

# cflag bit meaning 

const 
  CBAUD* = 10017
  B0* = 0
  B50* = 1
  B75* = 2
  B110* = 3
  B134* = 4
  B150* = 5
  B200* = 6
  B300* = 7
  B600* = 10
  B1200* = 11
  B1800* = 12
  B2400* = 13
  B4800* = 14
  B9600* = 15
  B19200* = 16
  B38400* = 17
  EXTA* = B19200
  EXTB* = B38400
  CSIZE* = 60
  CS5* = 0
  CS6* = 20
  CS7* = 40
  CS8* = 60
  CSTOPB* = 100
  CREAD* = 200
  PARENB* = 400
  PARODD* = 1000
  HUPCL* = 2000
  CLOCAL* = 4000
  CBAUDEX* = 10000
  B57600* = 10001
  B115200* = 10002
  B230400* = 10003
  B460800* = 10004
  B500000* = 10005
  B576000* = 10006
  B921600* = 10007
  B1000000* = 10010
  B1152000* = 10011
  B1500000* = 10012
  B2000000* = 10013
  B2500000* = 10014
  B3000000* = 10015
  B3500000* = 10016
  B4000000* = 10017
  MAX_BAUD* = B4000000
  CIBAUD* = 2003600000
  CMSPAR* = 0o010000000000
  CRTSCTS* = 0o020000000000

# lflag bits 

const 
  ISIG* = 1
  ICANON* = 2
  XCASE* = 4
  ECHO* = 10
  ECHOE* = 20
  ECHOK* = 40
  ECHONL* = 100
  NOFLSH* = 200
  TOSTOP* = 400
  ECHOCTL* = 1000
  ECHOPRT* = 2000
  ECHOKE* = 4000
  FLUSHO* = 10000
  PENDIN* = 40000
  IEXTEN* = 0o000000100000
  EXTPROC* = 0o000000200000

# tcflow() and TCXONC use these 

const 
  TCOOFF* = 0
  TCOON* = 1
  TCIOFF* = 2
  TCION* = 3

# tcflush() and TCFLSH use these 

const 
  TCIFLUSH* = 0
  TCOFLUSH* = 1
  TCIOFLUSH* = 2

# tcsetattr uses these 

const 
  TCSANOW* = 0
  TCSADRAIN* = 1
  TCSAFLUSH* = 2

# Compare a character C to a value VAL from the `cc' array in a
#   `struct termios'.  If VAL is _POSIX_VDISABLE, no character can match it.  

template cceq*(val, c: expr): expr = 
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

proc cfSetSpeed*(termios: ptr Termios; speed: Speed): cint {.
    importc: "cfsetspeed", header: "<termios.h>".}
# Put the state of FD into *TERMIOS_P.  

proc tcGetAttr*(fd: cint; termios: ptr Termios): cint {.
    importc: "tcgetattr", header: "<termios.h>".}
# Set the state of FD to *TERMIOS_P.
#   Values for OPTIONAL_ACTIONS (TCSA*) are in <bits/termios.h>.  

proc tcSetAttr*(fd: cint; optional_actions: cint; termios: ptr Termios): cint {.
    importc: "tcsetattr", header: "<termios.h>".}
# Set *TERMIOS_P to indicate raw mode.  

proc cfMakeRaw*(termios: ptr Termios) {.importc: "cfmakeraw", 
    header: "<termios.h>".}
# Send zero bits on FD.  

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

proc tcGetSid*(fd: cint): TPid {.importc: "tcgetsid", header: "<termios.h>".}
