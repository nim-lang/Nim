import argument_parser, tables, strutils, parseutils

## Example defining a subset of wget's functionality

const
  PARAM_VERSION = @["-V", "--version"]
  PARAM_HELP = @["-h", "--help"]
  PARAM_BACKGROUND = @["-b", "--background"]
  PARAM_OUTPUT = @["-o", "--output"]
  PARAM_NO_CLOBBER = @["-nc", "--no-clobber"]
  PARAM_PROGRESS = @["--progress"]
  PARAM_NO_PROXY = @["--no-proxy"]


template P(tnames: varargs[string], thelp: string, ttype = PK_EMPTY,
    tcallback: Tparameter_callback = nil) =
  ## Helper to avoid repetition of parameter adding boilerplate.
  params.add(new_parameter_specification(ttype, custom_validator = tcallback,
    help_text = thelp, names = tnames))


template got(param: varargs[string]) =
  ## Just dump the detected options on output.
  if result.options.hasKey(param[0]): echo("Found option '$1'." % [param[0]])


proc parse_progress(parameter: string; value: var Tparsed_parameter): string =
  ## Custom parser and validator of progress types for PARAM_PROGRESS.
  ##
  ## If the user specifies the PARAM_PROGRESS option this proc will be called
  ## so we can validate the input. The proc returns a non empty string if
  ## something went wrong with the description of the error, otherwise
  ## execution goes ahead.
  ##
  ## This validator only accepts values without changing the final output.
  if value.str_val == "bar" or value.str_val == "dot":
    return

  result = "The string $1 is not valid, use bar or dot." % [value.str_val]


proc process_commandline(): Tcommandline_results =
  ## Parses the commandline.
  ##
  ## Returns a Tcommandline_results with at least two positional parameter,
  ## where the last parameter is implied to be the destination of the copying.
  var params: seq[Tparameter_specification] = @[]

  P(PARAM_VERSION, "Shows the version of the program")
  P(PARAM_HELP, "Shows this help on the commandline", PK_HELP)
  P(PARAM_BACKGROUND, "Continues execution in the background")
  P(PARAM_OUTPUT, "Specifies a specific output file name", PK_STRING)
  P(PARAM_NO_CLOBBER, "Skip downloads that would overwrite existing files")
  P(PARAM_PROGRESS, "Select progress look (bar or dot)",
    PK_STRING, parse_progress)
  P(PARAM_NO_PROXY, "Don't use proxies even if available")

  result = parse(params)

  if result.positional_parameters.len < 1:
    echo "Missing URL(s) to download"
    echo_help(params)
    quit()

  got(PARAM_NO_CLOBBER)
  got(PARAM_BACKGROUND)
  got(PARAM_NO_PROXY)

  if result.options.hasKey(PARAM_VERSION[0]):
    echo "Version 3.1415"
    quit()

  if result.options.hasKey(PARAM_OUTPUT[0]):
    if result.positional_parameters.len > 1:
      echo "Error: can't use $1 option with multiple URLs" % [PARAM_OUTPUT[0]]
      echo_help(params)
      quit()
    echo "Will download to $1" % [result.options[PARAM_OUTPUT[0]].str_val]

  if result.options.hasKey(PARAM_PROGRESS[0]):
    echo "Will use progress type $1" % [result.options[PARAM_PROGRESS[0]].str_val]


when true:
  let args = process_commandline()
  for param in args.positional_parameters:
    echo "Downloading $1" % param.str_val
