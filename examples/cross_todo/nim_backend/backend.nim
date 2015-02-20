# Backend for a simple todo program with sqlite persistence.
#
# Most procs dealing with a TDbConn object may raise an EDb exception.

import db_sqlite, parseutils, strutils, times


type
  TTodo* = object
    ## A todo object holding the information serialized to the database.
    id: int64                 ## Unique identifier of the object in the
                              ## database, use the getId() accessor to read it.
    text*: string             ## Description of the task to do.
    priority*: int            ## The priority can be any user defined integer.
    isDone*: bool             ## Done todos are still kept marked.
    modificationDate: Time    ## The modification time can't be modified from
                              ## outside of this module, use the
                              ## getModificationDate accessor.

  TPagedParams* = object
    ## Contains parameters for a query, initialize default values with
    ## initDefaults().
    pageSize*: int64          ## Lines per returned query page, -1 for
                              ## unlimited.
    priorityAscending*: bool  ## Sort results by ascending priority.
    dateAscending*: bool      ## Sort results by ascending modification date.
    showUnchecked*: bool      ## Get unchecked objects.
    showChecked*: bool        ## Get checked objects.


# - General procs
#
proc initDefaults*(params: var TPagedParams) =
  ## Sets sane defaults for a TPagedParams object.
  ##
  ## Note that you should always provide a non zero pageSize, either a specific
  ## positive value or negative for unbounded query results.
  params.pageSize = high(int64)
  params.priorityAscending = false
  params.dateAscending = false
  params.showUnchecked = true
  params.showChecked = false


proc openDatabase*(path: string): TDbConn =
  ## Creates or opens the sqlite3 database.
  ##
  ## Pass the path to the sqlite database, if the database doesn't exist it
  ## will be created. The proc may raise a EDB exception
  let
    conn = db_sqlite.open(path, "user", "pass", "db")
    query = sql"""CREATE TABLE IF NOT EXISTS Todos (
      id INTEGER PRIMARY KEY,
      priority INTEGER NOT NULL,
      is_done BOOLEAN NOT NULL,
      desc TEXT NOT NULL,
      modification_date INTEGER NOT NULL,
      CONSTRAINT Todos UNIQUE (id))"""

  db_sqlite.exec(conn, query)
  result = conn


# - Procs related to TTodo objects
#
proc initFromDB(id: int64; text: string; priority: int, isDone: bool;
               modificationDate: Time): TTodo =
  ## Returns an initialized TTodo object created from database parameters.
  ##
  ## The proc assumes all values are right. Note this proc is NOT exported.
  assert(id >= 0, "Identity identifiers should not be negative")
  result.id = id
  result.text = text
  result.priority = priority
  result.isDone = isDone
  result.modificationDate = modificationDate


proc getId*(todo: TTodo): int64 =
  ## Accessor returning the value of the private id property.
  return todo.id


proc getModificationDate*(todo: TTodo): Time =
  ## Returns the last modification date of a TTodo entry.
  return todo.modificationDate


proc update*(todo: var TTodo; conn: TDbConn): bool =
  ## Checks the database for the object and refreshes its variables.
  ##
  ## Use this method if you (or another entity) have modified the database and
  ## want to update the object you have with whatever the database has stored.
  ## Returns true if the update succeeded, or false if the object was not found
  ## in the database any more, in which case you should probably get rid of the
  ## TTodo object.
  assert(todo.id >= 0, "The identifier of the todo entry can't be negative")
  let query = sql"""SELECT desc, priority, is_done, modification_date
    FROM Todos WHERE id = ?"""

  try:
    let rows = conn.getAllRows(query, $todo.id)
    if len(rows) < 1:
      return
    assert(1 == len(rows), "Woah, didn't expect so many rows")
    todo.text = rows[0][0]
    todo.priority = rows[0][1].parseInt
    todo.isDone = rows[0][2].parseBool
    todo.modificationDate = Time(rows[0][3].parseInt)
    result = true
  except:
    echo("Something went wrong selecting for id " & $todo.id)


proc save*(todo: var TTodo; conn: TDbConn): bool =
  ## Saves the current state of text, priority and isDone to the database.
  ##
  ## Returns true if the database object was updated (in which case the
  ## modification date will have changed). The proc can return false if the
  ## object wasn't found, for instance, in which case you should drop that
  ## object anyway and create a new one with addTodo(). Also EDb can be raised.
  assert(todo.id >= 0, "The identifier of the todo entry can't be negative")
  let
    currentDate = getTime()
    query = sql"""UPDATE Todos
      SET desc = ?, priority = ?, is_done = ?, modification_date = ?
      WHERE id = ?"""
    rowsUpdated = conn.execAffectedRows(query, $todo.text,
      $todo.priority, $todo.isDone, $int(currentDate), $todo.id)

  if 1 == rowsUpdated:
    todo.modificationDate = currentDate
    result = true


# - Procs dealing directly with the database
#
proc addTodo*(conn: TDbConn; priority: int; text: string): TTodo =
  ## Inserts a new todo into the database.
  ##
  ## Returns the generated todo object. If there is an error EDb will be raised.
  let
    currentDate = getTime()
    query = sql"""INSERT INTO Todos
      (priority, is_done, desc, modification_date)
      VALUES (?, 'false', ?, ?)"""
    todoId = conn.insertId(query, priority, text, $int(currentDate))

  result = initFromDB(todoId, text, priority, false, currentDate)


proc deleteTodo*(conn: TDbConn; todoId: int64): int64 {.discardable.} =
  ## Deletes the specified todo identifier.
  ##
  ## Returns the number of rows which were affected (1 or 0)
  let query = sql"""DELETE FROM Todos WHERE id = ?"""
  result = conn.execAffectedRows(query, $todoId)


proc getNumEntries*(conn: TDbConn): int =
  ## Returns the number of entries in the Todos table.
  ##
  ## If the function succeeds, returns the zero or positive value, if something
  ## goes wrong a negative value is returned.
  let query = sql"""SELECT COUNT(id) FROM Todos"""
  try:
    let row = conn.getRow(query)
    result = row[0].parseInt
  except:
    echo("Something went wrong retrieving number of Todos entries")
    result = -1


proc getPagedTodos*(conn: TDbConn; params: TPagedParams;
                    page = 0'i64): seq[TTodo] =
  ## Returns the todo entries for a specific page.
  ##
  ## Pages are calculated based on the params.pageSize parameter, which can be
  ## set to a negative value to specify no limit at all.  The query will be
  ## affected by the TPagedParams, which should have sane values (call
  ## initDefaults).
  assert(page >= 0, "You should request a page zero or bigger than zero")
  result = @[]

  # Well, if you don't want to see anything, there's no point in asking the db.
  if not params.showUnchecked and not params.showChecked: return

  let
    order_by = [
      if params.priorityAscending: "ASC" else: "DESC",
      if params.dateAscending: "ASC" else: "DESC"]

    query = sql("""SELECT id, desc, priority, is_done, modification_date
      FROM Todos
      WHERE is_done = ? OR is_done = ?
      ORDER BY priority $1, modification_date $2, id DESC
      LIMIT ? * ?,?""" % order_by)

    args = @[$params.showChecked, $(not params.showUnchecked),
      $params.pageSize, $page, $params.pageSize]

  #echo("Query " & string(query))
  #echo("args: " & args.join(", "))

  var newId: BiggestInt
  for row in conn.fastRows(query, args):
    let numChars = row[0].parseBiggestInt(newId)
    assert(numChars > 0, "Huh, couldn't parse identifier from database?")
    result.add(initFromDB(int64(newId), row[1], row[2].parseInt,
        row[3].parseBool, Time(row[4].parseInt)))


proc getTodo*(conn: TDbConn; todoId: int64): ref TTodo =
  ## Returns a reference to a TTodo or nil if the todo could not be found.
  var tempTodo: TTodo
  tempTodo.id = todoId
  if tempTodo.update(conn):
    new(result)
    result[] = tempTodo
