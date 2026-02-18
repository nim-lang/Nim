#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides the standard Nim command line parser.
## It supports one convenience iterator over all command line options and some
## lower-level features.
##
## Supported Syntax
## ================
##
## The syntax described here applies to the default way the parser works.
## The behavior is configurable, though, and two additional modes
## are supported, see the details: `Parser Modes`_.
##
## Parsing also depends on whether the `shortNoVal` and `longNoVal` parameters
## are omitted/empty or provided. The details are described in a
## `later section<#nimshortnoval-and-nimlongnoval>`_.
##
## The following syntax is supported:
##
## 1. Short options: `-a:5`, `-b=5`, `-cde`, `-fgh=5`
## 2. Long options: `--foo:bar`, `--foo=bar`, `--foo`
## 3. Arguments: everything that does not start with a `-`
##
## Passing values to options **requires** a separator (`:`/`=`), short options
## (flags) can be bundled together and the last one can take a value.
##
## Option values can begin with the separator character (`:`/`=`), so all of the
## following is valid:
##   - option `foo`, value `:`:  `--foo::`, `--foo=:`
##   - option `foo`, value `=`:  `--foo:=`, `--foo==`
##
## The `--` option, commonly used to denote that every token that follows is
## an argument, is interpreted as a long option, and its name is the empty
## string. Trailing arguments can be accessed with `remainingArgs<#remainingArgs,OptParser>`_
## or `cmdLineRest<#cmdLineRest,OptParser>`_.
##
## Parsing
## =======
##
## To parse command line options, use the `getopt iterator<#getopt.i,OptParser>`_.
## It initializes the `OptParser<#OptParser>`_ object internally and iterates
## through the command line options.
##
## For each token, the parser's `kind` (`CmdLineKind enum<#CmdLineKind>`_.),
## `key`, and `val` fields are yielded.
##
## For long and short options, `key` is the option's name, and `val` is either
## the option's value, if given, or an empty string. For arguments, the `key`
## field contains the argument itself, and `val` is unused (empty).
##
## Here is an example:
##
runnableExamples:
  import std/os

  let cmds = "-ab -e:5 --foo --bar=20 file.txt".parseCmdLine()
  var output: seq[string] = @[]
  # If cmds is not supplied, real arguments will be retrieved by the `os` module
  for kind, key, val in getopt(cmds):
    case kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if val == "":
        output.add("Option: " & key)
      else:
        output.add("Option and value: " & key & ", " & val)
    of cmdArgument:
      output.add("Argument: " & key)

  doAssert output == @[
    "Option: a",
    "Option: b",
    "Option and value: e, 5",
    "Option: foo",
    "Option and value: bar, 20",
    "Argument: file.txt"
  ]
##
## The `OptParser<#OptParser>`_ can be initialized with
## `initOptParser<#initOptParser,string,set[char],seq[string]>`_.
## The `next<#next,OptParser>`_ proc advances the parser by one token.
##
## When iterating the object manually with `next<#next,OptParser>`_, reaching
## the end of the command line is signalled by setting the `kind` field
## to `cmdEnd`.
##
## To set a default value for an option, assign the default value to a variable
## beforehand, then update it while parsing.
##
runnableExamples:
  import std/strutils

  var varName: string = "defaultValue"

  for kind, key, val in getopt(@["--varName:HELLO"]):
    case kind
    of cmdArgument:
      discard
    of cmdLongOption, cmdShortOption:
      case key
      of "varName":  # --varName:<value> in the console when executing
        varName = val.toLowerAscii() # do input sanitization in production
    of cmdEnd:
      discard

  doAssert varName == "hello"
##
## `shortNoVal` and `longNoVal`
## ============================
##
## The optional `shortNoVal` and `longNoVal` parameters in
## `initOptParser<#initOptParser,string,set[char],seq[string]>`_ and
## `getopt iterator<#getopt.i,OptParser>`_ are for
## specifying which short and long options do not accept values.
##
## When `shortNoVal` or `longNoVal` is non-empty, using the separators (`:`/`=`)
## becomes non-mandatory and users can separate a value from long
## options (that are not supplied to the corresponding argument) by whitespace
## or, in the case of a short option, by writing the value directly adjacent to
## the option.
##
## For short options, `-j4` becomes supported syntax (parsed as option `j` with
## value `4` instead of two separate options `j` and `4`). For long options,
## `--foo bar` becomes supported syntax in all `modes<Parser Modes>`_.
##
## In `LaxMode` and `GnuMode`, short options can also take values from the next
## argument (`-c val`), but this does **not** work in the default `Nim` mode.
##
## As more options which do not accept values are added to your program,
## remember to amend `shortNoVal` and `longNoVal` accordingly.
##
## The parser does not validate the input for syntax mistakes, thus, options
## can still have values if passed explicitly by the user, even when they are
## marked as `shortNoVal`/`longNoVal`.
##
## This behavior allows associating an option with the mistakenly passed value:
##
runnableExamples:
  import std/[sequtils, os]

  let cmds = "-n:9 --foo:bar".parseCmdLine()
  let parsed = toSeq(cmds.getopt(shortNoVal = {'n'}, longNoVal = @["foo"]))
  for (kind, key, val) in parsed:
   case kind
   of cmdEnd: raise newException(AssertionDefect, "Unreachable")
   of cmdShortOption, cmdLongOption:
     if key in ["n", "foo"] and val != "":
       # Substitute for proper error handling in your code
       discard "Option " & key & " can't take values!"
     else: discard
   of cmdArgument: discard
  doAssert parsed == @[
   (cmdShortOption, "n", "9"),
   (cmdLongOption, "foo", "bar")]
##
## .. Important::
##   Next-argument value-taking for short/long options is only enabled when
##   `shortNoVal`/`longNoVal` are non-empty. If your program has *no* options
##   that take no value, you still must pass a non-empty placeholder (for example,
##   `shortNoVal = {'\0'}` and/or `longNoVal = @[""]`) to enable this form.
##
## The following example illustrates the difference between having an empty
## `shortNoVal` and `longNoVal`, which is the default, and providing
## arguments for those two parameters:
##
runnableExamples:

  proc format(kind: CmdLineKind; key, val: string): string =
    case kind
    of cmdEnd: raise newException(AssertionDefect, "Unreachable")
    of cmdShortOption, cmdLongOption:
      if val == "": "Option: " & key
      else:         "Option and value: " & key & ", " & val
    of cmdArgument: "Argument: " & key

  let cmdLine = "-j4 --first bar"
  var output1, output2: seq[string] = @[]

  var emptyNoVal = initOptParser(cmdLine)
  for kind, key, val in emptyNoVal.getopt():
    output1.add format(kind, key, val)

  doAssert output1 == @[
    "Option: j",
    "Option: 4",
    "Option: first",
    "Argument: bar"
  ]

  var withNoVal = cmdLine.initOptParser(shortNoVal = {'c'},
                                  longNoVal = @["second"])
  for kind, key, val in withNoVal.getopt():
    output2.add format(kind, key, val)

  doAssert output2 == @[
    "Option and value: j, 4",
    "Option and value: first, bar"
  ]
##
## Parser Modes
## ============
##
## .. Warning:: Modes other than the default (`Nim`) are **experimental** and may
##    change in future releases.
##
## The parser supports several distinct rule sets that change how options are
## interpreted:
##
## 1. **LaxMode**: Most forgiving mode, combines `Nim` with POSIX-like
##    short option handling. Tries to follow the POSIX_ guidelines where possible.
## 2. **NimMode**: Standard Nim parsing rules (default).
## 3. **GnuMode**: GNU-inspired parsing (e.g. `=` as the only delimiter).
##    Puts some additional restrictions, following some of the GNU_ conventions.
##
## Modes are ordered from most relaxed to strictest. The names were
## chosen to set general user expectations and full compliance is neither
## achieved nor planned.
##
## Mode Differences
## ----------------
##
## **NimMode** (default):
##
## - Short options require adjacent values or explicit delimiters:
##   `-cval`, `-c:val`, `-c=val`
## - Short options follow POSIX-style bundling rules
## - Next-argument value taking (`-c val`) is **not** supported by default
## - Supports both `:` and `=` as delimiters
## - Allows whitespace around delimiters
## - Values starting with `-` are interpreted as new options
##
## **LaxMode**:
##
## - Essentially the Nim mode with some relaxations for short options:
##   + Allows short options to take values from the next argument: `-c val`
##   + Supports bundled short options with trailing value: `-abc val`
## - Values starting with `-` can be consumed as option arguments
##
## **GnuMode**:
##
## - Only `=` is treated as a delimiter (`:` is not a delimiter)
## - No whitespace allowed around `=`
## - Short options can take next-argument values (`-c val`), but only whitespace
##   is allowed as a delimiter, separators parse as part of the value
## - Short options follow POSIX-style bundling rules
## - Values starting with `-` can be consumed as option arguments
## - Known discrepancies compared to GNU getopt:
##   + No notion of optional/mandatory arguments, colon (`:`) doesn't
##     indicate them and overall is not a special character.
##
## Mode-Specific Behavior
## ----------------------
##
## The parser's behavior varies significantly between modes, particularly
## around how options consume their values:
##
## **Short Options**
##
## Consider `-c val`:
##
## - In `Nim` mode: `-c` is parsed as an option without a value, and `val` is
##   parsed as a separate argument, regardless of `shortNoVal` being empty or not.
## - In `Lax` and `Gnu` modes:
##   + When `shortNoVal` is empty, or not empty and `-c` is in it:
##     Same as `Nim`, parsed as option `-c` followed by argument `val`.
##   + When `-c` is not in `shortNoVal`:
##     parsed as option `-c`, `val` is consumed as its value.
##
## Consider `-c-10`:
##
## - If `shortNoVal` value is empty, all three modes parse three separate short
##   options: `c`, `1` and `0`.
## - Otherwise, if `-c` is not in `shortNoVal`:
##   + `Nim`: `-c` is an option without an argument. `-10` is interpreted as a
##      an option `-1` with the `0` argument.
##   + `Lax` and `Gnu` modes: `-10` is consumed as the value of `-c`
##     (allowing negative number values).
##
## **Long Options**
##
## Consider `--foo:bar`:
##
## - `Nim`: `:` is a valid delimiter, so `bar` is the value of `--foo`.
## - `LaxMode`: same as `Nim`.
## - `Gnu`: only `=` is a valid delimiter, so this parses as an option named
##   `foo:bar` without a value (unless `longNoVal` is non-empty and allows
##   next-argument consumption).
##
## Consider `--foo =bar`:
##
## - `Nim`: whitespace around delimiters is allowed, so `=bar` is the
##   value of `--foo`.
## - `LaxMode`: same as `Nim`.
## - `Gnu`: whitespace around `=` is not allowed, so `--foo` is an
##   option without a value, and `=bar` is parsed as an argument.
##
## Custom Rule Sets
## ================
##
## .. Warning:: Custom rule sets are unsupported and not tested
##
## If you require parsing rules beyond the three provided modes, it's possible
## to define a custom parser behavior by specifying a set of individual parser
## rules.
##
## Due to this feature being unsupported, it requires importing the private
## symbols of the module (with `import std/parseopt {.all.}`) and utilizing
## the unexported `initOptParser` overload, which accepts `set[ParserRules]`
## (see the `ParserRules` enum in the code for details).
##
## See also
## ========
##
## * `os module<os.html>`_ for lower-level command line parsing procs
## * `parseutils module<parseutils.html>`_ for helpers that parse tokens,
##   numbers, identifiers, etc.
## * `strutils module<strutils.html>`_ for common string handling operations
## * `json module<json.html>`_ for a JSON parser
## * `parsecfg module<parsecfg.html>`_ for a configuration file parser
## * `parsecsv module<parsecsv.html>`_ for a simple CSV (comma separated value)
##   parser
## * `parsexml module<parsexml.html>`_ for a XML / HTML parser
## * `other parsers<lib.html#pure-libraries-parsers>`_ for more parsers
## * POSIX_ - The Open Group Base Specifications Issue 8. Utility Conventions
## * GNU_ - GNU C Library reference manual. 26.1.1 Program Argument Syntax Conventions
##
## .. _GNU: https://sourceware.org/glibc/manual/latest/html_node/Argument-Syntax.html
## .. _POSIX: https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap12.html

{.push debugger: off.}

include "system/inclrtl"

import std/os
when defined(nimscript):
  from std/strutils import toLowerAscii, endsWith

type
  CliMode* = enum
    ## Parser behavior profiles used to control parser behavior.
    ## See `Parser Modes`_ for details.
    LaxMode, ## The most forgiving mode
    NimMode, ## Nim parsing rules (default)
    GnuMode ## GNU-style parsing

type
  ParserRules = enum
    ## Feature flags used to assemble parser behavior for a given mode.
    prSepAllowDelimBefore,       ## Allow whitespace before an opt-val separator
    prSepAllowDelimAfter,        ## Allow whitespace after an opt-val separator
    prShortAllowSep,             ## Allow `-k<separator>val` form
    prShortBundle,               ## Allow bundling short options behind one '-'
    prShortValAllowAdjacent,     ## Allow adjacent short option values: `-kval`
    prShortValAllowNextArg,      ## Allow next-argv short option values: `-k val`
    prShortValAllowDashLeading,  ## Allow values that start with '-' to be taken
    prLongAllowSep,              ## Allow `--opt<separator>val` form
    prLongValAllowNextArg,       ## Allow `--opt val` form, requires non-empty `longNoVal`
    prSepAllowColon,             ## Allow `:` as an opt-val separator
    prSepAllowEq,                ## Allow `=` as an opt-val separator

type
  CmdLineKind* = enum ## The detected command line token.
    cmdEnd,           ## End of command line reached
    cmdArgument,      ## An argument such as a filename
    cmdLongOption,    ## A long option such as --option
    cmdShortOption    ## A short option such as -c
  OptParser* = object of RootObj ## \
    ## Implementation of the command line parser.
    ##
    ## To initialize it, use the
    ## `initOptParser proc<#initOptParser,string,set[char],seq[string],CliMode>`_.
    ## `next<#next,OptParser>`_ is used to advance the parser state and move
    ## through the parsed tokens.
    pos: int
    inShortState: bool
    shortNoVal: set[char]
    longNoVal: seq[string]
    cmds: seq[string]
    idx: int
    separators: set[char]        ## Allowed separators for long/short option values
    rules: set[ParserRules]
    kind*: CmdLineKind           ## The detected command line token
    key*, val*: string           ## Key and value pair; the key is the option
                                 ## or the argument, and the value is not "" if
                                 ## the option was given a value

const DelimSet = {'\t', ' '} ## Allowed delimiters between tokens

func toRules(m: CliMode): set[ParserRules] =
  ## Default rule sets for the given mode `m`
  let
    Common = {
      prSepAllowEq,
      prShortValAllowAdjacent,
      prShortBundle,
      prLongValAllowNextArg,
      prLongAllowSep,
    }
    Lax = {
      prSepAllowColon,
      prSepAllowDelimBefore,
      prSepAllowDelimAfter,
      prShortAllowSep,
    }
    ShortPosix = {
      prShortValAllowNextArg,
      prShortValAllowDashLeading,
    }
  case m
  of LaxMode: Common + Lax + ShortPosix
  of NimMode: Common + Lax
  of GnuMode: Common + ShortPosix

proc parseWord(s: string, i: int, w: var string,
               delim: set[char] = DelimSet): int =
  result = i
  if result < s.len and s[result] == '\"':
    inc(result)
    while result < s.len:
      if s[result] == '"':
        inc result
        break
      add(w, s[result])
      inc(result)
  else:
    while result < s.len and s[result] notin delim:
      add(w, s[result])
      inc(result)

proc initOptParser(cmdline: openArray[string];
                    shortNoVal: set[char];
                    longNoVal: seq[string];
                    rules: set[ParserRules]): OptParser =
  result = OptParser(pos: 0, idx: 0,
                    cmds: @cmdline,
                    inShortState: false,
                    shortNoVal: shortNoVal,
                    longNoVal: longNoVal,
                    separators: {},
                    rules: rules,
                    kind: cmdEnd,
                    key: "", val: "",
                    )
  if prSepAllowEq    in rules: result.separators.incl('=')
  if prSepAllowColon in rules: result.separators.incl(':')
  if cmdline.len == 0:
    when declared(paramCount):
      when defined(nimscript):
        var ctr = 0
        var firstNimsFound = false
        for i in countup(0, paramCount()):
          if firstNimsFound: 
            result.cmds[ctr] = paramStr(i)
            inc ctr, 1
          if paramStr(i).toLowerAscii().endsWith(".nims") and not firstNimsFound:
            firstNimsFound = true 
            result.cmds = newSeq[string](paramCount()-i)
      else:
        result.cmds = newSeq[string](paramCount())
        for i in countup(1, paramCount()):
          result.cmds[i-1] = paramStr(i)
    else:
      # we cannot provide this for NimRtl creation on Posix, because we can't
      # access the command line arguments then!
      raiseAssert "empty command line given but" &
        " real command line is not accessible"

proc initOptParser*(cmdline: seq[string];
                    shortNoVal: set[char] = {};
                    longNoVal: seq[string] = @[];
                    mode: CliMode = NimMode): OptParser =
  ## Initializes the command line parser.
  ##
  ## **Parameters:**
  ##
  ## - `cmdline`: Sequence of command line arguments to parse. If empty, the
  ##   real command line as provided by the `os` module is retrieved instead.
  ##   If the command line is not available, an assertion will be raised.
  ## - `shortNoVal`: Set of short option characters that do not accept values.
  ##   See `shortNoVal and longNoVal<#nimshortnoval-and-nimlongnoval>`_ for details.
  ## - `longNoVal`: Sequence of long option names that do not accept values.
  ##   See `shortNoVal and longNoVal<#nimshortnoval-and-nimlongnoval>`_ for details.
  ## - `mode`: Parser behavior profile (`NimMode`, `LaxMode`, or `GnuMode`).
  ##   See `Parser Modes`_ for details.
  ##
  ## See also:
  ## * `getopt iterator<#getopt.i,seq[string],set[char],seq[string],CliMode>`_
  runnableExamples:
    var p = initOptParser()
    p = initOptParser(@["--left", "--debug:3", "-l", "-r:2"])
    p = initOptParser(@["--left", "--debug:3", "-l", "-r:2"],
                      shortNoVal = {'l'}, longNoVal = @["left"])
  initOptParser(cmdline, shortNoVal, longNoVal, toRules(mode))

proc initOptParser*(cmdline: seq[string],
                    shortNoVal: set[char] = {},
                    longNoVal: seq[string] = @[];
                    allowWhitespaceAfterColon: bool): OptParser {.deprecated:
      "`allowWhitespaceAfterColon` is deprecated, use parser modes instead".} =
  ## This is an overload for continued support of the legacy `allowWhitespaceAfterColon`
  ## option. It modifies the default parser mode so that the passed value is respected.
  ##
  ## Current default parser mode behaves as if `true` was passed (old default)
  ##
  ## - `allowWhitespaceAfterColon`: When `true`, allows forms like
  ##   `--option: value` or `--option= value` where the value is in the next
  ##   token after the delimiter. When `false`, the value must be in the same
  ##   token as the delimiter.
  var nimrules = toRules(NimMode)
  if allowWhitespaceAfterColon == false: nimrules.excl prSepAllowDelimAfter
  initOptParser(cmdline, shortNoVal, longNoVal, nimrules)

proc initOptParser*(cmdline = "";
                    shortNoVal: set[char] = {};
                    longNoVal: seq[string] = @[];
                    mode: CliMode = NimMode): OptParser =
  ## Initializes the command line parser from a command line string.
  ##
  ## The `cmdline` string is parsed into tokens using shell-like quoting rules.
  ##
  ## **Parameters:**
  ##
  ## - `cmdline`: Command line string to parse. If empty, the real command line
  ##   as provided by the `os` module is retrieved instead. If the command line
  ##   is not available, an assertion will be raised.
  ## - `shortNoVal`: Set of short option characters that do not accept values.
  ##   See `shortNoVal and longNoVal<#nimshortnoval-and-nimlongnoval>`_ for details.
  ## - `longNoVal`: Sequence of long option names that do not accept values.
  ##   See `shortNoVal and longNoVal<#nimshortnoval-and-nimlongnoval>`_ for details.
  ## - `mode`: Parser behavior profile (`NimMode`, `LaxMode`, or `GnuMode`).
  ##   See `Parser Modes`_ for details.
  ##
  ## **Note:** This does not provide a way of passing default values to arguments.
  ##
  ## See also:
  ## * `getopt iterator<#getopt.i,OptParser>`_
  runnableExamples:
    var p = initOptParser()
    p = initOptParser("--left --debug:3 -l -r:2")
    p = initOptParser("--left --debug:3 -l -r:2",
                      shortNoVal = {'l'}, longNoVal = @["left"])
  initOptParser(parseCmdLine(cmdline), shortNoVal, longNoVal, toRules(mode))

proc initOptParser*(cmdline = "";
                    shortNoVal: set[char] = {};
                    longNoVal: seq[string] = @[];
                    allowWhitespaceAfterColon: bool): OptParser {.deprecated:
      "`allowWhitespaceAfterColon` is deprecated, use parser modes instead".} =
  ## This is an overload for continued support of the legacy `allowWhitespaceAfterColon`
  ## option. It modifies the default parser mode so that the passed value is respected.
  ##
  ## Current default parser mode behaves as if `true` was passed (old default).
  ##
  ## - `allowWhitespaceAfterColon`: When `true`, allows forms like
  ##   `--option: value` or `--option= value` where the value is in the next
  ##   token after the delimiter. When `false`, the value must be in the same
  ##   token as the delimiter.
  var nimrules = toRules(NimMode)
  if allowWhitespaceAfterColon == false: nimrules.excl prSepAllowDelimAfter
  initOptParser(parseCmdLine(cmdline), shortNoVal, longNoVal, nimrules)

proc handleShortOption(p: var OptParser; cmd: string) =
  var i = p.pos
  p.kind = cmdShortOption
  if i < cmd.len: # multidigit short option support goes here
    add(p.key, cmd[i])
    inc(i)
  p.inShortState = true
  if prSepAllowDelimBefore in p.rules:
    while i < cmd.len and cmd[i] in DelimSet:
      inc(i)
      p.inShortState = false

  proc consumeDelims() =
    while i < cmd.len and cmd[i] in DelimSet: inc(i)

  proc advance(p: var OptParser; n = 1)=
    p.inShortState = false
    p.pos = 0
    inc p.idx, n
    
  template next(): untyped = p.cmds[p.idx + 1]

  let canTakeVal = card(p.shortNoVal) > 0 and p.key[0] notin p.shortNoVal 
  if i < cmd.len and cmd[i] in p.separators:
    # separator case
    if prShortAllowSep in p.rules:
      # allow separators: skip the separator and take the value after it
      inc(i)
      if prSepAllowDelimAfter in p.rules:
        consumeDelims()
    # prohibit separators: treat separator + remainder as the value
    # this represents an error state but produces output that can be validated
    p.val = substr(cmd, i)
    p.advance(1)
    return
  elif canTakeVal and prShortValAllowAdjacent in p.rules and i < cmd.len:
    # adjacent value
    if prSepAllowDelimBefore in p.rules:
      consumeDelims()
    p.val = substr(cmd, i)
    p.advance(1)
    return
  elif canTakeVal and
      prShortValAllowNextArg in p.rules and
      i >= cmd.len and
      p.idx + 1 < p.cmds.len and (
        prShortValAllowDashLeading in p.rules or
        not (next().len > 0 and next()[0] == '-')):
    # next-argument value
    p.val = next()
    p.advance(2)
    return
  p.pos = i
  if i >= cmd.len:
    p.advance(1)

proc next*(p: var OptParser) {.rtl, extern: "npo$1".} =
  ## Parses the next token.
  ##
  ## `p.kind` describes what kind of token has been parsed. `p.key` and
  ## `p.val` are set accordingly.
  runnableExamples:
    var p = initOptParser("--left -r:2 file.txt")
    p.next()
    doAssert p.kind == cmdLongOption and p.key == "left"
    p.next()
    doAssert p.kind == cmdShortOption and p.key == "r" and p.val == "2"
    p.next()
    doAssert p.kind == cmdArgument and p.key == "file.txt"
    p.next()
    doAssert p.kind == cmdEnd

  if p.idx >= p.cmds.len:
    p.kind = cmdEnd
    return

  var i = p.pos
  template cmd(): untyped = p.cmds[p.idx]
  template nextArg(): untyped = p.cmds[p.idx + 1]

  proc consumeDelims(cmds: openArray[string]; idx: int) =
    while i < cmds[idx].len and cmds[idx][i] in DelimSet: inc(i)

  proc advance(p: var OptParser; n = 1) =
    p.pos = 0
    inc p.idx, n

  consumeDelims(p.cmds, p.idx)
  p.pos = i
  setLen(p.key, 0)
  setLen(p.val, 0)
  if p.inShortState:
    p.inShortState = false
    if i < cmd.len:
      handleShortOption(p, p.cmds[p.idx])
      return
    else:
      p.advance(1)
      if p.idx >= p.cmds.len:
        p.kind = cmdEnd
        return

  if i < cmd.len and cmd[i] == '-':
    inc(i)
    if i < cmd.len and cmd[i] == '-':
      p.kind = cmdLongOption
      inc(i)
      i = parseWord(cmd, i, p.key,
        DelimSet + (if prLongAllowSep in p.rules: p.separators else: {}))
      if prSepAllowDelimBefore in p.rules:
        consumeDelims(p.cmds, p.idx)
      if prLongAllowSep in p.rules and i < cmd.len and cmd[i] in p.separators:
        inc(i)
        if prSepAllowDelimAfter in p.rules:
          consumeDelims(p.cmds, p.idx)
        if i >= cmd.len and p.idx + 1 < p.cmds.len and
            prSepAllowDelimAfter in p.rules:
          p.val = nextArg()
          p.advance(2)
        else:
          p.val = cmd.substr(i)
          p.advance(1)
      elif prLongValAllowNextArg in p.rules and
          len(p.longNoVal) > 0 and
          p.key notin p.longNoVal and
          p.idx + 1 < p.cmds.len:
        p.val = nextArg()
        p.advance(2)
      else:
        if i < cmd.len:
          # Leave remainder of the current token to be parsed as an argument.
          consumeDelims(p.cmds, p.idx)
          p.cmds[p.idx] = cmd.substr(i)
        else:
          p.advance(1)
    else:
      p.pos = i
      handleShortOption(p, cmd)
  else:
    p.kind = cmdArgument
    p.key = cmd
    p.advance(1)

when declared(quoteShellCommand):
  proc cmdLineRest*(p: OptParser): string {.rtl, extern: "npo$1".} =
    ## Retrieves the rest of the command line that has not been parsed yet.
    ##
    ## See also:
    ## * `remainingArgs proc<#remainingArgs,OptParser>`_
    ##
    runnableExamples:
      var p = initOptParser("--left -r:2 -- foo.txt bar.txt")
      while true:
        p.next()
        if p.kind == cmdLongOption and p.key == "":  # Look for "--"
          break
      doAssert p.cmdLineRest == "foo.txt bar.txt"
    result = p.cmds[p.idx .. ^1].quoteShellCommand

proc remainingArgs*(p: OptParser): seq[string] {.rtl, extern: "npo$1".} =
  ## Retrieves a sequence of the arguments that have not been parsed yet.
  ##
  ## See also:
  ## * `cmdLineRest proc<#cmdLineRest,OptParser>`_
  ##
  runnableExamples:
    var p = initOptParser("--left -r:2 -- foo.txt bar.txt")
    while true:
      p.next()
      if p.kind == cmdLongOption and p.key == "":  # Look for "--"
        break
    doAssert p.remainingArgs == @["foo.txt", "bar.txt"]
  result = @[]
  for i in p.idx..<p.cmds.len: result.add p.cmds[i]

iterator getopt*(p: var OptParser): tuple[kind: CmdLineKind, key,
    val: string] =
  ## Convenience iterator for iterating over the given
  ## `OptParser<#OptParser>`_.
  ##
  ## There is no need to check for `cmdEnd` while iterating. If using `getopt`
  ## with case switching, checking for `cmdEnd` is required.
  ##
  ## See also:
  ## * `initOptParser proc<#initOptParser,string,set[char],seq[string]>`_
  ##
  runnableExamples:
    # these are placeholders, of course
    proc writeHelp() = discard
    proc writeVersion() = discard

    var filename: string = ""
    var p = initOptParser("--left --debug:3 -l -r:2")

    for kind, key, val in p.getopt():
      case kind
      of cmdArgument:
        filename = key
      of cmdLongOption, cmdShortOption:
        case key
        of "help", "h": writeHelp()
        of "version", "v": writeVersion()
      of cmdEnd: assert(false) # cannot happen
    if filename == "":
      # no filename has been given, so we show the help
      writeHelp()
  p.pos = 0
  p.idx = 0
  while true:
    next(p)
    if p.kind == cmdEnd: break
    yield (p.kind, p.key, p.val)

iterator getopt*(cmdline: seq[string] = @[];
                  shortNoVal: set[char] = {};
                  longNoVal: seq[string] = @[];
                  mode: CliMode = NimMode):
            tuple[kind: CmdLineKind, key, val: string] =
  ## Convenience iterator for iterating over command line arguments.
  ##
  ## This creates a new `OptParser<#OptParser>`_. If no command line
  ## arguments are provided, the real command line as provided by the
  ## `os` module is retrieved instead.
  ##
  ## `shortNoVal` and `longNoVal` are used to specify which options
  ## do not take values. See the `documentation about these
  ## parameters<#nimshortnoval-and-nimlongnoval>`_ for more information on
  ## how this affects parsing.
  ##
  ## `mode` selects the parser behavior profile (`NimMode`, `LaxMode`,
  ## or `GnuMode`). See `Parser Modes`_ for details.
  ##
  ## There is no need to check for `cmdEnd` while iterating. If using `getopt`
  ## with case switching, checking for `cmdEnd` is required.
  ##
  ## See also:
  ## * `initOptParser proc<#initOptParser,seq[string],set[char],seq[string]>`_
  ##
  ## **Examples:**
  ##
  ##   ```Nim
  ##   # these are placeholders, of course
  ##   proc writeHelp() = discard
  ##   proc writeVersion() = discard
  ##
  ##   var filename: string
  ##   let params = @["--left", "--debug:3", "-l", "-r:2"]
  ##
  ##   for kind, key, val in getopt(params):
  ##     case kind
  ##     of cmdArgument:
  ##       filename = key
  ##     of cmdLongOption, cmdShortOption:
  ##       case key
  ##       of "help", "h": writeHelp()
  ##       of "version", "v": writeVersion()
  ##     of cmdEnd: assert(false) # cannot happen
  ##   if filename == "":
  ##     # no filename has been written, so we show the help
  ##     writeHelp()
  ##   ```
  var p = initOptParser(cmdline, shortNoVal = shortNoVal,
      longNoVal = longNoVal,
      rules = toRules(mode))
  while true:
    next(p)
    if p.kind == cmdEnd: break
    yield (p.kind, p.key, p.val)

{.pop.}
