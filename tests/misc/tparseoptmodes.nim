discard """
  action: run
"""

import parseopt
from std/sequtils import toSeq

type Opt = tuple[kind: CmdLineKind, key, val: string]
proc `$`(opt: Opt): string = "(" & $opt[0] & ", \"" & opt[1] & "\", \"" & opt[2] & "\")"

proc collect(args: seq[string] | string;
              shortNoVal: set[char] = {};
              longNoVal: seq[string] = @[]): seq[(CliMode, seq[Opt])] =
  for mode in CliMode:
    var p =  parseopt.initOptParser(args,
      shortNoVal = shortNoVal, longNoVal = longNoVal, mode = mode)
    let res = toSeq(parseopt.getopt(p))
    result.add (mode, res)

proc check(name: string;
            results: openArray[(CliMode, seq[Opt])];
            expected: proc(m: CliMode): seq[Opt]) =
  for (mode, res) in results:
    doAssert res == expected(mode), "[" & $mode & "]: " & name & ":\n" & $res

block:
  # pcShortValAllowNextArg: separate option-argument for mandatory opt-arg.
  let res = collect(@["-c", "4"], shortNoVal = {'a', 'b'})
  proc expected(m: CliMode): seq[Opt] =
   case m
   of LaxMode: @[(cmdShortOption, "c", "4")]
   of NimMode: @[(cmdShortOption, "c", ""), (cmdArgument, "4", "")]
   of GnuMode: @[(cmdShortOption, "c", "4")]
  check("short whitespace value", res, expected)

block:
  # No opt-arg knowledge: whitespace does not bind to short option.
  let res = collect(@["-c", "4"])
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdShortOption, "c", ""), (cmdArgument, "4", "")]
  check("short no-val whitespace value", res, expected)

block:
  # pcShortBundle + pcShortValAllowNextArg: grouped shorts with one opt-arg.
  let res = collect(@["-abc", "4"], shortNoVal = {'a', 'b'})
  proc expected(m: CliMode): seq[Opt] =
     case m
     of LaxMode:    @[(cmdShortOption, "a", ""),
                      (cmdShortOption, "b", ""),
                      (cmdShortOption, "c", "4")]

     of NimMode:    @[(cmdShortOption, "a", ""),
                      (cmdShortOption, "b", ""),
                      (cmdShortOption, "c", ""),
                      (cmdArgument, "4", "")]

     of GnuMode:    @[(cmdShortOption, "a", ""),
                      (cmdShortOption, "b", ""),
                      (cmdShortOption, "c", "4")]
  check("short bundle with trailing value", res, expected)

block:
  # pcShortValAllowAdjacent: option+argument in same token (dash-led value).
  let res = collect(@["-c-x"], shortNoVal = {'a', 'b'})
  proc expected(m: CliMode): seq[Opt] =
     @[(cmdShortOption, "c", "-x")]
  check("short adjacent dash-led", res, expected)

block:
  # pcShortBundle + pcShortValAllowAdjacent (dash-led value).
  let res = collect(@["-abc-10"], shortNoVal = {'a', 'b'})
  proc expected(m: CliMode): seq[Opt] =
     @[(cmdShortOption, "a", ""),
       (cmdShortOption, "b", ""),
       (cmdShortOption, "c", "-10")]
  check("short bundle with adjacent negative", res, expected)

block:
  # pcShortValAllowNextArg: option and option-argument can be separate args.
  let res = collect(@["-c", ":"], shortNoVal = {'a', 'b'})
  proc expected(m: CliMode): seq[Opt] =
     case m
     of LaxMode: @[(cmdShortOption, "c", ":")]
     of NimMode: @[(cmdShortOption, "c", ""), (cmdArgument, ":", "")]
     of GnuMode: @[(cmdShortOption, "c", ":")]
  check("short whitespace colon value", res, expected)

block:
  # pcShortValAllowAdjacent: combined option+argument without blanks.
  let res = collect(@["-abc4"], shortNoVal = {'a', 'b'})
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdShortOption, "a", ""),
      (cmdShortOption, "b", ""),
      (cmdShortOption, "c", "4")]
  check("short bundle adjacent value", res, expected)

block:
  # pcShortBundle: bundle of no-arg shorts should split into options.
  let res = collect(@["-ab"], shortNoVal = {'a', 'b'})
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdShortOption, "a", ""), (cmdShortOption, "b", "")]
  check("short bundle no-arg", res, expected)

block:
  # pcShortBundle + pcShortValAllowNextArg: a no-arg short followed by one with arg.
  let res = collect(@["-ac", "4"], shortNoVal = {'a', 'b'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode   : @[(cmdShortOption, "a", ""),
                       (cmdShortOption, "c", "4")]
      of NimMode:    @[(cmdShortOption, "a", ""),
                       (cmdShortOption, "c", ""),
                       (cmdArgument, "4", "")]
      of GnuMode:    @[(cmdShortOption, "a", ""),
                       (cmdShortOption, "c", "4")]
  check("short bundle trailing value", res, expected)

block:
  # pcShortValAllowNextArg + cmdline parsing: whitespace-separated opt-arg.
  let res = collect("-c \"foo bar\"", shortNoVal = {'a', 'b'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode: @[(cmdShortOption, "c", "foo bar")]
      of NimMode: @[(cmdShortOption, "c", ""), (cmdArgument, "foo bar", "")]
      of GnuMode: @[(cmdShortOption, "c", "foo bar")]
  check("short whitespace quoted value", res, expected)

block:
  # pcShortValAllowNextArg + pcShortValAllowDashLeading: negative numbers as opt-args.
  let res = collect(@["-n", "-10"], shortNoVal = {'a', 'b', 'c'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:  @[(cmdShortOption, "n", "-10")]
      of NimMode:  @[(cmdShortOption, "n", ""), (cmdShortOption, "1", "0")]
      of GnuMode:  @[(cmdShortOption, "n", "-10")]
  check("short negative value, shortNoVal used", res, expected)

block:
  # pcShortValAllowNextArg + pcShortValAllowDashLeading: negative numbers as opt-args.
  let res = collect(@["-n", "-10"])
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:    @[(cmdShortOption, "n", ""),
                       (cmdShortOption, "1", ""),
                       (cmdShortOption, "0", "")]
      of NimMode:    @[(cmdShortOption, "n", ""),
                       (cmdShortOption, "1", ""),
                       (cmdShortOption, "0", "")]
      of GnuMode:    @[(cmdShortOption, "n", ""),
                       (cmdShortOption, "1", ""),
                       (cmdShortOption, "0", "")]
  check("short negative value, shortNoVal empty", res, expected)

block:
  # pcShortValAllowNextArg: repeated option-argument pairs are interpreted in order.
  let res = collect(@["-c", "1", "-c", "2"], shortNoVal = {'a', 'b'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:    @[(cmdShortOption, "c", "1"),
                       (cmdShortOption, "c", "2")]
      of NimMode:    @[(cmdShortOption, "c", ""),
                       (cmdArgument, "1", ""),
                       (cmdShortOption, "c", ""),
                       (cmdArgument, "2", "")]
      of GnuMode:    @[(cmdShortOption, "c", "1"),
                       (cmdShortOption, "c", "2")]
  check("short repeat whitespace values", res, expected)

block:
  # pcShortValAllowAdjacent: adjacent opt-args preserve order for repeats.
  let res = collect(@["-c1", "-c2"], shortNoVal = {'a', 'b'})
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdShortOption, "c", "1"), (cmdShortOption, "c", "2")]
  check("short repeat adjacent values", res, expected)

block:
  # pcShortValAllowDashLeading: value starting with '-' is consumed as opt-arg.
  # Divergence from POSIX Guideline 14 when enabled.
  let res = collect(@["-c", "-a"], shortNoVal = {'b'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode: @[(cmdShortOption, "c", "-a")]
      of NimMode: @[(cmdShortOption, "c", ""), (cmdShortOption, "a", "")]
      of GnuMode: @[(cmdShortOption, "c", "-a")]
  check("short dash-led value", res, expected)

block:
  # Separator overrides shortNoVal
  let res = collect(@["-a=foo"], shortNoVal = {'a'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode: @[(cmdShortOption, "a", "foo")]
      of NimMode: @[(cmdShortOption, "a", "foo")]
      of GnuMode: @[(cmdShortOption, "a", "=foo")]
  check("separator suppresses shortNoVal", res, expected)

block:
  let res = collect(@["-a=foo"], shortNoVal = {'v'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode: @[(cmdShortOption, "a", "foo")]
      of NimMode: @[(cmdShortOption, "a", "foo")]
      of GnuMode: @[(cmdShortOption, "a", "=foo")]
  check("adjacent value-taking vs chort option bundling 1", res, expected)

block:
  # pcLongAllowSep, mixed long/short parsing.
  # Option-arguments may include ':'/'=' chars.
  let args = @[
    "foo bar",
    "--path:/i like space/projects",
    "--aa:bar=a",
    "--a=c:d",
    "--ab",
    "-c",
    "--a[baz]:doo"
  ]
  let res = collect(args, shortNoVal = {'c'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode: @[
        (cmdArgument, "foo bar", ""),
        (cmdLongOption, "path", "/i like space/projects"),
        (cmdLongOption, "aa", "bar=a"),
        (cmdLongOption, "a", "c:d"),
        (cmdLongOption, "ab", ""),
        (cmdShortOption, "c", ""),
        (cmdLongOption, "a[baz]", "doo")]
      of NimMode: @[
        (cmdArgument, "foo bar", ""),
        (cmdLongOption, "path", "/i like space/projects"),
        (cmdLongOption, "aa", "bar=a"),
        (cmdLongOption, "a", "c:d"),
        (cmdLongOption, "ab", ""),
        (cmdShortOption, "c", ""),
        (cmdLongOption, "a[baz]", "doo")]
      of GnuMode: @[
        (cmdArgument, "foo bar", ""),
        (cmdLongOption, "path:/i", ""), # longNoVal is empty so can't take arg here
        (cmdArgument, "like space/projects", ""),
        (cmdLongOption, "aa:bar", "a"),
        (cmdLongOption, "a", "c:d"),
        (cmdLongOption, "ab", ""),
        (cmdShortOption, "c", ""),
        (cmdLongOption, "a[baz]:doo", "")]
  check("mixed long/short argv tokens", res, expected)


block:
  # pcLongAllowSep + separators: long option separator handling.
  let res = collect(@["--foo:bar"])
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:      @[(cmdLongOption, "foo", "bar")]
      of NimMode:      @[(cmdLongOption, "foo", "bar")]
      of GnuMode:      @[(cmdLongOption, "foo:bar", "")]
  check("long option colon separator", res, expected)

block:
  # pcLongAllowSep + separators: long option separator handling.
  let res = collect(@["--foo= bar"])
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:      @[(cmdLongOption, "foo", "bar")]
      of NimMode:      @[(cmdLongOption, "foo", "bar")]
      of GnuMode:      @[(cmdLongOption, "foo", " bar")]
  check("long option whitespace around separators", res, expected)

block:
  let res = collect(@["--foo =bar"])
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:      @[(cmdLongOption, "foo", "bar")]
      of NimMode:      @[(cmdLongOption, "foo", "bar")]
      of GnuMode:      @[(cmdLongOption, "foo", ""), (cmdArgument, "=bar", "")]
  check("long option whitespace around separators", res, expected)

block:
  let res = collect("--foo =bar", longNoVal = @[""])
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdLongOption, "foo", "=bar")]
  check("long option argument delimited with whitespace, val allowed", res, expected)

block:
  let res = collect("--foo =bar")
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdLongOption, "foo", ""), (cmdArgument, "=bar", "")]
  check("long option argument delimited with whitespace, val not allowed", res, expected)

block:
  # pcLongAllowSep: '=' separator
  let res = collect(@["--foo=bar"])
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdLongOption, "foo", "bar")]
  check("long option equals separator", res, expected)

block:
  # pcLongValAllowNextArg: long option value can be next argument.
  let res = collect(@["--foo", "bar"], longNoVal = @[""])
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdLongOption, "foo", "bar")]
  check("long option next-arg value", res, expected)

block:
  # longNoVal disables next-arg value consumption.
  let res = collect(@["--foo", "bar"], longNoVal = @["foo"])
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdLongOption, "foo", ""), (cmdArgument, "bar", "")]
  check("long option longNoVal disables argument taking", res, expected)

block:
  # "--" is parsed as a long option with an empty key.
  let res = collect(@["--", "rest"])
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdLongOption, "", ""), (cmdArgument, "rest", "")]
  check("double-dash marker", res, expected)

block:
  # option values beginning with ':' - doubled up
  let res = collect(@["--foo::"])
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode: @[(cmdLongOption, "foo", ":")]
      of NimMode: @[(cmdLongOption, "foo", ":")]
      of GnuMode: @[(cmdLongOption, "foo::", "")]
  check("long option value starting with colon (doubled)", res, expected)

block:
  # option values beginning with '=' - doubled up
  let res = collect(@["--foo=="])
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdLongOption, "foo", "=")]
  check("long option value starting with equals (doubled)", res, expected)

block:
  # option values beginning with ':' - alternated with '='
  let res = collect(@["--foo=:"])
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdLongOption, "foo", ":")]
  check("long option value starting with colon (alternated)", res, expected)

block:
  # option values beginning with '=' - alternated with ':'
  let res = collect(@["--foo:="])
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode: @[(cmdLongOption, "foo", "=")]
      of NimMode: @[(cmdLongOption, "foo", "=")]
      of GnuMode: @[(cmdLongOption, "foo:", "")]
  check("long option value starting with equals (alternated)", res, expected)

block issue9619:
  let res = collect(@["--option=", "", "--anotherOption", "tree"])
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:    @[(cmdLongOption, "option", ""),
                       (cmdLongOption, "anotherOption", ""),
                       (cmdArgument, "tree", "")]
      of NimMode:    @[(cmdLongOption, "option", ""),
                       (cmdLongOption, "anotherOption", ""),
                       (cmdArgument, "tree", "")]
      of GnuMode:    @[(cmdLongOption, "option", ""),
                       (cmdArgument, "", ""),
                       (cmdLongOption, "anotherOption", ""),
                       (cmdArgument, "tree", "")]
  check("issue #9619, whitespace after separator", res, expected)


block issue22736:
  let res = collect(@["--long", "", "-h", "--long:", "-h", "--long=", "-h", "arg"])
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:    @[(cmdLongOption, "long", ""),
                       (cmdArgument, "", ""),
                       (cmdShortOption, "h", ""),
                       (cmdLongOption, "long", "-h"),
                       (cmdLongOption, "long", "-h"),
                       (cmdArgument, "arg", "")]
      of NimMode:    @[(cmdLongOption, "long", ""),
                       (cmdArgument, "", ""),
                       (cmdShortOption, "h", ""),
                       (cmdLongOption, "long", "-h"),
                       (cmdLongOption, "long", "-h"),
                       (cmdArgument, "arg", "")]
      of GnuMode:    @[(cmdLongOption, "long", ""),
                       (cmdArgument, "", ""),
                       (cmdShortOption, "h", ""),
                       (cmdLongOption, "long:", ""),
                       (cmdShortOption, "h", ""),
                       (cmdLongOption, "long", ""),
                       (cmdShortOption, "h", ""),
                       (cmdArgument, "arg", "")]
  check("issue #22736, whitespace after separator, colon separator", res, expected)

# Numbers =====================================================================

block:
  # Positive integer adjacent to option
  let res = collect("-n42", shortNoVal = {'v'})
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdShortOption, "n", "42")]
  check("numerical option: positive integer adjacent", res, expected)

block:
  # Positive integer adjacent to  no-val option
  let res = collect("-n42x", shortNoVal = {'n'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:  @[(cmdShortOption, "n", ""), (cmdShortOption, "4", "2x")]
      of NimMode:  @[(cmdShortOption, "n", ""), (cmdShortOption, "4", "2x")]
      of GnuMode:  @[(cmdShortOption, "n", ""), (cmdShortOption, "4", "2x")]
  check("numerical no-val option: positive integer adjacent", res, expected)

block:
  # Negative integer adjacent to option
  let res = collect("-n-42", shortNoVal = {'v'})
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdShortOption, "n", "-42")]
  check("numerical option: negative integer adjacent", res, expected)

block:
  # Floating point number as value
  let res = collect(@["-n", "3.14"], shortNoVal = {'v'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:      @[(cmdShortOption, "n", "3.14")]
      of NimMode:      @[(cmdShortOption, "n", ""), (cmdArgument, "3.14", "")]
      of GnuMode:      @[(cmdShortOption, "n", "3.14")]
  check("numerical option: floating point whitespace", res, expected)

block:
  # Floating point adjacent to option
  let res = collect(@["-n3.14"], shortNoVal = {'v'})
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdShortOption, "n", "3.14")]
  check("numerical option: floating point adjacent", res, expected)

block:
  # Negative floating point
  let res = collect(@["-n", "-3.14"], shortNoVal = {'v'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:      @[(cmdShortOption, "n", "-3.14")]
      of NimMode:      @[(cmdShortOption, "n", ""), (cmdShortOption, "3", ".14")]
      of GnuMode:      @[(cmdShortOption, "n", "-3.14")]
  check("numerical option: negative floating point whitespace", res, expected)

block:
  # Negative floating point adjacent
  let res = collect("-n-3.14", shortNoVal = {'v'})
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdShortOption, "n", "-3.14")]
  check("numerical option: negative floating point adjacent", res, expected)

block:
  # Large number
  let res = collect(@["-n", "414"], shortNoVal = {'v'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:      @[(cmdShortOption, "n", "414")]
      of NimMode:      @[(cmdShortOption, "n", ""), (cmdArgument, "414", "")]
      of GnuMode:      @[(cmdShortOption, "n", "414")]
  check("numerical option: large number", res, expected)


block:
  # Multiple numerical options
  let res = collect("-n 10 -m20 -k= 30 -40", shortNoVal = {'v'})
  proc expected(m: CliMode): seq[Opt] =
    case m
      of LaxMode:    @[(cmdShortOption, "n", "10"),
                       (cmdShortOption, "m", "20"),
                       (cmdShortOption, "k", ""),    # buggy but preserved
                       (cmdArgument, "30", ""),
                       (cmdShortOption, "4", "0")]
      of NimMode:    @[(cmdShortOption, "n", ""),
                       (cmdArgument, "10", ""),
                       (cmdShortOption, "m", "20"),
                       (cmdShortOption, "k", ""),   # buggy but preserved
                       (cmdArgument, "30", ""),
                       (cmdShortOption, "4", "0")]
      of GnuMode:    @[(cmdShortOption, "n", "10"),
                       (cmdShortOption, "m", "20"),
                       (cmdShortOption, "k", "="),
                       (cmdArgument, "30", ""),
                       (cmdShortOption, "4", "0")]
  check("numerical option: multiple options", res, expected)

block:
  # Long option with numerical value
  let res = collect(@["--count=42"], longNoVal = @[])
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdLongOption, "count", "42")]
  check("numerical option: long option with equals", res, expected)

block:
  # Long option with numerical value (whitespace)
  let res = collect(@["--count", "42"], longNoVal = @[""])
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdLongOption, "count", "42")]
  check("numerical option: long option with whitespace", res, expected)

block:
  # Long option with negative numerical value
  let res = collect(@["--offset=-10"], longNoVal = @[])
  proc expected(m: CliMode): seq[Opt] =
    @[(cmdLongOption, "offset", "-10")]
  check("numerical option: long option negative", res, expected)
