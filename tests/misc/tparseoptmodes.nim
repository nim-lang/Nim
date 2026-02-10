discard """
  action: run
  matrix: "-d:parseopt.mode=0; -d:parseopt.mode=1; -d:parseopt.mode=2"
"""

import parseopt {.all.}
from std/sequtils import toSeq


type Opt = tuple[kind: CmdLineKind, key, val: string]
proc `$`(opt: Opt): string = "(" & $opt[0] & ", \"" & opt[1] & "\", \"" & opt[2] & "\")"

proc check(name: string; got, expected: openArray[Opt]) =
  doAssert got == expected, "- " & name & ":\n" & $got

proc collect(args: seq[string]; shortNoVal: set[char] = {}; longNoVal: seq[string] = @[]): seq[Opt] =
  var p = parseopt.initOptParser(args, shortNoVal = shortNoVal, longNoVal = longNoVal)
  toSeq(parseopt.getopt(p))

proc collectStr(cmdline: string; shortNoVal: set[char] = {}; longNoVal: seq[string] = @[]): seq[Opt] =
  var p = parseopt.initOptParser(cmdline, shortNoVal = shortNoVal, longNoVal = longNoVal)
  toSeq(parseopt.getopt(p))

proc collectNoVal(args: seq[string]): seq[Opt] =
  var p = parseopt.initOptParser(args, shortNoVal = {}, longNoVal = @[])
  toSeq(parseopt.getopt(p))


block:
  # pcShortValAllowNextArg: separate option-argument for mandatory opt-arg.
  let res = collect(@["-c", "4"], shortNoVal = {'a', 'b'})
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdShortOption, "c", "4")]
    of rsNim:      @[(cmdShortOption, "c", ""), (cmdArgument, "4", "")]
    of rsGnu:      @[(cmdShortOption, "c", "4")]
  check("short whitespace value", res, expected)

block:
  # No opt-arg knowledge: whitespace does not bind to short option.
  let res = collectNoVal(@["-c", "4"])
  let expected = [(cmdShortOption, "c", ""), (cmdArgument, "4", "")]
  check("short no-val whitespace value", res, expected)

block:
  # pcShortBundle + pcShortValAllowNextArg: grouped shorts with one opt-arg.
  let res = collect(@["-abc", "4"], shortNoVal = {'a', 'b'})
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdShortOption, "a", ""),
                     (cmdShortOption, "b", ""),
                     (cmdShortOption, "c", "4")]

    of rsNim:      @[(cmdShortOption, "a", ""),
                     (cmdShortOption, "b", ""),
                     (cmdShortOption, "c", ""),
                     (cmdArgument, "4", "")]

    of rsGnu:      @[(cmdShortOption, "a", ""),
                     (cmdShortOption, "b", ""),
                     (cmdShortOption, "c", "4")]
  check("short bundle with trailing value", res, expected)

block:
  # pcShortValAllowAdjacent: option+argument in same token (dash-led value).
  let res = collect(@["-c-x"], shortNoVal = {'a', 'b'})
  let expected = @[(cmdShortOption, "c", "-x")]
  check("short adjacent dash-led", res, expected)

block:
  # pcShortBundle + pcShortValAllowAdjacent (dash-led value).
  let res = collect(@["-abc-10"], shortNoVal = {'a', 'b'})
  let expected = @[
    (cmdShortOption, "a", ""),
    (cmdShortOption, "b", ""),
    (cmdShortOption, "c", "-10")
  ]
  check("short bundle with adjacent negative", res, expected)

block:
  # pcShortValAllowNextArg: option and option-argument can be separate args.
  let res = collect(@["-c", ":"], shortNoVal = {'a', 'b'})
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdShortOption, "c", ":")]
    of rsNim:      @[(cmdShortOption, "c", ""), (cmdArgument, ":", "")]
    of rsGnu:      @[(cmdShortOption, "c", ":")]
  check("short whitespace colon value", res, expected)

block:
  # pcShortValAllowAdjacent: combined option+argument without blanks.
  let res = collect(@["-abc4"], shortNoVal = {'a', 'b'})
  let expected = [
    (cmdShortOption, "a", ""),
    (cmdShortOption, "b", ""),
    (cmdShortOption, "c", "4")
  ]
  check("short bundle adjacent value", res, expected)

block:
  # pcShortBundle: bundle of no-arg shorts should split into options.
  let res = collect(@["-ab"], shortNoVal = {'a', 'b'})
  let expected = [(cmdShortOption, "a", ""), (cmdShortOption, "b", "")]
  check("short bundle no-arg", res, expected)

block:
  # pcShortBundle + pcShortValAllowNextArg: a no-arg short followed by one with arg.
  let res = collect(@["-ac", "4"], shortNoVal = {'a', 'b'})
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdShortOption, "a", ""),
                     (cmdShortOption, "c", "4")]

    of rsNim:      @[(cmdShortOption, "a", ""),
                     (cmdShortOption, "c", ""),
                     (cmdArgument, "4", "")]

    of rsGnu:      @[(cmdShortOption, "a", ""),
                     (cmdShortOption, "c", "4")]
  check("short bundle trailing value", res, expected)

block:
  # pcShortValAllowNextArg + cmdline parsing: whitespace-separated opt-arg.
  let res = collectStr("-c \"foo bar\"", shortNoVal = {'a', 'b'})
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdShortOption, "c", "foo bar")]
    of rsNim:      @[(cmdShortOption, "c", ""), (cmdArgument, "foo bar", "")]
    of rsGnu:      @[(cmdShortOption, "c", "foo bar")]
  check("short whitespace quoted value", res, expected)

block:
  # pcShortValAllowNextArg + pcShortValAllowDashLeading: negative numbers as opt-args.
  let res = collect(@["-n", "-10"], shortNoVal = {'a', 'b', 'c'})
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdShortOption, "n", "-10")]
    of rsNim:      @[(cmdShortOption, "n", ""), (cmdShortOption, "1", "0")]
    of rsGnu:      @[(cmdShortOption, "n", "-10")]
  check("short negative value, shortNoVal used", res, expected)

block:
  # pcShortValAllowNextArg + pcShortValAllowDashLeading: negative numbers as opt-args.
  let res = collectNoVal(@["-n", "-10"])
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdShortOption, "n", ""),
                     (cmdShortOption, "1", ""),
                     (cmdShortOption, "0", "")]
    of rsNim:      @[(cmdShortOption, "n", ""),
                     (cmdShortOption, "1", ""),
                     (cmdShortOption, "0", "")]
    of rsGnu:      @[(cmdShortOption, "n", ""),
                     (cmdShortOption, "1", ""),
                     (cmdShortOption, "0", "")]
  check("short negative value, shortNoVal empty", res, expected)

block:
  # pcShortValAllowNextArg: repeated option-argument pairs are interpreted in order.
  let res = collect(@["-c", "1", "-c", "2"], shortNoVal = {'a', 'b'})
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdShortOption, "c", "1"),
                     (cmdShortOption, "c", "2")]
    of rsNim:      @[(cmdShortOption, "c", ""),
                     (cmdArgument, "1", ""),
                     (cmdShortOption, "c", ""),
                     (cmdArgument, "2", "")]
    of rsGnu:      @[(cmdShortOption, "c", "1"),
                     (cmdShortOption, "c", "2")]
  check("short repeat whitespace values", res, expected)

block:
  # pcShortValAllowAdjacent: adjacent opt-args preserve order for repeats.
  let res = collect(@["-c1", "-c2"], shortNoVal = {'a', 'b'})
  let expected = @[(cmdShortOption, "c", "1"), (cmdShortOption, "c", "2")]
  check("short repeat adjacent values", res, expected)

block:
  # pcShortValAllowDashLeading: value starting with '-' is consumed as opt-arg.
  # Divergence from POSIX Guideline 14 when enabled.
  let res = collect(@["-c", "-a"], shortNoVal = {'b'})
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdShortOption, "c", "-a")]
    of rsNim:      @[(cmdShortOption, "c", ""), (cmdShortOption, "a", "")]
    of rsGnu:      @[(cmdShortOption, "c", "-a")]
  check("short dash-led value", res, expected)

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
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[
      (cmdArgument, "foo bar", ""),
      (cmdLongOption, "path", "/i like space/projects"),
      (cmdLongOption, "aa", "bar=a"),
      (cmdLongOption, "a", "c:d"),
      (cmdLongOption, "ab", ""),
      (cmdShortOption, "c", ""),
      (cmdLongOption, "a[baz]", "doo")]
    of rsNim: @[
      (cmdArgument, "foo bar", ""),
      (cmdLongOption, "path", "/i like space/projects"),
      (cmdLongOption, "aa", "bar=a"),
      (cmdLongOption, "a", "c:d"),
      (cmdLongOption, "ab", ""),
      (cmdShortOption, "c", ""),
      (cmdLongOption, "a[baz]", "doo")]
    of rsGnu: @[
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
  # pcLongAllowSep + SepSet: long option separator handling.
  let res = collect(@["--foo:bar"])
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdLongOption, "foo", "bar")]
    of rsNim:      @[(cmdLongOption, "foo", "bar")]
    of rsGnu:      @[(cmdLongOption, "foo:bar", "")]
  check("long option colon separator", res, expected)

block:
  # pcLongAllowSep + SepSet: long option separator handling.
  let res = collect(@["--foo= bar"])
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdLongOption, "foo", "bar")]
    of rsNim:      @[(cmdLongOption, "foo", "bar")]
    of rsGnu:      @[(cmdLongOption, "foo", " bar")]
  check("long option whitespace around separators", res, expected)

block:
  let res = collect(@["--foo =bar"])
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdLongOption, "foo", "bar")]
    of rsNim:      @[(cmdLongOption, "foo", "bar")]
    of rsGnu:      @[(cmdLongOption, "foo", ""), (cmdArgument, "=bar", "")]
  check("long option whitespace around separators", res, expected)

block:
  let res = collectStr("--foo =bar", longNoVal = @[""])
  let expected = [(cmdLongOption, "foo", "=bar")]
  check("long option argument delimited with whitespace, val allowed", res, expected)

block:
  let res = collectStr("--foo =bar")
  let expected = [(cmdLongOption, "foo", ""), (cmdArgument, "=bar", "")]
  check("long option argument delimited with whitespace, val not allowed", res, expected)

block:
  # pcLongAllowSep: '=' separator
  let res = collect(@["--foo=bar"])
  let expected = @[(cmdLongOption, "foo", "bar")]
  check("long option equals separator", res, expected)

block:
  # pcLongValAllowNextArg: long option value can be next argument.
  let res = collect(@["--foo", "bar"], longNoVal = @[""])
  let expected = @[(cmdLongOption, "foo", "bar")]
  check("long option next-arg value", res, expected)

block:
  # longNoVal disables next-arg value consumption.
  let res = collect(@["--foo", "bar"], longNoVal = @["foo"])
  let expected = @[(cmdLongOption, "foo", ""), (cmdArgument, "bar", "")]
  check("long option longNoVal disables argument taking", res, expected)

block:
  # "--" is parsed as a long option with an empty key.
  let res = collect(@["--", "rest"])
  let expected = @[(cmdLongOption, "", ""), (cmdArgument, "rest", "")]
  check("double-dash marker", res, expected)

block issue9619:
  let res = collect(@["--option=", "", "--anotherOption", "tree"])
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdLongOption, "option", ""),
                     (cmdLongOption, "anotherOption", ""),
                     (cmdArgument, "tree", "")]
    of rsNim:      @[(cmdLongOption, "option", ""),
                     (cmdLongOption, "anotherOption", ""),
                     (cmdArgument, "tree", "")]
    of rsGnu:      @[(cmdLongOption, "option", ""),
                     (cmdArgument, "", ""),
                     (cmdLongOption, "anotherOption", ""),
                     (cmdArgument, "tree", "")]
  check("issue #9619, whitespace after separator", res, expected)


block issue22736:
  let res = collect(@["--long", "", "-h", "--long:", "-h", "--long=", "-h", "arg"])
  let expected = case parseopt.RuleMode
    of rsPosixLax: @[(cmdLongOption, "long", ""),
                     (cmdArgument, "", ""),
                     (cmdShortOption, "h", ""),
                     (cmdLongOption, "long", "-h"),
                     (cmdLongOption, "long", "-h"),
                     (cmdArgument, "arg", "")]
    of rsNim:      @[(cmdLongOption, "long", ""),
                     (cmdArgument, "", ""),
                     (cmdShortOption, "h", ""),
                     (cmdLongOption, "long", "-h"),
                     (cmdLongOption, "long", "-h"),
                     (cmdArgument, "arg", "")]
    of rsGnu:      @[(cmdLongOption, "long", ""),
                     (cmdArgument, "", ""),
                     (cmdShortOption, "h", ""),
                     (cmdLongOption, "long:", ""),
                     (cmdShortOption, "h", ""),
                     (cmdLongOption, "long", ""),
                     (cmdShortOption, "h", ""),
                     (cmdArgument, "arg", "")]
  check("issue #22736, whitespace after separator, colon separator", res, expected)
