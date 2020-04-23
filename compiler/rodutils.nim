#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Serialization utilities for the compiler; see also ic/utils
import strutils, math

# bcc on windows doesn't have C99 functions
when defined(windows) and defined(bcc):
  {.emit: """#if defined(_MSC_VER) && _MSC_VER < 1900
  #include <stdarg.h>
  static int c99_vsnprintf(char *outBuf, size_t size, const char *format, va_list ap) {
    int count = -1;
    if (size != 0) count = _vsnprintf_s(outBuf, size, _TRUNCATE, format, ap);
    if (count == -1) count = _vscprintf(format, ap);
    return count;
  }
  int snprintf(char *outBuf, size_t size, const char *format, ...) {
    int count;
    va_list ap;
    va_start(ap, format);
    count = c99_vsnprintf(outBuf, size, format, ap);
    va_end(ap);
    return count;
  }
  #endif
  """.}

proc c_snprintf(s: cstring; n:uint; frmt: cstring): cint {.importc: "snprintf", header: "<stdio.h>", nodecl, varargs.}

proc toStrMaxPrecision*(f: BiggestFloat, literalPostfix = ""): string =
  case classify(f)
  of fcNan:
    result = "NAN"
  of fcNegZero:
    result = "-0.0" & literalPostfix
  of fcZero:
    result = "0.0" & literalPostfix
  of fcInf:
    result = "INF"
  of fcNegInf:
    result = "-INF"
  else:
    result = newString(81)
    let n = c_snprintf(result.cstring, result.len.uint, "%#.16e%s", f, literalPostfix.cstring)
    setLen(result, n)
