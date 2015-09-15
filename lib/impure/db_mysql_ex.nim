import strutils, mysql
import db_mysql

type
  RowNew* = tuple[hasData: bool,data: seq[string]] ## new Row type with a boolean
                                                   ## indicating if any data were
                                                   ## retrieved

proc getRowNew*(db: DbConn, query: SqlQuery,
             args: varargs[string, `$`]): RowNew {.tags: [FReadDB].} =
  ## executes the query and returns RowNew with hasData indicating if any data
  ## were retrieved
  result.hasData = false
  rawExec(db, query, args)
  var sqlres = mysql.useResult(db)
  if sqlres != nil:
    var L = int(mysql.numFields(sqlres))
    result.data = newRow(L)
    var row = mysql.fetchRow(sqlres)
    if row != nil:
      for i in 0..L-1:
        setLen(result.data[i], 0)
        if row[i] == nil:
          result.data[i] = nil
        else:
          add(result.data[i], row[i])
          result.hasData = true
    properFreeResult(sqlres, row)

proc getAllRowsNew*(db: DbConn, query: SqlQuery,
                 args: varargs[string, `$`]): seq[RowNew] {.tags: [FReadDB].} =
  ## executes the query and returns the whole result dataset with a boolean for
  ## each row indicating whether row has any data
  result = @[]
  rawExec(db, query, args)
  var sqlres = mysql.useResult(db)
  if sqlres != nil:
    var L = int(mysql.numFields(sqlres))
    var row: cstringArray
    var j = 0
    while true:
      row = mysql.fetchRow(sqlres)
      if row == nil: break
      setLen(result, j+1)
      result[j].data = @[]
      result[j].hasData = false
      newSeq(result[j].data, L)
      for i in 0..L-1:
        if row[i] == nil:
          result[j].data[i] = nil
        else:
          result[j].data[i] = $row[i]
          result[j].hasData = true
      inc(j)
    mysql.freeResult(sqlres)

