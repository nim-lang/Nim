#
#  tre.h - TRE public API definitions
#
#  This software is released under a BSD-style license.
#  See the file LICENSE for details and copyright.
#
#

when not defined(treDll):
  when hostOS == "windows":
    const treDll = "tre.dll"
  elif hostOS == "macosx":
    const treDll = "libtre.dylib"
  else:
    const treDll = "libtre.so(.5|)"

const
  APPROX* = 1 ## approximate matching functionality
  MULTIBYTE* = 1 ## multibyte character set support.
  VERSION* = "0.8.0" ## TRE version string.
  VERSION_1* = 0 ## TRE version level 1.
  VERSION_2* = 8 ## TRE version level 2.
  VERSION_3* = 0 ## TRE version level 3.


# If the we're not using system regex.h, we need to define the
#   structs and enums ourselves.

type
  TRegoff* = cint
  TRegex*{.pure, final.} = object
    re_nsub*: int          ## Number of parenthesized subexpressions.
    value*: pointer        ## For internal use only.

  TRegmatch*{.pure, final.} = object
    rm_so*: TRegoff
    rm_eo*: TRegoff

  TReg_errcode*{.size: 4.} = enum  ## POSIX tre_regcomp() return error codes.
                                   ## (In the order listed in the standard.)	
    REG_OK = 0,               ## No error.
    REG_NOMATCH,              ## No match.
    REG_BADPAT,               ## Invalid regexp.
    REG_ECOLLATE,             ## Unknown collating element.
    REG_ECTYPE,               ## Unknown character class name.
    REG_EESCAPE,              ## Trailing backslash.
    REG_ESUBREG,              ## Invalid back reference.
    REG_EBRACK,               ## "[]" imbalance
    REG_EPAREN,               ## "\(\)" or "()" imbalance
    REG_EBRACE,               ## "\{\}" or "{}" imbalance
    REG_BADBR,                ## Invalid content of {}
    REG_ERANGE,               ## Invalid use of range operator
    REG_ESPACE,               ## Out of memory.
    REG_BADRPT                ## Invalid use of repetition operators.

# POSIX tre_regcomp() flags.

const
  REG_EXTENDED* = 1
  REG_ICASE* = (REG_EXTENDED shl 1)
  REG_NEWLINE* = (REG_ICASE shl 1)
  REG_NOSUB* = (REG_NEWLINE shl 1)

# Extra tre_regcomp() flags.

const
  REG_BASIC* = 0
  REG_LITERAL* = (REG_NOSUB shl 1)
  REG_RIGHT_ASSOC* = (REG_LITERAL shl 1)
  REG_UNGREEDY* = (REG_RIGHT_ASSOC shl 1)

# POSIX tre_regexec() flags.

const
  REG_NOTBOL* = 1
  REG_NOTEOL* = (REG_NOTBOL shl 1)

# Extra tre_regexec() flags.

const
  REG_APPROX_MATCHER* = (REG_NOTEOL shl 1)
  REG_BACKTRACKING_MATCHER* = (REG_APPROX_MATCHER shl 1)

# The maximum number of iterations in a bound expression.

const
  RE_DUP_MAX* = 255

# The POSIX.2 regexp functions

proc regcomp*(preg: var TRegex, regex: cstring, cflags: cint): cint{.cdecl,
    importc: "tre_regcomp", dynlib: treDll.}
proc regexec*(preg: var TRegex, string: cstring, nmatch: int,
              pmatch: ptr TRegmatch, eflags: cint): cint{.cdecl,
    importc: "tre_regexec", dynlib: treDll.}
proc regerror*(errcode: cint, preg: var TRegex, errbuf: cstring,
               errbuf_size: int): int{.cdecl, importc: "tre_regerror",
    dynlib: treDll.}
proc regfree*(preg: var TRegex){.cdecl, importc: "tre_regfree", dynlib: treDll.}
# Versions with a maximum length argument and therefore the capability to
#   handle null characters in the middle of the strings (not in POSIX.2).

proc regncomp*(preg: var TRegex, regex: cstring, len: int, cflags: cint): cint{.
    cdecl, importc: "tre_regncomp", dynlib: treDll.}
proc regnexec*(preg: var TRegex, string: cstring, len: int, nmatch: int,
               pmatch: ptr TRegmatch, eflags: cint): cint{.cdecl,
    importc: "tre_regnexec", dynlib: treDll.}
# Approximate matching parameter struct.

type
  TRegaparams*{.pure, final.} = object
    cost_ins*: cint           ## Default cost of an inserted character.
    cost_del*: cint           ## Default cost of a deleted character.
    cost_subst*: cint         ## Default cost of a substituted character.
    max_cost*: cint           ## Maximum allowed cost of a match.
    max_ins*: cint            ## Maximum allowed number of inserts.
    max_del*: cint            ## Maximum allowed number of deletes.
    max_subst*: cint          ## Maximum allowed number of substitutes.
    max_err*: cint            ## Maximum allowed number of errors total.


# Approximate matching result struct.

type
  TRegamatch*{.pure, final.} = object
    nmatch*: int              ## Length of pmatch[] array.
    pmatch*: ptr TRegmatch    ## Submatch data.
    cost*: cint               ## Cost of the match.
    num_ins*: cint            ## Number of inserts in the match.
    num_del*: cint            ## Number of deletes in the match.
    num_subst*: cint          ## Number of substitutes in the match.


# Approximate matching functions.

proc regaexec*(preg: var TRegex, string: cstring, match: ptr TRegamatch,
               params: TRegaparams, eflags: cint): cint{.cdecl,
    importc: "tre_regaexec", dynlib: treDll.}
proc reganexec*(preg: var TRegex, string: cstring, len: int,
                match: ptr TRegamatch, params: TRegaparams,
                eflags: cint): cint{.
    cdecl, importc: "tre_reganexec", dynlib: treDll.}
# Sets the parameters to default values.

proc regaparams_default*(params: ptr TRegaparams){.cdecl,
    importc: "tre_regaparams_default", dynlib: treDll.}

type
  TStrSource*{.pure, final.} = object
    get_next_char*: proc (c: cstring, pos_add: ptr cint,
                          context: pointer): cint{.cdecl.}
    rewind*: proc (pos: int, context: pointer){.cdecl.}
    compare*: proc (pos1: int, pos2: int, len: int, context: pointer): cint{.
        cdecl.}
    context*: pointer


proc reguexec*(preg: var TRegex, string: ptr TStrSource, nmatch: int,
               pmatch: ptr TRegmatch, eflags: cint): cint{.cdecl,
    importc: "tre_reguexec", dynlib: treDll.}

proc runtimeVersion*(): cstring{.cdecl, importc: "tre_version", dynlib: treDll.}
  # Returns the version string.	The returned string is static.

proc config*(query: cint, result: pointer): cint{.cdecl, importc: "tre_config",
    dynlib: treDll.}
  # Returns the value for a config parameter.  The type to which `result`
  # must point to depends of the value of `query`, see documentation for
  # more details.

const
  CONFIG_APPROX* = 0
  CONFIG_WCHAR* = 1
  CONFIG_MULTIBYTE* = 2
  CONFIG_SYSTEM_ABI* = 3
  CONFIG_VERSION* = 4

# Returns 1 if the compiled pattern has back references, 0 if not.

proc have_backrefs*(preg: var TRegex): cint{.cdecl,
    importc: "tre_have_backrefs", dynlib: treDll.}
# Returns 1 if the compiled pattern uses approximate matching features,
#   0 if not.

proc have_approx*(preg: var TRegex): cint{.cdecl, importc: "tre_have_approx",
    dynlib: treDll.}
