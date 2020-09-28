## Command line parsing module for Nim.
##
## `Nim <http://nim-lang.org>`_ provides the `parseopt module
## <http://nim-lang.org/parseopt.html>`_ to parse options from the
## commandline. This module tries to provide functionality to prevent you from
## writing commandline parsing and let you concentrate on providing the best
## possible experience for your users.
##
## Source code for this module can be found at
## https://github.com/gradha/argument_parser.

import os, strutils, tables, math, parseutils, sequtils, sets, algorithm,
  unicode

const
  VERSION_STR* = "0.1.2" ## Module version as a string.
  VERSION_INT* = (major: 0, minor: 1, maintenance: 2) ## \
  ## Module version as an integer tuple.
  ##
  ## Major versions changes mean a break in API backwards compatibility, either
  ## through removal of symbols or modification of their purpose.
  ##
  ## Minor version changes can add procs (and maybe default parameters). Minor
  ## odd versions are development/git/unstable versions. Minor even versions
  ## are public stable releases.
  ##
  ## Maintenance version changes mean bugfixes or non API changes.

# - Types

type
  Tparam_kind* = enum ## Different types of results for parameter parsing.
    PK_EMPTY, PK_INT, PK_FLOAT, PK_STRING, PK_BOOL,
    PK_BIGGEST_INT, PK_BIGGEST_FLOAT, PK_HELP

  Tparameter_callback* =
    proc (parameter: string; value: var Tparsed_parameter): string ## \
    ## Prototype of parameter callbacks
    ##
    ## A parameter callback is just a custom proc you provide which is invoked
    ## after a parameter is parsed passing the basic type validation. The
    ## `parameter` parameter is the string which triggered the option. The
    ## `value` parameter contains the string passed by the user already parsed
    ## into the basic type you specified for it.
    ##
    ## The callback proc has modification access to the Tparsed_parameter
    ## `value` parameter that will be put into Tcommandline_results: you can
    ## read it and also modify it, maybe changing its type. In fact, if you
    ## need special parsing, most likely you will end up specifying PK_STRING
    ## in the parameter input specification so that the parse() proc doesn't
    ## *mangle* the string before you can process it yourself.
    ##
    ## If the callback decides to abort the validation of the parameter, it has
    ## to put into result a non zero length string with a message for the user
    ## explaining why the validation failed, and maybe offer a hint as to what
    ## can be done to pass validation.

  Tparameter_specification* = object ## \
    ## Holds the expectations of a parameter.
    ##
    ## You create these objects and feed them to the parse() proc, which then
    ## uses them to detect parameters and turn them into something uself.
    names*: seq[string]  ## List of possible parameters to catch for this.
    consumes*: Tparam_kind ## Expected type of the parameter (empty for none)
    custom_validator*: Tparameter_callback  ## Optional custom callback
                                            ## to run after type conversion.
    help_text*: string    ## Help for this group of parameters.

  Tparsed_parameter* = object ## \
    ## Contains the parsed value from the user.
    ##
    ## This implements an object variant through the kind field. You can 'case'
    ## this field to write a generic proc to deal with parsed parameters, but
    ## nothing prevents you from accessing directly the type of field you want
    ## if you expect only one kind.
    case kind*: Tparam_kind
    of PK_EMPTY: discard
    of PK_INT: int_val*: int
    of PK_BIGGEST_INT: big_int_val*: BiggestInt
    of PK_FLOAT: float_val*: float
    of PK_BIGGEST_FLOAT: big_float_val*: BiggestFloat
    of PK_STRING: str_val*: string
    of PK_BOOL: bool_val*: bool
    of PK_HELP: discard

  Tcommandline_results* = object of RootObj ## \
    ## Contains the results of the parsing.
    ##
    ## Usually this is the result of the parse() call, but you can inherit from
    ## it to add your own fields for convenience.
    ##
    ## Note that you always have to access the ``options`` ordered table with
    ## the first variant of a parameter name. For instance, if you have an
    ## option specified like ``@["-s", "--silent"]`` and the user types
    ## ``--silent`` at the commandline, you have to use
    ## ``options.hasKey("-s")`` to test for it. This standarizes access through
    ## the first name variant for all options to avoid you repeating the test
    ## with different keys.
    positional_parameters*: seq[Tparsed_parameter]
    options*: OrderedTable[string, Tparsed_parameter]


# - Tparam_kind procs

proc `$`*(value: Tparam_kind): string =
  ## Stringifies the type, used to generate help texts.
  case value:
  of PK_EMPTY: result = ""
  of PK_INT: result = "INT"
  of PK_BIGGEST_INT: result = "BIG_INT"
  of PK_FLOAT: result = "FLOAT"
  of PK_BIGGEST_FLOAT: result = "BIG_FLOAG"
  of PK_STRING: result = "STRING"
  of PK_BOOL: result = "BOOL"
  of PK_HELP: result = ""

# - Tparameter_specification procs

proc init*(param: var Tparameter_specification, consumes = PK_EMPTY,
    custom_validator: Tparameter_callback = nil, help_text = "",
    names: varargs[string]) =
  ## Initialization helper with default parameters.
  ##
  ## You can decide to miss some if you like the defaults, reducing code. You
  ## can also use new_parameter_specification() for single assignment
  ## variables.
  param.names = @names
  param.consumes = consumes
  param.custom_validator = custom_validator
  param.help_text = help_text

proc new_parameter_specification*(consumes = PK_EMPTY,
    custom_validator: Tparameter_callback = nil, help_text = "",
    names: varargs[string]): Tparameter_specification =
  ## Initialization helper for single assignment variables.
  result.init(consumes, custom_validator, help_text, names)

# - Tparsed_parameter procs

proc `$`*(data: Tparsed_parameter): string =
  ## Stringifies the value, mostly for debug purposes.
  ##
  ## The proc will display the value followed by non string type in brackets.
  ## The non string types would be PK_INT (i), PK_BIGGEST_INT (I), PK_FLOAT
  ## (f), PK_BIGGEST_FLOAT (F), PK_BOOL (b). The string type would be enclosed
  ## inside quotes. PK_EMPTY produces the word `nil`, and PK_HELP produces the
  ## world `help`.
  case data.kind:
  of PK_EMPTY: result = "nil"
  of PK_INT: result = "$1(i)" % $data.int_val
  of PK_BIGGEST_INT: result = "$1(I)" % $data.big_int_val
  of PK_FLOAT: result = "$1(f)" % $data.float_val
  of PK_BIGGEST_FLOAT: result = "$1(F)" % $data.big_float_val
  of PK_STRING: result = "\"" & $data.str_val & "\""
  of PK_BOOL: result = "$1(b)" % $data.bool_val
  of PK_HELP: result = "help"


template new_parsed_parameter*(tkind: Tparam_kind, expr): Tparsed_parameter =
  ## Handy compile time template to build Tparsed_parameter object variants.
  ##
  ## The problem with object variants is that you first have to initialise them
  ## to a kind, then assign values to the correct variable, and it is a little
  ## bit annoying.
  ##
  ## Through this template you specify as the first parameter the kind of the
  ## Tparsed_parameter you want to build, and directly the value it will be
  ## initialised with. The template figures out at compile time what field to
  ## assign the variable to, and thus you reduce code clutter and may use this
  ## to initialise single assignments variables in `let` blocks. Example:
  ##
  ## .. code-block:: nim
  ##   let
  ##     parsed_param1 = new_parsed_parameter(PK_FLOAT, 3.41)
  ##     parsed_param2 = new_parsed_parameter(PK_BIGGEST_INT, 2358123 * 23123)
  ##     # The following line doesn't compile due to
  ##     # type mismatch: got <string> but expected 'int'
  ##     #parsed_param3 = new_parsed_parameter(PK_INT, "231")
  var result {.gensym.}: Tparsed_parameter
  result.kind = tkind
  when tkind == PK_EMPTY: discard
  elif tkind == PK_INT: result.int_val = expr
  elif tkind == PK_BIGGEST_INT: result.big_int_val = expr
  elif tkind == PK_FLOAT: result.float_val = expr
  elif tkind == PK_BIGGEST_FLOAT: result.big_float_val = expr
  elif tkind == PK_STRING: result.str_val = expr
  elif tkind == PK_BOOL: result.bool_val = expr
  elif tkind == PK_HELP: discard
  else: {.error: "unknown kind".}
  result

# - Tcommandline_results procs

proc init*(param: var Tcommandline_results;
    positional_parameters: seq[Tparsed_parameter] = @[];
    options: OrderedTable[string, Tparsed_parameter] =
      initOrderedTable[string, Tparsed_parameter](4)) =
  ## Initialization helper with default parameters.
  param.positional_parameters = positional_parameters
  param.options = options

proc `$`*(data: Tcommandline_results): string =
  ## Stringifies a Tcommandline_results structure for debug output
  var dict: seq[string] = @[]
  for key, value in data.options:
    dict.add("$1: $2" % [escape(key), $value])
  result = "Tcommandline_result{positional_parameters:[$1], options:{$2}}" % [
    join(map(data.positional_parameters, `$`), ", "), join(dict, ", ")]

# - Parse code

template raise_or_quit(exception, message: untyped) =
  ## Avoids repeating if check based on the default quit_on_failure variable.
  ##
  ## As a special case, if message has a zero length the call to quit won't
  ## generate any messages or errors (used by the mechanism to echo help to the
  ## user).
  if quit_on_failure:
    if len(message) > 0:
      quit(message)
    else:
      quit()
  else:
    raise newException(exception, message)

template run_custom_proc(parsed_parameter: Tparsed_parameter,
    custom_validator: Tparameter_callback,
    parameter: string) =
  ## Runs the custom validator if it is not nil.
  ##
  ## Pass in the string of the parameter triggering the call. If the
  if not custom_validator.isNil:
    try:
      let message = custom_validator(parameter, parsed_parameter)
      if message.len > 0:
        raise_or_quit(ValueError, ("Failed to validate value for " &
          "parameter $1:\n$2" % [escape(parameter), message]))
    except:
      raise_or_quit(ValueError, ("Couldn't run custom proc for " &
        "parameter $1:\n$2" % [escape(parameter),
        getCurrentExceptionMsg()]))

proc parse_parameter(quit_on_failure: bool, param, value: string,
    param_kind: Tparam_kind): Tparsed_parameter =
  ## Tries to parse a text according to the specified type.
  ##
  ## Pass the parameter string which requires a value and the text the user
  ## passed in for it. It will be parsed according to the param_kind. This proc
  ## will raise (ValueError, EOverflow) if something can't be parsed.
  result.kind = param_kind
  case param_kind:
  of PK_INT:
    try: result.int_val = value.parseInt
    except OverflowDefect:
      raise_or_quit(OverflowDefect, ("parameter $1 requires an " &
        "integer, but $2 is too large to fit into one") % [param,
        escape(value)])
    except ValueError:
      raise_or_quit(ValueError, ("parameter $1 requires an " &
        "integer, but $2 can't be parsed into one") % [param, escape(value)])
  of PK_STRING:
    result.str_val = value
  of PK_FLOAT:
    try: result.float_val = value.parseFloat
    except ValueError:
      raise_or_quit(ValueError, ("parameter $1 requires a " &
        "float, but $2 can't be parsed into one") % [param, escape(value)])
  of PK_BOOL:
    try: result.bool_val = value.parseBool
    except ValueError:
      raise_or_quit(ValueError, ("parameter $1 requires a " &
        "boolean, but $2 can't be parsed into one. Valid values are: " &
        "y, yes, true, 1, on, n, no, false, 0, off") % [param, escape(value)])
  of PK_BIGGEST_INT:
    try:
      let parsed_len = parseBiggestInt(value, result.big_int_val)
      if value.len != parsed_len or parsed_len < 1:
        raise_or_quit(ValueError, ("parameter $1 requires an " &
          "integer, but $2 can't be parsed completely into one") % [
          param, escape(value)])
    except ValueError:
      raise_or_quit(ValueError, ("parameter $1 requires an " &
        "integer, but $2 can't be parsed into one") % [param, escape(value)])
  of PK_BIGGEST_FLOAT:
    try:
      let parsed_len = parseBiggestFloat(value, result.big_float_val)
      if value.len != parsed_len or parsed_len < 1:
        raise_or_quit(ValueError, ("parameter $1 requires a " &
          "float, but $2 can't be parsed completely into one") % [
          param, escape(value)])
    except ValueError:
      raise_or_quit(ValueError, ("parameter $1 requires a " &
        "float, but $2 can't be parsed into one") % [param, escape(value)])
  of PK_EMPTY:
    discard
  of PK_HELP:
    discard


template build_specification_lookup():
    OrderedTable[string, ptr Tparameter_specification] =
  ## Returns the table used to keep pointers to all of the specifications.
  var result {.gensym.}: OrderedTable[string, ptr Tparameter_specification]
  result = initOrderedTable[string, ptr Tparameter_specification](expected.len)
  for i in 0..expected.len-1:
    for param_to_detect in expected[i].names:
      if result.hasKey(param_to_detect):
        raise_or_quit(KeyError,
          "Parameter $1 repeated in input specification" % param_to_detect)
      else:
        result[param_to_detect] = addr(expected[i])
  result


proc echo_help*(expected: seq[Tparameter_specification] = @[],
    type_of_positional_parameters = PK_STRING,
    bad_prefixes = @["-", "--"], end_of_options = "--")


proc parse*(expected: seq[Tparameter_specification] = @[],
    type_of_positional_parameters = PK_STRING, args: seq[string] = @[],
    bad_prefixes = @["-", "--"], end_of_options = "--",
    quit_on_failure = true): Tcommandline_results =
  ## Parses parameters and returns results.
  ##
  ## The expected array should contain a list of the parameters you want to
  ## detect, which can capture additional values. Uncaptured parameters are
  ## considered positional parameters for which you can specify a type with
  ## type_of_positional_parameters.
  ##
  ## Before accepting a positional parameter, the list of bad_prefixes is
  ## compared against it. If the positional parameter starts with any of them,
  ## an error is displayed to the user due to ambiguity. The user can overcome
  ## the ambiguity by typing the special string specified by end_of_options.
  ## Note that values captured by parameters are not checked against bad
  ## prefixes, otherwise it would be a problem to specify the dash as synonim
  ## for standard input for many programs.
  ##
  ## The args sequence should be the list of parameters passed to your program
  ## without the program binary (usually OSes provide the path to the binary as
  ## the zeroth parameter). If args is empty, the list will be retrieved from the
  ## OS.
  ##
  ## If there is any kind of error and quit_on_failure is true, the quit proc
  ## will be called with a user error message. If quit_on_failure is false
  ## errors will raise exceptions (usually ValueError or EOverflow) instead
  ## for you to catch and handle.

  assert type_of_positional_parameters != PK_EMPTY and
    type_of_positional_parameters != PK_HELP
  for bad_prefix in bad_prefixes:
    assert bad_prefix.len > 0, "Can't pass in a bad prefix of zero length"
  var
    expected = expected
    adding_options = true
  result.init()

  # Prepare the input parameter list, maybe get it from the OS if not available.
  var args = args
  if args.len == 0:
    let total_params = paramCount()
    #echo "Got no explicit args, retrieving from OS. Count: ", total_params
    newSeq(args, total_params)
    for i in 0..total_params - 1:
      #echo ($i)
      args[i] = paramStr(i + 1)

  # Generate lookup table for each type of parameter based on strings.
  var lookup = build_specification_lookup()

  # Loop through the input arguments detecting their type and doing stuff.
  var i = 0
  while i < args.len:
    let arg = args[i]
    block adding_positional_parameter:
      if arg.len > 0 and adding_options:
        if arg == end_of_options:
          # Looks like we found the end_of_options marker, disable options.
          adding_options = false
          break adding_positional_parameter
        elif lookup.hasKey(arg):
          var parsed: Tparsed_parameter
          let param = lookup[arg]

          # Insert check here for help, which aborts parsing.
          if param.consumes == PK_HELP:
            echo_help(expected, type_of_positional_parameters,
              bad_prefixes, end_of_options)
            raise_or_quit(KeyError, "")

          if param.consumes != PK_EMPTY:
            if i + 1 < args.len:
              parsed = parse_parameter(quit_on_failure,
                arg, args[i + 1], param.consumes)
              run_custom_proc(parsed, param.custom_validator, arg)
              i += 1
            else:
              raise_or_quit(ValueError, ("parameter $1 requires a " &
                "value, but none was provided") % [arg])
          result.options[param.names[0]] = parsed
          break adding_positional_parameter
        else:
          for bad_prefix in bad_prefixes:
            if arg.startsWith(bad_prefix):
              raise_or_quit(ValueError, ("Found ambiguos parameter '$1' " &
                "starting with '$2', put '$3' as the previous parameter " &
                "if you want to force it as positional parameter.") % [arg,
                bad_prefix, end_of_options])

      # Unprocessed, add the parameter to the list of positional parameters.
      result.positional_parameters.add(parse_parameter(quit_on_failure,
        $(1 + i), arg, type_of_positional_parameters))

    i += 1


proc toString(runes: seq[Rune]): string =
  result = ""
  for rune in runes: result.add(rune.toUTF8)


proc ascii_cmp(a, b: string): int =
  ## Comparison ignoring non ascii characters, for better switch sorting.
  let a = filterIt(toSeq(runes(a)), it.isAlpha())
  # Can't use filterIt twice, github bug #351.
  let b = filter(toSeq(runes(b)), proc(x: Rune): bool = x.isAlpha())
  return system.cmp(toString(a), toString(b))


proc build_help*(expected: seq[Tparameter_specification] = @[],
    type_of_positional_parameters = PK_STRING,
    bad_prefixes = @["-", "--"], end_of_options = "--"): seq[string] =
  ## Builds basic help text and returns it as a sequence of strings.
  ##
  ## Note that this proc doesn't do as much sanity checks as the normal parse()
  ## proc, though it's unlikely you will be using one without the other, so if
  ## you had a parameter specification problem you would find out soon.
  result = @["Usage parameters: "]

  # Generate lookup table for each type of parameter based on strings.
  let quit_on_failure = false
  var
    expected = expected
    lookup = build_specification_lookup()
    keys = toSeq(lookup.keys())

  # First generate the joined version of input parameters in a list.
  var
    seen = initHashSet[string]()
    prefixes: seq[string] = @[]
    helps: seq[string] = @[]
  for key in keys:
    if seen.contains(key):
      continue

    # Add the joined string to the list.
    let param = lookup[key][]
    var param_names = param.names
    sort(param_names, ascii_cmp)
    var prefix = join(param_names, ", ")
    # Don't forget about the type, if the parameter consumes values
    if param.consumes != PK_EMPTY and param.consumes != PK_HELP:
      prefix &= " " & $param.consumes
    prefixes.add(prefix)
    helps.add(param.help_text)
    # Ignore future elements.
    for name in param.names: seen.incl(name)

  # Calculate the biggest width and try to use that
  let width = prefixes.map(proc (x: string): int = 3 + len(x)).max

  for line in zip(prefixes, helps):
    result.add(line[0] & spaces(width - line[0].len) & line[1])


proc echo_help*(expected: seq[Tparameter_specification] = @[],
    type_of_positional_parameters = PK_STRING,
    bad_prefixes = @["-", "--"], end_of_options = "--") =
  ## Prints out help on the terminal.
  ##
  ## This is just a wrapper around build_help. Note that calling this proc
  ## won't exit your program, you should call quit() yourself.
  for line in build_help(expected,
      type_of_positional_parameters, bad_prefixes, end_of_options):
    echo line


when true:
  # Simply tests code embedded in docs.
  let
    parsed_param1 = new_parsed_parameter(PK_FLOAT, 3.41)
    parsed_param2 = new_parsed_parameter(PK_BIGGEST_INT, 2358123 * 23123)
    #parsed_param3 = new_parsed_parameter(PK_INT, "231")
