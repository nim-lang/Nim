# Tests the backend code.

import backend, db_sqlite, strutils, times


proc showPagedResults(conn: TDbConn; params: TPagedParams) =
  ## Shows the contents of the database in pages of specified size.
  ##
  ## Hmm... I guess this is more of a debug proc which should be moved outside,
  ## or to a commandline interface (hint).
  var
    page = 0'i64
    rows = conn.getPagedTodos(params)

  while rows.len > 0:
    echo("page " & $page)
    for row in rows:
      echo("row id:$1, text:$2, priority:$3, done:$4, date:$5" % [$row.getId,
        $row.text, $row.priority, $row.isDone,
        $row.getModificationDate])
    # Query the database for the next page or quit.
    if params.pageSize > 0:
      page = page + 1
      rows = conn.getPagedTodos(params, page)
    else:
      break


proc dumTest() =
  let conn = openDatabase("todo.sqlite3")
  try:
    let numTodos = conn.getNumEntries
    echo("Current database contains " & $numTodos & " todo items.")
    if numTodos < 10:
      # Fill some dummy rows if there are not many entries yet.
      discard conn.addTodo(3, "Filler1")
      discard conn.addTodo(4, "Filler2")

    var todo = conn.addTodo(2, "Testing")
    echo("New todo added with id " & $todo.getId)

    # Try changing it and updating the database.
    var clonedTodo = conn.getTodo(todo.getId)[]
    assert(clonedTodo.text == todo.text, "Should be equal")
    todo.text = "Updated!"
    todo.priority = 7
    todo.isDone = true
    if todo.save(conn):
      echo("Updated priority $1, done $2" % [$todo.priority, $todo.isDone])
    else:
      assert(false, "Uh oh, I wasn't expecting that!")

    # Verify our cloned copy is different but can be updated.
    assert(clonedTodo.text != todo.text, "Should be different")
    discard clonedTodo.update(conn)
    assert(clonedTodo.text == todo.text, "Should be equal")

    var params: TPagedParams
    params.initDefaults
    conn.showPagedResults(params)
    conn.deleteTodo(todo.getId)
    echo("Deleted rows for id 3? ")
    let res = conn.deleteTodo(todo.getId)
    echo("Deleted rows for id 3? " & $res)
    if todo.update(conn):
      echo("Later priority $1, done $2" % [$todo.priority, $todo.isDone])
    else:
      echo("Can't update object $1 from db!" % $todo.getId)

    # Try to list content in a different way.
    params.pageSize = 5
    params.priorityAscending = true
    params.dateAscending = true
    params.showChecked = true
    conn.showPagedResults(params)
  finally:
    conn.close
    echo("Database closed")


# Code that will be run only on the commandline.
when isMainModule:
  dumTest()
