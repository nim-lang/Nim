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
## The parser supports multiple `parsing modes<#parser-modes>`_ that affect how
## options are interpreted. The syntax described here applies to the default
## `Nim` mode. See `Parser Modes<#parser-modes>`_ for details on alternative
## modes and their differences.
##
## The following syntax is supported when arguments for the `shortNoVal` and
## `longNoVal` parameters, which are
## `described later<#nimshortnoval-and-nimlongnoval>`_, are not provided:
##
## 1. Short options: `-abcd`, `-e:5`, `-e=5`
## 2. Long options: `--foo:bar`, `--foo=bar`, `--foo`
## 3. Arguments: everything that does not start with a `-`
##
## These three kinds of tokens are enumerated in the
## `CmdLineKind enum<#CmdLineKind>`_.
##
## When option values begin with ':' or '=', they need to be doubled up (as in
## `--delim::`) or alternated (as in `--delim=:`).
##
## The `--` option, commonly used to denote that every token that follows is
## an argument, is interpreted as a long option, and its name is the empty
## string. Trailing arguments can be accessed with `remainingArgs<#remainingArgs,OptParser>`_
## or `cmdLineRest<#cmdLineRest,OptParser>`_.
##
## Parsing
## =======
##
## Use an `OptParser<#OptParser>`_ to parse command line options. It can be
## created with `initOptParser<#initOptParser,string,set[char],seq[string]>`_,
## and `next<#next,OptParser>`_ advances the parser by one token.
##
## For each token, the parser's `kind`, `key`, and `val` fields give
## information about that token. If the token is a long or short option, `key`
## is the option's name, and  `val` is either the option's value, if provided,
## or the empty string. For arguments, the `key` field contains the argument
## itself, and `val` is unused. To check if the end of the command line has
## been reached, check if `kind` is equal to `cmdEnd`.
##
## Here is an example:
##
##   ```Nim
##   import std/parseopt
##
##   var p = initOptParser("-ab -e:5 --foo --bar=20 file.txt")
##   while true:
##     p.next()
##     case p.kind
##     of cmdEnd: break
##     of cmdShortOption, cmdLongOption:
##       if p.val == "":
##         echo "Option: ", p.key
##       else:
##         echo "Option and value: ", p.key, ", ", p.val
##     of cmdArgument:
##       echo "Argument: ", p.key
##
##   # Output:
##   # Option: a
##   # Option: b
##   # Option and value: e, 5
##   # Option: foo
##   # Option and value: bar, 20
##   # Argument: file.txt
##   ```
##
## The `getopt iterator<#getopt.i,OptParser>`_, which is provided for
## convenience, can be used to iterate through all command line options as well.
##
## To set a default value for a variable assigned through `getopt` and accept arguments from the cmd line.
## Assign the default value to a variable before parsing.
## Then set the variable to the new value while parsing.
##
## Here is an example:
##
##   ```Nim
##   import std/parseopt
##
##   var varName: string = "defaultValue"
##
##   for kind, key, val in getopt():
##     case kind
##     of cmdArgument:
##       discard
##     of cmdLongOption, cmdShortOption:
##       case key:
##       of "varName": # --varName:<value> in the console when executing
##         varName = val # do input sanitization in production systems
##     of cmdEnd:
##       discard
##   ```
##
## `shortNoVal` and `longNoVal`
## ============================
##
## The optional `shortNoVal` and `longNoVal` parameters present in
## `initOptParser<#initOptParser,string,set[char],seq[string]>`_ are for
## specifying which short and long options do not accept values.
##
## When `shortNoVal` is non-empty, users are not required to separate short
## options and their values with a `:` or `=` since the parser knows which
## options accept values and which ones do not. This behavior also applies for
## long options if `longNoVal` is non-empty.
##
## For short options, `-j4` becomes supported syntax (parsed as option `j` with
## value `4` instead of two separate options `j` and `4`). For long options,
## `--foo bar` becomes supported syntax in all modes. In `PosixLax` and `Gnu`
## modes, short options can also take values from the next argument (e.g.,
## `-c val`), but this does **not** work in the default `Nim` mode.
##
## This is in addition to the `previously mentioned syntax<#supported-syntax>`_.
## Users can still separate options and their values with `:` or `=`, but that
## becomes optional.
##
## As more options which do not accept values are added to your program,
## remember to amend `shortNoVal` and `longNoVal` accordingly.
##
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
##   ```Nim
##   import std/parseopt
##
##   proc printToken(kind: CmdLineKind, key: string, val: string) =
##     case kind
##     of cmdEnd: doAssert(false)  # Doesn't happen with getopt()
##     of cmdShortOption, cmdLongOption:
##       if val == "":
##         echo "Option: ", key
##       else:
##         echo "Option and value: ", key, ", ", val
##     of cmdArgument:
##       echo "Argument: ", key
##
##   let cmdLine = "-j4 --first bar"
##
##   var emptyNoVal = initOptParser(cmdLine)
##   for kind, key, val in emptyNoVal.getopt():
##     printToken(kind, key, val)
##
##   # Output:
##   # Option: j
##   # Option: 4
##   # Option: first
##   # Argument: bar
##
##   var withNoVal = initOptParser(cmdLine, shortNoVal = {'c'},
##                                 longNoVal = @["second"])
##   for kind, key, val in withNoVal.getopt():
##     printToken(kind, key, val)
##
##   # Output:
##   # Option and value: j, 4
##   # Option and value: first, bar
##   ```
##
## Parser Modes
## ============
##
## .. Warning:: Modes other than the default (`Nim`) are **experimental** and may change
##    in future releases.
##
## The parser supports several distinct rule sets that change how options are
## interpreted. The modes are controlled by `ParserMode<#ParserMode>`_ constant.
## Select a mode with `-d:parseopt.mode=<int>`:
##
## - `0` (`PosixLax`): Most forgiving mode, combines `Nim` with POSIX-like
##    short option handling. Tries to follow the POSIX_ guidelines where possible.
## - `1` (`Nim`): Standard Nim parsing rules (default).
## - `2` (`Gnu`): GNU-inspired parsing (e.g. `=` as the only delimiter).
##   Puts some restrictions, following some of the GNU_ conventions.
##
## Modes are numbered from most relaxed (0) to strictest (2). The names were
## chosen to set general user expectations and full compliance is neither
## achieved nor planned.
##
## Mode Differences
## ----------------
##
## **Nim** (mode 1, default):
##
## - Short options require adjacent values or explicit delimiters: `-cval`, `-c:val`, `-c=val`
## - Next-argument value taking (`-c val`) is **not** supported by default
## - Supports both `:` and `=` as delimiters
## - Allows whitespace around delimiters
## - Values starting with `-` are interpreted as new options
##
## **PosixLax** (mode 0):
##
## - Essentially the Nim mode with a key relaxation for short options
## - Allows short options to take values from the next argument: `-c val`
## - Supports bundled short options with trailing value: `-abc val`
## - Values starting with `-` can be consumed as option arguments
##
## **Gnu** (mode 2):
##
## - Only `=` is treated as a delimiter (`:` is not a delimiter)
## - No whitespace allowed around `=`
## - Short options can take next-argument values: `-c val`
## - Values starting with `-` can be consumed as option arguments
##
## Mode-Specific Behavior
## ======================
##
## The parser's behavior varies significantly between modes, particularly
## around how options consume their values:
##
## **Short Options**
##
## Consider `-c val`:
##
## - In `Nim` mode: `-c` is parsed as an option without a value, and `val` is
##   parsed as an argument, regardless of `shortNoVal` being empty or not.
## - In `PosixLax` and `Gnu` modes: same as `Nim` when `shortNoVal` is
##   empty and `c` is not in it, when it's not, `val` is consumed as the value.
##
## Consider `-c-10`:
##
## - If `shortNoVal` value is empty, all three modes parse thre separate short
##   options: `c`, `1` and `0`.
## - Otherwise, if `-c` is not in `shortNoVal`:
##   + `Nim`: `-c` is an option without an argument. `-10` is interpreted as a
##      an option `-1` with the `0` argument.
##   + `PosixLax` and `Gnu`: `-10` is consumed as the value of `-c`
##     (allowing negative number values).
##
## **Long Options**
##
## Consider `--foo:bar`:
##
## - `Nim`: `:` is a valid delimiter, so `bar` is the value of `--foo`.
## - `PosixLax`: same as `Nim`.
## - `Gnu`: only `=` is a delimiter, so this parses as an option named
##   `foo:bar` without a value (unless `longNoVal` is non-empty and allows
##   next-argument consumption).
##
## Consider `--foo =bar`:
##
## - `Nim`: whitespace around delimiters is allowed, so `=bar` is the
##   value of `--foo`.
## - `PosixLax`: same as `Nim`.
## - `Gnu`: whitespace around `=` is not allowed, so `--foo` is an
##   option without a value, and `=bar` is parsed as an argument.
##
## Custom Rule Sets
## ================
##
## .. Warning:: Custom rule sets is an **experimental** feature.
##
## Beyond the three provided modes, you can define a custom parser behavior
## by specifying individual `ParserCapabilities<#ParserCapabilities>`_ at
## compile time by overriding the `ParserRulesMask<#ParserRulesMask>`_
## bit mask with `-d:parseopt.ruleset=<int32>`.
##
## This is useful when you need parsing rules that don't match any standard
## mode.
##
## When defined, `ParserRulesMask` value completely overrides the selected mode
## and the `RuleSet<#RuleSet>`_ derived from it. See `RuleSet<#RuleSet>`_ for
## details on the derivation process.
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

import std/[strutils, bitops]
import std/os

type
  ParserRuleMode = enum
    ## Parser behavior profiles used to select capability sets at compile time.
    rsPosixLax, ## The mose forgiving mode. Combines Nim-style parser with
                ## POSIX-like handling of short options, allowing passing
                ## whitespace-delimited arguments.
    rsNim,      ## Nim parsing rules (default).
    rsGnu ## GNU-style parsing:
          ## - Short options follow POSIX-style bundling and value handling.
          ## - Only '=' is a long/short delimiter (':' not treated as a delimiter).
          ## - Whitespace around '=' is disallowed.
          ##
          ## Known discrepancies:
          ## - No notion of optional/mandatory arguments.

type
  ParserCapabilities* = enum
    ## Feature flags used to assemble parser behavior for a given mode.
    pcSepAllowDelimBefore,       ## Allow whitespace before a separator (':'|'=')
    pcSepAllowDelimAfter,        ## Allow whitespace after a separator (':'|'=')
    pcShortAllowSep,             ## Allow `-c:val`/`-c=val` forms, see `SepSet`
    pcShortBundle,               ## Allow bundling short options behind one '-'
    pcShortValAllowAdjacent,     ## Allow adjacent short option values: `-cval`
    pcShortValAllowNextArg,      ## Allow next-argv short option values: `-c val`
    pcShortValAllowDashLeading,  ## Allow values that start with '-' to be taken
    pcLongAllowSep,              ## Allow `--opt=val`/`--opt:val`, see `SepSet`
    pcLongValAllowNextArg,       ## Allow `--opt val` form, requires non-emty `longNoVal`

func toRuleSet(mask: int32): set[ParserCapabilities] =
  for cap in ParserCapabilities:
    if testBit(mask, ord(cap)): result.incl(cap)

func toRuleSetMask*(caps: set[ParserCapabilities]): int32 =
  ## Helper to derive a value for a custom `ParserRulesMask<#ParserRulesMask>`_
  ## override value from `caps`.
  for cap in caps:
    result.setBit(ord(cap))

const
  ParserMode* {.intdefine: "parseopt.mode".}: int = ord(rsNim) ##|
  ## Parser mode switch. Defined at compilation with the `-d:parseopt.mode=<int>`.
  ## Valid integer values:
  ## - `0`: PosixLax mode
  ## - `1`: Nim mode (default)
  ## - `2`: Gnu mode
  ##
  ## See `Parser Modes<#parser-modes>`_ for details.
  ##
  ## If `ParserRulesMask<#ParserRulesMask>`_ is set at compile-time, it
  ## takes precedence and effectively overrides `ParserMode`.
  RuleMode: ParserRuleMode = static: ##|
    ## Selected parser mode controlled by `-d:parseopt.mode=<int>`.
    when ParserMode notin 0..int(ParserRuleMode.high):
      {.error: "Unknown parseopt parser mode!".}
    ParserRuleMode(ParserMode)

  DefaultRuleSet: set[ParserCapabilities] = static:
    ## Default capability set derived from the selected rule mode.
    let
      Common = {
        pcShortValAllowAdjacent,
        pcShortBundle,
        pcLongValAllowNextArg,
        pcLongAllowSep,
      }
      Lax = {
        pcSepAllowDelimBefore,
        pcSepAllowDelimAfter,
        pcShortAllowSep,
      }
      ShortPosix = {
        pcShortValAllowNextArg,
        pcShortValAllowDashLeading,
      }
    when RuleMode == rsPosixLax:
      Common + Lax + ShortPosix
    elif RuleMode == rsNim:
      Common + Lax
    elif RuleMode == rsGnu:
      Common + ShortPosix
    else: {.error: "No rule set defined for the parseopt parser mode." & $RuleMode .}

  ParserRulesMask* {.intdefine: "parseopt.ruleset".}: int32 = ##|
  ## Integer bitmask for the effective parser rule set.
  ## Used to override the chosen mode with a granular custom set of
  ## `ParserCapabilities<#ParserCapabilities>`_ rules.
  ##
  ## To enact, use the `-d:parseopt.ruleset=<N>` define at compile time.
  ##
  ## By default, this is derived from the active `RuleMode`.
  ## Each bit position corresponds to a `ParserCapabilities` enum value.
  ##
  ## To use a custom capability set instead of a predefined mode, define
  ## `parseopt.ruleset` at compile time in  your `config.nims`:
  ##
  ## ```nim
  ## import parseopt
  ## let myRuleSet = {
  ##   pcShortBundle,              # Allow -abc bundling
  ##   pcShortValAllowAdjacent,    # Allow -cval
  ##   pcLongAllowSep,             # Allow --opt=val
  ##   pcSepAllowDelimBefore,      # Allow --opt =val
  ##   pcSepAllowDelimAfter        # Allow --opt= val
  ## }
  ## switch("define", "parseopt.ruleset=" & $toRuleSetMask(myRuleSet))
  ## ```
  ##
  ## When `parseopt.ruleset` is defined, it completely bypasses the default
  ## derivation (steps 1-3) and directly controls the final `RuleSet`.
    toRuleSetMask(DefaultRuleSet)

  RuleSet*: set[ParserCapabilities] = toRuleSet(ParserRulesMask) ##|
  ## The final active parser capability set used throughout the module to
  ## control parsing behavior.
  ##
  ## Derivation Process:
  ##
  ## The `RuleSet` is derived through a multi-stage compile-time process:
  ##
  ## 1. Mode Selection: The `ParserMode<#ParserMode>`_ selects one of the
  ##    pre-defined parsing modes. Defaults to `Nim` mode.
  ##
  ## 2. Default Capabilities: Based on `RuleMode`, a default set of
  ##    `ParserCapabilities` is assembled.
  ##
  ## 3. Bitmask Conversion: The derived rule set is converted to an integer
  ##    bitmask and stored in `ParserRulesMask<#ParserRulesMask>`_.
  ##    This step allows user override: if `-d:parseopt.ruleset=<int32>` is
  ##    used as a compilation switch, it replaces the value.
  ##
  ## 4. Final Rule Set: `ParserRulesMask` is converted back
  ##    to the final value of `RuleSet` used by the parser.
  ##
  ## **See Also:**
  ## - `ParserCapabilities<#ParserCapabilities>`_ for individual capability meanings
  ## - `ParserMode<#ParserMode>`_ for mode selection
  ## - `ParserRulesMask<#ParserRulesMask>`_ for custom override mechanism

  SepSet = if RuleMode == rsGnu: {'='} else: {':', '='} ##|
  ## Allowed separators for long/short option values.
  DelimSet = {'\t', ' '} ## Allowed delimiters between tokens

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
    ## `initOptParser proc<#initOptParser,string,set[char],seq[string]>`_.
    pos: int
    inShortState: bool
    allowWhitespaceAfterColon: bool
    shortNoVal: set[char]
    longNoVal: seq[string]
    cmds: seq[string]
    idx: int
    kind*: CmdLineKind           ## The detected command line token
    key*, val*: string           ## Key and value pair; the key is the option
                                 ## or the argument, and the value is not "" if
                                 ## the option was given a value

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

proc initOptParser*(cmdline: seq[string], shortNoVal: set[char] = {},
                    longNoVal: seq[string] = @[];
                    allowWhitespaceAfterColon = pcSepAllowDelimAfter in RuleSet): OptParser =
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
  ## - `allowWhitespaceAfterColon`: When `true` (default), allows forms like
  ##   `--option: value` or `--option= value` where the value is in the next
  ##   command line argument after the delimiter. When `false`, the value must
  ##   be in the same argument as the delimiter.
  ##
  ## **Note:** The parser's behavior depends on the selected `parser mode
  ## <#parser-modes>`_, which is set at compile time with `-d:parseopt.mode=<int>`.
  ##
  ## See also:
  ## * `getopt iterator<#getopt.i,seq[string],set[char],seq[string]>`_
  runnableExamples:
    var p = initOptParser()
    p = initOptParser(@["--left", "--debug:3", "-l", "-r:2"])
    p = initOptParser(@["--left", "--debug:3", "-l", "-r:2"],
                      shortNoVal = {'l'}, longNoVal = @["left"])
  result = OptParser(pos: 0, idx: 0, inShortState: false,
                    shortNoVal: shortNoVal, longNoVal: longNoVal,
                    allowWhitespaceAfterColon: allowWhitespaceAfterColon
                    )
  if cmdline.len != 0:
    result.cmds = newSeq[string](cmdline.len)
    for i in 0..<cmdline.len:
      result.cmds[i] = cmdline[i]
  else:
    when declared(paramCount):
      when defined(nimscript):
        var ctr = 0
        var firstNimsFound = false
        for i in countup(0, paramCount()):
          if firstNimsFound: 
            result.cmds[ctr] = paramStr(i)
            inc ctr, 1
          if paramStr(i).endsWith(".nims") and not firstNimsFound:
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
  result.kind = cmdEnd
  result.key = ""
  result.val = ""

proc initOptParser*(cmdline = "", shortNoVal: set[char] = {},
                    longNoVal: seq[string] = @[];
                    allowWhitespaceAfterColon = pcSepAllowDelimAfter in RuleSet): OptParser =
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
  ## - `allowWhitespaceAfterColon`: When `true` (default), allows forms like
  ##   `--option: value` or `--option= value` where the value is in the next
  ##   token after the delimiter. When `false`, the value must be in the same
  ##   token as the delimiter.
  ##
  ## **Note:** This does not provide a way of passing default values to arguments.
  ## The parser's behavior depends on the selected `parser mode<#parser-modes>`_,
  ## which is set at compile time with `-d:parseopt.mode=<int>`.
  ##
  ## See also:
  ## * `getopt iterator<#getopt.i,OptParser>`_
  runnableExamples:
    var p = initOptParser()
    p = initOptParser("--left --debug:3 -l -r:2")
    p = initOptParser("--left --debug:3 -l -r:2",
                      shortNoVal = {'l'}, longNoVal = @["left"])

  initOptParser(parseCmdLine(cmdline), shortNoVal, longNoVal, allowWhitespaceAfterColon)

proc handleShortOption(p: var OptParser; cmd: string) =
  var i = p.pos
  p.kind = cmdShortOption
  if i < cmd.len:
    add(p.key, cmd[i])
    inc(i)
  p.inShortState = true
  when pcSepAllowDelimBefore in RuleSet:
    while i < cmd.len and cmd[i] in DelimSet:
      inc(i)
      p.inShortState = false
  let canTakeVal = card(p.shortNoVal) > 0 and p.key[0] notin p.shortNoVal

  template consumeDelims() =
      while i < cmd.len and cmd[i] in DelimSet: inc(i)

  template consumeSepValue() =
    inc(i)
    p.inShortState = false
    when pcSepAllowDelimAfter in RuleSet:
      consumeDelims()
    p.val = substr(cmd, i)
    p.pos = 0
    inc p.idx

  template consumeAdjacentValue() =
    p.inShortState = false
    when pcSepAllowDelimBefore in RuleSet:
      consumeDelims()
    p.val = substr(cmd, i)
    p.pos = 0
    inc p.idx

  template canConsumeNextArg(): bool =
    when pcShortValAllowNextArg in RuleSet:
      if canTakeVal and i >= cmd.len and p.idx + 1 < p.cmds.len:
        when pcShortValAllowDashLeading in RuleSet:
          true
        else:
          p.cmds[p.idx + 1].len == 0 or p.cmds[p.idx + 1][0] != '-'
      else:
        false
    else:
      false

  template sepAllowedAndFound(): bool =
    when pcShortAllowSep in RuleSet:
      i < cmd.len and cmd[i] in SepSet
    else:
      false

  if sepAllowedAndFound():
    consumeSepValue()
  elif canTakeVal and i < cmd.len:
    when pcShortValAllowAdjacent in RuleSet:
      consumeAdjacentValue()
    else:
      p.pos = i
  elif canConsumeNextArg():
    p.inShortState = false
    p.val = p.cmds[p.idx + 1]
    p.pos = 0
    inc p.idx, 2
    return
  else:
    p.pos = i
  if i >= cmd.len:
    p.inShortState = false
    p.pos = 0
    inc p.idx

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
  template consumeDelims() =
    while i < p.cmds[p.idx].len and p.cmds[p.idx][i] in DelimSet: inc(i)

  consumeDelims()
  p.pos = i
  setLen(p.key, 0)
  setLen(p.val, 0)
  if p.inShortState:
    p.inShortState = false
    if i >= p.cmds[p.idx].len:
      inc p.idx
      p.pos = 0
      if p.idx >= p.cmds.len:
        p.kind = cmdEnd
        return
    else:
      handleShortOption(p, p.cmds[p.idx])
      return

  if i < p.cmds[p.idx].len and p.cmds[p.idx][i] == '-':
    inc(i)
    if i < p.cmds[p.idx].len and p.cmds[p.idx][i] == '-':
      p.kind = cmdLongOption
      inc(i)
      var foundSep = false

      template sepFoundAndAllowed(): bool =
        when pcLongAllowSep in RuleSet:
          if i < p.cmds[p.idx].len and p.cmds[p.idx][i] in SepSet:
            foundSep = true
            inc(i)
            when pcSepAllowDelimAfter in RuleSet:
              consumeDelims()
            true
          else:
            false
        else:
          false

      template canConsumeNextArg(): bool =
        when pcLongValAllowNextArg in RuleSet:
          len(p.longNoVal) > 0 and p.key notin p.longNoVal and p.idx+1 < p.cmds.len
        else:
          false

      i = parseWord(p.cmds[p.idx], i, p.key,
            DelimSet + (when pcLongAllowSep in RuleSet: SepSet else: {}))
      when pcSepAllowDelimBefore in RuleSet:
        consumeDelims()
      if sepFoundAndAllowed():
        # if we're at the end, use the next command line option:
        if i >= p.cmds[p.idx].len and p.idx < p.cmds.len and p.allowWhitespaceAfterColon:
          inc p.idx
          i = 0
        if p.idx < p.cmds.len:
          p.val = p.cmds[p.idx].substr(i)
        else:
          p.val = ""
        inc p.idx
      elif canConsumeNextArg():
        p.val = p.cmds[p.idx+1]
        inc p.idx, 2
      else:
        p.val = ""
        if not foundSep and i < p.cmds[p.idx].len:
          # Leave remainder of the current token to be parsed as an argument.
          consumeDelims()
          p.cmds[p.idx] = p.cmds[p.idx].substr(i)
        else:
          inc p.idx
      p.pos = 0
    else:
      p.pos = i
      handleShortOption(p, p.cmds[p.idx])
  else:
    p.kind = cmdArgument
    p.key = p.cmds[p.idx]
    inc p.idx
    p.pos = 0

when declared(quoteShellCommand):
  proc cmdLineRest*(p: OptParser): string {.rtl, extern: "npo$1".} =
    ## Retrieves the rest of the command line that has not been parsed yet.
    ##
    ## See also:
    ## * `remainingArgs proc<#remainingArgs,OptParser>`_
    ##
    ## **Examples:**
    ##   ```Nim
    ##   var p = initOptParser("--left -r:2 -- foo.txt bar.txt")
    ##   while true:
    ##     p.next()
    ##     if p.kind == cmdLongOption and p.key == "":  # Look for "--"
    ##       break
    ##   doAssert p.cmdLineRest == "foo.txt bar.txt"
    ##   ```
    result = p.cmds[p.idx .. ^1].quoteShellCommand

proc remainingArgs*(p: OptParser): seq[string] {.rtl, extern: "npo$1".} =
  ## Retrieves a sequence of the arguments that have not been parsed yet.
  ##
  ## See also:
  ## * `cmdLineRest proc<#cmdLineRest,OptParser>`_
  ##
  ## **Examples:**
  ##   ```Nim
  ##   var p = initOptParser("--left -r:2 -- foo.txt bar.txt")
  ##   while true:
  ##     p.next()
  ##     if p.kind == cmdLongOption and p.key == "":  # Look for "--"
  ##       break
  ##   doAssert p.remainingArgs == @["foo.txt", "bar.txt"]
  ##   ```
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
  ## **Examples:**
  ##
  ##   ```Nim
  ##   # these are placeholders, of course
  ##   proc writeHelp() = discard
  ##   proc writeVersion() = discard
  ##
  ##   var filename: string
  ##   var p = initOptParser("--left --debug:3 -l -r:2")
  ##
  ##   for kind, key, val in p.getopt():
  ##     case kind
  ##     of cmdArgument:
  ##       filename = key
  ##     of cmdLongOption, cmdShortOption:
  ##       case key
  ##       of "help", "h": writeHelp()
  ##       of "version", "v": writeVersion()
  ##     of cmdEnd: assert(false) # cannot happen
  ##   if filename == "":
  ##     # no filename has been given, so we show the help
  ##     writeHelp()
  ##   ```
  p.pos = 0
  p.idx = 0
  while true:
    next(p)
    if p.kind == cmdEnd: break
    yield (p.kind, p.key, p.val)

iterator getopt*(cmdline: seq[string] = @[],
                  shortNoVal: set[char] = {}, longNoVal: seq[string] = @[]):
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
      longNoVal = longNoVal)
  while true:
    next(p)
    if p.kind == cmdEnd: break
    yield (p.kind, p.key, p.val)

{.pop.}
