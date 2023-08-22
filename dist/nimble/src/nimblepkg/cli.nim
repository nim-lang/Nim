# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.
#
# Rough rules/philosophy for the messages that Nimble displays are the following:
#   - Green is only shown when the requested operation is successful.
#   - Blue can be used to emphasise certain keywords, for example actions such
#     as "Downloading" or "Reading".
#   - Red is used when the requested operation fails with an error.
#   - Yellow is used for warnings.
#
#   - Dim for LowPriority.
#   - Bright for HighPriority.
#   - Normal for MediumPriority.

import terminal, sets, strutils
import common

type
  CLI* = ref object
    level: Priority
    warnings: HashSet[(string, string)]
    suppressionCount: int ## Amount of messages which were not shown.
    showColor: bool ## Whether messages should be colored.
    suppressMessages: bool ## Whether Warning, Message and Success messages
                           ## should be suppressed, useful for
                           ## commands like `dump` whose output should be
                           ## machine readable.

  Priority* = enum
    DebugPriority, LowPriority, MediumPriority, HighPriority, SilentPriority

  DisplayType* = enum
    Error, Warning, Details, Hint, Message, Success

  ForcePrompt* = enum
    dontForcePrompt, forcePromptYes, forcePromptNo

const
  longestCategory = len("Downloading")
  foregrounds: array[Error .. Success, ForegroundColor] =
    [fgRed, fgYellow, fgBlue, fgWhite, fgCyan, fgGreen]
  styles: array[DebugPriority .. HighPriority, set[Style]] =
    [{styleDim}, {styleDim}, {}, {styleBright}]

proc newCLI(): CLI =
  result = CLI(
    level: HighPriority,
    showColor: true,
  )

var globalCLI = newCLI()

proc calculateCategoryOffset(category: string): int =
  assert category.len <= longestCategory
  return longestCategory - category.len

proc isSuppressed(displayType: DisplayType): bool =
  # Don't print any Warning, Message or Success messages when suppression of
  # warnings is enabled. That is, unless the user asked for --verbose output.
  if globalCLI.suppressMessages and displayType >= Warning and
     globalCLI.level == HighPriority:
    return true

proc displayCategory(category: string, displayType: DisplayType,
                     priority: Priority) =
  if isSuppressed(displayType):
    return

  # Calculate how much the `category` must be offset to align along a center
  # line.
  let offset = calculateCategoryOffset(category)

  # Display the category.
  let text = "$1$2 " % [spaces(offset), category]
  if globalCLI.showColor:
    if priority != DebugPriority:
      setForegroundColor(stdout, foregrounds[displayType])
    writeStyled(text, styles[priority])
    resetAttributes()
  else:
    stdout.write(text)

proc displayLine(category, line: string, displayType: DisplayType,
                 priority: Priority) =
  if isSuppressed(displayType):
    return

  displayCategory(category, displayType, priority)

  # Display the message.
  echo(line)

proc display*(category, msg: string, displayType = Message,
              priority = MediumPriority) =
  # Multiple warnings containing the same messages should not be shown.
  let warningPair = (category, msg)
  if displayType == Warning:
    if warningPair in globalCLI.warnings:
      return
    else:
      globalCLI.warnings.incl(warningPair)

  # Suppress this message if its priority isn't high enough.
  # TODO: Per-priority suppression counts?
  if priority < globalCLI.level:
    if priority != DebugPriority:
      globalCLI.suppressionCount.inc
    return

  # Display each line in the message.
  var i = 0
  for line in msg.splitLines():
    if len(line) == 0: continue
    displayLine(if i == 0: category else: "...", line, displayType, priority)
    i.inc

proc displayWarning*(message: string, priority = HighPriority) =
  display("Warning: ", message, Warning, priority)

proc displayHint*(message: string, priority = HighPriority) =
  display("Hint: ", message, Hint, priority)

proc displayDetails*(message: string, priority = HighPriority) =
  display("Details: ", message, Details, priority)

proc displaySuccess*(message: string, priority = HighPriority) =
  display("Success: ", message, Success, priority)

proc displayError*(message: string,  priority = HighPriority) =
  display("Error: ", message, Error, priority)

proc displayInfo*(message: string, priority = HighPriority) =
  display("Info: ", message, Message, priority)

template defineDisplayMethods(displayMethodName: untyped) {.dirty.} =
  method displayMethodName*(error: ref CatchableError, priority = HighPriority)
      {.base.} =
    displayMethodName(error.msg, priority)
    var errorIt = error
    if errorIt.parent != nil:
      displayDetails((ref CatchableError)(errorIt.parent), priority)

  method displayMethodName*(error: ref NimbleError, priority = HighPriority) =
    procCall (ref CatchableError)(error).displayMethodName(priority)
    displayHint(error.hint, priority)

defineDisplayMethods(displayDetails)
defineDisplayMethods(displayError)
defineDisplayMethods(displayWarning)

proc displayDebug*(category, msg: string) =
  ## Convenience for displaying debug messages.
  display(category, msg, priority = DebugPriority)

proc displayDebug*(msg: string) =
  ## Convenience for displaying debug messages with a default category.
  displayDebug("Debug:", msg)

proc displayTip*() =
  ## Called just before Nimble exits. Shows some tips for the user, for example
  ## the amount of messages that were suppressed and how to show them.
  if globalCLI.suppressionCount > 0:
    let msg = "$1 messages have been suppressed, use --verbose to show them." %
             $globalCLI.suppressionCount
    display("Tip:", msg, Warning, HighPriority)

proc prompt*(forcePrompts: ForcePrompt, question: string): bool =
  case forcePrompts
  of forcePromptYes:
    display("Prompt:", question & " -> [forced yes]", Warning, HighPriority)
    return true
  of forcePromptNo:
    display("Prompt:", question & " -> [forced no]", Warning, HighPriority)
    return false
  of dontForcePrompt:
    display("Prompt:", question & " [y/N]", Warning, HighPriority)
    displayCategory("Answer:", Warning, HighPriority)
    let yn = stdin.readLine()
    case yn.normalize
    of "y", "yes":
      return true
    of "n", "no":
      return false
    else:
      return false

proc promptCustom*(forcePrompts: ForcePrompt, question, default: string): string =
  case forcePrompts:
  of forcePromptYes:
    display("Prompt:", question & " -> [forced " & default & "]", Warning,
      HighPriority)
    return default
  else:
    if default == "":
      display("Prompt:", question, Warning, HighPriority)
      displayCategory("Answer:", Warning, HighPriority)
      let user = stdin.readLine()
      if user.len == 0: return promptCustom(forcePrompts, question, default)
      else: return user
    else:
      display("Prompt:", question & " [" & default & "]", Warning, HighPriority)
      displayCategory("Answer:", Warning, HighPriority)
      let user = stdin.readLine()
      if user == "": return default
      else: return user

proc promptCustom*(question, default: string): string =
  return promptCustom(dontForcePrompt, question, default)

proc promptListInteractive(question: string, args: openarray[string]): string =
  display("Prompt:", question, Warning, HighPriority)
  display("Select", "Cycle with 'Tab', 'Enter' when done", Message,
    HighPriority)
  displayCategory("Choices:", Warning, HighPriority)
  var
    current = 0
    selected = false
  # Incase the cursor is at the bottom of the terminal
  for arg in args:
    stdout.write "\n"
  # Reset the cursor to the start of the selection prompt
  cursorUp(stdout, args.len)
  cursorForward(stdout, longestCategory)
  hideCursor(stdout)

  # The selection loop
  while not selected:
    setForegroundColor(fgDefault)
    # Loop through the options
    for i, arg in args:
      # Check if the option is the current
      if i == current:
        writeStyled("> " & arg & " <", {styleBright})
      else:
        writeStyled("  " & arg & "  ", {styleDim})
      # Move the cursor back to the start
      for s in 0..<(arg.len + 4):
        cursorBackward(stdout)
      # Move down for the next item
      cursorDown(stdout)
    # Move the cursor back up to the start of the selection prompt
    for i in 0..<(args.len()):
      cursorUp(stdout)
    resetAttributes(stdout)

    # Ensure that the screen is updated before input
    flushFile(stdout)
    # Begin key input
    while true:
      case getch():
      of '\t':
        current = (current + 1) mod args.len
        break
      of '\r':
        selected = true
        break
      of '\3':
        showCursor(stdout)
        raise nimbleError("Keyboard interrupt")
      of '\27':
        if getch() != '\91': continue
        case getch():
        of char(65): # Up arrow
          current = (args.len + current - 1) mod args.len
          break
        of char(66): # Down arrow
          current = (current + 1) mod args.len
          break
        else: discard
      else: discard

  # Erase all lines of the selection
  for i in 0..<args.len:
    eraseLine(stdout)
    cursorDown(stdout)
  # Move the cursor back up to the initial selection line
  for i in 0..<args.len():
    cursorUp(stdout)
  showCursor(stdout)
  display("Answer:", args[current], Warning,HighPriority)
  return args[current]

proc promptListFallback(question: string, args: openarray[string]): string =
  display("Prompt:", question & " [" & join(args, "/") & "]", Warning,
    HighPriority)
  displayCategory("Answer:", Warning, HighPriority)
  result = stdin.readLine()
  for arg in args:
    if arg.cmpIgnoreCase(result) == 0:
      return arg

proc promptList*(forcePrompts: ForcePrompt, question: string, args: openarray[string]): string =
  case forcePrompts:
  of forcePromptYes:
    result = args[0]
    display("Prompt:", question & " -> [forced " & result & "]", Warning,
      HighPriority)
  else:
    if isatty(stdout):
      return promptListInteractive(question, args)
    else:
      return promptListFallback(question, args)

proc setVerbosity*(level: Priority) =
  globalCLI.level = level

proc setShowColor*(val: bool) =
  globalCLI.showColor = val

proc setSuppressMessages*(val: bool) =
  globalCLI.suppressMessages = val
