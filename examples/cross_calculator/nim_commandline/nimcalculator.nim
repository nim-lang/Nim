# Implements a command line interface against the backend.

import backend, parseopt, strutils

const
  USAGE = """nimcalculator - Nim cross platform calculator
  (beta version, only integer addition is supported!)

Usage:
  nimcalculator [options] [-a=value -b=value]
Options:
  -a=value    sets the integer value of the a parameter
  -b=value    sets the integer value of the b parameter
  -h, --help  shows this help

If no options are used, an interactive mode is entered.
"""

type
  TCommand = enum       # The possible types of operation
    cmdParams,          # Two valid parameters were provided
    cmdInteractive      # No parameters were provided, run interactive mode

  TParamConfig = object of RootObj
    action: TCommand      # store the type of operation
    paramA, paramB: int   # possibly store the valid parameters


proc parseCmdLine(): TParamConfig =
  ## Parses the commandline.
  ##
  ## Returns a TParamConfig structure filled with the proper values or directly
  ## calls quit() with the appropriate error message.
  var
    hasA = false
    hasB = false
    p = initOptParser()
    key, val: TaintedString

  result.action = cmdInteractive # By default presume interactive mode.
  try:
    while true:
      next p
      key = p.key
      val = p.val

      case p.kind
      of cmdArgument:
        stdout.write USAGE
        quit "Erroneous argument detected: " & key, 1
      of cmdLongOption, cmdShortOption:
        case key.normalize
        of "help", "h":
          stdout.write USAGE
          quit 0
        of "a":
          result.paramA = val.parseInt
          hasA = true
        of "b":
          result.paramB = val.parseInt
          hasB = true
        else:
          stdout.write USAGE
          quit "Unexpected option: " & key, 2
      of cmdEnd: break
  except ValueError:
    stdout.write USAGE
    quit "Invalid value " & val &  " for parameter " & key, 3

  if hasA and hasB:
    result.action = cmdParams
  elif hasA or hasB:
    stdout.write USAGE
    quit "Error: provide both A and B to operate in param mode", 4


proc parseUserInput(question: string): int =
  ## Parses a line of user input, showing question to the user first.
  ##
  ## If the user input is an empty line quit() is called. Returns the value
  ## parsed as an integer.
  while true:
    echo question
    let input = stdin.readLine
    try:
      result = input.parseInt
      break
    except ValueError:
      if input.len < 1: quit "Blank line detected, quitting.", 0
      echo "Sorry, `$1' doesn't seem to be a valid integer" % input

proc interactiveMode() =
  ## Asks the user for two integer values, adds them and exits.
  let
    paramA = parseUserInput("Enter the first parameter (blank to exit):")
    paramB = parseUserInput("Enter the second parameter (blank to exit):")
  echo "Calculating... $1 + $2 = $3" % [$paramA, $paramB,
    $backend.myAdd(paramA, paramB)]


when isMainModule:
  ## Main entry point.
  let opt = parseCmdLine()
  if cmdParams == opt.action:
    echo "Param mode: $1 + $2 = $3" % [$opt.paramA, $opt.paramB,
      $backend.myAdd(opt.paramA, opt.paramB)]
  else:
    echo "Entering interactive addition mode"
    interactiveMode()
