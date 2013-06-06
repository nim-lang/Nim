import os, osproc, streams, strutils, sequtils, tests

type
  TSymKind = enum ## Enums we want to parse from idetools.
    skUnknown, skProc, skTemplate, skIterator, skLet, skForVar, skType, skConst,
    skField, skParam, skVar, skEnumField, skResult,

  Texpected = tuple[input_file, option, path, sig: string;
    kind: TSymKind; line, col: int]

const
  COL_OPTION = 0
  COL_KIND = 1
  COL_SYMBOL_PATH = 2
  COL_SIGNATURE = 3
  COL_MODULE_PATH = 4
  COL_LINE = 5
  COL_COLUM = 6
  COL_DOCSTRING = 7
  TESTFILE = "tests.nim"
  I416 = "issue_416.nim"
  I452 = "issue_452.nim"


proc run_idetools(p: Texpected): string  =
  ## Runs the idetools command, returning output as a single string.
  let
    compiler {.global.} = findExe("nimrod")
    args = @["--verbosity:0", "--hints:off", "idetools", "--$1" % [p.option],
      "--track:$1,$2,$3" % [p.input_file, $p.line, $p.col], p.input_file]
  var
    process = startProcess(compiler, args = args)
    stream = outputStream(process)
    buf = ""

  result = ""
  while stream.readLine(buf): result &= buf
  process.close()


proc parse_idetools(idetools_output: string): seq[string] =
  ## Splits the idetools output in columns and makes sure we have enough.
  ##
  ## Returns nil on error.
  let cols = split(idetools_output, '\t')
  if cols.len < 7:
    echo "Expected 7 columns of output, but got $1 in '$2'" %
      [$cols.len, idetools_output]
    return

  result = cols


template fail(failure_text: string) =
  ## Dumps the failure text, then the cols that were being parsed and returns.
  echo failure_text
  echo "This happened parsing:"
  for index, value in cols.pairs: echo "\t$1: $2" % [$index, value]
  return


proc validate_parsed_columns(cols: seq[string], expected: Texpected): bool =
  ## Makes sure the expected values are found in the provided cols.
  ##
  ## Returns false if something doesn't match.
  if cols[COL_OPTION] != expected.option:
    fail "Expected '$1' for option column but got '$2'" %
      [expected.option, cols[COL_OPTION]]

  if parseEnum[TSymKind](cols[COL_KIND], skUnknown) != expected.kind:
    fail "Expected '$1' for kind column but got '$2'" %
      [$expected.kind, cols[COL_KIND]]

  if cols[COL_SYMBOL_PATH] != expected.path:
    fail "Expected '$1' for symbol path but got '$2'" %
      [expected.path, cols[COL_SYMBOL_PATH]]

  if cols[COL_SIGNATURE] != expected.sig:
    fail "Expected '$1' for symbol signature but got '$2'" %
      [expected.path, cols[COL_SIGNATURE]]

  result = true


proc test_stuff(all_runs: seq[Texpected], verbose: bool): int =
  ## Main tester loop, returns number of errors.
  for params in all_runs:
    if verbose:
      echo "Looking at $1, line $2 column $3" % [params.input_file,
        $params.line, $params.col]

    let output = run_idetools(params)
    if verbose: echo output

    let
      stored_result = result
      cols = parse_idetools(output)
    if cols.isNil():
      result += 1
    else:
      if not validate_parsed_columns(cols, params):
        result += 1
    # If the result increased, we failed, tell where.
    if stored_result != result:
      echo "...was looking at $1, line $2 column $3" % [params.input_file,
        $params.line, $params.col]


when isMainModule:
  var verbose : bool
  for i in 0..ParamCount() - 1:
    if paramStr(i + 1) == "verbose":
      verbose = true

  let all_runs : seq[Texpected] = @[ #\
    # Normal verification of generic output.
    (TESTFILE, "def", "system.TFile", "TFile", skType, 4, 11),
    (TESTFILE, "def", "system.Open",
      "proc (var TFile, string, TFileMode, int): bool", skProc, 5, 7),
    (TESTFILE, "def", "system.&",
      "proc (string, string): string{.noSideEffect.}", skProc, 5, 21),
    (TESTFILE, "def", "system.TFileMode.fmWrite",
      "TFileMode", skEnumField, 5, 38),
    (TESTFILE, "def", "system.Close",
      "proc (TFile)", skProc, 7, 6),
    (TESTFILE, "def", "unicode.runes",
      "iterator (string): TRune", skIterator, 12, 23),
    (TESTFILE, "def", "sequtils.toSeq",
      "proc (expr): expr", skTemplate, 12, 15),
    (TESTFILE, "def", "tests.SOME_SEQUENCE",
      "", skConst, 15, 7),
    (TESTFILE, "def", "system.@",
      "proc (array[IDX, T]): seq[T]{.noSideEffect.}", skProc, 15, 23),
    (TESTFILE, "def", "tests.bad_string",
      "", skType, 17, 3),
    (TESTFILE, "def", "tests.test_iterators.filename",
      "string", skParam, 11, 24),
    (TESTFILE, "def", "tests.test_enums.o",
      "TFile", skVar, 6, 5),
    (TESTFILE, "def", "tests.test_iterators.input",
      "TaintedString", skLet, 12, 34),
    (TESTFILE, "def", "tests.test_iterators.letter",
      "TRune", skForVar, 13, 35),
    (TESTFILE, "def", "tests.adder.result",
      "int", skResult, 23, 3),
    (TESTFILE, "def", "tests.TPerson.name",
      "", skField, 19, 6), #\
    # Test case for issue https://github.com/Araq/Nimrod/issues/452
    (I452, "def", "issue_452.VERSION_STR1", "", skConst, 2, 2),
    (I452, "def", "issue_452.VERSION_STR2", "", skConst, 3, 2),
    (I452, "def", "issue_452.forward1", "", skProc, 7, 5),
    (I452, "def", "issue_452.forward2", "", skProc, 8, 5), #\
    # Test case for issue https://github.com/Araq/Nimrod/issues/416
    (I416, "def", "sequtils.toSeq", "proc (expr): expr", skTemplate, 12, 16),
    (I416, "def", "unicode.runes", "iterator (string): TRune",
      skIterator, 12, 22),
    (I416, "def", "system.string", "string", skType, 12, 28),
    (I416, "def", "issue_416.failtest.input", "TaintedString", skLet, 12, 35),
    ]

  quit(test_stuff(all_runs, verbose))
