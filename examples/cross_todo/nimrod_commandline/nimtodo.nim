# Implements a command line interface against the backend.

import backend, db_sqlite, os, parseopt, parseutils, strutils, times

const
  USAGE = """nimtodo - Nimrod cross platform todo manager

Usage:
  nimtodo [command] [list options]

Commands:
  -a=int text Adds a todo entry with the specified priority and text.
  -c=int      Marks the specified todo entry as done.
  -u=int      Marks the specified todo entry as not done.
  -d=int|all  Deletes a single entry from the database, or all entries.
  -g          Generates some rows with values for testing.
  -l          Lists the contents of the database.
  -h, --help  shows this help

List options (optional):
  -p=+|-      Sorts list by ascending|desdencing priority. Default:desdencing.
  -m=+|-      Sorts list by ascending|desdencing date. Default:desdencing.
  -t          Show checked entries. By default they are not shown.
  -z          Hide unchecked entries. By default they are shown.

Examples:
  nimtodo -a=4 Water the plants
  nimtodo -c:87
  nimtodo -d:2
  nimtodo -d:all
  nimtodo -l -p=+ -m=- -t

"""

type
  TCommand = enum     # The possible types of commands
    cmdAdd            # The user wants to add a new todo entry.
    cmdCheck          # User wants to check a todo entry.
    cmdUncheck        # User wants to uncheck a todo entry.
    cmdDelete         # User wants to delete a single todo entry.
    cmdNuke           # User wants to purge all database entries.
    cmdGenerate       # Add random rows to the database, for testing.
    cmdList           # User wants to list contents.

  TParamConfig = object of TObject
    # Structure containing the parsed options from the commandline.
    command: TCommand         # Store the type of operation
    addPriority: int          # Only valid with cmdAdd, stores priority.
    addText: seq[string]      # Only valid with cmdAdd, stores todo text.
    todoId: int64             # The todo id for operations like check or delete.
    listParams: TPagedParams  # Uses the backend structure directly for params.


proc initDefaults(params: var TParamConfig) =
  ## Initialises defaults value in the structure.
  ##
  ## Most importantly we want to have an empty list for addText.
  params.listParams.initDefaults
  params.addText = @[]


proc parseCmdLine(): TParamConfig =
  ## Parses the commandline.
  ##
  ## Returns a TParamConfig structure filled with the proper values or directly
  ## calls quit() with the appropriate error message.
  var
    specifiedCommand = false
    usesListParams = false
    p = initOptParser()
    key, val: TaintedString
    newId: biggestInt

  result.initDefaults

  try:
    while true:
      next(p)
      key = p.key
      val = p.val

      case p.kind
      of cmdArgument:
        if specifiedCommand and cmdAdd == result.command:
          result.addText.add(key)
        else:
          stdout.write(USAGE)
          quit("Argument ($1) detected without add command." % [key], 1)
      of cmdLongOption, cmdShortOption:
        case normalize(key)
        of "help", "h":
          stdout.write(USAGE)
          quit(0)
        of "a":
          if specifiedCommand:
            stdout.write(USAGE)
            quit("Only one command can be specified at a time! ($1)" % [val], 2)
          else:
            result.command = cmdAdd
            result.addPriority = val.parseInt
            specifiedCommand = true
        of "c":
          if specifiedCommand:
            stdout.write(USAGE)
            quit("Only one command can be specified at a time! ($1)" % [val], 2)
          else:
            result.command = cmdCheck
            let numChars = string(val).parseBiggestInt(newId)
            if numChars < 1: raise newException(EInvalidValue, "Empty string?")
            result.todoId = newId
            specifiedCommand = true
        of "u":
          if specifiedCommand:
            stdout.write(USAGE)
            quit("Only one command can be specified at a time! ($1)" % [val], 2)
          else:
            result.command = cmdUncheck
            let numChars = val.parseBiggestInt(newId)
            if numChars < 1: raise newException(EInvalidValue, "Empty string?")
            result.todoId = newId
            specifiedCommand = true
        of "d":
          if specifiedCommand:
            stdout.write(USAGE)
            quit("Only one command can be specified at a time! ($1)" % [val], 2)
          else:
            if "all" == val:
              result.command = cmdNuke
            else:
              result.command = cmdDelete
              let numChars = val.parseBiggestInt(newId)
              if numChars < 1:
                raise newException(EInvalidValue, "Empty string?")
              result.todoId = newId
            specifiedCommand = true
        of "g":
          if specifiedCommand:
            stdout.write(USAGE)
            quit("Only one command can be specified at a time! ($1)" % [val], 2)
          else:
            if val.len > 0:
              stdout.write(USAGE)
              quit("Unexpected value '$1' for switch l." % [val], 3)
            result.command = cmdGenerate
            specifiedCommand = true
        of "l":
          if specifiedCommand:
            stdout.write(USAGE)
            quit("Only one command can be specified at a time! ($1)" % [val], 2)
          else:
            if val.len > 0:
              stdout.write(USAGE)
              quit("Unexpected value '$1' for switch l." % [val], 3)
            result.command = cmdList
            specifiedCommand = true
        of "p":
          usesListParams = true
          case val
          of "+":
            result.listParams.priorityAscending = true
          of "-":
            result.listParams.priorityAscending = false
          else:
            stdout.write(USAGE)
            quit("Priority parameter ($1) should be + or |." % [val], 4)
        of "m":
          usesListParams = true
          case val
          of "+":
            result.listParams.dateAscending = true
          of "-":
            result.listParams.dateAscending = false
          else:
            stdout.write(USAGE)
            quit("Date parameter ($1) should be + or |." % [val], 4)
        of "t":
          usesListParams = true
          if val.len > 0:
            stdout.write(USAGE)
            quit("Unexpected value '$1' for switch t." % [val], 5)
          result.listParams.showChecked = true
        of "z":
          usesListParams = true
          if val.len > 0:
            stdout.write(USAGE)
            quit("Unexpected value '$1' for switch z." % [val], 5)
          result.listParams.showUnchecked = false
        else:
          stdout.write(USAGE)
          quit("Unexpected option '$1'." % [key], 6)
      of cmdEnd:
        break
  except EInvalidValue:
    stdout.write(USAGE)
    quit("Invalid int value '$1' for parameter '$2'." % [val, key], 7)

  if not specifiedCommand:
    stdout.write(USAGE)
    quit("Didn't specify any command.", 8)

  if cmdAdd == result.command and result.addText.len < 1:
    stdout.write(USAGE)
    quit("Used the add command, but provided no text/description.", 9)

  if usesListParams and cmdList != result.command:
    stdout.write(USAGE)
    quit("Used list options, but didn't specify the list command.", 10)


proc generateDatabaseRows(conn: TDbConn) =
  ## Adds some rows to the database ignoring errors.
  discard conn.addTodo(1, "Watch another random youtube video")
  discard conn.addTodo(2, "Train some starcraft moves for the league")
  discard conn.addTodo(3, "Spread the word about Nimrod")
  discard conn.addTodo(4, "Give fruit superavit to neighbours")
  var todo = conn.addTodo(4, "Send tax form through snail mail")
  todo.isDone = true
  discard todo.save(conn)
  discard conn.addTodo(1, "Download new anime to watch")
  todo = conn.addTodo(2, "Build train model from scraps")
  todo.isDone = true
  discard todo.save(conn)
  discard conn.addTodo(5, "Buy latest Britney Spears album")
  discard conn.addTodo(6, "Learn a functional programming language")
  echo("Generated some entries, they were added to your database.")


proc listDatabaseContents(conn: TDbConn; listParams: TPagedParams) =
  ## Dumps the database contents formatted to the standard output.
  ##
  ## Pass the list/filter parameters parsed from the commandline.
  var params = listParams
  params.pageSize = -1

  let todos = conn.getPagedTodos(params)
  if todos.len < 1:
    echo("Database empty")
    return

  echo("Todo id, is done, priority, last modification date, text:")
  # First detect how long should be our columns for formatting.
  var cols: array[0..2, int]
  for todo in todos:
    cols[0] = max(cols[0], ($todo.getId).len)
    cols[1] = max(cols[1], ($todo.priority).len)
    cols[2] = max(cols[2], ($todo.getModificationDate).len)

  # Now dump all the rows using the calculated alignment sizes.
  for todo in todos:
    echo("$1 $2 $3, $4, $5" % [
      ($todo.getId).align(cols[0]),
      if todo.isDone: "[X]" else: "[-]",
      ($todo.priority).align(cols[1]),
      ($todo.getModificationDate).align(cols[2]),
      todo.text])


proc deleteOneTodo(conn: TDbConn; todoId: int64) =
  ## Deletes a single todo entry from the database.
  let numDeleted = conn.deleteTodo(todoId)
  if numDeleted > 0:
    echo("Deleted todo id " & $todoId)
  else:
    quit("Couldn't delete todo id " & $todoId, 11)


proc deleteAllTodos(conn: TDbConn) =
  ## Deletes all the contents from the database.
  ##
  ## Note that it would be more optimal to issue a direct DELETE sql statement
  ## on the database, but for the sake of the example we will restrict
  ## ourselfves to the API exported by backend.
  var
    counter: int64
    params: TPagedParams

  params.initDefaults
  params.pageSize = -1
  params.showUnchecked = true
  params.showChecked = true

  let todos = conn.getPagedTodos(params)
  for todo in todos:
    if conn.deleteTodo(todo.getId) > 0:
      counter += 1
    else:
      quit("Couldn't delete todo id " & $todo.getId, 12)

  echo("Deleted $1 todo entries from database." % $counter)


proc setTodoCheck(conn: TDbConn; todoId: int64; value: bool) =
  ## Changes the check state of a todo entry to the specified value.
  let
    newState = if value: "checked" else: "unchecked"
    todo = conn.getTodo(todoId)

  if todo == nil:
    quit("Can't modify todo id $1, its not in the database." % $todoId, 13)

  if todo[].isDone == value:
    echo("Todo id $1 was already set to $2." % [$todoId, newState])
    return

  todo[].isDone = value
  if todo[].save(conn):
    echo("Todo id $1 set to $2." % [$todoId, newState])
  else:
    quit("Error updating todo id $1 to $2." % [$todoId, newState])


proc addTodo(conn: TDbConn; priority: int; tokens: seq[string]) =
  ## Adds to the database a todo with the specified priority.
  ##
  ## The tokens are joined as a single string using the space character. The
  ## created id will be displayed to the user.
  let todo = conn.addTodo(priority, tokens.join(" "))
  echo("Created todo entry with id:$1 for priority $2 and text '$3'." % [
    $todo.getId, $todo.priority, todo.text])


when isMainModule:
  ## Main entry point.
  let
    opt = parseCmdLine()
    dbPath = getConfigDir() / "nimtodo.sqlite3"

  if not dbPath.existsFile:
    createDir(getConfigDir())
    echo("No database found at $1, it will be created for you." % dbPath)

  let conn = openDatabase(dbPath)
  try:
    case opt.command
    of cmdAdd: addTodo(conn, opt.addPriority, opt.addText)
    of cmdCheck: setTodoCheck(conn, opt.todoId, true)
    of cmdUncheck: setTodoCheck(conn, opt.todoId, false)
    of cmdDelete: deleteOneTodo(conn, opt.todoId)
    of cmdNuke: deleteAllTodos(conn)
    of cmdGenerate: generateDatabaseRows(conn)
    of cmdList: listDatabaseContents(conn, opt.listParams)
  finally:
    conn.close
