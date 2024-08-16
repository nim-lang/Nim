import macros
import parseutils
import unicode
import math
import pegs
import streams

type
  FormatError = object of CatchableError ## Error in the format string.

  Writer = concept W
    ## Writer to output a character `c`.
    write(W, 'c')

  FmtAlign = enum ## Format alignment
    faDefault  ## default for given format type
    faLeft     ## left aligned
    faRight    ## right aligned
    faCenter   ## centered
    faPadding  ## right aligned, fill characters after sign (numbers only)

  FmtSign = enum ## Format sign
    fsMinus    ## only unary minus, no reservered sign space for positive numbers
    fsPlus     ## unary minus and unary plus
    fsSpace    ## unary minus and reserved space for positive numbers

  FmtType = enum ## Format type
    ftDefault  ## default format for given parameter type
    ftStr      ## string
    ftChar     ## character
    ftDec      ## decimal integer
    ftBin      ## binary integer
    ftOct      ## octal integer
    ftHex      ## hexadecimal integer
    ftFix      ## real number in fixed point notation
    ftSci      ## real number in scientific notation
    ftGen      ## real number in generic form (either fixed point or scientific)
    ftPercent  ## real number multiplied by 100 and % added

  Format = tuple ## Formatting information.
    typ: FmtType     ## format type
    precision: int    ## floating point precision
    width: int        ## minimal width
    fill: string      ## the fill character, UTF8
    align: FmtAlign  ## alignment
    sign: FmtSign    ## sign notation
    baseprefix: bool  ## whether binary, octal, hex should be prefixed by 0b, 0x, 0o
    upcase: bool      ## upper case letters in hex or exponential formats
    comma: bool       ##
    arysep: string    ## separator for array elements

  PartKind = enum pkStr, pkFmt

  Part = object
    ## Information of a part of the target string.
    case kind: PartKind ## type of the part
    of pkStr:
      str: string ## literal string
    of pkFmt:
      arg: int ## position argument
      fmt: string ## format string
      field: string ## field of argument to be accessed
      index: int ## array index of argument to be accessed
      nested: bool ## true if the argument contains nested formats

const
  DefaultPrec = 6 ## Default precision for floating point numbers.
  DefaultFmt: Format = (ftDefault, -1, -1, "", faDefault, fsMinus, false, false, false, "")
    ## Default format corresponding to the empty format string, i.e.
    ##   `x.format("") == x.format(DefaultFmt)`.
  round_nums = [0.5, 0.05, 0.005, 0.0005, 0.00005, 0.000005, 0.0000005, 0.00000005]
    ## Rounding offset for floating point numbers up to precision 8.

proc write(s: var string; c: char) =
  s.add(c)

proc has(c: Captures; i: range[0..pegs.MaxSubpatterns-1]): bool {.nosideeffect, inline.} =
  ## Tests whether `c` contains a non-empty capture `i`.
  let b = c.bounds(i)
  result = b.first <= b.last

proc get(str: string; c: Captures; i: range[0..MaxSubpatterns-1]; def: char): char {.nosideeffect, inline.} =
  ## If capture `i` is non-empty return that portion of `str` cast
  ## to `char`, otherwise return `def`.
  result = if c.has(i): str[c.bounds(i).first] else: def

proc get(str: string; c: Captures; i: range[0..MaxSubpatterns-1]; def: string; begoff: int = 0): string {.nosideeffect, inline.} =
  ## If capture `i` is non-empty return that portion of `str` as
  ## string, otherwise return `def`.
  let b = c.bounds(i)
  result = if c.has(i): str.substr(b.first + begoff, b.last) else: def

proc get(str: string; c: Captures; i: range[0..MaxSubpatterns-1]; def: int; begoff: int = 0): int {.nosideeffect, inline.} =
  ## If capture `i` is non-empty return that portion of `str`
  ## converted to int, otherwise return `def`.
  if c.has(i):
    discard str.parseInt(result, c.bounds(i).first + begoff)
  else:
    result = def

proc parse(fmt: string): Format {.nosideeffect.} =
  # Converts the format string `fmt` into a `Format` structure.
  let p =
    sequence(capture(?sequence(anyRune(), &charSet({'<', '>', '=', '^'}))),
             capture(?charSet({'<', '>', '=', '^'})),
             capture(?charSet({'-', '+', ' '})),
             capture(?charSet({'#'})),
             capture(?(+digits())),
             capture(?charSet({','})),
             capture(?sequence(charSet({'.'}), +digits())),
             capture(?charSet({'b', 'c', 'd', 'e', 'E', 'f', 'F', 'g', 'G', 'n', 'o', 's', 'x', 'X', '%'})),
             capture(?sequence(charSet({'a'}), *pegs.any())))
  # let p=peg"{(_&[<>=^])?}{[<>=^]?}{[-+ ]?}{[#]?}{[0-9]+?}{[,]?}{([.][0-9]+)?}{[bcdeEfFgGnosxX%]?}{(a.*)?}"

  var caps: Captures
  if fmt.rawmatch(p, 0, caps) < 0:
    raise newException(FormatError, "Invalid format string")

  result.fill = fmt.get(caps, 0, "")

  case fmt.get(caps, 1, 0.char)
  of '<': result.align = faLeft
  of '>': result.align = faRight
  of '^': result.align = faCenter
  of '=': result.align = faPadding
  else: result.align = faDefault

  case fmt.get(caps, 2, '-')
  of '-': result.sign = fsMinus
  of '+': result.sign = fsPlus
  of ' ': result.sign = fsSpace
  else: result.sign = fsMinus

  result.baseprefix = caps.has(3)

  result.width = fmt.get(caps, 4, -1)

  if caps.has(4) and fmt[caps.bounds(4).first] == '0':
    if result.fill != "":
      raise newException(FormatError, "Leading 0 in with not allowed with explicit fill character")
    if result.align != faDefault:
      raise newException(FormatError, "Leading 0 in with not allowed with explicit alignment")
    result.fill = "0"
    result.align = faPadding

  result.comma = caps.has(5)

  result.precision = fmt.get(caps, 6, -1, 1)

  case fmt.get(caps, 7, 0.char)
  of 's': result.typ = ftStr
  of 'c': result.typ = ftChar
  of 'd', 'n': result.typ = ftDec
  of 'b': result.typ = ftBin
  of 'o': result.typ = ftOct
  of 'x': result.typ = ftHex
  of 'X': result.typ = ftHex; result.upcase = true
  of 'f', 'F': result.typ = ftFix
  of 'e': result.typ = ftSci
  of 'E': result.typ = ftSci; result.upcase = true
  of 'g': result.typ = ftGen
  of 'G': result.typ = ftGen; result.upcase = true
  of '%': result.typ = ftPercent
  else: result.typ = ftDefault

  result.arysep = fmt.get(caps, 8, "", 1)

proc getalign(fmt: Format; defalign: FmtAlign; slen: int) : tuple[left, right:int] {.nosideeffect.} =
  ## Returns the number of left and right padding characters for a
  ## given format alignment and width of the object to be printed.
  ##
  ## `fmt`
  ##    the format data
  ## `default`
  ##    if `fmt.align == faDefault`, then this alignment is used
  ## `slen`
  ##    the width of the object to be printed.
  ##
  ## The returned values `(left, right)` will be as minimal as possible
  ## so that `left + slen + right >= fmt.width`.
  result.left = 0
  result.right = 0
  if (fmt.width >= 0) and (slen < fmt.width):
    let alg = if fmt.align == faDefault: defalign else: fmt.align
    case alg:
    of faLeft: result.right = fmt.width - slen
    of faRight, faPadding: result.left = fmt.width - slen
    of faCenter:
      result.left = (fmt.width - slen) div 2
      result.right = fmt.width - slen - result.left
    else: discard

proc writefill(o: var Writer; fmt: Format; n: int; signum: int = 0) =
  ## Write characters for filling. This function also writes the sign
  ## of a numeric format and handles the padding alignment
  ## accordingly.
  ##
  ## `o`
  ##   output object
  ## `add`
  ##   output function
  ## `fmt`
  ##   format to be used (important for padding alignment)
  ## `n`
  ##   the number of filling characters to be written
  ## `signum`
  ##   the sign of the number to be written, < 0 negative, > 0 positive, = 0 zero
  if fmt.align == faPadding and signum != 0:
    if signum < 0: write(o, '-')
    elif fmt.sign == fsPlus: write(o, '+')
    elif fmt.sign == fsSpace: write(o, ' ')

  if fmt.fill.len == 0:
    for i in 1..n: write(o, ' ')
  else:
    for i in 1..n:
      for c in fmt.fill:
        write(o, c)

  if fmt.align != faPadding and signum != 0:
    if signum < 0: write(o, '-')
    elif fmt.sign == fsPlus: write(o, '+')
    elif fmt.sign == fsSpace: write(o, ' ')

proc writeformat(o: var Writer; s: string; fmt: Format) =
  ## Write string `s` according to format `fmt` using output object
  ## `o` and output function `add`.
  if fmt.typ notin {ftDefault, ftStr}:
    raise newException(FormatError, "String variable must have 's' format type")

  # compute alignment
  let len = if fmt.precision < 0: runelen(s) else: min(runelen(s), fmt.precision)
  var alg = getalign(fmt, faLeft, len)
  writefill(o, fmt, alg.left)
  var pos = 0
  for i in 0..len-1:
    let rlen = runeLenAt(s, pos)
    for j in pos..pos+rlen-1: write(o, s[j])
    pos += rlen
  writefill(o, fmt, alg.right)

proc writeformat(o: var Writer; c: char; fmt: Format) =
  ## Write character `c` according to format `fmt` using output object
  ## `o` and output function `add`.
  if not (fmt.typ in {ftChar, ftDefault}):
    raise newException(FormatError, "Character variable must have 'c' format type")

  # compute alignment
  var alg = getalign(fmt, faLeft, 1)
  writefill(o, fmt, alg.left)
  write(o, c)
  writefill(o, fmt, alg.right)

proc writeformat(o: var Writer; c: Rune; fmt: Format) =
  ## Write rune `c` according to format `fmt` using output object
  ## `o` and output function `add`.
  if not (fmt.typ in {ftChar, ftDefault}):
    raise newException(FormatError, "Character variable must have 'c' format type")

  # compute alignment
  var alg = getalign(fmt, faLeft, 1)
  writefill(o, fmt, alg.left)
  let s = c.toUTF8
  for c in s: write(o, c)
  writefill(o, fmt, alg.right)

proc abs(x: SomeUnsignedInt): SomeUnsignedInt {.inline.} = x
  ## Return the absolute value of the unsigned int `x`.

proc writeformat(o: var Writer; i: SomeInteger; fmt: Format) =
  ## Write integer `i` according to format `fmt` using output object
  ## `o` and output function `add`.
  var fmt = fmt
  if fmt.typ == ftDefault:
    fmt.typ = ftDec
  if not (fmt.typ in {ftBin, ftOct, ftHex, ftDec}):
    raise newException(FormatError, "Integer variable must of one of the following types: b,o,x,X,d,n")

  var base: type(i)
  var len = 0
  case fmt.typ:
  of ftDec:
    base = 10
  of ftBin:
    base = 2
    if fmt.baseprefix: len += 2
  of ftOct:
    base = 8
    if fmt.baseprefix: len += 2
  of ftHex:
    base = 16
    if fmt.baseprefix: len += 2
  else: assert(false)

  if fmt.sign != fsMinus or i < 0: len.inc

  var x: type(i) = abs(i)
  var irev: type(i) = 0
  var ilen = 0
  while x > 0.SomeInteger:
    len.inc
    ilen.inc
    irev = irev * base + x mod base
    x = x div base
  if ilen == 0:
    ilen.inc
    len.inc

  var alg = getalign(fmt, faRight, len)
  writefill(o, fmt, alg.left, if i >= 0.SomeInteger: 1 else: -1)
  if fmt.baseprefix:
    case fmt.typ
    of ftBin:
      write(o, '0')
      write(o, 'b')
    of ftOct:
      write(o, '0')
      write(o, 'o')
    of ftHex:
      write(o, '0')
      write(o, 'x')
    else:
      raise newException(FormatError, "# only allowed with b, o, x or X")
  while ilen > 0:
    ilen.dec
    let c = irev mod base
    irev = irev div base
    if c < 10:
      write(o, ('0'.int + c.int).char)
    elif fmt.upcase:
      write(o, ('A'.int + c.int - 10).char)
    else:
      write(o, ('a'.int + c.int - 10).char)
  writefill(o, fmt, alg.right)

proc writeformat(o: var Writer; p: pointer; fmt: Format) =
  ## Write pointer `i` according to format `fmt` using output object
  ## `o` and output function `add`.
  ##
  ## Pointers are cast to unsigned int and formatted as hexadecimal
  ## with prefix unless specified otherwise.
  var f = fmt
  if f.typ == 0.char:
    f.typ = 'x'
    f.baseprefix = true
  writeformat(o, add, cast[uint](p), f)

proc writeformat(o: var Writer; x: SomeFloat; fmt: Format) =
  ## Write real number `x` according to format `fmt` using output
  ## object `o` and output function `add`.
  var fmt = fmt
  # handle default format
  if fmt.typ == ftDefault:
    fmt.typ = ftGen
    if fmt.precision < 0: fmt.precision = DefaultPrec
  if not (fmt.typ in {ftFix, ftSci, ftGen, ftPercent}):
    raise newException(FormatError, "Integer variable must of one of the following types: f,F,e,E,g,G,%")

  let positive = x >= 0 and classify(x) != fcNegZero
  var len = 0

  if fmt.sign != fsMinus or not positive: len.inc

  var prec = if fmt.precision < 0: DefaultPrec else: fmt.precision
  var y = abs(x)
  var exp = 0
  var numstr, frstr: array[0..31, char]
  var numlen, frbeg, frlen = 0

  if fmt.typ == ftPercent: y *= 100

  case classify(x):
  of fcNan:
    numstr[0..2] = ['n', 'a', 'n']
    numlen = 3
  of fcInf, fcNegInf:
    numstr[0..2] = ['f', 'n', 'i']
    numlen = 3
  of fcZero, fcNegZero:
    numstr[0] = '0'
    numlen = 1
  else: # a usual fractional number
    if not (fmt.typ in {ftFix, ftPercent}): # not fixed point
      exp = int(floor(log10(y)))
      if fmt.typ == ftGen:
        if prec == 0: prec = 1
        if -4 <= exp and exp < prec:
          prec = prec-1-exp
          exp = 0
        else:
          prec = prec - 1
          len += 4 # exponent
      else:
        len += 4 # exponent
      # shift y so that 1 <= abs(y) < 2
      if exp > 0: y /= pow(10.SomeFloat, abs(exp).SomeFloat)
      elif exp < 0: y *= pow(10.SomeFloat, abs(exp).SomeFloat)
    elif fmt.typ == ftPercent:
      len += 1 # percent sign

    # handle rounding by adding +0.5 * LSB
    if prec < len(round_nums): y += round_nums[prec]

    # split into integer and fractional part
    var mult = 1'i64
    for i in 1..prec: mult *= 10
    var num = y.int64
    var fr = ((y - num.SomeFloat) * mult.SomeFloat).int64
    # build integer part string
    while num != 0:
      numstr[numlen] = ('0'.int + (num mod 10)).char
      numlen.inc
      num = num div 10
    if numlen == 0:
      numstr[0] = '0'
      numlen.inc
    # build fractional part string
    while fr != 0:
      frstr[frlen] = ('0'.int + (fr mod 10)).char
      frlen.inc
      fr = fr div 10
    while frlen < prec:
      frstr[frlen] = '0'
      frlen.inc
    # possible remove trailing 0
    if fmt.typ == ftGen:
      while frbeg < frlen and frstr[frbeg] == '0': frbeg.inc
  # update length of string
  len += numlen;
  if frbeg < frlen:
    len += 1 + frlen - frbeg # decimal point and fractional string

  let alg = getalign(fmt, faRight, len)
  writefill(o, fmt, alg.left, if positive: 1 else: -1)
  for i in (numlen-1).countdown(0): write(o, numstr[i])
  if frbeg < frlen:
    write(o, '.')
    for i in (frlen-1).countdown(frbeg): write(o, frstr[i])
  if fmt.typ == ftSci or (fmt.typ == ftGen and exp != 0):
    write(o, if fmt.upcase: 'E' else: 'e')
    if exp >= 0:
      write(o, '+')
    else:
      write(o, '-')
      exp = -exp
    if exp < 10:
      write(o, '0')
      write(o, ('0'.int + exp).char)
    else:
      var i=0
      while exp > 0:
        numstr[i] = ('0'.int + exp mod 10).char
        i+=1
        exp = exp div 10
      while i>0:
        i-=1
        write(o, numstr[i])
  if fmt.typ == ftPercent: write(o, '%')
  writefill(o, fmt, alg.right)

proc writeformat(o: var Writer; b: bool; fmt: Format) =
  ## Write boolean value `b` according to format `fmt` using output
  ## object `o`. A boolean may be formatted numerically or as string.
  ## In the former case true is written as 1 and false as 0, in the
  ## latter the strings "true" and "false" are shown, respectively.
  ## The default is string format.
  if fmt.typ in {ftStr, ftDefault}:
    writeformat(o,
                if b: "true"
                else: "false",
                fmt)
  elif fmt.typ in {ftBin, ftOct, ftHex, ftDec}:
    writeformat(o,
                if b: 1
                else: 0,
                fmt)
  else:
    raise newException(FormatError, "Boolean values must of one of the following types: s,b,o,x,X,d,n")

proc writeformat(o: var Writer; ary: openArray[system.any]; fmt: Format) =
  ## Write array `ary` according to format `fmt` using output object
  ## `o` and output function `add`.
  if ary.len == 0: return

  var sep: string
  var nxtfmt = fmt
  if fmt.arysep == nil:
    sep = "\t"
  elif fmt.arysep.len == 0:
    sep = ""
  else:
    let sepch = fmt.arysep[0]
    let nxt = 1 + skipUntil(fmt.arysep, sepch, 1)
    if nxt >= 1:
      nxtfmt.arysep = fmt.arysep.substr(nxt)
      sep = fmt.arysep.substr(1, nxt-1)
    else:
      nxtfmt.arysep = ""
      sep = fmt.arysep.substr(1)
  writeformat(o, ary[0], nxtfmt)
  for i in 1..ary.len-1:
    for c in sep: write(o, c)
    writeformat(o, ary[i], nxtfmt)

proc addformat[T](o: var Writer; x: T; fmt: Format = DefaultFmt) {.inline.} =
  ## Write `x` formatted with `fmt` to `o`.
  writeformat(o, x, fmt)

proc addformat[T](o: var Writer; x: T; fmt: string) {.inline.} =
  ## The same as `addformat(o, x, parse(fmt))`.
  addformat(o, x, fmt.parse)

proc addformat(s: var string; x: string) {.inline.} =
  ## Write `x` to `s`. This is a fast specialized version for
  ## appending unformatted strings.
  add(s, x)

proc addformat(f: File; x: string) {.inline.} =
  ## Write `x` to `f`. This is a fast specialized version for
  ## writing unformatted strings to a file.
  write(f, x)

proc addformat[T](f: File; x: T; fmt: Format = DefaultFmt) {.inline.} =
  ## Write `x` to file `f` using format `fmt`.
  var g = f
  writeformat(g, x, fmt)

proc addformat[T](f: File; x: T; fmt: string) {.inline.} =
  ## Write `x` to file `f` using format string `fmt`. This is the same
  ## as `addformat(f, x, parse(fmt))`
  addformat(f, x, parse(fmt))

proc addformat(s: Stream; x: string) {.inline.} =
  ## Write `x` to `s`. This is a fast specialized version for
  ## writing unformatted strings to a stream.
  write(s, x)

proc addformat[T](s: Stream; x: T; fmt: Format = DefaultFmt) {.inline.} =
  ## Write `x` to stream `s` using format `fmt`.
  var g = s
  writeformat(g, x, fmt)

proc addformat[T](s: Stream; x: T; fmt: string) {.inline.} =
  ## Write `x` to stream `s` using format string `fmt`. This is the same
  ## as `addformat(s, x, parse(fmt))`
  addformat(s, x, parse(fmt))

proc format[T](x: T; fmt: Format): string =
  ## Return `x` formatted as a string according to format `fmt`.
  result = ""
  addformat(result, x, fmt)

proc format[T](x: T; fmt: string): string =
  ## Return `x` formatted as a string according to format string `fmt`.
  result = format(x, fmt.parse)

proc format[T](x: T): string {.inline.} =
  ## Return `x` formatted as a string according to the default format.
  ## The default format corresponds to an empty format string.
  var fmt {.global.} : Format = DefaultFmt
  result = format(x, fmt)

proc unquoted(s: string): string {.compileTime.} =
  ## Return `s` {{ and }} by single { and }, respectively.
  result = ""
  var pos = 0
  while pos < s.len:
    let nxt = pos + skipUntil(s, {'{', '}'})
    result.add(s.substr(pos, nxt))
    pos = nxt + 2

proc splitfmt(s: string): seq[Part] {.compiletime, nosideeffect.} =
  ## Split format string `s` into a sequence of "parts".
  ##

  ## Each part is either a literal string or a format specification. A
  ## format specification is a substring of the form
  ## "{[arg][:format]}" where `arg` is either empty or a number
  ## referring to the arg-th argument and an additional field or array
  ## index. The format string is a string accepted by `parse`.
  let subpeg = sequence(capture(digits()),
                          capture(?sequence(charSet({'.'}), *pegs.identStartChars(), *identChars())),
                          capture(?sequence(charSet({'['}), +digits(), charSet({']'}))),
                          capture(?sequence(charSet({':'}), *pegs.any())))
  result = @[]
  var pos = 0
  while true:
    let oppos = pos + skipUntil(s, {'{', '}'}, pos)
    # reached the end
    if oppos >= s.len:
      if pos < s.len:
        result.add(Part(kind: pkStr, str: s.substr(pos).unquoted))
      return
    # skip double
    if oppos + 1 < s.len and s[oppos] == s[oppos+1]:
      result.add(Part(kind: pkStr, str: s.substr(pos, oppos)))
      pos = oppos + 2
      continue
    if s[oppos] == '}':
      error("Single '}' encountered in format string")
    if oppos > pos:
      result.add(Part(kind: pkStr, str: s.substr(pos, oppos-1).unquoted))
    # find matching closing }
    var lvl = 1
    var nested = false
    pos = oppos
    while lvl > 0:
      pos.inc
      pos = pos + skipUntil(s, {'{', '}'}, pos)
      if pos >= s.len:
        error("Single '{' encountered in format string")
      if s[pos] == '{':
        lvl.inc
        if lvl == 2:
          nested = true
        if lvl > 2:
          error("Too many nested format levels")
      else:
        lvl.dec
    let clpos = pos
    var fmtpart = Part(kind: pkFmt, arg: -1, fmt: s.substr(oppos+1, clpos-1), field: "", index: int.high, nested: nested)
    if fmtpart.fmt.len > 0:
      var m: array[0..3, string]
      if not fmtpart.fmt.match(subpeg, m):
        error("invalid format string")

      if m[1].len > 0:
        fmtpart.field = m[1].substr(1)
      if m[2].len > 0:
        discard parseInt(m[2].substr(1, m[2].len-2), fmtpart.index)

      if m[0].len > 0: discard parseInt(m[0], fmtpart.arg)
      if m[3].len == 0:
        fmtpart.fmt = ""
      elif m[3][0] == ':':
        fmtpart.fmt = m[3].substr(1)
      else:
        fmtpart.fmt = m[3]
    result.add(fmtpart)
    pos = clpos + 1

proc literal(s: string): NimNode {.compiletime, nosideeffect.} =
  ## Return the nim literal of string `s`. This handles the case if
  ## `s` is nil.
  result = newLit(s)

proc literal(b: bool): NimNode {.compiletime, nosideeffect.} =
  ## Return the nim literal of boolean `b`. This is either `true`
  ## or `false` symbol.
  result = if b: "true".ident else: "false".ident

proc literal[T](x: T): NimNode {.compiletime, nosideeffect.} =
  ## Return the nim literal of value `x`.
  when type(x) is enum:
    result = ($x).ident
  else:
    result = newLit(x)

proc generatefmt(fmtstr: string;
                 args: var openArray[tuple[arg:NimNode, cnt:int]];
                 arg: var int;): seq[tuple[val, fmt:NimNode]] {.compiletime.} =
  ## fmtstr
  ##   the format string
  ## args
  ##   array of expressions for the arguments
  ## arg
  ##   the number of the next argument for automatic parsing
  ##
  ## If arg is < 0 then the functions assumes that explicit numbering
  ## must be used, otherwise automatic numbering is used starting at
  ## `arg`. The value of arg is updated according to the number of
  ## arguments being used. If arg == 0 then automatic and manual
  ## numbering is not decided (because no explicit manual numbering is
  ## fixed und no automatically numbered argument has been used so
  ## far).
  ##
  ## The function returns a list of pairs `(val, fmt)` where `val` is
  ## an expression to be formatted and `fmt` is the format string (or
  ## Format). Therefore, the resulting string can be generated by
  ## concatenating expressions `val.format(fmt)`. If `fmt` is `nil`
  ## then `val` is a (literal) string expression.
  try:
    result = @[]
    for part in splitfmt(fmtstr):
      case part.kind
      of pkStr: result.add((newLit(part.str), nil))
      of pkFmt:
        # first compute the argument expression
        # start with the correct index
        var argexpr : NimNode
        if part.arg >= 0:
          if arg > 0:
            error("Cannot switch from automatic field numbering to manual field specification")
          if part.arg >= args.len:
            error("Invalid explicit argument index: " & $part.arg)
          argexpr = args[part.arg].arg
          args[part.arg].cnt = args[part.arg].cnt + 1
          arg = -1
        else:
          if arg < 0:
            error("Cannot switch from manual field specification to automatic field numbering")
          if arg >= args.len:
            error("Too few arguments for format string")
          argexpr = args[arg].arg
          args[arg].cnt = args[arg].cnt + 1
          arg.inc
        # possible field access
        if part.field.len > 0:
          argexpr = newDotExpr(argexpr, part.field.ident)
        # possible array access
        if part.index < int.high:
          argexpr = newNimNode(nnkBracketExpr).add(argexpr, newLit(part.index))
        # now the expression for the format data
        var fmtexpr: NimNode
        if part.nested:
          # nested format string. Compute the format string by
          # concatenating the parts of the substring.
          for e in generatefmt(part.fmt, args, arg):
            var newexpr = if part.fmt.len == 0: e.val else: newCall(bindsym"format", e.val, e.fmt)
            if fmtexpr != nil and fmtexpr.kind != nnkNilLit:
              fmtexpr = infix(fmtexpr, "&", newexpr)
            else:
              fmtexpr = newexpr
        else:
          # literal format string, precompute the format data
          fmtexpr = newNimNode(nnkPar)
          for field, val in part.fmt.parse.fieldPairs:
            fmtexpr.add(newNimNode(nnkExprColonExpr).add(field.ident, literal(val)))
        # add argument
        result.add((argexpr, fmtexpr))
  finally:
    discard

proc addfmtfmt(fmtstr: string; args: NimNode; retvar: NimNode): NimNode {.compileTime.} =
  var argexprs = newseq[tuple[arg:NimNode; cnt:int]](args.len)
  result = newNimNode(nnkStmtListExpr)
  # generate let bindings for arguments
  for i in 0..args.len-1:
    let argsym = gensym(nskLet, "arg" & $i)
    result.add(newLetStmt(argsym, args[i]))
    argexprs[i].arg = argsym
  # add result values
  var arg = 0
  for e in generatefmt(fmtstr, argexprs, arg):
    if e.fmt == nil or e.fmt.kind == nnkNilLit:
      result.add(newCall(bindsym"addformat", retvar, e.val))
    else:
      result.add(newCall(bindsym"addformat", retvar, e.val, e.fmt))
  for i, arg in argexprs:
    if arg.cnt == 0:
      warning("Argument " & $(i+1) & " `" & args[i].repr & "` is not used in format string")

macro addfmt(s: var string, fmtstr: string{lit}, args: varargs[typed]): untyped =
  ## The same as `s.add(fmtstr.fmt(args...))` but faster.
  result = addfmtfmt($fmtstr, args, s)

var s: string = ""
s.addfmt("a:{}", 42)
